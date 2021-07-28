import 'dart:io';

///
abstract class RunConfiguration {
  ///
  final Directory projectDir;

  /// Android application id.
  final String androidAppId;

  /// iOS application id.
  final String iosAppId;

  ///
  final String iosAppStoreConnectKeyId;

  ///
  final String iosAppStoreConnectKeyIssuer;

  ///
  final File iosAppStoreConnectKey;

  ///
  const RunConfiguration({
    required this.projectDir,
    required this.androidAppId,
    required this.iosAppId,
    required this.iosAppStoreConnectKeyId,
    required this.iosAppStoreConnectKeyIssuer,
    required this.iosAppStoreConnectKey,
  });
}
