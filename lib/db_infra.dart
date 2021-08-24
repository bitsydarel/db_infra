library db_infra;

import 'dart:convert';
import 'dart:io';

import 'package:db_infra/src/apis/apple/bundle_id_manager.dart';
import 'package:db_infra/src/apis/apple/certificates_manager.dart';
import 'package:db_infra/src/apis/apple/profiles_manager.dart';
import 'package:db_infra/src/infra_configurations/infra_configuration.dart';
import 'package:db_infra/src/infra_configurations/infra_setup_configuration.dart';
import 'package:db_infra/src/infra_encryptor.dart';
import 'package:db_infra/src/infra_encryptor_type.dart';
import 'package:db_infra/src/infra_logger.dart';
import 'package:db_infra/src/infra_setup_executors/infra_ios_setup_executor.dart';
import 'package:db_infra/src/infra_software_builders/infra_flutter_ios_build_executor.dart';
import 'package:db_infra/src/infra_storage_type.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:db_infra/src/utils/file_utils.dart';
import 'package:db_infra/src/utils/infra_extensions.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:io/io.dart';
import 'package:meta/meta.dart';

export 'package:db_infra/src/utils/script/script_extension.dart';
export 'package:db_infra/src/utils/script/script_utils.dart';
export 'package:db_infra/src/utils/constants.dart';
export 'package:db_infra/src/infra_configurations/infra_setup_configuration.dart';

const String _configFileName = 'infra_config.json';

/// DB Infrastructure.
class DBInfra {
  /// Directory of the project the infrastructure is run on.
  final Directory projectDirectory;

  /// Directory of the project infrastructure tools.
  final Directory infraDirectory;

  /// Create a DB Infrastructure.
  const DBInfra({required this.projectDirectory, required this.infraDirectory});

  /// Setup the infrastructure.
  Future<void> setup(InfraSetupConfiguration configuration) async {
    final ProfilesManager profilesManager = configuration.getProfilesManager();

    final CertificatesManager certificatesManager =
        configuration.getCertificatesManager();

    final BundleIdManager bundleIdManager = configuration.getBundleManager();

    final InfraIosSetupExecutor iosSetupExecutor = InfraIosSetupExecutor(
      configuration: configuration,
      infraDirectory: infraDirectory,
      profilesManager: profilesManager,
      certificatesManager: certificatesManager,
      bundleIdManager: bundleIdManager,
    );

    final InfraConfiguration infraConfiguration =
        await iosSetupExecutor.setupInfra();

    final List<File> filesToEncrypt = <File>[
      infraConfiguration.iosCertificateSigningRequest,
      infraConfiguration.iosCertificateSigningRequestPrivateKey,
      infraConfiguration.iosExportOptionsPlist,
      infraConfiguration.iosAppStoreConnectKey,
    ];

    final List<File> encryptedFiles =
        await configuration.encryptor.encryptFiles(filesToEncrypt);

    await infraConfiguration.storage.saveFiles(encryptedFiles);

    final File configurationFile = File(
      '${projectDirectory.path}/$_configFileName',
    );

    configuration.storage.logger.logInfo(
      'Creating infrastructure configuration file',
    );

    await saveConfiguration(infraConfiguration, configurationFile);

    configuration.storage.logger.logSuccess(
      'Infrastructure configuration file created.',
    );
  }

  /// Build flutter android app.
  Future<void> build({bool sign = true}) async {
    final File configurationFile = File(
      '${projectDirectory.path}/$_configFileName',
    );

    final InfraConfiguration configuration =
        await loadConfiguration(configurationFile, infraDirectory);

    final ProfilesManager profilesManager = configuration.getProfilesManager();

    final CertificatesManager certificatesManager =
        configuration.getCertificatesManager();

    final List<File> storedFiles = await configuration.storage.loadFiles();

    final List<File> decryptedFiles =
        await configuration.encryptor.decryptFiles(storedFiles);

    for (final File decryptedFile in decryptedFiles) {
      copyFile(infraDirectory, decryptedFile);
    }

    final File iosFlutterOutput = await InfraFlutterIosBuildExecutor(
      projectDirectory: projectDirectory,
      configuration: configuration,
      profilesManager: profilesManager,
      certificatesManager: certificatesManager,
    ).build();

    stdout.writeln('iOS Output: ${iosFlutterOutput.path}');
  }

  /// Load the infrastructure configuration.
  @visibleForTesting
  Future<InfraConfiguration> loadConfiguration(
    final File configuration,
    final Directory infraDirectory, {
    final bool enableLogging = false,
  }) async {
    final String fileContent = configuration.readAsStringSync();

    final Object? rawJson = jsonDecode(fileContent);

    if (rawJson is JsonMap) {
      final InfraEncryptorType infraEncryptorType = rawJson.getEncryptorType();

      final InfraLogger logger = InfraLogger(enableLogging: enableLogging);

      final InfraEncryptor infraEncryptor =
          rawJson.getEncryptor(infraEncryptorType, logger, infraDirectory);

      final InfraStorageType infraStorageType = rawJson.getStorageType();

      if (rawJson is JsonMap) {
        return InfraConfiguration.fromJson(
          json: rawJson,
          infraEncryptorType: infraEncryptorType,
          infraEncryptor: infraEncryptor,
          infraStorageType: infraStorageType,
          logger: const InfraLogger(enableLogging: true),
          infraDir: infraDirectory,
        );
      }
    }

    throw UnrecoverableException(
      "Can't load infra configuration with json\n$fileContent",
      ExitCode.config.code,
    );
  }

  /// Save the infrastructure configuration.
  @visibleForTesting
  Future<void> saveConfiguration(
    InfraConfiguration configuration,
    File configurationFile,
  ) async {
    final Map<String, Object?> configAsJson = await configuration.toJson();

    configurationFile.writeAsStringSync(jsonEncode(configAsJson), flush: true);
  }

  /// Cleanup the infrastructure after the build or setup is done.
  Future<void> cleanup() async {
    infraDirectory.deleteSync(recursive: true);
  }

  /// Get the infrastructure configuration file.
  File getConfigurationFile() {
    final File configurationFile = File(
      '${projectDirectory.path}/$_configFileName',
    );

    if (!configurationFile.existsSync()) {
      throw UnrecoverableException(
        '$_configFileName not found in project',
        ExitCode.config.code,
      );
    }

    return configurationFile;
  }
}
