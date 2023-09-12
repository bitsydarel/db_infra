import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:db_infra/db_infra.dart';
import 'package:io/io.dart';

Future<void> main(List<String> arguments) async {
  final CommandRunner<void> commandRunner = CommandRunner<void>(
    'db_infra',
    'A command-line tool that help to automate your release workflow',
  );

  commandRunner.argParser
    ..addOption(
      infraConfigFileArg,
      help: 'Specify the name of the infrastructure configuration file.',
      defaultsTo: 'infra_config.json',
    )
    ..addFlag(
      infraVerboseLoggingArg,
      defaultsTo: true,
      help: 'Enable verbosity in the execution of the script.',
    );

  commandRunner
    ..addCommand(InfraSetupCommand())
    ..addCommand(InfraBuildCommand());

  await runZonedGuarded<Future<void>>(
    () => commandRunner.run(arguments),
    (Object error, StackTrace history) {
      stderr
        ..writeln(error)
        ..writeln(history);

      if (error is UnrecoverableException) {
        exit(error.exitCode);
      } else if (error is Error) {
        exit(ExitCode.osError.code);
      } else if (error is Exception) {
        exit(ExitCode.tempFail.code);
      }
    },
  );

  exit(ExitCode.success.code);
}
