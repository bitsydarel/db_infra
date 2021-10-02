import 'package:db_infra/src/utils/types.dart';

/// Infrastructure encryptor type.
enum EncryptorType {
  ///
  base64,
}

///
extension StringEncryptorTypeExtension on String {
  ///
  EncryptorType asEncryptorType() {
    return EncryptorType.values.firstWhere(
      (EncryptorType type) => type.name == this,
    );
  }
}

///
extension EncryptorTypeExtension on EncryptorType {
  ///
  String get name => enumName(this);
}
