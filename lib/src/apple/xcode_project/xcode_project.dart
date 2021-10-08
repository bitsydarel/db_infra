import 'dart:io';

import 'package:db_infra/src/apple/certificates/certificate.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile.dart';
import 'package:path/path.dart' as path;

///
const String codeSignIdentityKey = 'CODE_SIGN_IDENTITY';

///
const String codeSignStyleKey = 'CODE_SIGN_STYLE';

///
const String provisionProfileKey = 'PROVISIONING_PROFILE';

///
const String provisioningProfileSpecifierKey = 'PROVISIONING_PROFILE_SPECIFIER';

///
File createCodeSigningXCConfig(
  Directory parentDirectory,
  ProvisionProfile provisionProfile,
  Certificate certificate,
) {
  final File xcConfigFile = File(
    path.join(parentDirectory.path, 'Infra.xcconfig'),
  );

  final List<String> newConfig = <String>[
    '$codeSignIdentityKey=${certificate.name}',
    '$codeSignStyleKey=Manual',
    '$provisionProfileKey=${provisionProfile.uuid}',
    '$provisioningProfileSpecifierKey=${provisionProfile.name}',
  ];

  xcConfigFile.writeAsStringSync(newConfig.join('\n'), flush: true);

  return xcConfigFile;
}

///
void updateProjectSigningConfiguration(
  final File codeSigningConfig,
  final File releaseConfig,
) {
  final String filename = path.basename(codeSigningConfig.path);

  final String importStatement = '#include? "$filename"';

  final List<String> releaseConfigLines = releaseConfig.readAsLinesSync();

  releaseConfig.writeAsStringSync(
    <String>[
      ...releaseConfig.readAsLinesSync(),
      if (!releaseConfigLines.contains(importStatement)) importStatement,
    ].join('\n'),
    mode: FileMode.writeOnly,
    flush: true,
  );
}

///
void cleanupProjectSigningConfiguration(
  final File codeSigningConfig,
  final File releaseConfig,
) {
  final String filename = path.basename(codeSigningConfig.path);

  final List<String> lines = releaseConfig.readAsLinesSync().where(
    (String line) {
      return !line.contains(filename);
    },
  ).toList();

  releaseConfig.writeAsStringSync(lines.join('\n'), flush: true);
}
