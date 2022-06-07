import 'dart:io';

import 'package:db_infra/src/apple/provision_profile/provision_profile_type.dart';
import 'package:db_infra/src/build_output_type.dart';
import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/encryptor/encryptor.dart';
import 'package:db_infra/src/storage/storage.dart';

///
class InfraSetupConfiguration extends Configuration {
  ///
  final String? iosCertificateSigningRequestPath;

  ///
  final String? iosCertificateSigningRequestPrivateKeyPath;

  ///
  final String? iosCertificateSigningRequestName;

  ///
  final String? iosCertificateSigningRequestEmail;

  ///
  final String? iosProvisionProfileName;

  ///
  final String? iosCertificateId;

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
    required ProvisionProfileType iosProvisionProfileType,
    this.iosCertificateSigningRequestPrivateKeyPath,
    this.iosCertificateSigningRequestPath,
    this.iosCertificateSigningRequestName,
    this.iosCertificateSigningRequestEmail,
    this.iosProvisionProfileName,
    this.iosCertificateId,
  }) : super(
          androidAppId: androidAppId,
          iosAppId: iosAppId,
          iosAppStoreConnectKeyId: iosAppStoreConnectKeyId,
          iosAppStoreConnectKeyIssuer: iosAppStoreConnectKeyIssuer,
          iosAppStoreConnectKey: iosAppStoreConnectKey,
          iosProvisionProfileType: iosProvisionProfileType,
          storage: storage,
          encryptor: encryptor,
          storageType: storageType,
          encryptorType: encryptorType,
          iosBuildOutputType: iosBuildOutputType,
          androidBuildOutputType: androidBuildOutputType,
        );
}
