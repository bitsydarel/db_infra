import 'dart:io';

import 'package:db_infra/src/apple/provision_profile/provision_profile_type.dart';
import 'package:db_infra/src/build_output_type.dart';
import 'package:db_infra/src/build_signing_type.dart';
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
  final String? iosDeveloperTeamId;

  ///
  final IosBuildSigningType iosBuildSigningType;

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
    required String androidKeyAlias,
    required String androidKeyPassword,
    required File androidStoreFile,
    required String androidStorePassword,
    required this.iosBuildSigningType,
    this.iosCertificateSigningRequestPrivateKeyPath,
    this.iosCertificateSigningRequestPath,
    this.iosCertificateSigningRequestName,
    this.iosCertificateSigningRequestEmail,
    this.iosProvisionProfileName,
    this.iosCertificateId,
    this.iosDeveloperTeamId,
  }) : super(
          androidAppId: androidAppId,
          iosAppId: iosAppId,
          iosAppStoreConnectKeyId: iosAppStoreConnectKeyId,
          iosAppStoreConnectKeyIssuer: iosAppStoreConnectKeyIssuer,
          iosAppStoreConnectKey: iosAppStoreConnectKey,
          iosProvisionProfileType: iosProvisionProfileType,
          iosBuildOutputType: iosBuildOutputType,
          androidKeyAlias: androidKeyAlias,
          androidKeyPassword: androidKeyPassword,
          androidStoreFile: androidStoreFile,
          androidStorePassword: androidStorePassword,
          androidBuildOutputType: androidBuildOutputType,
          storage: storage,
          encryptor: encryptor,
          storageType: storageType,
          encryptorType: encryptorType,
        );
}
