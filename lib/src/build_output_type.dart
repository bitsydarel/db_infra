import 'dart:io';

import 'package:collection/collection.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as path;

///
enum IosBuildOutputType {
  ///
  ipa,
}

///
enum AndroidBuildOutputType {
  ///
  apk,

  ///
  appbundle,
}

///
extension IosBuildOutputTypeExtension on IosBuildOutputType {
  ///
  String get name => enumName(this);

  ///
  File? outputFile(final Directory projectDirectory) {
    final Directory outputDirectory;
    final Glob releaseFileFinder;

    switch (this) {
      case IosBuildOutputType.ipa:
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
extension AndroidBuildOutputTypeExtension on AndroidBuildOutputType {
  ///
  String get name => enumName(this);

  ///
  File? outputFile(final Directory projectDirectory) {
    final Directory outputDirectory;
    final Glob releaseFileFinder;

    switch (this) {
      case AndroidBuildOutputType.apk:
        outputDirectory = Directory(
          path.join(projectDirectory.path, 'build/app/outputs/flutter-apk'),
        );
        releaseFileFinder = Glob('**-release.apk');
        break;
      case AndroidBuildOutputType.appbundle:
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
extension StringIosBuildOutputTypeExtension on String {
  ///
  IosBuildOutputType asIosBuildOutputType() {
    return IosBuildOutputType.values.firstWhere(
      (IosBuildOutputType type) => enumName(type) == this,
    );
  }

  ///
  AndroidBuildOutputType asAndroidBuildOutputType() {
    return AndroidBuildOutputType.values.firstWhere(
      (AndroidBuildOutputType type) => enumName(type) == this,
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
