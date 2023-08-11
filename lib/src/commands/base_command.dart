import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/encryptor/aes_encryptor.dart';
import 'package:db_infra/src/encryptor/encryptor.dart';
import 'package:db_infra/src/storage/storage.dart';
import 'package:db_infra/src/utils/utils.dart';
import 'package:io/io.dart';
import 'package:meta/meta.dart';

/// Contains base functions and methods use by command of db_infra.
@internal
abstract class BaseCommand extends Command<void> {
  /// Load the infrastructure configuration.
  @protected
  Future<InfraBuildConfiguration> loadConfiguration({
    required File configuration,
    required Directory infraDirectory,
    String? aesPassword,
  }) async {
    final String fileContent = configuration.readAsStringSync();

    final Object? rawJson = jsonDecode(fileContent);

    if (rawJson is JsonMap) {
      return InfraBuildConfiguration.fromJson(
        json: rawJson,
        infraDir: infraDirectory,
        aesPassword: aesPassword,
      );
    }

    throw UnrecoverableException(
      "Can't load infra configuration with json\n$fileContent",
      ExitCode.config.code,
    );
  }

  /// Save the build configuration.
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
    Configuration configuration,
    Directory infraDirectory,
  ) async {
    infraDirectory.deleteSync(recursive: true);
  }
}

/// Extensions for the [ArgResults] to simplify work with it.
@internal
extension ArgResultsExtension on ArgResults {
  /// Get the configuration file passed by the arg [infraConfigFileArg].
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

  /// Get the project directory specified by the command.
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
      case EncryptorType.aes:
        final String? aesPassword =
            parseOptionalString(infraAesEncryptorPasswordArg);

        if (aesPassword == null) {
          throw UnrecoverableException(
            'infra encryptor $name need a password to be provided.',
            ExitCode.config.code,
          );
        }

        return AesEncryptor(aesPassword, infraDirectory);
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
    final Directory infraDirectory,
  ) {
    final String? infraDiskStorageLocation =
        parseOptionalString(infraDiskStorageLocationArg);

    final String? ftpUsername = parseOptionalString(infraFtpUsernameArg);
    final String? ftpPassword = parseOptionalString(infraFtpPasswordArg);
    final String? ftpServerUrl = parseOptionalString(infraFtpUrlArg);
    final String? ftpFolderName = parseOptionalString(infraFtpFolderNameArg);
    final String? ftpServerPort = parseOptionalString(infraFtpPortArg);

    final String? gcloudProjectId =
        parseOptionalString(infraGcloudProjectIdArg);
    final String? gcloudProjectBucketName =
        parseOptionalString(infraGcloudProjectBucketNameArg);
    final String? gcloudProjectServiceAccountFile =
        parseOptionalString(infraGcloudProjectServiceAccountFileArg);
    final String? gcloudProjectBucketFolder =
        parseOptionalString(infraGcloudProjectBucketFolderArg);

    return infraStorageType.from(
      infraDirectory: infraDirectory,
      ftpUsername: ftpUsername,
      ftpPassword: ftpPassword,
      ftpServerUrl: ftpServerUrl,
      ftpServerPort: ftpServerPort != null ? int.parse(ftpServerPort) : null,
      ftpServerFolderName: ftpFolderName ?? 'credentials',
      gcloudProjectId: gcloudProjectId,
      gcloudBucketName: gcloudProjectBucketName,
      gcloudBucketFolder: gcloudProjectBucketFolder,
      gcloudServiceAccountFile:
          gcloudProjectServiceAccountFile?.trim().isNotEmpty == true
              ? File(gcloudProjectServiceAccountFile!)
              : null,
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

    throw ArgumentError('$argumentName need to be specified');
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
