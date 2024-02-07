import 'dart:io';

import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/setup_executor/setup_executor.dart';
import 'package:db_infra/src/shell_runner.dart';

///
class AndroidSetupExecutor extends SetupExecutor {
  ///
  const AndroidSetupExecutor({
    required InfraSetupConfiguration configuration,
    required Directory infraDirectory,
    this.runner = const ShellRunner(),
  }) : super(configuration, infraDirectory);

  ///
  final ShellRunner runner;

  @override
  Future<InfraBuildConfiguration> setupInfra() async {
    final String appId = configuration.androidAppId;

    return InfraBuildConfiguration(
      androidAppId: appId,
      androidKeyAlias: configuration.androidKeyAlias,
      androidStoreFile: configuration.androidStoreFile,
      androidKeyPassword: configuration.androidKeyPassword,
      androidStorePassword: configuration.androidStorePassword,
      androidBuildOutputType: configuration.androidBuildOutputType,
      storage: configuration.storage,
      encryptor: configuration.encryptor,
      storageType: configuration.storageType,
      encryptorType: configuration.encryptorType,
      iosAppId: configuration.iosAppId,
      iosSigningType: configuration.iosBuildSigningType,
      iosBuildOutputType: configuration.iosBuildOutputType,
      iosAppStoreConnectKey: configuration.iosAppStoreConnectKey,
      iosExportOptionsPlist: File('Not used for android'),
      iosAppStoreConnectKeyId: configuration.iosAppStoreConnectKeyId,
      iosProvisionProfileType: configuration.iosProvisionProfileType,
      iosAppStoreConnectKeyIssuer: configuration.iosAppStoreConnectKeyIssuer,
      iosCertificateSigningRequestName:
          configuration.iosCertificateSigningRequestName,
      iosCertificateSigningRequestEmail:
          configuration.iosCertificateSigningRequestEmail,
      iosProvisionProfileName: configuration.iosProvisionProfileName,
      iosCertificateId: configuration.iosCertificateId,
      iosDeveloperTeamId: configuration.iosDeveloperTeamId,
    );
  }
}
