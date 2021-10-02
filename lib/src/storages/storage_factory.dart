import 'dart:io';

import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/storage.dart';
import 'package:db_infra/src/storage_type.dart';
import 'package:db_infra/src/storages/disk_storage.dart';
import 'package:db_infra/src/storages/ftp_storage.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:io/io.dart';

/// Infrastructure storage type extension.
extension StorageTypeExtension on StorageType {
  ///
  Storage fromJson(
    final JsonMap json,
    final Logger logger,
    final Directory infraDirectory,
  ) {
    switch (this) {
      case StorageType.disk:
        return DiskStorage.fromJson(json, logger, infraDirectory);
      case StorageType.ftp:
        return FtpStorage.fromJson(json, logger, infraDirectory);
      default:
        throw UnsupportedError('${enumName(this)} is not supported');
    }
  }

  ///
  Storage from({
    required final Logger infraLogger,
    required final Directory infraDirectory,
    final Directory? storageDirectory,
    final String? ftpUsername,
    final String? ftpPassword,
    final String? ftpServerUrl,
    final int? ftpServerPort,
    final String? ftpServerFolderName,
  }) {
    switch (this) {
      case StorageType.disk:
        if (storageDirectory != null) {
          return DiskStorage(
            storageDirectory: storageDirectory,
            logger: infraLogger,
            infraDirectory: infraDirectory,
          );
        }

        throw UnrecoverableException(
          'Infra storage type $name '
          'request but storage directory not specified',
          ExitCode.config.code,
        );
      case StorageType.ftp:
        if (ftpUsername != null &&
            ftpPassword != null &&
            ftpServerUrl != null &&
            ftpServerPort != null &&
            ftpServerFolderName != null) {
          return FtpStorage(
            username: ftpUsername,
            password: ftpPassword,
            serverUrl: ftpServerUrl,
            serverPort: ftpServerPort,
            serverFolderName: ftpServerFolderName,
            logger: infraLogger,
            infraDirectory: infraDirectory,
          );
        }

        throw UnrecoverableException(
          'Infra storage type $name '
          'request but ftp username, password, url need to be specified',
          ExitCode.config.code,
        );
      default:
        throw UnsupportedError('Infra storage type $name is not supported');
    }
  }
}
