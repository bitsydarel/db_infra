import 'dart:io';

import 'package:archive/archive_io.dart' as archiver;
import 'package:bdlogging/bdlogging.dart';
import 'package:db_infra/src/storage/storage.dart';
import 'package:db_infra/src/utils/utils.dart';
import 'package:gcloud/storage.dart' as storage;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:io/io.dart';
import 'package:path/path.dart' as path;

const String _gcloudProjectIdKey = 'gcloudProjectId';
const String _bucketNameKey = 'bucketName';
const String _serviceAccountKey = 'serviceAccount';
const String _bucketFolderKey = 'bucketFolder';

///
class GoogleCloudStorage extends Storage {
  ///
  const GoogleCloudStorage({
    required this.bucketName,
    required this.bucketFolder,
    required this.serviceAccount,
    required this.gcloudProjectId,
    required this.infraDirectory,
  });

  ///
  factory GoogleCloudStorage.fromJson(
    JsonMap json,
    Directory infraDirectory,
  ) {
    final Object? gcloudProjectId = json[_gcloudProjectIdKey];
    final Object? bucketName = json[_bucketNameKey];
    final Object? bucketFolder = json[_bucketFolderKey];
    final Object? serviceAccount = json[_serviceAccountKey];

    return GoogleCloudStorage(
      gcloudProjectId: gcloudProjectId is String
          ? gcloudProjectId
          : throw ArgumentError(gcloudProjectId),
      bucketName:
          bucketName is String ? bucketName : throw ArgumentError(bucketName),
      bucketFolder: bucketFolder is String
          ? bucketFolder
          : throw ArgumentError(bucketFolder),
      serviceAccount: serviceAccount is String
          ? serviceAccount
          : throw ArgumentError(serviceAccount),
      infraDirectory: infraDirectory,
    );
  }

  @override
  JsonMap toJson() {
    return <String, String>{
      _gcloudProjectIdKey: gcloudProjectId,
      _bucketNameKey: bucketName,
      _serviceAccountKey: serviceAccount,
      _bucketFolderKey: bucketFolder,
    };
  }

  ///
  final String gcloudProjectId;

  ///
  final String serviceAccount;

  ///
  final String bucketName;

  ///
  final String bucketFolder;

  ///
  final Directory infraDirectory;

  @override
  Future<List<File>> loadFiles() async {
    final storage.Bucket bucket = await _getGcloudBucket();

    final Directory localDirectory = Directory(
      path.join(infraDirectory.path, 'data'),
    )..createSync(recursive: true);

    final String zipFileName = _getZipFileName();

    final File localZipFile = File(
      path.join(localDirectory.path, zipFileName),
    )..createSync();

    await bucket
        .read('$bucketFolder/$zipFileName')
        .pipe(localZipFile.openWrite());

    if (localZipFile.lengthSync() <= 0) {
      throw UnrecoverableException(
        'Could not unzip file $zipFileName from Gcloud bucket $bucketName',
        ExitCode.tempFail.code,
      );
    }

    await archiver.extractFileToDisk(localZipFile.path, localDirectory.path);

    localZipFile.deleteSync();

    final List<File> downloadedFiles = localDirectory
        .listSync(recursive: true)
        .map((FileSystemEntity fileSystemEntity) => File(fileSystemEntity.path))
        .map(infraDirectory.copyFile)
        .toList();

    localDirectory.deleteSync(recursive: true);

    return downloadedFiles;
  }

  @override
  Future<void> saveFiles(List<File> files) async {
    final storage.Bucket bucket = await _getGcloudBucket();

    final File zipFile = File(
      path.join(infraDirectory.path, _getZipFileName()),
    );

    final archiver.ZipFileEncoder encoder = archiver.ZipFileEncoder()
      ..create(zipFile.path);

    for (final File file in files) {
      final FileSystemEntityType fileType =
          FileSystemEntity.typeSync(file.path);

      if (fileType == FileSystemEntityType.directory) {
        encoder.addDirectory(Directory(file.path));
      } else if (fileType == FileSystemEntityType.file) {
        encoder.addFile(file);
      }
    }

    encoder.close();

    if (!zipFile.existsSync() && zipFile.lengthSync() <= 0) {
      throw UnrecoverableException(
        'Could not create file to upload to Gcloud bucket ${zipFile.path}',
        ExitCode.osFile.code,
      );
    }

    try {
      await zipFile.openRead().pipe(
            bucket.write(
              '$bucketFolder/${path.basename(zipFile.path)}',
              length: zipFile.lengthSync(),
            ),
          );
    } on Object catch (e, s) {
      BDLogger()
        .error('Could not write zip file to GCP bucket', e, stackTrace: s);
      throw UnrecoverableException(
        'Could not upload to Gcloud storage ${zipFile.path}',
        ExitCode.tempFail.code,
      );
    }
  }

  String _getZipFileName() => 'data.zip';

  Future<storage.Bucket> _getGcloudBucket() async {
    final auth.ServiceAccountCredentials credentials =
        auth.ServiceAccountCredentials.fromJson(serviceAccount);

    // Get an HTTP authenticated client using the service account credentials.
    final auth.AutoRefreshingAuthClient client =
        await auth.clientViaServiceAccount(
      credentials,
      storage.Storage.SCOPES,
    );

    final storage.Storage gcloudStorage =
        storage.Storage(client, gcloudProjectId);

    final storage.Bucket bucket = gcloudStorage.bucket(bucketName);

    return bucket;
  }
}
