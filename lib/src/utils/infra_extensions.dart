import 'dart:io';

import 'package:db_infra/src/apis/apple/api/appstoreconnectapi_bundle_id.dart';
import 'package:db_infra/src/apis/apple/api/appstoreconnectapi_certificates.dart';
import 'package:db_infra/src/apis/apple/api/appstoreconnectapi_profiles.dart';
import 'package:db_infra/src/apis/apple/bundle_id_manager.dart';
import 'package:db_infra/src/apis/apple/certificates_manager.dart';
import 'package:db_infra/src/apis/apple/keychains_manager.dart';
import 'package:db_infra/src/apis/apple/profiles_manager.dart';
import 'package:db_infra/src/infra_encryptor.dart';
import 'package:db_infra/src/infra_encryptor_type.dart';
import 'package:db_infra/src/infra_logger.dart';
import 'package:db_infra/src/infra_run_configuration.dart';
import 'package:db_infra/src/infra_storage_type.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:db_infra/src/utils/network_manager.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:db_infra/src/infra_encryptors/infra_encryptor_factory.dart';
import 'package:io/io.dart';

///
extension InfraConfigurationJsonExtension on JsonMap {
  ///
  InfraStorageType getStorageType() {
    final Object? storageType = this['storageType'];

    return storageType is String
        ? storageType.asStorageType()
        : throw ArgumentError(storageType);
  }

  ///
  InfraEncryptorType getEncryptorType() {
    final Object? encryptorType = this['encryptorType'];

    return encryptorType is String
        ? encryptorType.asEncryptorType()
        : throw UnrecoverableException(
            'Infrastructure encryptor type could not be parsed from json $this',
            ExitCode.config.code,
          );
  }

  ///
  InfraEncryptor getEncryptor(
    final InfraEncryptorType encryptorType,
    final InfraLogger infraLogger,
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
  Future<JsonMap> asEncrypted(final InfraEncryptor encryptor) async {
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
  Future<JsonMap> asDecrypted(final InfraEncryptor encryptor) async {
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
extension RunConfigurationExtensions on InfraRunConfiguration {
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
