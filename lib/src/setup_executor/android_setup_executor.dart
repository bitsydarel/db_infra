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
      iosAppId: configuration.iosAppId,
      iosAppStoreConnectKeyId: configuration.iosAppStoreConnectKeyId,
      iosAppStoreConnectKeyIssuer: configuration.iosAppStoreConnectKeyIssuer,
      iosAppStoreConnectKey: configuration.iosAppStoreConnectKey,
      iosProvisionProfileType: configuration.iosProvisionProfileType,
      iosBuildOutputType: configuration.iosBuildOutputType,
      iosExportOptionsPlist: File('Not used for android'),
      androidKeyAlias: configuration.androidKeyAlias,
      androidStoreFile: configuration.androidStoreFile,
      androidKeyPassword: configuration.androidKeyPassword,
      androidStorePassword: configuration.androidStorePassword,
      androidBuildOutputType: configuration.androidBuildOutputType,
      storage: configuration.storage,
      encryptor: configuration.encryptor,
      storageType: configuration.storageType,
      encryptorType: configuration.encryptorType,
      iosSigningType: configuration.iosBuildSigningType,
    );
  }
}
