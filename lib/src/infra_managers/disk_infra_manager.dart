import 'dart:convert';
import 'dart:io';

import 'package:db_infra/src/infra_configuration.dart';
import 'package:db_infra/src/infra_manager.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:db_infra/src/utils/network_manager.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;

const String _storageDirectoryKey = 'storageDir';
const String _configFileName = 'infra_config.json';

///
class DiskInfraManager extends InfraManager {
  ///
  final Directory? storageDirectory;

  ///
  DiskInfraManager({
    required Directory projectDir,
    this.storageDirectory,
  }) : super(projectDirectory: projectDir);

  @override
  Future<InfraConfiguration> loadConfiguration() async {
    final File configurationFile = File(
      '${projectDirectory.path}/$_configFileName',
    );

    if (!configurationFile.existsSync()) {
      throw UnrecoverableException(
        'infra_config.json not found in project',
        ExitCode.config.code,
      );
    }

    final String fileContent = configurationFile.readAsStringSync();

    final Object? rawJson = jsonDecode(fileContent);

    if (rawJson is JsonMap) {
      final Object? contentDirPath = rawJson[_storageDirectoryKey];

      if (contentDirPath is String) {
        final Directory contentDir = Directory(contentDirPath);

        if (contentDir.existsSync()) {
          return InfraConfiguration.fromJson(
            projectDirectory,
            contentDir,
            rawJson,
          );
        }
      }
    }

    throw UnrecoverableException(
      "Can't load infra configuration with json\n$fileContent",
      ExitCode.config.code,
    );
  }

  @override
  Future<void> saveConfiguration(InfraConfiguration configuration) async {
    final Directory? contentDir = storageDirectory;

    if (contentDir == null) {
      throw UnrecoverableException(
        'Disk Infra Manager require an storage directory',
        ExitCode.config.code,
      );
    }

    contentDir.createSync(recursive: true);

    final Map<String, Object?> configAsMap = configuration.toJson();

    configAsMap[_storageDirectoryKey] = path.canonicalize(contentDir.path);

    final File configurationFile = File(
      '${projectDirectory.path}/$_configFileName',
    )..writeAsString(jsonEncode(configAsMap), flush: true);

    _copyFile(projectDirectory, configurationFile);

    _copyFile(contentDir, configuration.iosAppStoreConnectKey);
    _copyFile(contentDir, configuration.iosExportOptionsPlist);
    _copyFile(contentDir, configuration.iosCertificateSigningRequest);
    _copyFile(
      contentDir,
      configuration.iosCertificateSigningRequestPrivateKey,
    );
  }

  void _copyFile(final Directory directory, final File file) {
    File('${directory.path}/${path.basename(file.path)}')
        .writeAsBytesSync(file.readAsBytesSync(), flush: true);
  }
}
