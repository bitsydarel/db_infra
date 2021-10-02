import 'package:db_infra/src/utils/types.dart';

///
enum StorageType {
  ///
  disk,

  ///
  ftp,
}

///
extension StringStorageTypeExtension on String {
  ///
  StorageType asStorageType() {
    return StorageType.values.firstWhere(
      (StorageType type) => enumName(type) == this,
    );
  }
}

///
extension StorageTypeExtension on StorageType {
  ///
  String get name => enumName(this);
}
