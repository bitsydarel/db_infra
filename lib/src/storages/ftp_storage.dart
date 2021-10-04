import 'dart:io';

import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/storage.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:ftpconnect/ftpconnect.dart';
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
  final Logger logger;

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
              timeout: const Duration(minutes: 5).inSeconds,
            );

  ///
  factory FtpStorage.fromJson(
    JsonMap json,
    Logger logger,
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
    );

    final File localZipFile = File(
      path.join(localDirectory.path, _getZipFileName()),
    )..createSync(recursive: true);

    final List<String> directoryPaths = path.split(serverFolderName);

    for (final String directoryPath in directoryPaths) {
      await _ftpConnection.createFolderIfNotExist(directoryPath);
      await _ftpConnection.changeDirectory(directoryPath);
    }

    await _ftpConnection.downloadFileWithRetry(
      _getZipFileName(),
      localZipFile,
      pRetryCount: 3,
    );

    await _ftpConnection.disconnect();

    await FTPConnect.unZipFile(localZipFile, localDirectory.path);

    localZipFile.deleteSync(recursive: true);

    return localDirectory
        .listSync(recursive: true)
        .map((FileSystemEntity fileSystemEntity) => File(fileSystemEntity.path))
        .toList();
  }

  @override
  Future<void> saveFiles(List<File> files) async {
    await _ftpConnection.connect();

    final File zipFile = File(
      path.join(infraDirectory.path, _getZipFileName()),
    );

    await FTPConnect.zipFiles(
      files.map((File file) => file.path).toList(),
      zipFile.path,
    );

    logger.logInfo(
      'Creating directory $serverFolderName on ftp server if not exist',
    );

    final List<String> directoryPaths = path.split(serverFolderName);

    for (final String directoryPath in directoryPaths) {
      await _ftpConnection.createFolderIfNotExist(directoryPath);
      await _ftpConnection.changeDirectory(directoryPath);
    }

    _ftpConnection.uploadFileWithRetry(zipFile, pRetryCount: 3);

    logger.logSuccess('File uploads completed.');

    zipFile.deleteSync(recursive: true);
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
