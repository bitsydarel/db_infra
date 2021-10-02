import 'package:db_infra/src/utils/types.dart';

///
enum BuildDistributorType {
  ///
  directory
}

///
extension StringBuildDistributorTypeExtension on String {
  ///
  BuildDistributorType asBuildDistributorType() {
    return BuildDistributorType.values.firstWhere(
      (BuildDistributorType type) => enumName(type) == this,
    );
  }
}

///
extension BuildDistributorTypeExtension on BuildDistributorType {
  ///
  String get name => enumName(this);
}
