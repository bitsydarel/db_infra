import 'dart:io';

import 'package:db_infra/db_infra.dart';
import 'package:args/args.dart';
import 'package:db_infra/src/utils/exceptions.dart';
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
      await dbInfra.build();
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
