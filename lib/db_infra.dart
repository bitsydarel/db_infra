library db_infra;

import 'dart:convert';
import 'dart:io';

import 'package:db_infra/src/apis/apple/bundle_id_manager.dart';
import 'package:db_infra/src/apis/apple/certificates_manager.dart';
import 'package:db_infra/src/apis/apple/profiles_manager.dart';
import 'package:db_infra/src/build_distributor.dart';
import 'package:db_infra/src/build_executors/flutter_ios_build_executor.dart';
import 'package:db_infra/src/configurations/infra_build_configuration.dart';
import 'package:db_infra/src/configurations/infra_setup_configuration.dart';
import 'package:db_infra/src/setup_executors/ios_setup_executor.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:db_infra/src/utils/file_utils.dart';
import 'package:db_infra/src/utils/infra_extensions.dart';
import 'package:io/io.dart';
import 'package:meta/meta.dart';

export 'package:db_infra/src/configurations/infra_build_configuration.dart';
export 'package:db_infra/src/configurations/infra_setup_configuration.dart';
export 'package:db_infra/src/utils/constants.dart';
export 'package:db_infra/src/utils/exceptions.dart';
export 'package:db_infra/src/utils/script/script_extension.dart';
export 'package:db_infra/src/utils/script/script_utils.dart';

/// DB Infrastructure configuration file name.
const String configFileName = 'infra_config.json';

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

    final IosSetupExecutor iosSetupExecutor = IosSetupExecutor(
      configuration: configuration,
      infraDirectory: infraDirectory,
      profilesManager: profilesManager,
      certificatesManager: certificatesManager,
      bundleIdManager: bundleIdManager,
    );

    final InfraBuildConfiguration infraConfiguration =
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
      '${projectDirectory.path}/$configFileName',
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
  Future<void> build({
    required InfraBuildConfiguration configuration,
    required BuildDistributor buildDistributor,
    bool sign = true,
  }) async {
    final ProfilesManager profilesManager = configuration.getProfilesManager();

    final CertificatesManager certificatesManager =
        configuration.getCertificatesManager();

    await decryptInfraFiles(configuration);

    final File iosFlutterOutput = await FlutterIosBuildExecutor(
      projectDirectory: projectDirectory,
      configuration: configuration,
      profilesManager: profilesManager,
      certificatesManager: certificatesManager,
    ).build();

    stdout.writeln('iOS Output: ${iosFlutterOutput.path}');

    buildDistributor.distribute(iosFlutterOutput);
  }

  /// Decrypt infrastructure files.
  @visibleForTesting
  Future<void> decryptInfraFiles(InfraBuildConfiguration configuration) async {
    final List<File> storedFiles = await configuration.storage.loadFiles();

    final List<File> decryptedFiles =
        await configuration.encryptor.decryptFiles(storedFiles);

    for (final File decryptedFile in decryptedFiles) {
      copyFile(infraDirectory, decryptedFile);
    }
  }

  /// Save the infrastructure configuration.
  @visibleForTesting
  Future<void> saveConfiguration(
    InfraBuildConfiguration configuration,
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
      '${projectDirectory.path}/$configFileName',
    );

    if (!configurationFile.existsSync()) {
      throw UnrecoverableException(
        '$configFileName not found in project',
        ExitCode.config.code,
      );
    }

    return configurationFile;
  }
}
