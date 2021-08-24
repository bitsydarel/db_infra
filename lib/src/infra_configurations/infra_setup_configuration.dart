import 'dart:io';

import 'package:db_infra/src/infra_build_output_type.dart';
import 'package:db_infra/src/infra_run_configuration.dart';
import 'package:db_infra/src/infra_encryptor.dart';
import 'package:db_infra/src/infra_encryptor_type.dart';
import 'package:db_infra/src/infra_storage.dart';
import 'package:db_infra/src/infra_storage_type.dart';

///
class InfraSetupConfiguration extends InfraRunConfiguration {
  ///
  final String? iosCertificateSigningRequestPath;

  ///
  final String? iosCertificateSigningRequestPrivateKeyPath;

  ///
  final String? iosCertificateSigningRequestName;

  ///
  final String? iosCertificateSigningRequestEmail;

  ///
  final String? iosDistributionProvisionProfileUUID;

  ///
  final String? iosDistributionCertificateId;

  ///
  const InfraSetupConfiguration({
    required String androidAppId,
    required String iosAppId,
    required String iosAppStoreConnectKeyId,
    required String iosAppStoreConnectKeyIssuer,
    required File iosAppStoreConnectKey,
    required InfraStorage storage,
    required InfraEncryptor encryptor,
    required InfraStorageType storageType,
    required InfraEncryptorType encryptorType,
    required InfraIosBuildOutputType iosBuildOutputType,
    required InfraAndroidBuildOutputType androidBuildOutputType,
    this.iosCertificateSigningRequestPath,
    this.iosCertificateSigningRequestPrivateKeyPath,
    this.iosCertificateSigningRequestName,
    this.iosCertificateSigningRequestEmail,
    this.iosDistributionProvisionProfileUUID,
    this.iosDistributionCertificateId,
  }) : super(
          androidAppId: androidAppId,
          iosAppId: iosAppId,
          iosAppStoreConnectKeyId: iosAppStoreConnectKeyId,
          iosAppStoreConnectKeyIssuer: iosAppStoreConnectKeyIssuer,
          iosAppStoreConnectKey: iosAppStoreConnectKey,
          storage: storage,
          encryptor: encryptor,
          storageType: storageType,
          encryptorType: encryptorType,
          iosBuildOutputType: iosBuildOutputType,
          androidBuildOutputType: androidBuildOutputType,
        );
}
