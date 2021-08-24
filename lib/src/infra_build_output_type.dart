import 'dart:io';

import 'package:db_infra/src/utils/types.dart';
import 'package:glob/list_local_fs.dart';
import 'package:glob/glob.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

///
enum InfraIosBuildOutputType {
  ///
  ipa,
}

///
enum InfraAndroidBuildOutputType {
  ///
  apk,

  ///
  appbundle,
}

///
extension InfraIosBuildOutputTypeExtension on InfraIosBuildOutputType {
  ///
  String get name => enumName(this);

  ///
  File? outputFile(final Directory projectDirectory) {
    final Directory outputDirectory;
    final Glob releaseFileFinder;

    switch (this) {
      case InfraIosBuildOutputType.ipa:
        outputDirectory = Directory(
          path.join(projectDirectory.path, 'build/ios/ipa'),
        );
        releaseFileFinder = Glob('**.ipa');
        break;
    }

    return _getOutputFile(outputDirectory, releaseFileFinder);
  }
}

///
extension InfraAndroidBuildOutputTypeExtension on InfraAndroidBuildOutputType {
  ///
  String get name => enumName(this);

  ///
  File? outputFile(final Directory projectDirectory) {
    final Directory outputDirectory;
    final Glob releaseFileFinder;

    switch (this) {
      case InfraAndroidBuildOutputType.apk:
        outputDirectory = Directory(
          path.join(projectDirectory.path, 'build/app/outputs/flutter-apk'),
        );
        releaseFileFinder = Glob('**-release.apk');
        break;
      case InfraAndroidBuildOutputType.appbundle:
        outputDirectory = Directory(
          path.join(projectDirectory.path, 'build/app/outputs/bundle/release'),
        );
        releaseFileFinder = Glob('**-release.aab');
        break;
    }

    return _getOutputFile(outputDirectory, releaseFileFinder);
  }
}

///
extension StringInfraIosBuildOutputTypeExtension on String {
  ///
  InfraIosBuildOutputType asIosBuildOutputType() {
    return InfraIosBuildOutputType.values.firstWhere(
      (InfraIosBuildOutputType type) => enumName(type) == this,
    );
  }

  ///
  InfraAndroidBuildOutputType asAndroidBuildOutputType() {
    return InfraAndroidBuildOutputType.values.firstWhere(
      (InfraAndroidBuildOutputType type) => enumName(type) == this,
    );
  }
}

File? _getOutputFile(final Directory outputDir, final Glob releaseOutput) {
  if (outputDir.existsSync()) {
    final List<FileSystemEntity> outputFiles =
        releaseOutput.listSync(root: outputDir.path);

    final FileSystemEntity? outputFileEntity = outputFiles.firstOrNull;

    if (outputFileEntity != null && outputFileEntity.existsSync()) {
      return File(outputFileEntity.path);
    }
  }

  return null;
}
