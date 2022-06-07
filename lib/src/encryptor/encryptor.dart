library encryptor;

import 'dart:io';

import 'package:db_infra/src/utils/utils.dart';

export 'base64_encryptor.dart';
export 'encryptor_factory.dart';
export 'encryptor_type.dart';

/// Infrastructure file encryptor.
abstract class Encryptor {
  /// A const constructor to allow child to define their const constructor.
  const Encryptor();

  /// Encrypt [files].
  ///
  /// Returns the new created files that have been encrypted.
  Future<List<File>> encryptFiles(final List<File> files);

  /// Decrypt [files].
  ///
  /// Return the new created files that have been decrypted.
  Future<List<File>> decryptFiles(final List<File> files);

  /// Encrypt the [text].
  ///
  /// returns the encrypted version of the [text].
  Future<String> encrypt(final String text);

  /// Decrypt the [encryptedText].
  ///
  /// returns the decrypted version of the [encryptedText].
  Future<String> decrypt(final String encryptedText);

  /// Convert the encryptor to json.
  JsonMap toJson();
}
