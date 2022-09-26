library build_executor;

import 'dart:io';

import 'package:db_infra/src/configuration/configuration.dart';
import 'package:meta/meta.dart';

export 'flutter_ios_build_executor.dart';

///
abstract class BuildExecutor {
  ///
  @protected
  final InfraBuildConfiguration configuration;

  ///
  final Directory projectDirectory;

  ///
  const BuildExecutor({
    required this.projectDirectory,
    required this.configuration,
  });

  ///
  Future<File> build();
}
