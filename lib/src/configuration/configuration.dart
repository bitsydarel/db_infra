library configuration;

import 'dart:io';

import 'package:db_infra/src/apple/provision_profile/provision_profile_type.dart';
import 'package:db_infra/src/build_output_type.dart';
import 'package:db_infra/src/encryptor/encryptor.dart';
import 'package:db_infra/src/storage/storage.dart';

export 'infra_build_configuration.dart';
export 'infra_setup_configuration.dart';
export 'run_configuration.dart';

///
abstract class Configuration {
  /// The Android application package name.
  final String androidAppId;

  /// The iOS application bundle identifier.
  final String iosAppId;

  /// The App Store Connect API Key ID for iOS.
  final String iosAppStoreConnectKeyId;

  /// The App Store Connect API Key Issuer ID for iOS.
  final String iosAppStoreConnectKeyIssuer;

  /// The iOS App Store Connect API key file used for authentication with
  /// Apple services during build and distribution.
  final File iosAppStoreConnectKey;

  /// The storage implementation used for
  /// saving build artifacts and encrypted files.
  final Storage storage;

  /// The encryptor implementation used for encrypting sensitive files.
  final Encryptor encryptor;

  /// The type of storage used (disk, FTP, cloud, etc.).
  final StorageType storageType;

  /// The type of encryptor used (base64, AES, etc.).
  final EncryptorType encryptorType;

  /// The output type for the iOS build (e.g., IPA).
  final IosBuildOutputType iosBuildOutputType;

  /// The output type for the Android build (e.g., APK, AAB).
  final AndroidBuildOutputType androidBuildOutputType;

  /// The type of iOS provisioning profile (development, distribution, etc.).
  final ProvisionProfileType iosProvisionProfileType;

  /// The alias for the Android signing key within the keystore.
  final String androidKeyAlias;

  /// The password for the Android signing key.
  final String androidKeyPassword;

  /// The password for the Android keystore.
  final String androidStorePassword;

  /// The Android keystore file used for signing the Android app.
  final File androidStoreFile;

  ///
  const Configuration({
    required this.androidAppId,
    required this.iosAppId,
    required this.iosAppStoreConnectKeyId,
    required this.iosAppStoreConnectKeyIssuer,
    required this.iosAppStoreConnectKey,
    required this.androidKeyAlias,
    required this.androidKeyPassword,
    required this.androidStoreFile,
    required this.androidStorePassword,
    required this.storage,
    required this.encryptor,
    required this.storageType,
    required this.encryptorType,
    required this.iosBuildOutputType,
    required this.androidBuildOutputType,
    required this.iosProvisionProfileType,
  });
}
