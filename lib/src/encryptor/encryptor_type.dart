/// Infrastructure encryptor type.
enum EncryptorType {
  ///
  base64,

  ///
  aes,
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
