import 'package:db_infra/src/utils/types.dart';

///
enum InfraStorageType {
  ///
  disk,

  ///
  ftp,
}

///
extension StringInfraStorageTypeExtension on String {
  ///
  InfraStorageType asStorageType() {
    return InfraStorageType.values.firstWhere(
      (InfraStorageType type) => enumName(type) == this,
    );
  }
}

///
extension InfraStorageTypeExtension on InfraStorageType {
  ///
  String get name => enumName(this);
}
