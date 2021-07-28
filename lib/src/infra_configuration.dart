import 'dart:io';

import 'package:db_infra/src/run_configuration.dart';
import 'package:db_infra/src/utils/network_manager.dart';
import 'package:path/path.dart' as path;

///
class InfraConfiguration extends RunConfiguration {
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
  InfraConfiguration({
    required Directory projectDir,
    required String androidAppId,
    required String iosAppId,
    required String iosAppStoreConnectKeyId,
    required String iosAppStoreConnectKeyIssuer,
    required File iosAppStoreConnectKey,
    required this.iosCertificateSigningRequest,
    required this.iosCertificateSigningRequestPrivateKey,
    required this.iosCertificateSigningRequestName,
    required this.iosCertificateSigningRequestEmail,
    required this.iosDistributionProvisionProfileUUID,
    required this.iosDistributionCertificateId,
    required this.iosExportOptionsPlist,
  }) : super(
          projectDir: projectDir,
          androidAppId: androidAppId,
          iosAppId: iosAppId,
          iosAppStoreConnectKeyId: iosAppStoreConnectKeyId,
          iosAppStoreConnectKeyIssuer: iosAppStoreConnectKeyIssuer,
          iosAppStoreConnectKey: iosAppStoreConnectKey,
        );

  ///
  factory InfraConfiguration.fromJson(
    final Directory projectDir,
    final Directory infraDir,
    final JsonMap json,
  ) {
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

    return InfraConfiguration(
      projectDir: projectDir,
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
    );
  }

  ///
  JsonMap toJson() {
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
      'iosExportOptionsPlist': iosExportOptionsPlist.path,
    };
  }
}
