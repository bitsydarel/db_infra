library db_infra;

import 'package:db_infra/src/setup_configuration.dart';

export 'package:db_infra/src/setup_configuration.dart';
export 'package:db_infra/src/utils/script_utils.dart';
export 'package:db_infra/src/build_executor.dart';

/// Darel Bitsy Infrastructure.
abstract class DBInfra {
  ///
  final SetupConfiguration configuration;

  ///
  const DBInfra(this.configuration);

  /// Setup the infrastructure.
  Future<void> setup();

  /// Build flutter android app.
  Future<void> build({bool sign = true});
}
