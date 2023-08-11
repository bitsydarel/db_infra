library storage;

import 'dart:io';

import 'package:db_infra/src/storage/disk_storage.dart';
import 'package:db_infra/src/storage/ftp_storage.dart';
import 'package:db_infra/src/storage/google_cloud_storage.dart';
import 'package:db_infra/src/utils/utils.dart';
import 'package:io/io.dart';

export 'disk_storage.dart';
export 'ftp_storage.dart';
export 'google_cloud_storage.dart';

///
abstract class Storage {
  ///
  const Storage();

  ///
  Future<void> saveFiles(final List<File> files);

  ///
  Future<List<File>> loadFiles();

  ///
  JsonMap toJson();
}

///
enum StorageType {
  ///
  disk,

  ///
  ftp,

  ///
  googleCloud,
}

///
extension StringStorageTypeExtension on String {
  ///
  StorageType asStorageType() {
    return StorageType.values.firstWhere(
      (StorageType type) => type.name == this,
    );
  }
}

/// Infrastructure storage type extension.
extension StorageByTypeFactoryExtension on StorageType {
  ///
  Storage fromJson(
    final JsonMap json,
    final Directory infraDirectory,
  ) {
    switch (this) {
      case StorageType.disk:
        return DiskStorage.fromJson(json, infraDirectory);
      case StorageType.ftp:
        return FtpStorage.fromJson(json, infraDirectory);
      case StorageType.googleCloud:
        return GoogleCloudStorage.fromJson(json, infraDirectory);
      default:
        throw UnsupportedError('$name is not supported');
    }
  }

  ///
  Storage from({
    required final Directory infraDirectory,
    final Directory? storageDirectory,
    final String? ftpUsername,
    final String? ftpPassword,
    final String? ftpServerUrl,
    final int? ftpServerPort,
    final String? ftpServerFolderName,
    final String? gcloudProjectId,
    final String? gcloudBucketName,
    final String? gcloudBucketFolder,
    final File? gcloudServiceAccountFile,
  }) {
    switch (this) {
      case StorageType.disk:
        if (storageDirectory != null) {
          return DiskStorage(
            storageDirectory: storageDirectory,
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
            infraDirectory: infraDirectory,
          );
        }

        throw UnrecoverableException(
          'Infra storage type $name '
          'requested but ftp username, password, url need to be specified',
          ExitCode.config.code,
        );
      case StorageType.googleCloud:
        if (gcloudProjectId != null &&
            gcloudBucketName != null &&
            gcloudServiceAccountFile != null &&
            gcloudBucketFolder != null &&
            gcloudServiceAccountFile.existsSync()) {
          return GoogleCloudStorage(
            bucketName: gcloudBucketName,
            bucketFolder: gcloudBucketFolder,
            serviceAccount: gcloudServiceAccountFile.readAsStringSync(),
            gcloudProjectId: gcloudProjectId,
            infraDirectory: infraDirectory,
          );
        }
        throw UnrecoverableException(
          'Infra storage type $name '
          'requested but $infraGcloudProjectIdArg, '
          '$infraGcloudProjectBucketNameArg, '
          '$infraGcloudProjectServiceAccountFileArg need to be specified',
          ExitCode.config.code,
        );
      default:
        throw UnsupportedError('Infra storage type $name is not supported');
    }
  }
}
