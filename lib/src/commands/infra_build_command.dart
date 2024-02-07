import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:bdlogging/bdlogging.dart';
import 'package:db_infra/src/apple/bundle_id/bundle_id_manager.dart';
import 'package:db_infra/src/apple/certificates/certificates_manager.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile_manager.dart';
import 'package:db_infra/src/build_distributor/build_distributor.dart';
import 'package:db_infra/src/build_executor/build_executor.dart';
import 'package:db_infra/src/build_executor/flutter_android_build_executor.dart';
import 'package:db_infra/src/commands/base_command.dart';
import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/environment_variable_handler/environment_variable_handler.dart';
import 'package:db_infra/src/utils/utils.dart';

///
class InfraBuildCommand extends BaseCommand {
  @override
  String get name => 'build';

  @override
  String get description {
    return 'Build the application using the configuration file';
  }

  ///
  InfraBuildCommand() {
    argParser
      ..addMultiOption(
        infraBuildDistributorTypeArg,
        help: 'Specify the infrastructure build distributor type.',
        allowed: BuildDistributorType.values.map((BuildDistributorType e) {
          return e.name;
        }),
        defaultsTo: <String>[BuildDistributorType.directory.name],
      )
      ..addOption(
        infraBuildEnvVariableTypeArg,
        help: 'Specify the infrastructure build environment type to use',
        allowed: EnvironmentVariableHandlerType.values.asNameList(),
      )
      ..addOption(
        infraBuildDotEnvVariableFileArg,
        help: 'Specify the infrastructure build dot environment file to use',
      )
      ..addOption(
        infraAesEncryptorPasswordArg,
        help: 'Specify the infrastructure AES encryptor password',
      )
      ..addOption(
        infraBuildOutputDirectoryArg,
        help: 'Specify the output directory.',
      );
  }

  @override
  FutureOr<void> run() async {
    final ArgResults globalArgs = globalResults!;
    final ArgResults commandArgs = argResults!;

    BDLogger().addHandler(
      ConsoleLogHandler(
        supportedLevels: globalArgs.isVerbosityEnabled()
            ? BDLevel.levels
            : <BDLevel>[BDLevel.warning, BDLevel.error],
      ),
    );

    final File configurationFile =
        globalArgs.getConfigurationFile(checkIfExist: true);

    final Directory projectDir = commandArgs.getProjectDirectory();

    final Directory infraDir = projectDir.createInfraDirectory();

    final String? aesEncryptorPassword =
        commandArgs.parseOptionalString(infraAesEncryptorPasswordArg);

    final InfraBuildConfiguration buildConfiguration = await loadConfiguration(
      configuration: configurationFile,
      infraDirectory: infraDir,
      aesPassword: aesEncryptorPassword,
    );

    final List<BuildDistributorType> buildDistributorTypes =
        _getBuildDistributorTypes(commandArgs);

    final List<BuildDistributor> buildDistributors = buildDistributorTypes.map((
      BuildDistributorType e,
    ) {
      return _getBuildDistributor(
        commandArgs,
        projectDir,
        buildConfiguration,
        e,
      );
    }).toList();

    final EnvironmentVariableHandlerType? envHandlerType =
        _getEnvironmentVariableType(commandArgs);

    EnvironmentVariableHandler? envHandler;

    if (envHandlerType != null) {
      envHandler = _getEnvironmentVariableHandler(envHandlerType, commandArgs);
    }

    final CertificatesManager certificatesManager =
        buildConfiguration.getCertificatesManager();

    final ProvisionProfileManager profilesManager =
        buildConfiguration.getProfilesManager(certificatesManager, infraDir);

    final BundleIdManager bundleIdManager =
        buildConfiguration.getBundleManager();

    BDLogger().info(
      'Building ${buildConfiguration.iosAppId} with '
      'configuration file: ${configurationFile.path}...',
    );

    await decryptInfraFiles(infraDir, buildConfiguration);

    final File iosFlutterOutput;

    try {
      iosFlutterOutput = await FlutterIosBuildExecutor(
        projectDirectory: projectDir,
        configuration: buildConfiguration,
        provisionProfilesManager: profilesManager,
        certificatesManager: certificatesManager,
        bundleIdManager: bundleIdManager,
        environmentVariableHandler: envHandler,
      ).build();
    } on Object catch (_) {
      certificatesManager.cleanupLocally();
      rethrow;
    }

    await Future.forEach(
      buildDistributors,
      (BuildDistributor distributor) async {
        switch (distributor.buildDistributorType) {
          case BuildDistributorType.directory:
          case BuildDistributorType.appStoreConnect:
            return distributor.distribute(iosFlutterOutput);
        }
      },
    );

    final File androidFlutterOutput = await FlutterAndroidBuildExecutor(
      configuration: buildConfiguration,
      projectDirectory: projectDir,
      environmentVariableHandler: envHandler,
    ).build();

    await Future.forEach(
      buildDistributors,
      (BuildDistributor distributor) async {
        switch (distributor.buildDistributorType) {
          case BuildDistributorType.directory:
            return distributor.distribute(androidFlutterOutput);
          case BuildDistributorType.appStoreConnect:
            return Future<void>.value();
        }
      },
    );

    await cleanup(buildConfiguration, infraDir);
  }

  List<BuildDistributorType> _getBuildDistributorTypes(ArgResults args) {
    final Object? argumentValue = args[infraBuildDistributorTypeArg];

    if (argumentValue is List<String> && argumentValue.isNotEmpty) {
      return argumentValue
          .map((String e) => e.asBuildDistributorType())
          .toList();
    }

    throw ArgumentError('$infraBuildDistributorTypeArg need to be specified');
  }

  BuildDistributor _getBuildDistributor(
    final ArgResults args,
    final Directory projectDirectory,
    final InfraBuildConfiguration configuration,
    final BuildDistributorType buildDistributorType,
  ) {
    final String? outputDirectoryPath =
        args.parseOptionalString(infraBuildOutputDirectoryArg);

    return buildDistributorType.toDistributor(
      projectDirectory: projectDirectory,
      configuration: configuration,
      outputDirectoryPath: outputDirectoryPath,
    );
  }

  EnvironmentVariableHandlerType? _getEnvironmentVariableType(ArgResults args) {
    final String? environmentVariableType =
        args.parseOptionalString(infraBuildEnvVariableTypeArg);

    return environmentVariableType?.asEnvironmentVariableType();
  }

  EnvironmentVariableHandler? _getEnvironmentVariableHandler(
    EnvironmentVariableHandlerType type,
    ArgResults args,
  ) {
    switch (type) {
      case EnvironmentVariableHandlerType.dotEnv:
        final String dotFilePath =
            args.parseString(infraBuildDotEnvVariableFileArg);

        final File dotFile = File(dotFilePath);

        if (!dotFile.existsSync()) {
          throw ArgumentError.value(
            dotFilePath,
            infraBuildDotEnvVariableFileArg,
            '$infraBuildEnvVariableTypeArg of ${type.name} selected but valid '
            'dot file path was not provided.',
          );
        }

        return type.asEnvironmentVariableHandler(
          dotEnvironmentVariableFile: dotFile,
        );
      default:
        throw UnimplementedError();
    }
  }
}
