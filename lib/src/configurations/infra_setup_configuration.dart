import 'dart:io';

import 'package:db_infra/src/build_output_type.dart';
import 'package:db_infra/src/encryptor.dart';
import 'package:db_infra/src/encryptor_type.dart';
import 'package:db_infra/src/run_configuration.dart';
import 'package:db_infra/src/storage.dart';
import 'package:db_infra/src/storage_type.dart';

///
class InfraSetupConfiguration extends RunConfiguration {
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
    required Storage storage,
    required Encryptor encryptor,
    required StorageType storageType,
    required EncryptorType encryptorType,
    required IosBuildOutputType iosBuildOutputType,
    required AndroidBuildOutputType androidBuildOutputType,
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
