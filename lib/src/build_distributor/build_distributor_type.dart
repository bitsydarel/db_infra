///
enum BuildDistributorType {
  ///
  directory,
  ///
  appStoreConnect,
}

///
extension StringBuildDistributorTypeExtension on String {
  ///
  BuildDistributorType asBuildDistributorType() {
    return BuildDistributorType.values.firstWhere(
      (BuildDistributorType type) => type.name == this,
    );
  }
}
