import 'dart:io';

import 'package:args/args.dart';
import 'package:db_infra/db_infra.dart';
import 'package:db_infra/src/build_distributor.dart';
import 'package:db_infra/src/build_distributor_type.dart';
import 'package:io/io.dart';

Future<void> main(List<String> arguments) async {
  final DBInfra dbInfra;

  try {
    final ArgResults argResult = argumentParser.parse(arguments);

    if (argResult.wasParsed(helpArgument)) {
      printHelpMessage();
      exitCode = 0;
      return;
    }

    if (argResult.runSetup && argResult.runBuild) {
      throw const FormatException(
        "Can't run --$setupProjectArg with --$buildProjectArg",
      );
    }

    if (!argResult.runSetup && !argResult.runBuild) {
      throw const FormatException(
        '--$setupProjectArg or '
        '--$buildProjectArg need to be specified',
      );
    }

    final Directory projectDir = argResult.getProjectDirectory();

    final Directory infraDir = Directory('${projectDir.path}/.infra')
      ..createSync();

    dbInfra = DBInfra(projectDirectory: projectDir, infraDirectory: infraDir);

    if (argResult.runSetup) {
      final InfraSetupConfiguration configuration =
          argResult.toSetupConfiguration(infraDir);

      await dbInfra.setup(configuration);
    } else {
      final File configurationFile = File(
        '${projectDir.path}/$configFileName',
      );

      final InfraBuildConfiguration configuration = await loadConfiguration(
        configurationFile,
        infraDir,
        enableLogging: argResult.isLoggingEnabled(),
      );

      final BuildDistributorType buildDistributorType =
          argResult.getBuildDistributorType();

      final BuildDistributor buildDistributor = argResult.getBuildDistributor(
        configuration.storage.logger,
        configuration,
        buildDistributorType,
      );

      await dbInfra.build(
        configuration: configuration,
        buildDistributor: buildDistributor,
      );
    }

    await dbInfra.cleanup();

    exit(ExitCode.success.code);
  } on Exception catch (e) {
    printHelpMessage(e is FormatException ? e.message : e.toString());
    if (e is UnrecoverableException) {
      exit(e.exitCode);
    } else {
      exit(ExitCode.osError.code);
    }
  }
}
