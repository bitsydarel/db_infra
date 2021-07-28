import 'dart:io';

import 'package:db_infra/src/infra_configuration.dart';
import 'package:db_infra/src/shell_runner.dart';
import 'package:db_infra/src/build_executor.dart';
import 'package:db_infra/src/software_builders/apple/certificate.dart';
import 'package:db_infra/src/software_builders/apple/certificates_manager.dart';
import 'package:db_infra/src/software_builders/apple/profile.dart';
import 'package:db_infra/src/software_builders/apple/profiles_manager.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;

///
class FlutterIosBuildExecutor extends BuildExecutor {
  ///
  final CertificatesManager certificatesManager;

  ///
  final ProfilesManager profilesManager;

  ///
  final ShellRunner runner;

  ///
  const FlutterIosBuildExecutor({
    required InfraConfiguration configuration,
    required this.certificatesManager,
    required this.profilesManager,
    this.runner = const ShellRunner(),
  }) : super(configuration: configuration);

  @override
  Future<void> build() async {
    certificatesManager.keychainsManager.importIntoAppKeychain(
      configuration.iosCertificateSigningRequestPrivateKey,
    );

    final String certificateId = configuration.iosDistributionCertificateId;

    final Certificate? certificate =
        await certificatesManager.getCertificateWithId(certificateId);

    if (certificate != null && !certificate.hasExpired()) {
      await certificatesManager.importCertificate(certificate);
    } else {
      throw UnrecoverableException(
        'Certificate with id ${configuration.iosDistributionCertificateId} '
        'not found or has expired.\nRe-Run the setup command.',
        ExitCode.tempFail.code,
      );
    }

    final Profile? profile = await profilesManager.getProfileWithUUID(
      configuration.iosDistributionProvisionProfileUUID,
    );

    if (profile != null) {
      await profilesManager.importProfile(profile);
    } else {
      throw UnrecoverableException(
        'Provision Profile with uuid '
        '${configuration.iosDistributionProvisionProfileUUID} not found.\n'
        'Re-Run the setup command.',
        ExitCode.tempFail.code,
      );
    }

    final String oldPath = path.canonicalize(Directory.current.path);
    final String projectDir = path.canonicalize(configuration.projectDir.path);

    Directory.current = projectDir;

    final ShellOutput output = runner.execute(
      'flutter',
      <String>[
        'build',
        'ipa',
        '--release',
        '--export-options-plist',
        configuration.iosExportOptionsPlist.path,
      ],
    );

    Directory.current = oldPath;

    stdout.writeln(output.stdout);

    if (output.stderr.isNotEmpty) {
      stderr.writeln(output.stderr);
      throw UnrecoverableException(output.stderr, ExitCode.tempFail.code);
    }
  }
}
