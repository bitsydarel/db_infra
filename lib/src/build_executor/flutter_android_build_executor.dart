import 'dart:io';

import 'package:db_infra/src/build_executor/build_executor.dart';
import 'package:db_infra/src/build_output_type.dart';
import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/environment_variable_handler/environment_variable_handler.dart';
import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/shell_runner.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;

///
class FlutterAndroidBuildExecutor extends BuildExecutor {
  ///
  FlutterAndroidBuildExecutor({
    required this.logger,
    required Directory projectDirectory,
    required InfraBuildConfiguration configuration,
    this.runner = const ShellRunner(),
    this.environmentVariableHandler,
  }) : super(projectDirectory: projectDirectory, configuration: configuration);

  ///
  final EnvironmentVariableHandler? environmentVariableHandler;

  ///
  final Logger logger;

  ///
  final ShellRunner runner;

  @override
  Future<File> build() async {
    final Directory androidFlutterDir = Directory(
      path.join(projectDirectory.path, 'android'),
    );

    final Map<String, Object>? environmentVariables =
        await environmentVariableHandler?.call();

    final File infraAndroidConfig = File(
      path.join(androidFlutterDir.path, 'local.properties'),
    );

    updateAndroidProjectSigningConfigurationO(
      infraAndroidConfig,
      configuration.androidKeyAlias,
      configuration.androidKeyPassword,
      configuration.androidStoreFile,
      configuration.androidStorePassword,
      environmentVariables,
    );

    final List<String>? dartDefines =
        await environmentVariableHandler?.asDartDefines();

    final String oldPath = path.canonicalize(Directory.current.path);
    final String projectDir = path.canonicalize(projectDirectory.path);

    Directory.current = projectDir;

    final ShellOutput output = runner.execute(
      'flutter',
      <String>[
        'build',
        configuration.androidBuildOutputType.name,
        '--release',
        if (dartDefines != null) ...dartDefines
      ],
      <String, String>{'CI': 'true'},
    );

    Directory.current = oldPath;

    infraAndroidConfig.deleteSync();

    if (output.stdout.contains('BUILD FAILED') ||
        output.stderr.contains('BUILD FAILED')) {
      logger
        ..logInfo(output.stdout)
        ..logError(output.stderr);
      throw UnrecoverableException(output.stderr, ExitCode.tempFail.code);
    }

    final File? outputFile =
        configuration.androidBuildOutputType.outputFile(projectDirectory);

    if (outputFile == null) {
      throw UnrecoverableException(
        'Could not find build android '
        '${configuration.androidBuildOutputType.name}',
        ExitCode.software.code,
      );
    }

    return outputFile;
  }
}

///
void updateAndroidProjectSigningConfigurationO(
  final File propertiesConfig,
  final String androidKeyAlias,
  final String androidKeyPassword,
  final File androidStoreFile,
  final String androidStorePassword,
  final Map<String, Object>? environmentVariables,
) {
  propertiesConfig.writeAsStringSync(
    <String>[
      'ANDROID_KEY_ALIAS=$androidKeyAlias',
      'ANDROID_KEY_PASSWORD=$androidKeyPassword',
      'ANDROID_STORE_PASSWORD=$androidStorePassword',
      'ANDROID_STORE_FILE=${androidStoreFile.absolute.path}',
      if (environmentVariables != null)
        ...environmentVariables.entries.map((MapEntry<String, Object> entry) {
          return '${entry.key}=${entry.value}';
        }).toList(),
    ].join('\n'),
    mode: FileMode.writeOnly,
    flush: true,
  );
}
