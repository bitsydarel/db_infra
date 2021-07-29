library db_infra;

import 'package:db_infra/src/setup_configuration.dart';

export 'package:db_infra/src/setup_configuration.dart';
export 'package:db_infra/src/run_configuration.dart';
export 'package:db_infra/src/infra_configuration.dart';
export 'package:db_infra/src/utils/script_utils.dart';
export 'package:db_infra/src/build_executor.dart';
export 'package:db_infra/src/infra_manager.dart';
export 'package:db_infra/src/setup_executors/ios_setup_executor.dart';
export 'package:db_infra/src/software_builders/flutter_ios_build_executor.dart';
export 'package:db_infra/src/software_builders/apple/certificates_manager.dart';
export 'package:db_infra/src/software_builders/apple/bundle_id_manager.dart';
export 'package:db_infra/src/software_builders/apple/profiles_manager.dart';
export 'package:db_infra/src/utils/constants.dart';

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
