import 'dart:io';

import 'package:bdlogging/bdlogging.dart';
import 'package:db_infra/src/build_executor/build_executor.dart';
import 'package:db_infra/src/build_output_type.dart';
import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/environment_variable_handler/environment_variable_handler.dart';
import 'package:db_infra/src/shell_runner.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;

///
class FlutterAndroidBuildExecutor extends BuildExecutor {
  ///
  FlutterAndroidBuildExecutor({
    required this.runner,
    required Directory projectDirectory,
    required InfraBuildConfiguration configuration,
    String? buildFlavor,
    this.environmentVariableHandler,
  }) : super(
          buildFlavor: buildFlavor,
          configuration: configuration,
          projectDirectory: projectDirectory,
        );

  ///
  final EnvironmentVariableHandler? environmentVariableHandler;

  ///
  final ShellRunner runner;

  @override
  Future<File> build() async {
    BDLogger().info('Starting Android Flutter build...');

    final Directory androidFlutterDir = Directory(
      path.join(projectDirectory.path, 'android'),
    );

    final Map<String, Object>? environmentVariables =
        await environmentVariableHandler?.call();

    final File infraAndroidConfig = File(
      path.join(androidFlutterDir.path, 'local.properties'),
    );

    final String? flutterFlavor = buildFlavor;

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

    BDLogger().info('ANDROID FLUTTER BUILD STARTED');

    final ShellOutput output = await runner.executeAsync(
      'flutter',
      <String>[
        'build',
        configuration.androidBuildOutputType.name,
        if (flutterFlavor != null) ...<String>['--flavor', flutterFlavor],
        '--release',
        if (dartDefines != null) ...dartDefines
      ],
      <String, String>{'CI': 'true'},
    );

    Directory.current = oldPath;

    infraAndroidConfig.deleteSync();

    if (output.isFailure()) {
      final UnrecoverableException exception = UnrecoverableException(
        output.stderr,
        ExitCode.tempFail.code,
      );

      BDLogger()
        ..info('ANDROID FLUTTER BUILD FAILED')
        ..info(output.stdout)
        ..error(output.stderr, exception);

      throw exception;
    }

    BDLogger().info('ANDROID FLUTTER BUILD COMPLETED\n${output.stdout}');

    final File? outputFile =
        configuration.androidBuildOutputType.outputFile(projectDirectory);

    if (outputFile == null || !outputFile.existsSync()) {
      throw UnrecoverableException(
        'Could not find android build output file at ${outputFile?.path}',
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
