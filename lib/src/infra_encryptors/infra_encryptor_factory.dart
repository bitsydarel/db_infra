import 'dart:io';

import 'package:db_infra/src/infra_encryptor.dart';
import 'package:db_infra/src/infra_encryptor_type.dart';
import 'package:db_infra/src/infra_encryptors/infra_base64_encryptor.dart';
import 'package:db_infra/src/infra_logger.dart';
import 'package:db_infra/src/utils/types.dart';

/// Infrastructure encryptor type extension.
extension InfraStorageTypeExtension on InfraEncryptorType {
  ///
  InfraEncryptor fromJson(
    final JsonMap json,
    final InfraLogger logger,
    final Directory infraDirectory,
  ) {
    switch (this) {
      case InfraEncryptorType.base64:
        return InfraBase64Encryptor(infraDirectory);
      default:
        throw UnsupportedError('infra encryptor $name is not supported');
    }
  }

  ///
  InfraEncryptor from({
    required final InfraLogger infraLogger,
    required final Directory infraDirectory,
  }) {
    switch (this) {
      case InfraEncryptorType.base64:
        return InfraBase64Encryptor(infraDirectory);
      default:
        throw UnsupportedError('infra encryptor $name is not supported');
    }
  }
}
