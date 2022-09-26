import 'dart:io';

import 'package:db_infra/src/apple/certificates/certificate.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile.dart';
import 'package:db_infra/src/build_signing_type.dart';
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
const String iosDeveloperTeamIdKey = 'DEVELOPMENT_TEAM';

///
File createCodeSigningXCConfig({
  required Directory parentDirectory,
  required IosBuildSigningType signingType,
  Certificate? certificate,
  ProvisionProfile? provisionProfile,
  String? developerTeamId,
  Map<String, Object>? envs,
}) {
  final File xcConfigFile = File(
    path.join(parentDirectory.path, 'Infra.xcconfig'),
  );

  final StringBuffer newConfig = StringBuffer();

  if (certificate != null) {
    newConfig.writeln('$codeSignIdentityKey=${certificate.name}');
  }
  switch (signingType) {
    case IosBuildSigningType.automatic:
      newConfig.writeln('$codeSignStyleKey=Automatic');
      break;
    case IosBuildSigningType.manuel:
      newConfig.writeln('$codeSignStyleKey=Manual');
      break;
  }

  if (provisionProfile != null) {
    newConfig
      ..writeln('$provisionProfileKey=${provisionProfile.uuid}')
      ..writeln('$provisioningProfileSpecifierKey=${provisionProfile.name}');
  }

  if (developerTeamId != null) {
    newConfig.writeln('$iosDeveloperTeamIdKey=$developerTeamId');
  }

  if (envs != null) {
    envs.entries.forEach((MapEntry<String, Object> entry) {
      newConfig.writeln('${entry.key}=${entry.value}');
    });
  }

  xcConfigFile.writeAsStringSync(newConfig.toString(), flush: true);

  return xcConfigFile;
}

///
void updateIosProjectSigningConfiguration(
  final File codeSigningConfig,
  final File releaseConfig,
) {
  final String filename = path.basename(codeSigningConfig.path);

  final String importStatement = '#include? "$filename"';

  final List<String> releaseConfigLines = releaseConfig.readAsLinesSync();

  releaseConfig.writeAsStringSync(
    <String>[
      ...releaseConfigLines,
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

  codeSigningConfig.deleteSync();
}
