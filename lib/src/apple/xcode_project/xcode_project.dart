import 'dart:io';

import 'package:bdlogging/bdlogging.dart';
import 'package:db_infra/src/apple/certificates/certificate.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile_type.dart';
import 'package:db_infra/src/build_signing_type.dart';
import 'package:path/path.dart' as path;

///
const String codeSignIdentityKey = 'CODE_SIGN_IDENTITY';

///
const String codeSignStyleKey = 'CODE_SIGN_STYLE';

///
const String provisionProfileKey = 'PROVISIONING_PROFILE';

///
const String provisionStyleKey = 'ProvisioningStyle';

///
const String provisioningProfileSpecifierKey = 'PROVISIONING_PROFILE_SPECIFIER';

///
const String iosDeveloperTeamIdKey = 'DEVELOPMENT_TEAM';

///
Map<String, String> createCodeSigningArguments({
  required IosBuildSigningType signingType,
  required ProvisionProfileType provisionProfileType,
  Certificate? certificate,
  ProvisionProfile? provisionProfile,
  String? developerTeamId,
}) {
  final Map<String, String> args = <String, String>{};

  if (developerTeamId != null) {
    args[iosDeveloperTeamIdKey] = developerTeamId;
  }

  switch (signingType) {
    case IosBuildSigningType.automatic:
      final String codeSigningIdentity =
          provisionProfileType == ProvisionProfileType.iosAppStore
              ? 'Apple Distribution'
              : 'Apple Development';

      args[codeSignIdentityKey] = '"$codeSigningIdentity"';
      args[codeSignStyleKey] = 'Automatic';

      if (provisionProfile == null) {
        args[provisionStyleKey] = 'Automatic';
      } else {
        args[provisionStyleKey] = 'Manual';
        args[provisionProfileKey] = provisionProfile.uuid;
        args[provisioningProfileSpecifierKey] = provisionProfile.name;
      }
      break;
    case IosBuildSigningType.manual:
      if (certificate != null) {
        args[codeSignIdentityKey] = certificate.name;
      }
      args[codeSignStyleKey] = 'Manual';
      args[provisionStyleKey] = 'Manual';

      if (provisionProfile != null) {
        args[provisionProfileKey] = provisionProfile.uuid;
        args[provisioningProfileSpecifierKey] = provisionProfile.name;
      }
      break;
  }

  return args;
}

///
File createCodeSigningXCConfig({
  required Directory parentDirectory,
  required Map<String, String> codeSigningArguments,
  Map<String, Object>? envs,
}) {
  final File xcConfigFile = File(
    path.join(parentDirectory.path, 'Infra.xcconfig'),
  );

  final StringBuffer newConfig = StringBuffer();

  codeSigningArguments.entries.forEach((MapEntry<String, String> entry) {
    newConfig.writeln('${entry.key}=${entry.value}');
  });

  if (envs != null) {
    envs.entries.forEach((MapEntry<String, Object> entry) {
      if (!entry.key.contains('.')) {
        newConfig.writeln('${entry.key}=${entry.value}');
      } else {
        BDLogger().info(
          'Key ${entry.key} cannot be added to ${xcConfigFile.path}',
        );
      }
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

  final String importStatement = '#include "$filename"';

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
