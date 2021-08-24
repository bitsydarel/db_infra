import 'dart:io';

import 'package:db_infra/src/infra_configurations/infra_configuration.dart';
import 'package:meta/meta.dart';

///
abstract class InfraBuildExecutor {
  ///
  @protected
  final InfraConfiguration configuration;

  ///
  final Directory projectDirectory;

  ///
  const InfraBuildExecutor({
    required this.projectDirectory,
    required this.configuration,
  });

  ///
  Future<File> build();
}
