///
const String baseConfigurationReferenceKey = 'baseConfigurationReference';

///
const String buildSettingsStartKey = 'buildSettings = {';

///
const String buildSettingsEndKey = '};';

///
const String codeSignIdentityKey = 'CODE_SIGN_IDENTITY';

///
const String codeSignStyleKey = 'CODE_SIGN_STYLE';

///
const String provisionProfileKey = 'PROVISIONING_PROFILE';

///
const String provisioningProfileSpecifierKey = 'PROVISIONING_PROFILE_SPECIFIER';

///
Map<String, int> getCodeSigningSettings(
  int settingsStartIndex,
  List<String> lines,
) {
  final Map<String, int> configs = <String, int>{
    buildSettingsStartKey: settingsStartIndex,
  };

  for (int ln = settingsStartIndex; ln < lines.length; ln++) {
    final String currentLine = lines[ln];

    if (currentLine.contains(codeSignIdentityKey)) {
      configs[codeSignIdentityKey] = ln;
    } else if (currentLine.contains(codeSignStyleKey)) {
      configs[codeSignStyleKey] = ln;
    } else if (currentLine.contains(provisionProfileKey)) {
      configs[provisionProfileKey] = ln;
    } else if (currentLine.contains(provisioningProfileSpecifierKey)) {
      configs[provisioningProfileSpecifierKey] = ln;
    } else if (currentLine.trim().contains(buildSettingsEndKey)) {
      configs[buildSettingsEndKey] = ln;
    }
  }

  return configs;
}
