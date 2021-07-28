import 'package:db_infra/src/infra_configuration.dart';
import 'package:db_infra/src/setup_configuration.dart';

///
abstract class SetupExecutor {
  ///
  final SetupConfiguration configuration;

  ///
  const SetupExecutor(this.configuration);

  ///
  Future<InfraConfiguration> setupInfra();
}
