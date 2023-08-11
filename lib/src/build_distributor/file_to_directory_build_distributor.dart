import 'dart:io';

import 'package:bdlogging/bdlogging.dart';
import 'package:db_infra/src/build_distributor/build_distributor.dart';
import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/utils/file_utils.dart';

///
class FileToDirectoryBuildDistributor extends BuildDistributor {
  ///
  final Directory buildOutputDirectory;

  ///
  const FileToDirectoryBuildDistributor(
    this.buildOutputDirectory,
    InfraBuildConfiguration configuration,
    BuildDistributorType buildDistributorType,
  ) : super(buildDistributorType, configuration);

  @override
  Future<void> distribute(File output) async {
    final File buildOutput = buildOutputDirectory.copyFile(output);
    BDLogger().info('Output: ${buildOutput.path}');
  }
}
