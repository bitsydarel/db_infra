import 'dart:io';

import 'package:db_infra/src/apple/certificates/certificate.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile.dart';
import 'package:db_infra/src/apple/xcode_project/xcode_build_settings.dart';

final RegExp _indentationMatcher = RegExp(r'(^.\s+)');

///
void updateXcodeProjectSigningConfiguration(
  final File xcodeProject,
  ProvisionProfile provisionProfile,
  Certificate certificate,
) {
  final List<String> lines = xcodeProject.readAsLinesSync();

  final int buildSettingsStart =
      _getFirstLineThatContains('Begin XCBuildConfiguration section', lines);

  final int buildSettingsEnd =
      _getFirstLineThatContains('End XCBuildConfiguration section', lines);

  for (int ln = buildSettingsStart; ln < buildSettingsEnd; ln++) {
    final String previousLine = lines[ln - 1];
    final String currentLine = lines[ln];
    final String nextLine = lines[ln + 1];

    final bool isSettingStart = currentLine.contains(buildSettingsStartKey);

    final bool isExtendedSettingStart =
        previousLine.contains(baseConfigurationReferenceKey);

    if (isSettingStart && isExtendedSettingStart) {
      final String indentation =
          _indentationMatcher.stringMatch(nextLine) ?? '';

      final Map<String, int> configs = getCodeSigningSettings(ln, lines);

      final int startLineNumber = configs[buildSettingsStartKey]!;
      final int endLineNumber = configs[buildSettingsEndKey]!;

      updateConfigs(
        startLineNumber,
        certificate.name,
        provisionProfile.uuid,
        provisionProfile.name,
        indentation,
        lines,
        configs,
      );

      ln = endLineNumber + 1;
    }
  }

  xcodeProject.writeAsStringSync(lines.join('\n'), flush: true);
}

int _getFirstLineThatContains(String match, List<String> lines) {
  return lines.indexWhere((String line) => line.contains(match));
}

///
void updateConfigs(
  int startLineNumber,
  String certificateName,
  String provisionProfileUuid,
  String provisionProfileName,
  String indentation,
  List<String> lines,
  Map<String, int> configs,
) {
  void handle(MapEntry<String, int> entry) {
    final String key = entry.key;
    final int lineNumber = entry.value;
    String value = '';

    switch (key) {
      case codeSignIdentityKey:
        value = '$indentation$codeSignIdentityKey = "$certificateName";';
        break;
      case codeSignStyleKey:
        value = '$indentation$codeSignStyleKey = Manual;';
        break;
      case provisionProfileKey:
        value = '$indentation$provisionProfileKey = $provisionProfileUuid;';
        break;
      case provisioningProfileSpecifierKey:
        value = '$indentation$provisioningProfileSpecifierKey = '
            '"$provisionProfileName";';
        break;
    }

    if (value.isNotEmpty) {
      if (lineNumber > startLineNumber) {
        lines[lineNumber] = value;
      } else {
        lines.insert(lineNumber, value);
      }
    }
  }

  configs.entries.where((MapEntry<String, int> entry) {
    return entry.value > startLineNumber;
  }).forEach(handle);

  configs.entries.where((MapEntry<String, int> entry) {
    return entry.value < startLineNumber;
  }).forEach(handle);
}
