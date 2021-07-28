import 'dart:io';

import 'package:db_infra/src/run_configuration.dart';

///
class SetupConfiguration extends RunConfiguration {
  ///
  final String? iosCertificateSigningRequestPath;

  ///
  final String? iosCertificateSigningRequestPrivateKeyPath;

  ///
  final String? iosCertificateSigningRequestName;

  ///
  final String? iosCertificateSigningRequestEmail;

  ///
  final String? iosDistributionProvisionProfileUUID;

  ///
  final String? iosDistributionCertificateId;

  ///
  const SetupConfiguration({
    required Directory projectDir,
    required String androidAppId,
    required String iosAppId,
    required String iosAppStoreConnectKeyId,
    required String iosAppStoreConnectKeyIssuer,
    required File iosAppStoreConnectKey,
    this.iosCertificateSigningRequestPath,
    this.iosCertificateSigningRequestPrivateKeyPath,
    this.iosCertificateSigningRequestName,
    this.iosCertificateSigningRequestEmail,
    this.iosDistributionProvisionProfileUUID,
    this.iosDistributionCertificateId,
  }) : super(
          projectDir: projectDir,
          androidAppId: androidAppId,
          iosAppId: iosAppId,
          iosAppStoreConnectKeyId: iosAppStoreConnectKeyId,
          iosAppStoreConnectKeyIssuer: iosAppStoreConnectKeyIssuer,
          iosAppStoreConnectKey: iosAppStoreConnectKey,
        );
}
