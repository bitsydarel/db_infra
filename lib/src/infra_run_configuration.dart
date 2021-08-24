import 'dart:io';

import 'package:db_infra/src/infra_build_output_type.dart';
import 'package:db_infra/src/infra_encryptor.dart';
import 'package:db_infra/src/infra_encryptor_type.dart';
import 'package:db_infra/src/infra_storage.dart';
import 'package:db_infra/src/infra_storage_type.dart';

///
abstract class InfraRunConfiguration {
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
  final InfraStorage storage;

  ///
  final InfraEncryptor encryptor;

  ///
  final InfraStorageType storageType;

  ///
  final InfraEncryptorType encryptorType;

  ///
  final InfraIosBuildOutputType iosBuildOutputType;

  ///
  final InfraAndroidBuildOutputType androidBuildOutputType;

  ///
  const InfraRunConfiguration({
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
  });
}
