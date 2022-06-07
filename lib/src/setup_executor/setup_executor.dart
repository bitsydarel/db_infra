library setup_executor;

import 'dart:io';

import 'package:db_infra/src/configuration/configuration.dart';

export 'ios_setup_executor.dart';

/// A interface that provide a blueprint for setup.
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
