import 'dart:io';

import 'package:db_infra/src/build_output_type.dart';
import 'package:db_infra/src/encryptor.dart';
import 'package:db_infra/src/encryptor_type.dart';
import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/run_configuration.dart';
import 'package:db_infra/src/storage.dart';
import 'package:db_infra/src/storage_type.dart';
import 'package:db_infra/src/storages/storage_factory.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:db_infra/src/utils/infra_extensions.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;

///
class InfraBuildConfiguration extends RunConfiguration {
  ///
  final File iosCertificateSigningRequest;

  ///
  final File iosCertificateSigningRequestPrivateKey;

  ///
  final String? iosCertificateSigningRequestName;

  ///
  final String? iosCertificateSigningRequestEmail;

  ///
  final String iosDistributionProvisionProfileUUID;

  ///
  final String iosDistributionCertificateId;

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
    required this.iosCertificateSigningRequest,
    required this.iosCertificateSigningRequestPrivateKey,
    required this.iosCertificateSigningRequestName,
    required this.iosCertificateSigningRequestEmail,
    required this.iosDistributionProvisionProfileUUID,
    required this.iosDistributionCertificateId,
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
        );

  ///
  static Future<InfraBuildConfiguration> fromJson({
    required final JsonMap json,
    required final StorageType infraStorageType,
    required final EncryptorType infraEncryptorType,
    required final Encryptor infraEncryptor,
    required final Logger logger,
    required final Directory infraDir,
  }) async {
    final Object? androidAppId = json['androidAppId'];

    final Object? iosAppId = json['iosAppId'];

    final Object? iosAppStoreConnectKeyId = json['iosAppStoreConnectKeyId'];

    final Object? iosAppStoreConnectKeyIssuer =
        json['iosAppStoreConnectKeyIssuer'];

    final Object? iosAppStoreConnectKey = json['iosAppStoreConnectKey'];

    final Object? iosCertificateSigningRequest =
        json['iosCertificateSigningRequest'];

    final Object? iosCertificateSigningRequestPrivateKey =
        json['iosCertificateSigningRequestPrivateKey'];

    final Object? iosCertificateSigningRequestName =
        json['iosCertificateSigningRequestName'];

    final Object? iosCertificateSigningRequestEmail =
        json['iosCertificateSigningRequestEmail'];

    final Object? iosDistributionProvisionProfileUUID =
        json['iosDistributionProvisionProfileUUID'];

    final Object? iosDistributionCertificateId =
        json['iosDistributionCertificateId'];

    final Object? iosExportOptionsPlist = json['iosExportOptionsPlist'];

    final Object? iosBuildOutputType = json['iosBuildOutputType'];

    final Object? androidBuildOutputType = json['androidBuildOutputType'];

    final Object? storageRaw = json['storage'];

    // decrypt the storage as it's value is encrypted.
    final JsonMap storageAsJson = storageRaw is JsonMap
        ? await storageRaw.asDecrypted(infraEncryptor)
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
      iosDistributionProvisionProfileUUID:
          iosDistributionProvisionProfileUUID is String
              ? iosDistributionProvisionProfileUUID
              : throw ArgumentError(iosDistributionProvisionProfileUUID),
      iosDistributionCertificateId: iosDistributionCertificateId is String
          ? iosDistributionCertificateId
          : throw ArgumentError(iosDistributionCertificateId),
      iosExportOptionsPlist: iosExportOptionsPlist is String
          ? File('${infraDir.path}/$iosExportOptionsPlist')
          : throw ArgumentError(iosExportOptionsPlist),
      storageType: infraStorageType,
      storage: infraStorageType.fromJson(storageAsJson, logger, infraDir),
      encryptorType: infraEncryptorType,
      encryptor: infraEncryptor,
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
      'androidAppId': androidAppId,
      'iosAppId': iosAppId,
      'iosAppStoreConnectKeyId': iosAppStoreConnectKeyId,
      'iosAppStoreConnectKeyIssuer': iosAppStoreConnectKeyIssuer,
      'iosAppStoreConnectKey': path.basename(iosAppStoreConnectKey.path),
      'iosCertificateSigningRequest':
          path.basename(iosCertificateSigningRequest.path),
      'iosCertificateSigningRequestPrivateKey':
          path.basename(iosCertificateSigningRequestPrivateKey.path),
      'iosCertificateSigningRequestName': iosCertificateSigningRequestName,
      'iosCertificateSigningRequestEmail': iosCertificateSigningRequestEmail,
      'iosDistributionProvisionProfileUUID':
          iosDistributionProvisionProfileUUID,
      'iosDistributionCertificateId': iosDistributionCertificateId,
      'iosExportOptionsPlist': path.basename(iosExportOptionsPlist.path),
      'encryptor': encryptor.toJson(),
      'encryptorType': encryptorType.name,
      'storage': encryptedStorageProperties,
      'storageType': storageType.name,
      'iosBuildOutputType': iosBuildOutputType.name,
      'androidBuildOutputType': androidBuildOutputType.name,
    };
  }
}
