import 'dart:io';

import 'package:bdlogging/bdlogging.dart';
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
import 'package:db_infra/src/build_signing_type.dart';
import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/setup_executor/setup_executor.dart';
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

    final String? developerTeamId = configuration.iosDeveloperTeamId;

    final ProvisionProfileType provisionProfileType =
        configuration.iosProvisionProfileType;

    final IosBuildSigningType signingType = configuration.iosBuildSigningType;

    final File exportOptionsPlist;
    final InfraBuildConfiguration buildConfiguration;

    if (developerTeamId != null) {
      exportOptionsPlist = profilesManager.exportOptionsPlist(
        appId: appId,
        signingType: signingType,
        developerTeamId: developerTeamId,
        provisionProfileType: provisionProfileType,
      );

      buildConfiguration = _createBuildConfiguration(
        signingType: signingType,
        iosDeveloperTeamId: developerTeamId,
        exportOptionsPlist: exportOptionsPlist,
        certificateSigningRequest: getCertificateSigningRequestFile(),
      );
    } else {
      final String? provisionProfileName =
          configuration.iosProvisionProfileName?.trim();

      CertificateSigningRequest? csr = getCertificateSigningRequestFile();

      _ProvisionProfileWithCertificateSha1? data;

      if (csr != null && provisionProfileName != null) {
        data = await getExistingProvisionProfile(
          appId,
          csr,
          provisionProfileName,
          configuration.iosProvisionProfileType,
        );
      } else if (csr != null) {
        data = await createAndInstallProvisionProfile(appId, csr);
      } else {
        csr = createCertificateSigningRequestFile();

        data = await createAndInstallProvisionProfile(appId, csr);
      }

      exportOptionsPlist = profilesManager.exportOptionsPlist(
        appId: appId,
        signingType: signingType,
        certificateSha1: data.certificateSha1,
        provisionProfile: data.profile,
        developerTeamId: developerTeamId,
        provisionProfileType: provisionProfileType,
      );

      buildConfiguration = _createBuildConfiguration(
        profileData: data,
        signingType: signingType,
        certificateSigningRequest: csr,
        iosDeveloperTeamId: developerTeamId,
        exportOptionsPlist: exportOptionsPlist,
      );
    }

    certificatesManager.cleanupLocally();

    return buildConfiguration;
  }

  ///
  @visibleForTesting
  Future<_ProvisionProfileWithCertificateSha1> getExistingProvisionProfile(
    String appId,
    CertificateSigningRequest csr,
    String provisionProfileName,
    ProvisionProfileType provisionProfileType,
  ) async {
    BDLogger().info(
      'Using existing Provision Profile provided $provisionProfileName...',
    );
    final ProvisionProfile? profile =
        await profilesManager.getProfileWithName(provisionProfileName);

    if (profile == null) {
      throw UnrecoverableException(
        'No Provision Profile found with id $provisionProfileName, '
        'in your available list of provision profiles',
        ExitCode.config.code,
      );
    }

    final BundleId? bundleId =
        await bundleIdManager.getBundleId(profile.bundleId.id);

    if (bundleId != null &&
        !bundleIdManager.isBundleIdForApp(bundleId, appId)) {
      throw UnrecoverableException(
        'The specified provision profile is bundle id does not match '
        'the current project appId\n${bundleId.identifier} != $appId',
        ExitCode.config.code,
      );
    }

    BDLogger().info(
      'Searching valid signing certificate '
      'for Provision profile ${profile.name}',
    );

    final List<Certificate> validCertificates =
        await profilesManager.getValidCertificate(profile);

    if (validCertificates.isNotEmpty) {
      BDLogger().info(
        'Found valid signing certificates:\n'
        '${validCertificates.map(
              (Certificate e) => '${e.id} - ${e.name}',
            ).join('\n')}',
      );

      for (final Certificate certificate in validCertificates) {
        final bool isSignedByPrivateKey = await certificatesManager
            .isSignedWithPrivateKey(certificate, csr.privateKey);

        if (isSignedByPrivateKey) {
          return _installCertificateForProvisionProfile(
            csr,
            certificate,
            profile,
          );
        }
      }

      return _createNewCertificateForProfile(
        csr,
        profile,
        provisionProfileType,
      );
    } else {
      return _createNewCertificateForProfile(
        csr,
        profile,
        provisionProfileType,
      );
    }
  }

  Future<_ProvisionProfileWithCertificateSha1> _createNewCertificateForProfile(
    CertificateSigningRequest csr,
    ProvisionProfile profile,
    ProvisionProfileType provisionProfileType,
  ) async {
    BDLogger().warning(
      'Did not find certificate signed with ${csr.privateKey.path}',
    );

    final CertificateType newCertificateType =
        provisionProfileType.isDevelopment()
            ? CertificateType.development
            : CertificateType.distribution;

    BDLogger().info(
      'Creating a new certificate of type ${newCertificateType.name}',
    );

    final CertificateSigningRequest resolvedCsr =
        csr.request != null && csr.request!.existsSync()
            ? csr
            : createCSRFromPrivateKey(csr.privateKey, csr.publicKey);

    final Certificate newCertificate =
        await certificatesManager.createCertificate(
      resolvedCsr.request!,
      newCertificateType,
    );

    BDLogger().info(
      'Created a new certificate ${newCertificate.name} - ${newCertificate.id}',
    );

    return _installCertificateForProvisionProfile(
      csr,
      newCertificate,
      profile,
    );
  }

  _ProvisionProfileWithCertificateSha1 _installCertificateForProvisionProfile(
    CertificateSigningRequest csr,
    Certificate certificate,
    ProvisionProfile profile,
  ) {
    certificatesManager
      ..importCertificateFileLocally(csr.privateKey)
      ..importCertificateFileLocally(csr.publicKey);

    final String? sha1 =
        certificatesManager.importCertificateLocally(certificate);

    if (sha1 == null) {
      throw UnrecoverableException(
        'Could not retrieve certificate SHA1 for certificate: '
        '${certificate.name} - ${certificate.id}',
        ExitCode.osError.code,
      );
    }

    return _ProvisionProfileWithCertificateSha1(
      profile: profile,
      certificate: certificate,
      certificateSha1: sha1,
    );
  }

  ///
  @visibleForTesting
  Future<_ProvisionProfileWithCertificateSha1> createAndInstallProvisionProfile(
    String appId,
    CertificateSigningRequest csr,
  ) async {
    BDLogger().info('Creating new Provision profile for $appId');

    final BundleId bundleId = await bundleIdManager.getOrCreateBundleId(appId);

    final CertificateType certificateType =
        configuration.iosProvisionProfileType.isDevelopment()
            ? CertificateType.development
            : CertificateType.distribution;

    final Certificate? certificateSignedByKey =
        await certificatesManager.findCertificateSignedByKey(csr.privateKey);

    final Certificate certificate;

    if (certificateSignedByKey?.type == certificateType) {
      BDLogger().info(
        'Found reusable ${certificateType.key} Certificate '
        'signed with ${csr.privateKey.path}',
      );

      certificate = certificateSignedByKey!;
    } else {
      BDLogger().info(
        'No reusable ${certificateType.key} Certificate found.\n'
        'Creating new one signed with ${csr.privateKey.path}...',
      );

      final CertificateSigningRequest resolvedCsr =
          csr.request != null && csr.request!.existsSync()
              ? csr
              : createCSRFromPrivateKey(csr.privateKey, csr.publicKey);

      certificate = await certificatesManager.createCertificate(
        resolvedCsr.request!,
        certificateType,
      );

      BDLogger().info(
        '${certificate.type.key} Certificate '
        '${certificate.id} - ${certificate.name} created.',
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

    return _installCertificateForProvisionProfile(
      csr,
      certificate,
      newProfile,
    );
  }

  ///
  @visibleForTesting
  CertificateSigningRequest? getCertificateSigningRequestFile() {
    final String? csrPath = configuration.iosCertificateSigningRequestPath;

    final String? csrPrivateKeyPath =
        configuration.iosCertificateSigningRequestPrivateKeyPath;

    final String? csrPublicKeyPath =
        configuration.iosCertificateSigningRequestPublicKeyPath;

    if (csrPrivateKeyPath != null && csrPublicKeyPath != null) {
      final File csrPublicKeyFile = File(csrPublicKeyPath);
      final File csrPrivateKeyFile = File(csrPrivateKeyPath);

      if (csrPrivateKeyFile.existsSync() && csrPublicKeyFile.existsSync()) {
        return CertificateSigningRequest(
          request: csrPath != null ? File(csrPath) : null,
          publicKey: csrPublicKeyFile,
          privateKey: csrPrivateKeyFile,
        );
      }
    }

    return null;
  }

  ///
  @visibleForTesting
  CertificateSigningRequest createCSRFromPrivateKey(
    File privateKey,
    File publicKey,
  ) {
    final String? csrName = configuration.iosCertificateSigningRequestName;
    final String? csrEmail = configuration.iosCertificateSigningRequestEmail;

    return certificatesManager.createCertificateSigningRequest(
      appId: configuration.iosAppId,
      csrEmail: csrEmail,
      csrName: csrName,
      privateKey: privateKey,
      publicKey: publicKey,
    );
  }

  ///
  @visibleForTesting
  CertificateSigningRequest createCertificateSigningRequestFile() {
    final String? csrName = configuration.iosCertificateSigningRequestName;
    final String? csrEmail = configuration.iosCertificateSigningRequestEmail;

    return certificatesManager.createCertificateSigningRequest(
      appId: configuration.iosAppId,
      csrEmail: csrEmail,
      csrName: csrName,
    );
  }

  InfraBuildConfiguration _createBuildConfiguration({
    required final File exportOptionsPlist,
    required final IosBuildSigningType signingType,
    final CertificateSigningRequest? certificateSigningRequest,
    final _ProvisionProfileWithCertificateSha1? profileData,
    final String? iosDeveloperTeamId,
  }) {
    return InfraBuildConfiguration(
      androidAppId: configuration.androidAppId,
      iosAppId: configuration.iosAppId,
      iosAppStoreConnectKeyId: configuration.iosAppStoreConnectKeyId,
      iosAppStoreConnectKeyIssuer: configuration.iosAppStoreConnectKeyIssuer,
      iosAppStoreConnectKey: configuration.iosAppStoreConnectKey,
      iosCertificateSigningRequest: certificateSigningRequest?.request,
      iosCertificateSigningRequestPrivateKey:
          certificateSigningRequest?.privateKey,
      iosCertificateSigningRequestPublicKey:
          certificateSigningRequest?.publicKey,
      iosCertificateSigningRequestName:
          configuration.iosCertificateSigningRequestName,
      iosCertificateSigningRequestEmail:
          configuration.iosCertificateSigningRequestEmail,
      iosProvisionProfileName: profileData?.profile.name,
      iosProvisionProfileType:
          profileData?.profile.type ?? configuration.iosProvisionProfileType,
      iosCertificateId: profileData?.certificate.id,
      iosDeveloperTeamId: iosDeveloperTeamId,
      iosExportOptionsPlist: exportOptionsPlist,
      iosSigningType: signingType,
      encryptor: configuration.encryptor,
      storage: configuration.storage,
      storageType: configuration.storageType,
      encryptorType: configuration.encryptorType,
      iosBuildOutputType: configuration.iosBuildOutputType,
      androidBuildOutputType: configuration.androidBuildOutputType,
      androidKeyAlias: configuration.androidKeyAlias,
      androidKeyPassword: configuration.androidKeyPassword,
      androidStoreFile: configuration.androidStoreFile,
      androidStorePassword: configuration.androidStorePassword,
    );
  }
}

class _ProvisionProfileWithCertificateSha1 {
  final String certificateSha1;
  final Certificate certificate;
  final ProvisionProfile profile;

  const _ProvisionProfileWithCertificateSha1({
    required this.profile,
    required this.certificate,
    required this.certificateSha1,
  });
}
