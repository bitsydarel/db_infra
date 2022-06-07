import 'dart:io';

import 'package:db_infra/src/encryptor/encryptor.dart';
import 'package:db_infra/src/utils/utils.dart';

/// Infrastructure encryptor type extension.
extension StorageTypeExtension on EncryptorType {
  /// Create a [Encryptor] from [json].
  Encryptor fromJson(JsonMap json, Directory infraDirectory) {
    switch (this) {
      case EncryptorType.base64:
        return Base64Encryptor(infraDirectory);
      default:
        throw UnsupportedError('infra encryptor $name is not supported');
    }
  }

  /// Create a [Encryptor] from [infraDirectory].¬
  Encryptor from(Directory infraDirectory) {
    switch (this) {
      case EncryptorType.base64:
        return Base64Encryptor(infraDirectory);
      default:
        throw UnsupportedError('infra encryptor $name is not supported');
    }
  }
}
