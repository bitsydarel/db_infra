import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:db_infra/db_infra.dart';
import 'package:io/io.dart';

void main(List<String> arguments) {
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

  commandRunner.run(arguments).catchError((Object error, StackTrace history) {
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
  });
}
