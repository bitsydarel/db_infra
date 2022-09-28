import 'dart:io';

import 'package:db_infra/db_infra.dart';
import 'package:db_infra/src/build_distributor/build_distributor.dart';
import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/shell_runner.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;

///
class FileToAppStoreConnectBuildDistributor extends BuildDistributor {
  ///
  const FileToAppStoreConnectBuildDistributor({
    required this.logger,
    required this.projectDirectory,
    required InfraBuildConfiguration configuration,
    required BuildDistributorType buildDistributorType,
    this.runner = const ShellRunner(),
  }) : super(buildDistributorType, configuration);

  ///
  final Logger logger;

  ///
  final ShellRunner runner;

  ///
  final Directory projectDirectory;

  @override
  Future<void> distribute(File output) async {
    if (!output.existsSync()) {
      throw UnrecoverableException(
        'Cannot distribute file $output because it does not exist.',
        ExitCode.software.code,
      );
    }

    final String oldPath = path.canonicalize(Directory.current.path);
    final String projectDir = path.canonicalize(projectDirectory.path);

    Directory.current = projectDir;

    final Directory privateKeysDir = Directory(
      path.join(projectDirectory.path, 'private_keys'),
    );

    // So we don't delete user's existing directory.
    final bool existedBefore = privateKeysDir.existsSync();

    final File privateKey = File(
      path.join(
        privateKeysDir.path,
        'AuthKey_${configuration.iosAppStoreConnectKeyId}.p8',
      ),
    )..createSync(recursive: true)
      ..writeAsBytesSync(configuration.iosAppStoreConnectKey.readAsBytesSync());

    final ShellOutput commandOutput = runner.execute(
      'xcrun',
      <String>[
        'altool',
        '--upload-app',
        '--type',
        'ios',
        '-f',
        output.path,
        '--apiKey',
        configuration.iosAppStoreConnectKeyId,
        '--apiIssuer',
        configuration.iosAppStoreConnectKeyIssuer,
      ],
      <String, String>{'CI': 'true'},
    );

    if (existedBefore) {
      privateKey.deleteSync();
    } else {
      privateKeysDir.deleteSync(recursive: true);
    }

    Directory.current = oldPath;

    if (commandOutput.stderr.isNotEmpty) {
      logger
        ..logInfo(commandOutput.stdout)
        ..logError(commandOutput.stderr);

      throw UnrecoverableException(
        commandOutput.stderr,
        ExitCode.tempFail.code,
      );
    }
  }
}
