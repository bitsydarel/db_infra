import 'dart:io';

import 'package:db_infra/src/build_distributor/build_distributor.dart';
import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:io/io.dart';

///
extension BuildDistributorExtension on BuildDistributorType {
  ///
  BuildDistributor toDistributor({
    required final Logger infraLogger,
    required final InfraBuildConfiguration configuration,
    String? outputDirectoryPath,
  }) {
    switch (this) {
      case BuildDistributorType.directory:
        final Directory outputDirectory = Directory(outputDirectoryPath ?? '');

        if (outputDirectoryPath != null) {
          outputDirectory.createSync(recursive: true);

          return FileToDirectoryBuildDistributor(
            outputDirectory,
            infraLogger,
            configuration,
          );
        } else {
          throw UnrecoverableException(
            'Build distributor type $name require '
            'an existing output directory path',
            ExitCode.config.code,
          );
        }
    }
  }
}
