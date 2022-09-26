import 'dart:io';

import 'package:db_infra/src/encryptor/aes_encryptor.dart';
import 'package:db_infra/src/encryptor/encryptor.dart';
import 'package:db_infra/src/utils/utils.dart';
import 'package:io/io.dart';

/// Infrastructure encryptor type extension.
extension StorageTypeExtension on EncryptorType {
  /// Create a [Encryptor] from [json].
  Encryptor fromJson({
    required JsonMap json,
    required Directory infraDirectory,
    String? aesPassword,
  }) {
    switch (this) {
      case EncryptorType.base64:
        return Base64Encryptor(infraDirectory);
      case EncryptorType.aes:
        if (aesPassword == null) {
          throw UnrecoverableException(
            'infra encryptor $name need a password to be provided.',
            ExitCode.config.code,
          );
        }
        return AesEncryptor(aesPassword, infraDirectory);
    }
  }

  /// Create a [Encryptor] from [infraDirectory].¬
  Encryptor from({
    required Directory infraDirectory,
    String? aesPassword,
  }) {
    switch (this) {
      case EncryptorType.base64:
        return Base64Encryptor(infraDirectory);
      case EncryptorType.aes:
        if (aesPassword == null) {
          throw UnrecoverableException(
            'infra encryptor $name need a password to be provided.',
            ExitCode.config.code,
          );
        }
        return AesEncryptor(aesPassword, infraDirectory);
    }
  }
}
