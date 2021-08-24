import 'dart:io';

import 'package:db_infra/src/infra_logger.dart';
import 'package:db_infra/src/infra_storage.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;

const String _usernameKey = 'ftpUsername';
const String _passwordKey = 'ftpPassword';
const String _serverUrlKey = 'ftpServerUrl';
const String _serverPortKey = 'ftpServerPort';
const String _serverFolderNameKey = 'ftpFolderName';

///
class InfraFtpStorage extends InfraStorage {
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

  ///
  InfraFtpStorage({
    required this.username,
    required this.password,
    required this.serverUrl,
    required this.serverPort,
    required this.serverFolderName,
    required InfraLogger logger,
    required Directory infraDirectory,
  }) : super(logger, infraDirectory);

  ///
  factory InfraFtpStorage.fromJson(
    JsonMap json,
    InfraLogger logger,
    Directory infraDirectory,
  ) {
    final Object? username = json[_usernameKey];
    final Object? password = json[_passwordKey];
    final Object? serverUrl = json[_serverUrlKey];
    final Object? serverPort = json[_serverPortKey];
    final Object? serverFolderName = json[_serverFolderNameKey];

    return InfraFtpStorage(
      username: username is String ? username : throw ArgumentError(username),
      password: password is String ? password : throw ArgumentError(password),
      serverUrl:
          serverUrl is String ? serverUrl : throw ArgumentError(serverUrl),
      serverFolderName: serverFolderName is String
          ? serverFolderName
          : throw ArgumentError(serverFolderName),
      serverPort: serverPort is int
          ? int.parse(serverPort.toString())
          : throw ArgumentError(serverPort.toString()),
      logger: logger,
      infraDirectory: infraDirectory,
    );
  }

  @override
  Future<List<File>> loadFiles() async {
    final FTPConnect ftpConnect = FTPConnect(
      serverUrl,
      user: username,
      pass: password,
      port: serverPort,
      timeout: const Duration(minutes: 5).inSeconds,
    );

    await ftpConnect.connect();

    final Directory localDirectory = Directory(
      path.join(infraDirectory.path, serverFolderName),
    );

    final File localZipFile = File(
      path.join(localDirectory.path, _getZipFileName()),
    );

    await ftpConnect.downloadFileWithRetry(
      _getZipFileName(),
      localZipFile,
      pRetryCount: 3,
    );

    await ftpConnect.disconnect();

    await FTPConnect.unZipFile(localZipFile, localDirectory.path);

    localZipFile.deleteSync(recursive: true);

    return localDirectory
        .listSync(recursive: true)
        .map((FileSystemEntity fileSystemEntity) => File(fileSystemEntity.path))
        .toList();
  }

  @override
  Future<void> saveFiles(List<File> files) async {
    final FTPConnect ftpConnect = FTPConnect(
      serverUrl,
      user: username,
      pass: password,
      debug: logger.enableLogging,
    );

    await ftpConnect.connect();

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

    // this also move to the specified directory.
    await ftpConnect.createFolderIfNotExist(serverFolderName);

    int retryCount = 0;

    while (retryCount <= 3) {
      try {
        await ftpConnect.uploadFile(zipFile);
        break;
      } on SocketException catch (se) {
        logger
          ..logError(se.message)
          ..logError('Failed to upload ${zipFile.path}')
          ..logError('Retry count $retryCount');
        retryCount++;

        if (retryCount == 3) {
          throw UnrecoverableException(
            se.osError.toString(),
            ExitCode.tempFail.code,
          );
        }
      }
    }

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

  String _getZipFileName() => '$serverFolderName.zip';
}
