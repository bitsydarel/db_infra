import 'dart:io';

import 'package:db_infra/src/infra_configurations/infra_configuration.dart';
import 'package:db_infra/src/infra_configurations/infra_setup_configuration.dart';

///
abstract class InfraSetupExecutor {
  ///
  final Directory infraDirectory;

  ///
  final InfraSetupConfiguration configuration;

  ///
  const InfraSetupExecutor(this.configuration, this.infraDirectory);

  ///
  Future<InfraConfiguration> setupInfra();
}
