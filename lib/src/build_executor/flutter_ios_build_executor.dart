import 'dart:io';

import 'package:db_infra/src/apple/bundle_id/bundle_id_manager.dart';
import 'package:db_infra/src/apple/certificates/certificate.dart';
import 'package:db_infra/src/apple/certificates/certificates_manager.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile_manager.dart';
import 'package:db_infra/src/apple/xcode_project/xcode_project.dart';
import 'package:db_infra/src/build_executor/build_executor.dart';
import 'package:db_infra/src/build_output_type.dart';
import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/environment_variable_handler/environment_variable_handler.dart';
import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/shell_runner.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;

///
class FlutterIosBuildExecutor extends BuildExecutor {
  ///
  final CertificatesManager certificatesManager;

  ///
  final ProvisionProfileManager provisionProfilesManager;

  ///
  final BundleIdManager bundleIdManager;

  ///
  final EnvironmentVariableHandler? environmentVariableHandler;

  ///
  final Logger logger;

  ///
  final ShellRunner runner;

  ///
  const FlutterIosBuildExecutor({
    required this.provisionProfilesManager,
    required this.certificatesManager,
    required this.bundleIdManager,
    required this.logger,
    required Directory projectDirectory,
    required InfraBuildConfiguration configuration,
    this.runner = const ShellRunner(),
    this.environmentVariableHandler,
  }) : super(projectDirectory: projectDirectory, configuration: configuration);

  @override
  Future<File> build() async {
    final String? developerTeamId = configuration.iosDeveloperTeamId;

    Certificate? certificate;
    ProvisionProfile? provisionProfile;

    if (developerTeamId == null) {
      final File? certificatePrivateKey =
          configuration.iosCertificateSigningRequestPrivateKey;

      if (certificatePrivateKey == null ||
          !certificatePrivateKey.existsSync()) {
        throw UnrecoverableException(
          'iosCertificateSigningRequestPrivateKey is not set, '
          'did you properly run the setup ?',
          ExitCode.config.code,
        );
      }

      certificatesManager.importCertificateFileLocally(certificatePrivateKey);

      final String? certificateId = configuration.iosCertificateId;

      if (certificateId == null) {
        throw UnrecoverableException(
          'iosCertificateId is not set, did you properly run the setup ?',
          ExitCode.config.code,
        );
      }

      certificate = await certificatesManager.getCertificate(certificateId);

      if (certificate != null && !certificate.hasExpired()) {
        certificatesManager.importCertificateLocally(certificate);
      } else {
        throw UnrecoverableException(
          'Certificate with id $certificateId '
          'not found or has expired.\nRe-Run the setup command.',
          ExitCode.tempFail.code,
        );
      }

      final String? iosProvisionProfileName =
          configuration.iosProvisionProfileName;

      if (iosProvisionProfileName == null) {
        throw UnrecoverableException(
          'iosCertificateId is not set, did you properly run the setup ?',
          ExitCode.config.code,
        );
      }

      provisionProfile = await provisionProfilesManager.getProfileWithName(
        iosProvisionProfileName,
      );

      if (provisionProfile != null) {
        provisionProfilesManager
            .importProvisionProfileLocally(provisionProfile);
      } else {
        throw UnrecoverableException(
          'Provision Profile with uuid '
          '${configuration.iosProvisionProfileName} not found.\n'
          'Re-Run the setup command.',
          ExitCode.tempFail.code,
        );
      }
    }

    if (!configuration.iosExportOptionsPlist.existsSync()) {
      throw UnrecoverableException(
        'File ${configuration.iosExportOptionsPlist.path} does not exist',
        ExitCode.tempFail.code,
      );
    }

    final Directory iosFlutterDir = Directory(
      path.join(projectDirectory.path, 'ios/Flutter'),
    );

    final Map<String, Object>? environmentVariables =
        await environmentVariableHandler?.call();

    final File codeSigningConfig = createCodeSigningXCConfig(
      parentDirectory: iosFlutterDir,
      signingType: configuration.iosSigningType,
      logger: logger,
      developerTeamId: developerTeamId,
      provisionProfile: provisionProfile,
      certificate: certificate,
      envs: environmentVariables,
    );

    final File releaseConfig = File(
      path.join(iosFlutterDir.path, 'Release.xcconfig'),
    );

    updateIosProjectSigningConfiguration(codeSigningConfig, releaseConfig);

    final List<String>? dartDefines =
        await environmentVariableHandler?.asDartDefines();

    final String oldPath = path.canonicalize(Directory.current.path);
    final String projectDir = path.canonicalize(projectDirectory.path);

    Directory.current = projectDir;

    final ShellOutput output = runner.execute(
      'flutter',
      <String>[
        'build',
        configuration.iosBuildOutputType.name,
        '--release',
        '--export-options-plist',
        configuration.iosExportOptionsPlist.path,
        if (dartDefines != null) ...dartDefines,
      ],
      <String, String>{'CI': 'true'},
    );

    Directory.current = oldPath;

    cleanupProjectSigningConfiguration(codeSigningConfig, releaseConfig);

    if (output.stderr.isNotEmpty) {
      logger
        ..logInfo(output.stdout)
        ..logError(output.stderr);
      throw UnrecoverableException(output.stderr, ExitCode.tempFail.code);
    }

    final File? outputFile =
        configuration.iosBuildOutputType.outputFile(projectDirectory);

    if (outputFile == null) {
      throw UnrecoverableException(
        'Could not find build ios ${configuration.iosBuildOutputType.name}',
        ExitCode.software.code,
      );
    }

    if (provisionProfile != null) {
      provisionProfilesManager.deleteProvisionProfileLocally(provisionProfile);
    }
    certificatesManager.cleanupLocally();

    return outputFile;
  }
}
