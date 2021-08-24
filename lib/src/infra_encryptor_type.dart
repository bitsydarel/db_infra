import 'package:db_infra/src/utils/types.dart';

/// Infrastructure encryptor type.
enum InfraEncryptorType {
  ///
  base64,
}

///
extension StringInfraEncryptorTypeExtension on String {
  ///
  InfraEncryptorType asEncryptorType() {
    return InfraEncryptorType.values.firstWhere(
      (InfraEncryptorType type) => enumName(type) == this,
    );
  }
}

///
extension InfraEncryptorTypeExtension on InfraEncryptorType {
  ///
  String get name => enumName(this);
}
