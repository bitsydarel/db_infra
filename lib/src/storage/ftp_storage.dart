import 'dart:io';

import 'package:db_infra/src/logger.dart' as db_log;
import 'package:db_infra/src/storage/storage.dart';
import 'package:db_infra/src/utils/utils.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:io/io.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

const String _usernameKey = 'ftpUsername';
const String _passwordKey = 'ftpPassword';
const String _serverUrlKey = 'ftpServerUrl';
const String _serverPortKey = 'ftpServerPort';
const String _serverFolderNameKey = 'ftpFolderName';

///
class FtpStorage extends Storage {
  ///
  final String username;

  ///
  final String password;

  ///
  final String serverUrl;

  ///
  final int serverPort;

  ///
  final String serverFolderName;

  final FTPConnect _ftpConnection;

  ///
  final db_log.Logger logger;

  ///
  final Directory infraDirectory;

  ///
  FtpStorage({
    required this.username,
    required this.password,
    required this.serverUrl,
    required this.serverPort,
    required this.serverFolderName,
    required this.logger,
    required this.infraDirectory,
    @visibleForTesting FTPConnect? ftpConnection,
  }) : _ftpConnection = ftpConnection ??
            FTPConnect(
              serverUrl,
              user: username,
              pass: password,
              port: serverPort,
              debug: logger.enableLogging,
              timeout: const Duration(minutes: 15).inSeconds,
            );

  ///
  factory FtpStorage.fromJson(
    JsonMap json,
    db_log.Logger logger,
    Directory infraDirectory,
  ) {
    final Object? username = json[_usernameKey];
    final Object? password = json[_passwordKey];
    final Object? serverUrl = json[_serverUrlKey];
    final Object? serverPort = json[_serverPortKey];
    final Object? serverFolderName = json[_serverFolderNameKey];

    return FtpStorage(
      username: username is String ? username : throw ArgumentError(username),
      password: password is String ? password : throw ArgumentError(password),
      serverUrl:
          serverUrl is String ? serverUrl : throw ArgumentError(serverUrl),
      serverFolderName: serverFolderName is String
          ? serverFolderName
          : throw ArgumentError(serverFolderName),
      serverPort: serverPort is String
          ? int.parse(serverPort.toString())
          : throw ArgumentError(serverPort.toString()),
      logger: logger,
      infraDirectory: infraDirectory,
    );
  }

  @override
  Future<List<File>> loadFiles() async {
    await _ftpConnection.connect();

    final Directory localDirectory = Directory(
      path.join(infraDirectory.path, 'data'),
    )..createSync(recursive: true);

    final File localZipFile = File(
      path.join(localDirectory.path, _getZipFileName()),
    )..createSync();

    final List<String> directoryPaths = path.split(serverFolderName);

    for (final String directoryPath in directoryPaths) {
      await _changeDirectory(directoryPath);
    }

    final String zipFileName = _getZipFileName();

    final bool fileDownloaded = await _ftpConnection.downloadFileWithRetry(
      _getZipFileName(),
      localZipFile,
      pRetryCount: 3,
    );

    if (!fileDownloaded) {
      throw UnrecoverableException(
        'Could not download file $zipFileName from FTP',
        ExitCode.tempFail.code,
      );
    }

    await _ftpConnection.disconnect();

    await localZipFile.unzip(localDirectory.path);

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
    await _ftpConnection.connect();

    final File zipFile = File(
      path.join(infraDirectory.path, _getZipFileName()),
    );

    await zipFile.zip(files);

    logger.logInfo(
      'Creating directory $serverFolderName on ftp server if not exist.',
    );

    final List<String> directoryPaths = path.split(serverFolderName);

    for (final String directoryPath in directoryPaths) {
      await _changeDirectory(directoryPath);
    }

    if (!zipFile.existsSync()) {
      throw UnrecoverableException(
        'Could not create file to upload to ftp server ${zipFile.path}',
        ExitCode.osFile.code,
      );
    }

    final bool fileUploaded =
        await _ftpConnection.uploadFileWithRetry(zipFile, pRetryCount: 3);

    if (fileUploaded) {
      logger.logSuccess('File uploads completed.');
    } else {
      throw UnrecoverableException(
        'Could not upload to ftp server ${zipFile.path}',
        ExitCode.tempFail.code,
      );
    }
  }

  Future<void> _changeDirectory(String directory) async {
    final bool folderCreated =
        await _ftpConnection.createFolderIfNotExist(directory);

    if (!folderCreated) {
      throw UnrecoverableException(
        'Folder $directory does not exist and '
        'could not be created on $serverUrl',
        ExitCode.tempFail.code,
      );
    }

    if (path.basename(await _ftpConnection.currentDirectory()) == directory) {
      return;
    }

    final bool directoryChanged =
        await _ftpConnection.changeDirectory(directory);

    final String currentFtpDirectory = path.basename(
      await _ftpConnection.currentDirectory(),
    );

    if (!directoryChanged || currentFtpDirectory != directory) {
      throw UnrecoverableException(
        'Could not move to folder $directory on $serverUrl',
        ExitCode.tempFail.code,
      );
    }
  }

  @override
  JsonMap toJson() {
    return <String, Object>{
      _usernameKey: username,
      _passwordKey: password,
      _serverUrlKey: serverUrl,
      _serverPortKey: serverPort,
      _serverFolderNameKey: serverFolderName,
    };
  }

  String _getZipFileName() => 'data.zip';
}
