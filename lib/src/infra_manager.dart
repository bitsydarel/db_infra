import 'dart:io';

import 'package:db_infra/src/infra_configuration.dart';

///
abstract class InfraManager {
  ///
  final Directory projectDirectory;

  ///
  InfraManager({required this.projectDirectory});

  ///
  Future<void> saveConfiguration(final InfraConfiguration configuration);

  ///
  Future<InfraConfiguration> loadConfiguration();
}
