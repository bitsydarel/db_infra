import 'dart:io';

import 'package:db_infra/src/apis/apple/api/appstoreconnectapi_bundle_id.dart';
import 'package:db_infra/src/apis/apple/api/appstoreconnectapi_certificates.dart';
import 'package:db_infra/src/apis/apple/api/appstoreconnectapi_profiles.dart';
import 'package:db_infra/src/apis/apple/bundle_id_manager.dart';
import 'package:db_infra/src/apis/apple/certificates_manager.dart';
import 'package:db_infra/src/apis/apple/keychains_manager.dart';
import 'package:db_infra/src/apis/apple/profiles_manager.dart';
import 'package:db_infra/src/encryptor.dart';
import 'package:db_infra/src/encryptor_type.dart';
import 'package:db_infra/src/encryptors/encryptor_factory.dart';
import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/run_configuration.dart';
import 'package:db_infra/src/storage_type.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:db_infra/src/utils/network_manager.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:io/io.dart';

///
extension InfraConfigurationJsonExtension on JsonMap {
  ///
  StorageType getStorageType() {
    final Object? storageType = this['storageType'];

    return storageType is String
        ? storageType.asStorageType()
        : throw ArgumentError(storageType);
  }

  ///
  EncryptorType getEncryptorType() {
    final Object? encryptorType = this['encryptorType'];

    return encryptorType is String
        ? encryptorType.asEncryptorType()
        : throw UnrecoverableException(
            'Infrastructure encryptor type could not be parsed from json $this',
            ExitCode.config.code,
          );
  }

  ///
  Encryptor getEncryptor(
    final EncryptorType encryptorType,
    final Logger infraLogger,
    final Directory infraDirectory,
  ) {
    final Object? encryptorAsJson = this['encryptor'];

    return encryptorType.fromJson(
      encryptorAsJson is JsonMap
          ? encryptorAsJson
          : throw UnrecoverableException(
              'Infrastructure encryptor could not be parsed from json $this',
              ExitCode.config.code,
            ),
      infraLogger,
      infraDirectory,
    );
  }

  ///
  Future<JsonMap> asEncrypted(final Encryptor encryptor) async {
    final JsonMap encryptedMap = <String, Object?>{};

    for (final MapEntry<String, Object?> entry in entries) {
      final Object? encryptedValue = entry.value != null
          ? await encryptor.encrypt(entry.value.toString())
          : entry.value;

      encryptedMap[entry.key] = encryptedValue;
    }

    return encryptedMap;
  }

  ///
  Future<JsonMap> asDecrypted(final Encryptor encryptor) async {
    final JsonMap decryptedMap = <String, Object?>{};

    for (final MapEntry<String, Object?> entry in entries) {
      final Object? decryptedValue = entry.value != null
          ? await encryptor.decrypt(entry.value.toString())
          : entry.value;

      decryptedMap[entry.key] = decryptedValue;
    }

    return decryptedMap;
  }
}

///
extension RunConfigurationExtensions on RunConfiguration {
  ///
  ProfilesManager getProfilesManager() {
    return ProfilesManager(
      api: AppStoreConnectApiProfiles(
        configuration: this,
        httpClient: networkManager,
      ),
    );
  }

  ///
  CertificatesManager getCertificatesManager() {
    final KeychainsManager keychainsManager =
        KeychainsManager(appKeychain: iosAppId);

    return CertificatesManager(
      keychainsManager: keychainsManager,
      httpClient: networkManager,
      api: AppStoreConnectApiCertificates(
        configuration: this,
        httpClient: networkManager,
      ),
    );
  }

  ///
  BundleIdManager getBundleManager() {
    return BundleIdManager(
      api: AppStoreConnectApiBundleId(
        configuration: this,
        httpClient: networkManager,
      ),
    );
  }
}
