import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:db_infra/src/configurations/infra_build_configuration.dart';
import 'package:db_infra/src/encryptor.dart';
import 'package:db_infra/src/encryptor_type.dart';
import 'package:db_infra/src/encryptors/base64_encryptor.dart';
import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/run_configuration.dart';
import 'package:db_infra/src/storage.dart';
import 'package:db_infra/src/storage_type.dart';
import 'package:db_infra/src/storages/storage_factory.dart';
import 'package:db_infra/src/utils/constants.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:db_infra/src/utils/file_utils.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:io/io.dart';
import 'package:meta/meta.dart';

///
abstract class BaseCommand extends Command<void> {
  /// Load the infrastructure configuration.
  @protected
  Future<InfraBuildConfiguration> loadConfiguration(
    File configuration,
    Directory infraDirectory,
    Logger logger,
  ) async {
    final String fileContent = configuration.readAsStringSync();

    final Object? rawJson = jsonDecode(fileContent);

    if (rawJson is JsonMap) {
      return InfraBuildConfiguration.fromJson(
        json: rawJson,
        logger: logger,
        infraDir: infraDirectory,
      );
    }

    throw UnrecoverableException(
      "Can't load infra configuration with json\n$fileContent",
      ExitCode.config.code,
    );
  }

  ///
  @protected
  Future<void> saveConfiguration(
    InfraBuildConfiguration configuration,
    File configurationFile,
  ) async {
    final Map<String, Object?> configAsJson = await configuration.toJson();

    configurationFile.writeAsStringSync(jsonEncode(configAsJson), flush: true);
  }

  /// Decrypt infrastructure files.
  @protected
  Future<void> decryptInfraFiles(
    Directory infraDirectory,
    InfraBuildConfiguration configuration,
  ) async {
    final List<File> storedFiles = await configuration.storage.loadFiles();

    final List<File> decryptedFiles =
        await configuration.encryptor.decryptFiles(storedFiles);

    for (final File decryptedFile in decryptedFiles) {
      infraDirectory.copyFile(decryptedFile);
    }
  }

  /// Cleanup the infrastructure after the build or setup is done.
  @protected
  Future<void> cleanup(
    RunConfiguration configuration,
    Directory infraDirectory,
  ) async {
    infraDirectory.deleteSync(recursive: true);
  }
}

///
extension ArgResultsExtension on ArgResults {
  ///
  File getConfigurationFile({bool checkIfExist = false}) {
    final String configFilePath = parseString(infraConfigFileArg);

    final File configurationFile = File(configFilePath);

    if (checkIfExist && !configurationFile.existsSync()) {
      throw UnrecoverableException(
        'Specified infrastructure configuration file does not exist:\n'
        '$configurationFile\n',
        ExitCode.config.code,
      );
    }

    return configurationFile;
  }

  ///
  Directory getProjectDirectory() {
    final Directory projectDir = getResolvedDirectory(rest.last);

    if (!projectDir.existsSync()) {
      throw const FormatException('specified project dir does not exist');
    }

    return projectDir;
  }

  ///
  bool isVerbosityEnabled() {
    final Object? enabled = this[infraVerboseLoggingArg];

    return enabled is bool ? enabled : false;
  }

  ///
  EncryptorType getInfraEncryptorType() {
    final String infraEncryptorType = parseString(infraEncryptorTypeArg);

    return infraEncryptorType.asEncryptorType();
  }

  ///
  Encryptor getInfraEncryptor(
    final EncryptorType infraEncryptorType,
    final Directory infraDirectory,
  ) {
    switch (infraEncryptorType) {
      case EncryptorType.base64:
        return Base64Encryptor(infraDirectory);
      default:
        throw UnsupportedError('${infraEncryptorType.name} is unsupported');
    }
  }

  ///
  StorageType getInfraStorageType() {
    final String infraStorageType = parseString(infraStorageTypeArg);

    return infraStorageType.asStorageType();
  }

  ///
  Storage getInfraStorage(
    final StorageType infraStorageType,
    final Encryptor infraEncryptor,
    final Logger logger,
    final Directory infraDirectory,
  ) {
    final String? infraDiskStorageLocation =
        parseOptionalString(infraDiskStorageLocationArg);

    final String? ftpUsername = parseOptionalString(infraFtpUsernameArg);
    final String? ftpPassword = parseOptionalString(infraFtpPasswordArg);
    final String? ftpServerUrl = parseOptionalString(infraFtpUrlArg);
    final String? ftpFolderName = parseOptionalString(infraFtpFolderNameArg);
    final String? ftpServerPort = parseOptionalString(infraFtpPortArg);

    return infraStorageType.from(
      infraLogger: logger,
      infraDirectory: infraDirectory,
      ftpUsername: ftpUsername,
      ftpPassword: ftpPassword,
      ftpServerUrl: ftpServerUrl,
      ftpServerPort: ftpServerPort != null ? int.parse(ftpServerPort) : null,
      ftpServerFolderName: ftpFolderName ?? 'credentials',
      storageDirectory: infraDiskStorageLocation?.trim().isNotEmpty == true
          ? Directory(infraDiskStorageLocation!)
          : null,
    );
  }

  ///
  String parseString(final String argumentName) {
    final Object? argumentValue = this[argumentName];

    if (argumentValue is String && argumentValue.trim().isNotEmpty) {
      return argumentValue;
    }

    throw FormatException('$argumentName need to be specified');
  }

  ///
  String? parseOptionalString(final String argumentName) {
    final Object? argumentValue = this[argumentName];

    if (argumentValue is String && argumentValue.trim().isNotEmpty) {
      return argumentValue;
    }
    return null;
  }
}
