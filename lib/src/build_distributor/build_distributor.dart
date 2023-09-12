library build_distributor;

import 'dart:io';

import 'package:db_infra/src/build_distributor/build_distributor_type.dart';
import 'package:db_infra/src/configuration/configuration.dart';

export 'build_distributor_factory.dart';
export 'build_distributor_type.dart';
export 'file_to_directory_build_distributor.dart';

///
abstract class BuildDistributor {
  ///
  const BuildDistributor(this.buildDistributorType, this.configuration);

  ///
  final BuildDistributorType buildDistributorType;

  ///
  final InfraBuildConfiguration configuration;

  ///
  Future<void> distribute(File output);
}
