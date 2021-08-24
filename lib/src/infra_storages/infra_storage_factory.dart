import 'dart:io';

import 'package:db_infra/src/infra_logger.dart';
import 'package:db_infra/src/infra_storage.dart';
import 'package:db_infra/src/infra_storage_type.dart';
import 'package:db_infra/src/infra_storages/infra_disk_storage.dart';
import 'package:db_infra/src/infra_storages/infra_ftp_storage.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:io/io.dart';

/// Infrastructure storage type extension.
extension InfraStorageTypeExtension on InfraStorageType {
  ///
  InfraStorage fromJson(
    final JsonMap json,
    final InfraLogger logger,
    final Directory infraDirectory,
  ) {
    switch (this) {
      case InfraStorageType.disk:
        return InfraDiskStorage.fromJson(json, logger, infraDirectory);
      case InfraStorageType.ftp:
        return InfraFtpStorage.fromJson(json, logger, infraDirectory);
      default:
        throw UnsupportedError('${enumName(this)} is not supported');
    }
  }

  ///
  InfraStorage from({
    required final InfraLogger infraLogger,
    required final Directory infraDirectory,
    final Directory? storageDirectory,
    final String? ftpUsername,
    final String? ftpPassword,
    final String? ftpServerUrl,
    final int? ftpServerPort,
    final String? ftpServerFolderName,
  }) {
    switch (this) {
      case InfraStorageType.disk:
        if (storageDirectory != null) {
          return InfraDiskStorage(
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
      case InfraStorageType.ftp:
        if (ftpUsername != null &&
            ftpPassword != null &&
            ftpServerUrl != null &&
            ftpServerPort != null &&
            ftpServerFolderName != null) {
          return InfraFtpStorage(
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
