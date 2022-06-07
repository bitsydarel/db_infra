import 'dart:io';

import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/storage/storage.dart';
import 'package:db_infra/src/utils/utils.dart';
import 'package:io/io.dart';

const String _storageDirectoryKey = 'storageDirectory';

///
class DiskStorage extends Storage {
  ///
  final Directory storageDirectory;

  ///
  final Logger logger;

  ///
  final Directory infraDirectory;

  ///
  const DiskStorage({
    required this.storageDirectory,
    required this.logger,
    required this.infraDirectory,
  });

  /// Infrastructure disk storage from json.
  factory DiskStorage.fromJson(
    JsonMap json,
    Logger logger,
    Directory infraDirectory,
  ) {
    final Object? storageDirectoryParam = json[_storageDirectoryKey];

    final Directory storageDirectory = storageDirectoryParam is String
        ? Directory(storageDirectoryParam)
        : throw ArgumentError(
            '$storageDirectoryParam is not a valid $_storageDirectoryKey',
          );

    if (!storageDirectory.existsSync()) {
      throw UnrecoverableException(
        '${storageDirectory.path} does not exist',
        ExitCode.config.code,
      );
    }

    return DiskStorage(
      storageDirectory: storageDirectory,
      logger: logger,
      infraDirectory: infraDirectory,
    );
  }

  @override
  Future<List<File>> loadFiles() async {
    final List<File> files = <File>[];

    final List<FileSystemEntity> storageFiles = storageDirectory.listSync();

    for (final FileSystemEntity storageFileEntity in storageFiles) {
      if (FileSystemEntity.isFileSync(storageFileEntity.path)) {
        final File storageFile = File(storageFileEntity.path);

        files.add(storageFile);
      }
    }

    return files;
  }

  @override
  Future<void> saveFiles(List<File> files) async {
    storageDirectory.createSync(recursive: true);

    for (final File file in files) {
      storageDirectory.copyFile(file);
    }
  }

  @override
  JsonMap toJson() {
    return <String, String>{_storageDirectoryKey: storageDirectory.path};
  }
}
