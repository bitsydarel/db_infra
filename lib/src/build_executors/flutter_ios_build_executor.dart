import 'dart:io';

import 'package:db_infra/src/apple/bundle_id/bundle_id_manager.dart';
import 'package:db_infra/src/apple/certificates/certificate.dart';
import 'package:db_infra/src/apple/certificates/certificates_manager.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile_manager.dart';
import 'package:db_infra/src/build_executor.dart';
import 'package:db_infra/src/build_output_type.dart';
import 'package:db_infra/src/configurations/infra_build_configuration.dart';
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
  }) : super(projectDirectory: projectDirectory, configuration: configuration);

  @override
  Future<File> build() async {
    certificatesManager.importCertificateFileLocally(
      configuration.iosCertificateSigningRequestPrivateKey,
    );

    final String certificateId = configuration.iosCertificateId;

    final Certificate? certificate =
        await certificatesManager.getCertificate(certificateId);

    if (certificate != null && !certificate.hasExpired()) {
      certificatesManager.importCertificateLocally(certificate);
    } else {
      throw UnrecoverableException(
        'Certificate with id ${configuration.iosCertificateId} '
        'not found or has expired.\nRe-Run the setup command.',
        ExitCode.tempFail.code,
      );
    }

    final ProvisionProfile? profile =
        await provisionProfilesManager.getProfileWithID(
      configuration.iosProvisionProfileId,
    );

    if (profile != null) {
      provisionProfilesManager.importProvisionProfileLocally(profile);
    } else {
      throw UnrecoverableException(
        'Provision Profile with uuid '
        '${configuration.iosProvisionProfileId} not found.\n'
        'Re-Run the setup command.',
        ExitCode.tempFail.code,
      );
    }

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
      ],
    );

    Directory.current = oldPath;

    if (output.stderr.isNotEmpty) {
      logger.logError(output.stderr);
      throw UnrecoverableException(output.stderr, ExitCode.tempFail.code);
    }

    final File? outputFile =
        configuration.iosBuildOutputType.outputFile(projectDirectory);

    if (outputFile == null) {
      throw UnrecoverableException('Could not find ', ExitCode.software.code);
    }

    provisionProfilesManager.deleteProvisionProfileLocally(profile);
    certificatesManager.cleanupLocally();

    return outputFile;
  }
}
