import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:db_infra/src/apple/bundle_id/bundle_id_manager.dart';
import 'package:db_infra/src/apple/certificates/certificates_manager.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile_manager.dart';
import 'package:db_infra/src/build_distributor.dart';
import 'package:db_infra/src/build_distributor_type.dart';
import 'package:db_infra/src/build_distributors/build_distributor_factory.dart';
import 'package:db_infra/src/build_executors/ios/flutter_ios_build_executor.dart';
import 'package:db_infra/src/commands/base_command.dart';
import 'package:db_infra/src/configurations/infra_build_configuration.dart';
import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/utils/constants.dart';
import 'package:db_infra/src/utils/file_utils.dart';
import 'package:db_infra/src/utils/infra_extensions.dart';
import 'package:db_infra/src/utils/types.dart';

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
        allowed: BuildDistributorType.values.map(enumName),
        defaultsTo: BuildDistributorType.directory.name,
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
        getBuildDistributorType(commandArgs);

    final BuildDistributor buildDistributor = getBuildDistributor(
      commandArgs,
      logger,
      buildConfiguration,
      buildDistributorType,
    );

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
    ).build();

    await buildDistributor.distribute(iosFlutterOutput);

    await cleanup(buildConfiguration, infraDir);
  }

  /// Get the build distributor
  BuildDistributorType getBuildDistributorType(ArgResults args) {
    final String buildDistributorType =
        args.parseString(infraBuildDistributorTypeArg);

    return buildDistributorType.asBuildDistributorType();
  }

  ///
  BuildDistributor getBuildDistributor(
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
}
