import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:db_infra/src/apple/bundle_id/bundle_id_manager.dart';
import 'package:db_infra/src/apple/certificates/certificates_manager.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile_manager.dart';
import 'package:db_infra/src/build_distributor/build_distributor.dart';
import 'package:db_infra/src/build_executor/build_executor.dart';
import 'package:db_infra/src/commands/base_command.dart';
import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/environment_variable_handler/environment_variable_handler.dart';
import 'package:db_infra/src/logger.dart';
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
      ..addOption(
        infraBuildDistributorTypeArg,
        help: 'Specify the infrastructure build distributor type.',
        allowed: BuildDistributorType.values.map((BuildDistributorType e) {
          return e.name;
        }),
        defaultsTo: BuildDistributorType.directory.name,
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
        infraBuildOutputDirectoryArg,
        help: 'Specify the output directory.',
      );
  }

  @override
  FutureOr<void> run() async {
    final ArgResults globalArgs = globalResults!;
    final ArgResults commandArgs = argResults!;

    final Logger logger = Logger(
      enableLogging: globalArgs.isVerbosityEnabled(),
    );

    final File configurationFile =
        globalArgs.getConfigurationFile(checkIfExist: true);

    final Directory projectDir = commandArgs.getProjectDirectory();

    final Directory infraDir = projectDir.createInfraDirectory();

    final InfraBuildConfiguration buildConfiguration = await loadConfiguration(
      configurationFile,
      infraDir,
      logger,
    );

    final BuildDistributorType buildDistributorType =
        _getBuildDistributorType(commandArgs);

    final BuildDistributor buildDistributor = _getBuildDistributor(
      commandArgs,
      logger,
      buildConfiguration,
      buildDistributorType,
    );

    final EnvironmentVariableHandlerType? envHandlerType =
        _getEnvironmentVariableType(commandArgs);

    EnvironmentVariableHandler? envHandler;

    if (envHandlerType != null) {
      envHandler = _getEnvironmentVariableHandler(envHandlerType, commandArgs);
    }

    final CertificatesManager certificatesManager =
        buildConfiguration.getCertificatesManager(logger);

    final ProvisionProfileManager profilesManager = buildConfiguration
        .getProfilesManager(certificatesManager, infraDir, logger);

    final BundleIdManager bundleIdManager =
        buildConfiguration.getBundleManager();

    logger.logInfo(
      'Building ${buildConfiguration.iosAppId} with '
      'configuration file: ${configurationFile.path}...',
    );

    await decryptInfraFiles(infraDir, buildConfiguration);

    final File iosFlutterOutput = await FlutterIosBuildExecutor(
      projectDirectory: projectDir,
      configuration: buildConfiguration,
      provisionProfilesManager: profilesManager,
      certificatesManager: certificatesManager,
      bundleIdManager: bundleIdManager,
      logger: logger,
      environmentVariableHandler: envHandler,
    ).build();

    await buildDistributor.distribute(iosFlutterOutput);

    await cleanup(buildConfiguration, infraDir);
  }

  BuildDistributorType _getBuildDistributorType(ArgResults args) {
    final String buildDistributorType =
        args.parseString(infraBuildDistributorTypeArg);

    return buildDistributorType.asBuildDistributorType();
  }

  BuildDistributor _getBuildDistributor(
    final ArgResults args,
    final Logger logger,
    final InfraBuildConfiguration configuration,
    final BuildDistributorType buildDistributorType,
  ) {
    final String? outputDirectoryPath =
        args.parseOptionalString(infraBuildOutputDirectoryArg);

    return buildDistributorType.toDistributor(
      infraLogger: logger,
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
