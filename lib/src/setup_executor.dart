import 'dart:io';

import 'package:db_infra/src/configurations/infra_build_configuration.dart';
import 'package:db_infra/src/configurations/infra_setup_configuration.dart';

///
abstract class SetupExecutor {
  ///
  final Directory infraDirectory;

  ///
  final InfraSetupConfiguration configuration;

  ///
  const SetupExecutor(this.configuration, this.infraDirectory);

  ///
  Future<InfraBuildConfiguration> setupInfra();
}
