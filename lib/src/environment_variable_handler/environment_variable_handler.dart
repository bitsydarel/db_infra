library environment_variable;

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:db_infra/src/environment_variable_handler/dot_env_environment_variable_handler.dart';

export 'dot_env_environment_variable_handler.dart';

/// An interface for environment variables.
abstract class EnvironmentVariableHandler {
  /// Const constructor so child can define theirs.
  const EnvironmentVariableHandler();

  /// Get the environment variable as a [Map] of [String] and nullable [Object].
  Future<Map<String, Object>> call();

  /// Join all the environment variables as dart defines.
  Future<List<String>> asDartDefines() async {
    final Map<String, Object> envVars = await call();

    final List<String> dartDefines = <String>[];

    for (final MapEntry<String, Object?> keyValue in envVars.entries) {
      dartDefines.add('--dart-define=${keyValue.key}=${keyValue.value}');
    }

    return dartDefines;
  }
}

/// Environment variable type.
enum EnvironmentVariableHandlerType {
  /// Dot environment variable.
  ///
  /// https://www.ibm.com/docs/en/aix/7.2?topic=files-env-file
  dotEnv,
}

/// Extensions function that convert a [String] to
/// [EnvironmentVariableHandlerType] and [EnvironmentVariableHandler].
extension EnvironmentVariableTypeHandlerFromString on String {
  ///
  EnvironmentVariableHandlerType? asEnvironmentVariableType() {
    return EnvironmentVariableHandlerType.values.firstWhereOrNull(
      (EnvironmentVariableHandlerType type) => type.name == this,
    );
  }
}

/// Extensions function that convert a [EnvironmentVariableHandlerType] to
/// [EnvironmentVariableHandler].
extension EnvironmentVariableHandlerFromType on EnvironmentVariableHandlerType {
  ///
  EnvironmentVariableHandler? asEnvironmentVariableHandler({
    File? dotEnvironmentVariableFile,
  }) {
    switch (this) {
      case EnvironmentVariableHandlerType.dotEnv:
        return DotEnvEnvironmentVariableHandler(dotEnvironmentVariableFile!);
    }
  }
}
