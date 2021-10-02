import 'dart:io';

import 'package:db_infra/src/configurations/infra_build_configuration.dart';

///
abstract class BuildDistributor {
  ///
  const BuildDistributor(this.configuration);

  ///
  final InfraBuildConfiguration configuration;

  ///
  Future<void> distribute(File output);
}
