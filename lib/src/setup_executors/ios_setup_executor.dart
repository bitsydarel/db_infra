import 'dart:io';

import 'package:db_infra/src/apple/bundle_id/bundle_id.dart';
import 'package:db_infra/src/apple/bundle_id/bundle_id_manager.dart';
import 'package:db_infra/src/apple/certificates/certificate.dart';
import 'package:db_infra/src/apple/certificates/certificate_signing_request.dart';
import 'package:db_infra/src/apple/certificates/certificate_type.dart';
import 'package:db_infra/src/apple/certificates/certificates_manager.dart';
import 'package:db_infra/src/apple/device/device.dart';
import 'package:db_infra/src/apple/device/device_manager.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile_manager.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile_type.dart';
import 'package:db_infra/src/configurations/infra_build_configuration.dart';
import 'package:db_infra/src/configurations/infra_setup_configuration.dart';
import 'package:db_infra/src/setup_executor.dart';
import 'package:db_infra/src/shell_runner.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:io/io.dart';
import 'package:meta/meta.dart';

///
class IosSetupExecutor extends SetupExecutor {
  ///
  final ProvisionProfileManager profilesManager;

  ///
  final CertificatesManager certificatesManager;

  ///
  final BundleIdManager bundleIdManager;

  ///
  final DeviceManager deviceManager;

  ///
  final ShellRunner runner;

  ///
  const IosSetupExecutor({
    required InfraSetupConfiguration configuration,
    required Directory infraDirectory,
    required this.profilesManager,
    required this.certificatesManager,
    required this.bundleIdManager,
    required this.deviceManager,
    this.runner = const ShellRunner(),
  }) : super(configuration, infraDirectory);

  @override
  Future<InfraBuildConfiguration> setupInfra() async {
    final String appId = configuration.iosAppId;

    _ProvisionProfileWithCertificateSha1? data;

    CertificateSigningRequest? csr = getCertificateSigningRequestFile();
    final String? provisionProfileId =
        configuration.iosProvisionProfileId?.trim();

    if (csr != null && provisionProfileId != null) {
      data =
          await getAndInstallProvisionProfile(appId, provisionProfileId, csr);
    } else if (csr != null) {
      data = await createAndInstallProvisionProfile(appId, csr);
    } else {
      csr = createCertificateSigningRequestFile();

      if (csr != null) {
        data = await createAndInstallProvisionProfile(appId, csr);
      }
    }

    if (csr != null && data != null) {
      final File exportOptionsPlist = profilesManager
          .exportOptionsPlist(appId, data.profile, certificateSha1: data.sha1);

      final InfraBuildConfiguration buildConfiguration =
          _createBuildConfiguration(csr, data, exportOptionsPlist);

      certificatesManager.cleanupLocally();

      return buildConfiguration;
    }

    throw UnrecoverableException(
      'Could not find or create Certificate signing request, '
      'please provide one or specify email and name tto be used',
      ExitCode.tempFail.code,
    );
  }

  ///
  @visibleForTesting
  Future<_ProvisionProfileWithCertificateSha1> getAndInstallProvisionProfile(
    String appId,
    String provisionProfileID,
    CertificateSigningRequest csr,
  ) async {
    final ProvisionProfile? profile =
        await profilesManager.getProfileWithID(provisionProfileID);

    if (profile == null) {
      throw UnrecoverableException(
        'No provision profile found with uuid $provisionProfileID, '
        'in your available list of provision profiles',
        ExitCode.config.code,
      );
    }

    final BundleId? bundleId =
        await bundleIdManager.getBundleId(profile.bundleId.id);

    if (bundleId != null && bundleId.identifier != appId) {
      throw UnrecoverableException(
        'The specified provision profile is bundle id does not match '
        'the current project appId\n${bundleId.identifier} != $appId',
        ExitCode.config.code,
      );
    }

    final Certificate? validCertificate =
        await profilesManager.getValidCertificate(profile);

    if (validCertificate != null) {
      final bool isSignedByPrivateKey = await certificatesManager
          .isSignedWithPrivateKey(validCertificate, csr.privateKey);

      if (isSignedByPrivateKey) {
        certificatesManager.importCertificateFileLocally(csr.privateKey);

        final File? publicKey = csr.publicKey;

        if (publicKey != null) {
          certificatesManager.importCertificateFileLocally(publicKey);
        }

        final String? sha1 =
            certificatesManager.importCertificateLocally(validCertificate);

        return _ProvisionProfileWithCertificateSha1(profile, sha1);
      }

      throw UnrecoverableException(
        'Distribution certificate ${validCertificate.name} with id '
        '${validCertificate.id} was not signed with ${csr.privateKey.path}',
        ExitCode.tempFail.code,
      );
    } else {
      throw UnrecoverableException(
        'Provision profile with uuid $provisionProfileID does not have '
        'usable distribution certificate\n'
        "Either create one in the developer portal or don't specify the "
        'provision profile, we will create a new provision profile.',
        ExitCode.config.code,
      );
    }
  }

  ///
  @visibleForTesting
  Future<_ProvisionProfileWithCertificateSha1> createAndInstallProvisionProfile(
    String appId,
    CertificateSigningRequest csr,
  ) async {
    final BundleId bundleId = await bundleIdManager.getOrCreateBundleId(appId);

    final CertificateType certificateType =
        configuration.iosProvisionProfileType.isDevelopment()
            ? CertificateType.development
            : CertificateType.distribution;

    final Certificate? certificateSignedByKey =
        await certificatesManager.findCertificateSignedByKey(csr.privateKey);

    final Certificate certificate;

    if (certificateSignedByKey?.type == certificateType) {
      certificate = certificateSignedByKey!;
    } else {
      certificate = await certificatesManager.createCertificate(
        csr.request,
        certificateType,
      );
    }

    final List<Device> devices;

    if (configuration.iosProvisionProfileType ==
        ProvisionProfileType.iosAppStore) {
      devices = <Device>[];
    } else {
      devices = await deviceManager.getAllDevices();
    }

    final ProvisionProfile newProfile =
        await profilesManager.createProvisionProfile(
      bundleId,
      <Certificate>[certificate],
      devices,
      configuration.iosProvisionProfileType,
    );

    certificatesManager.importCertificateFileLocally(csr.privateKey);

    final File? publicKey = csr.publicKey;

    if (publicKey != null) {
      certificatesManager.importCertificateFileLocally(publicKey);
    }

    final String? sha1 =
        certificatesManager.importCertificateLocally(certificate);

    return _ProvisionProfileWithCertificateSha1(newProfile, sha1);
  }

  ///
  @visibleForTesting
  CertificateSigningRequest? getCertificateSigningRequestFile() {
    final String? csrPath = configuration.iosCertificateSigningRequestPath;

    final String? csrPrivateKeyPath =
        configuration.iosCertificateSigningRequestPrivateKeyPath;

    if (csrPrivateKeyPath != null) {
      final File csrPrivateKeyFile = File(csrPrivateKeyPath);

      if (csrPrivateKeyFile.existsSync()) {
        final File csrFile;

        if (csrPath != null) {
          csrFile = File(csrPath);

          return CertificateSigningRequest(
            request: csrFile,
            privateKey: csrPrivateKeyFile,
          );
        } else {
          return createCSRFromPrivateKey(csrPrivateKeyFile);
        }
      }
    }

    return null;
  }

  ///
  @visibleForTesting
  CertificateSigningRequest createCSRFromPrivateKey(
    File privateKey,
  ) {
    final String? csrName = configuration.iosCertificateSigningRequestName;
    final String? csrEmail = configuration.iosCertificateSigningRequestEmail;

    return certificatesManager.createCertificateSigningRequest(
      configuration.iosAppId,
      csrEmail,
      csrName,
      privateKey,
    );
  }

  ///
  @visibleForTesting
  CertificateSigningRequest? createCertificateSigningRequestFile() {
    final String? csrName = configuration.iosCertificateSigningRequestName;
    final String? csrEmail = configuration.iosCertificateSigningRequestEmail;

    if (csrName != null && csrEmail != null) {
      return certificatesManager.createCertificateSigningRequest(
        configuration.iosAppId,
        csrEmail,
        csrName,
      );
    }

    return null;
  }

  InfraBuildConfiguration _createBuildConfiguration(
    final CertificateSigningRequest csr,
    final _ProvisionProfileWithCertificateSha1 profileData,
    final File exportOptionsPlist,
  ) {
    return InfraBuildConfiguration(
      androidAppId: configuration.androidAppId,
      iosAppId: configuration.iosAppId,
      iosAppStoreConnectKeyId: configuration.iosAppStoreConnectKeyId,
      iosAppStoreConnectKeyIssuer: configuration.iosAppStoreConnectKeyIssuer,
      iosAppStoreConnectKey: configuration.iosAppStoreConnectKey,
      iosCertificateSigningRequest: csr.request,
      iosCertificateSigningRequestPrivateKey: csr.privateKey,
      iosCertificateSigningRequestName:
          configuration.iosCertificateSigningRequestName,
      iosCertificateSigningRequestEmail:
          configuration.iosCertificateSigningRequestEmail,
      iosProvisionProfileId: profileData.profile.id,
      iosProvisionProfileType: profileData.profile.type,
      iosCertificateId: profileData.profile.certificates.first.id,
      iosExportOptionsPlist: exportOptionsPlist,
      encryptor: configuration.encryptor,
      storage: configuration.storage,
      storageType: configuration.storageType,
      encryptorType: configuration.encryptorType,
      iosBuildOutputType: configuration.iosBuildOutputType,
      androidBuildOutputType: configuration.androidBuildOutputType,
    );
  }
}

class _ProvisionProfileWithCertificateSha1 {
  final ProvisionProfile profile;
  final String? sha1;

  const _ProvisionProfileWithCertificateSha1(this.profile, this.sha1);
}
