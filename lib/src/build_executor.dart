import 'package:db_infra/src/infra_configuration.dart';
import 'package:meta/meta.dart';

///
abstract class BuildExecutor {
  ///
  @protected
  final InfraConfiguration configuration;

  ///
  const BuildExecutor({required this.configuration});

  ///
  Future<void> build();
}
