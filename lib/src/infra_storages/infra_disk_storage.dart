import 'dart:io';

import 'package:db_infra/src/infra_logger.dart';
import 'package:db_infra/src/infra_storage.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:db_infra/src/utils/file_utils.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:io/io.dart';

const String _storageDirectoryKey = 'storageDirectory';

///
class InfraDiskStorage extends InfraStorage {
  ///
  final Directory storageDirectory;

  ///
  const InfraDiskStorage({
    required this.storageDirectory,
    required InfraLogger logger,
    required Directory infraDirectory,
  }) : super(logger, infraDirectory);

  /// Infrastructure disk storage from json.
  factory InfraDiskStorage.fromJson(
    JsonMap json,
    InfraLogger logger,
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

    return InfraDiskStorage(
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
      copyFile(storageDirectory, file);
    }
  }

  @override
  JsonMap toJson() {
    return <String, String>{_storageDirectoryKey: storageDirectory.path};
  }
}
