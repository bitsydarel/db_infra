import 'dart:io';

import 'package:db_infra/src/infra_configurations/infra_configuration.dart';
import 'package:db_infra/src/infra_configurations/infra_setup_configuration.dart';
import 'package:db_infra/src/infra_setup_executor.dart';
import 'package:db_infra/src/shell_runner.dart';
import 'package:db_infra/src/apis/apple/bundle_id.dart';
import 'package:db_infra/src/apis/apple/bundle_id_manager.dart';
import 'package:db_infra/src/apis/apple/certificate.dart';
import 'package:db_infra/src/apis/apple/certificate_signing_request.dart';
import 'package:db_infra/src/apis/apple/certificates_manager.dart';
import 'package:db_infra/src/apis/apple/device.dart';
import 'package:db_infra/src/apis/apple/profile.dart';
import 'package:db_infra/src/apis/apple/profiles_manager.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:io/io.dart';
import 'package:meta/meta.dart';

///
class InfraIosSetupExecutor extends InfraSetupExecutor {
  ///
  final ProfilesManager profilesManager;

  ///
  final CertificatesManager certificatesManager;

  ///
  final BundleIdManager bundleIdManager;

  ///
  final ShellRunner runner;

  ///
  const InfraIosSetupExecutor({
    required InfraSetupConfiguration configuration,
    required Directory infraDirectory,
    required this.profilesManager,
    required this.certificatesManager,
    required this.bundleIdManager,
    this.runner = const ShellRunner(),
  }) : super(configuration, infraDirectory);

  @override
  Future<InfraConfiguration> setupInfra() async {
    final String appId = configuration.iosAppId;

    CertificateSigningRequest? csr = getCertificateSigningRequestFile();

    if (csr != null) {
      final String? provisionProfileId =
          configuration.iosDistributionProvisionProfileUUID?.trim();

      final _ProvisionProfileWithCertificateSha1 data;

      if (provisionProfileId != null) {
        data =
            await getAndInstallProvisionProfile(appId, provisionProfileId, csr);
      } else {
        data = await createAndInstallProvisionProfile(appId, csr);
      }

      final File exportOptionsPlist = data.profile.generateExportOptionsPlist(
        infraDirectory,
        appId,
        certificateSha1: data.sha1,
      );

      return _createConfiguration(csr, data, exportOptionsPlist);
    }

    csr = createCertificateSigningRequestFile();

    if (csr != null) {
      final _ProvisionProfileWithCertificateSha1 data =
          await createAndInstallProvisionProfile(appId, csr);

      final File exportOptionsPlist = data.profile.generateExportOptionsPlist(
        infraDirectory,
        appId,
        certificateSha1: data.sha1,
      );

      return _createConfiguration(csr, data, exportOptionsPlist);
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
    String provisionProfileUUID,
    CertificateSigningRequest csr,
  ) async {
    final Profile? profile =
        await profilesManager.getProfileWithUUID(provisionProfileUUID);

    if (profile == null) {
      throw UnrecoverableException(
        'No provision profile found with uuid $provisionProfileUUID, '
        'in your available list of provision profiles',
        ExitCode.config.code,
      );
    }

    final BundleId bundleId =
        await bundleIdManager.api.get(profile.bundleId.id);

    if (bundleId.identifier != appId) {
      throw UnrecoverableException(
        'The specified provision profile is bundle id does not the current '
        'project appId\n${bundleId.identifier} != $appId',
        ExitCode.config.code,
      );
    }

    final Certificate? validCertificate =
        await getValidDistributionCertificate(profile);

    if (validCertificate != null) {
      final bool areMatch = await certificatesManager.isSignedWithPrivateKey(
        validCertificate,
        csr.privateKey,
      );

      if (areMatch) {
        certificatesManager.keychainsManager
            .importIntoAppKeychain(csr.privateKey);

        final File? publicKey = csr.publicKey;

        if (publicKey != null) {
          certificatesManager.keychainsManager.importIntoAppKeychain(publicKey);
        }

        final String? sha1 =
            await certificatesManager.importCertificate(validCertificate);

        profilesManager.importProfile(profile);

        return _ProvisionProfileWithCertificateSha1(profile, sha1);
      }

      throw UnrecoverableException(
        'Distribution certificate ${validCertificate.name} with id '
        '${validCertificate.id} was not signed with ${csr.privateKey.path}',
        ExitCode.tempFail.code,
      );
    } else {
      throw UnrecoverableException(
        'Provision profile with uuid $provisionProfileUUID does not have '
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

    final Certificate certificate = await certificatesManager
        .createAndCleanDistributionCertificate(csr.request);

    final Profile newProfile = await profilesManager.reCreateDistribution(
      bundleId,
      <Certificate>[certificate],
      const <Device>[],
    );

    certificatesManager.keychainsManager.importIntoAppKeychain(csr.privateKey);

    final File? publicKey = csr.publicKey;

    if (publicKey != null) {
      certificatesManager.keychainsManager.importIntoAppKeychain(publicKey);
    }

    final String? sha1 =
        await certificatesManager.importCertificate(certificate);

    profilesManager.importProfile(newProfile);

    return _ProvisionProfileWithCertificateSha1(newProfile, sha1);
  }

  ///
  @visibleForTesting
  Future<Certificate?> getValidDistributionCertificate(
    final Profile profile,
  ) async {
    for (final ProfileRelation relation in profile.certificates) {
      final Certificate certificate =
          await certificatesManager.api.get(relation.id);

      if (certificate.isDistribution() && !certificate.hasExpired()) {
        return certificate;
      }
    }
  }

  ///
  @visibleForTesting
  CertificateSigningRequest? getCertificateSigningRequestFile() {
    final String? csrPath = configuration.iosCertificateSigningRequestPath;
    final String? csrPrivateKeyPath =
        configuration.iosCertificateSigningRequestPrivateKeyPath;

    if (csrPath != null && csrPrivateKeyPath != null) {
      final File csrFile = File(csrPath);
      final File csrPrivateKeyFile = File(csrPrivateKeyPath);

      if (csrFile.existsSync() && csrPrivateKeyFile.existsSync()) {
        return CertificateSigningRequest(
          request: csrFile,
          privateKey: csrPrivateKeyFile,
        );
      }
    }

    return null;
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

  InfraConfiguration _createConfiguration(
    final CertificateSigningRequest csr,
    final _ProvisionProfileWithCertificateSha1 profileData,
    final File exportOptionsPlist,
  ) {
    return InfraConfiguration(
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
      iosDistributionProvisionProfileUUID: profileData.profile.uuid,
      iosDistributionCertificateId: profileData.profile.certificates.first.id,
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
  final Profile profile;
  final String? sha1;

  const _ProvisionProfileWithCertificateSha1(this.profile, this.sha1);
}
