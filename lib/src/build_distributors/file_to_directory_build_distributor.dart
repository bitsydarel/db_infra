import 'dart:io';

import 'package:db_infra/src/build_distributor.dart';
import 'package:db_infra/src/configurations/infra_build_configuration.dart';
import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/utils/file_utils.dart';

///
class FileToDirectoryBuildDistributor extends BuildDistributor {
  ///
  final Directory buildOutputDirectory;

  ///
  final Logger logger;

  ///
  const FileToDirectoryBuildDistributor(
    this.buildOutputDirectory,
    this.logger,
    InfraBuildConfiguration configuration,
  ) : super(configuration);

  @override
  Future<void> distribute(File output) async {
    final File buildOutput = buildOutputDirectory.copyFile(output);
    logger.logSuccess('Output: ${buildOutput.path}');
  }
}
