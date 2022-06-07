import 'dart:io';

import 'package:db_infra/src/apple/provision_profile/provision_profile_type.dart';
import 'package:db_infra/src/build_output_type.dart';
import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/encryptor/encryptor.dart';
import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/storage/storage.dart';
import 'package:db_infra/src/utils/utils.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;

///
class InfraBuildConfiguration extends Configuration {
  ///
  final File iosCertificateSigningRequest;

  ///
  final File iosCertificateSigningRequestPrivateKey;

  ///
  final String? iosCertificateSigningRequestName;

  ///
  final String? iosCertificateSigningRequestEmail;

  ///
  final String iosProvisionProfileName;

  ///
  final String iosCertificateId;

  ///
  final File iosExportOptionsPlist;

  ///
  InfraBuildConfiguration({
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
    required this.iosCertificateSigningRequest,
    required this.iosCertificateSigningRequestPrivateKey,
    required this.iosCertificateSigningRequestName,
    required this.iosCertificateSigningRequestEmail,
    required this.iosProvisionProfileName,
    required this.iosCertificateId,
    required this.iosExportOptionsPlist,
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
          iosProvisionProfileType: iosProvisionProfileType,
        );

  ///
  static Future<InfraBuildConfiguration> fromJson({
    required final JsonMap json,
    required final Logger logger,
    required final Directory infraDir,
  }) async {
    final Object? androidAppId = json[androidAppIdArg];

    final Object? iosAppId = json[iosAppIdArg];

    final Object? iosAppStoreConnectKeyId = json[iosAppStoreConnectKeyIdArg];

    final Object? iosAppStoreConnectKeyIssuer =
        json[iosAppStoreConnectKeyIssuerArg];

    final Object? iosAppStoreConnectKey = json[iosAppStoreConnectKeyPathArg];

    final Object? iosCertificateSigningRequest =
        json[iosCertificateSigningRequestPathArg];

    final Object? iosCertificateSigningRequestPrivateKey =
        json[iosCertificateSigningRequestPrivateKeyPathArg];

    final Object? iosCertificateSigningRequestName =
        json[iosCertificateSigningRequestNameArg];

    final Object? iosCertificateSigningRequestEmail =
        json[iosCertificateSigningRequestEmailArg];

    final Object? iosProvisionProfileName = json[iosProvisionProfileNameArg];

    final Object? iosProvisionProfileType = json[iosProvisionProfileTypeArg];

    final Object? iosCertificateId = json[iosCertificateIdArg];

    final Object? iosExportOptionsPlist = json['iosExportOptionsPlist'];

    final Object? iosBuildOutputType = json['iosBuildOutputType'];

    final Object? androidBuildOutputType = json['androidBuildOutputType'];

    final EncryptorType encryptorType = json.getEncryptorType();

    final Encryptor encryptor =
        json.getEncryptor(encryptorType, logger, infraDir);

    final StorageType infraStorageType = json.getStorageType();

    final Object? storageRaw = json['storage'];

    // decrypt the storage as it's value is encrypted.
    final JsonMap storageAsJson = storageRaw is JsonMap
        ? await storageRaw.asDecrypted(encryptor)
        : throw UnrecoverableException(
            'Infrastructure storage invalid json: $storageRaw',
            ExitCode.config.code,
          );




    return InfraBuildConfiguration(
      androidAppId: androidAppId is String
          ? androidAppId
          : throw ArgumentError(androidAppId),
      iosAppId: iosAppId is String ? iosAppId : throw ArgumentError(iosAppId),
      iosAppStoreConnectKeyId: iosAppStoreConnectKeyId is String
          ? iosAppStoreConnectKeyId
          : throw ArgumentError(iosAppStoreConnectKeyId),
      iosAppStoreConnectKeyIssuer: iosAppStoreConnectKeyIssuer is String
          ? iosAppStoreConnectKeyIssuer
          : throw ArgumentError(iosAppStoreConnectKeyIssuer),
      iosAppStoreConnectKey: iosAppStoreConnectKey is String
          ? File('${infraDir.path}/$iosAppStoreConnectKey')
          : throw ArgumentError(iosAppStoreConnectKey),
      iosCertificateSigningRequest: iosCertificateSigningRequest is String
          ? File('${infraDir.path}/$iosCertificateSigningRequest')
          : throw ArgumentError(iosCertificateSigningRequest),
      iosCertificateSigningRequestPrivateKey:
          iosCertificateSigningRequestPrivateKey is String
              ? File('${infraDir.path}/$iosCertificateSigningRequestPrivateKey')
              : throw ArgumentError(iosCertificateSigningRequestPrivateKey),
      iosCertificateSigningRequestName:
          iosCertificateSigningRequestName is String
              ? iosCertificateSigningRequestName
              : null,
      iosCertificateSigningRequestEmail:
          iosCertificateSigningRequestEmail is String
              ? iosCertificateSigningRequestEmail
              : null,
      iosProvisionProfileName: iosProvisionProfileName is String
          ? iosProvisionProfileName
          : throw ArgumentError(iosProvisionProfileName),
      iosProvisionProfileType: iosProvisionProfileType is String
          ? iosProvisionProfileType.fromKey()
          : throw ArgumentError(iosProvisionProfileType),
      iosCertificateId: iosCertificateId is String
          ? iosCertificateId
          : throw ArgumentError(iosCertificateId),
      iosExportOptionsPlist: iosExportOptionsPlist is String
          ? File('${infraDir.path}/$iosExportOptionsPlist')
          : throw ArgumentError(iosExportOptionsPlist),
      storageType: infraStorageType,
      storage: infraStorageType.fromJson(storageAsJson, logger, infraDir),
      encryptorType: encryptorType,
      encryptor: encryptor,
      iosBuildOutputType: iosBuildOutputType is String
          ? iosBuildOutputType.asIosBuildOutputType()
          : throw ArgumentError(iosBuildOutputType),
      androidBuildOutputType: androidBuildOutputType is String
          ? androidBuildOutputType.asAndroidBuildOutputType()
          : throw ArgumentError(androidBuildOutputType),
    );
  }

  ///
  Future<JsonMap> toJson() async {
    final JsonMap encryptedStorageProperties =
        await storage.toJson().asEncrypted(encryptor);

    return <String, Object?>{
      androidAppIdArg: androidAppId,
      iosAppIdArg: iosAppId,
      iosAppStoreConnectKeyIdArg: iosAppStoreConnectKeyId,
      iosAppStoreConnectKeyIssuerArg: iosAppStoreConnectKeyIssuer,
      iosAppStoreConnectKeyPathArg: path.basename(iosAppStoreConnectKey.path),
      iosCertificateSigningRequestPathArg:
          path.basename(iosCertificateSigningRequest.path),
      iosCertificateSigningRequestPrivateKeyPathArg:
          path.basename(iosCertificateSigningRequestPrivateKey.path),
      iosCertificateSigningRequestNameArg: iosCertificateSigningRequestName,
      iosCertificateSigningRequestEmailArg: iosCertificateSigningRequestEmail,
      iosProvisionProfileNameArg: iosProvisionProfileName,
      iosProvisionProfileTypeArg: iosProvisionProfileType.key,
      iosCertificateIdArg: iosCertificateId,
      'iosExportOptionsPlist': path.basename(iosExportOptionsPlist.path),
      'encryptor': encryptor.toJson(),
      infraEncryptorTypeArg: encryptorType.name,
      'storage': encryptedStorageProperties,
      infraStorageTypeArg: storageType.name,
      'iosBuildOutputType': iosBuildOutputType.name,
      'androidBuildOutputType': androidBuildOutputType.name,
    };
  }
}

///
extension InfraConfigurationJsonExtension on JsonMap {
  ///
  StorageType getStorageType() {
    final Object? storageType = this[infraStorageTypeArg];

    return storageType is String
        ? storageType.asStorageType()
        : throw ArgumentError(storageType);
  }

  ///
  EncryptorType getEncryptorType() {
    final Object? encryptorType = this[infraEncryptorTypeArg];

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
