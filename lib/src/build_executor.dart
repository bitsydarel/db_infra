import 'dart:io';

import 'package:db_infra/src/configurations/infra_build_configuration.dart';
import 'package:meta/meta.dart';

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
