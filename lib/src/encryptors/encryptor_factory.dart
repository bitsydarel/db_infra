import 'dart:io';

import 'package:db_infra/src/encryptor.dart';
import 'package:db_infra/src/encryptor_type.dart';
import 'package:db_infra/src/encryptors/base64_encryptor.dart';
import 'package:db_infra/src/utils/types.dart';

/// Infrastructure encryptor type extension.
extension StorageTypeExtension on EncryptorType {
  ///
  Encryptor fromJson(JsonMap json, Directory infraDirectory) {
    switch (this) {
      case EncryptorType.base64:
        return Base64Encryptor(infraDirectory);
      default:
        throw UnsupportedError('infra encryptor $name is not supported');
    }
  }

  ///
  Encryptor from(Directory infraDirectory) {
    switch (this) {
      case EncryptorType.base64:
        return Base64Encryptor(infraDirectory);
      default:
        throw UnsupportedError('infra encryptor $name is not supported');
    }
  }
}
