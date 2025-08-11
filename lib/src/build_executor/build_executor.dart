library build_executor;

import 'dart:io';

import 'package:db_infra/src/configuration/configuration.dart';
import 'package:meta/meta.dart';

export 'flutter_ios_build_executor.dart';

///
abstract class BuildExecutor {
  ///
  final String? buildFlavor;

  ///
  final Directory projectDirectory;

  ///
  @protected
  final InfraBuildConfiguration configuration;

  ///
  const BuildExecutor({
    required this.buildFlavor,
    required this.configuration,
    required this.projectDirectory,
  });

  ///
  Future<File> build();
}
