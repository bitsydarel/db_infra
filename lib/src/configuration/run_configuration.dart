import 'dart:io';

import 'package:db_infra/src/apple/provision_profile/provision_profile_type.dart';
import 'package:db_infra/src/build_output_type.dart';
import 'package:db_infra/src/encryptor/encryptor.dart';
import 'package:db_infra/src/storage/storage.dart';

///
abstract class Configuration {
  /// Android application id.
  final String androidAppId;

  /// iOS application id.
  final String iosAppId;

  ///
  final String iosAppStoreConnectKeyId;

  ///
  final String iosAppStoreConnectKeyIssuer;

  ///
  final File iosAppStoreConnectKey;

  ///
  final Storage storage;

  ///
  final Encryptor encryptor;

  ///
  final StorageType storageType;

  ///
  final EncryptorType encryptorType;

  ///
  final IosBuildOutputType iosBuildOutputType;

  ///
  final AndroidBuildOutputType androidBuildOutputType;

  ///
  final ProvisionProfileType iosProvisionProfileType;

  ///
  const Configuration({
    required this.androidAppId,
    required this.iosAppId,
    required this.iosAppStoreConnectKeyId,
    required this.iosAppStoreConnectKeyIssuer,
    required this.iosAppStoreConnectKey,
    required this.storage,
    required this.encryptor,
    required this.storageType,
    required this.encryptorType,
    required this.iosBuildOutputType,
    required this.androidBuildOutputType,
    required this.iosProvisionProfileType,
  });
}
