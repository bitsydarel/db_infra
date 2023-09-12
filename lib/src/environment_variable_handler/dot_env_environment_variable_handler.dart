import 'dart:io';

import 'package:db_infra/src/environment_variable_handler/environment_variable_handler.dart';
import 'package:meta/meta.dart';

/// .env environment variable handler.
class DotEnvEnvironmentVariableHandler extends EnvironmentVariableHandler {
  ///
  DotEnvEnvironmentVariableHandler(this.dotEnvFile);

  ///
  final File dotEnvFile;

  Map<String, Object>? _dovEnv;

  @override
  Future<Map<String, Object>> call() async {
    return _dovEnv ??= parseEnvironmentVariables(dotEnvFile);
  }

  ///
  @visibleForTesting
  static Map<String, Object> parseEnvironmentVariables(File dotEnvFile) {
    final Map<String, Object> env = <String, Object>{};

    final List<String> lines = dotEnvFile.readAsLinesSync();

    for (final String line in lines) {
      final MapEntry<String, Object>? envVariable = parseEnvironmentLine(line);

      if (envVariable != null) {
        env[envVariable.key] = envVariable.value;
      }
    }

    return env;
  }

  ///
  @visibleForTesting
  static MapEntry<String, Object>? parseEnvironmentLine(String line) {
    if (!line.contains('=')) {
      return null;
    }

    final int separatorIndex = line.indexOf('=');

    final String key = line.substring(0, separatorIndex);
    final String value = line.substring(separatorIndex + 1, line.length);

    return MapEntry<String, Object>(key, value);
  }
}
