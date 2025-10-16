/// This file defines the BuildTargetPlatform enum
/// representing different build target platforms.
enum BuildTargetPlatform {
  /// Android platform.
  android,

  /// iOS platform.
  ios,
}

/// Extension that converts a `String` into a `BuildTargetPlatform`.
extension StringBuildTargetPlatformExtension on String {
  /// Converts this `String` to a
  /// `BuildTargetPlatform` by matching the enum's `name`.
  ///
  /// Returns the matching platform.
  /// Throws a `StateError` if no match is found.
  /// Note: the comparison is case\-sensitive (e.g., `android`, `ios`).
  BuildTargetPlatform asBuildTargetPlatform() {
    return BuildTargetPlatform.values.firstWhere(
      (BuildTargetPlatform type) => type.name == this,
    );
  }
}
