import 'dart:io';
import 'dart:typed_data';

import 'package:db_infra/src/encryptor/encryptor.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:encrypt/encrypt.dart' as lib_encrypt;
import 'package:path/path.dart' as path;

const String _encryptedFileExtension = '.encrypted';

///
class AesEncryptor extends Encryptor {
  ///
  const AesEncryptor(this.password, this.infraDirectory);

  ///
  final String password;

  ///
  final Directory infraDirectory;

  @override
  Future<String> encrypt(String text) async {
    final lib_encrypt.Key key = lib_encrypt.Key.fromUtf8(password);

    final lib_encrypt.IV iv = lib_encrypt.IV.fromUtf8(password);

    final lib_encrypt.Encrypter encrypter =
        lib_encrypt.Encrypter(lib_encrypt.AES(key));

    return encrypter.encrypt(text, iv: iv).base64;
  }

  @override
  Future<String> decrypt(String encryptedText) async {
    final lib_encrypt.Key key = lib_encrypt.Key.fromUtf8(password);

    final lib_encrypt.IV iv = lib_encrypt.IV.fromUtf8(password);

    final lib_encrypt.Encrypter encrypter =
        lib_encrypt.Encrypter(lib_encrypt.AES(key));

    return encrypter.decrypt64(encryptedText, iv: iv);
  }

  @override
  Future<List<File>> encryptFiles(List<File> files) async {
    final List<File> encryptedFiles = <File>[];

    final lib_encrypt.Key key = lib_encrypt.Key.fromUtf8(password);

    final lib_encrypt.IV iv = lib_encrypt.IV.fromUtf8(password);

    final lib_encrypt.Encrypter encrypter =
        lib_encrypt.Encrypter(lib_encrypt.AES(key));

    for (final File file in files) {
      assert(file.existsSync(), '${file.path} does not exist');

      final Uint8List fileContent = file.readAsBytesSync();

      final String newFilePath = path.join(
        infraDirectory.path,
        path.basename(file.path),
      );

      final File encryptedFile = File(
        '$newFilePath$_encryptedFileExtension',
      )..writeAsStringSync(
          encrypter.encryptBytes(fileContent, iv: iv).base64,
          flush: true,
          mode: FileMode.writeOnly,
        );

      encryptedFiles.add(encryptedFile);
    }

    return encryptedFiles;
  }

  @override
  Future<List<File>> decryptFiles(List<File> files) async {
    final List<File> decryptedFiles = <File>[];

    final lib_encrypt.Key key = lib_encrypt.Key.fromUtf8(password);

    final lib_encrypt.IV iv = lib_encrypt.IV.fromUtf8(password);

    final lib_encrypt.Encrypter encrypter =
        lib_encrypt.Encrypter(lib_encrypt.AES(key));

    for (final File file in files) {
      final String filename = path.basename(file.path);

      assert(file.existsSync(), '${file.path} does not exist');

      assert(
        filename.endsWith(_encryptedFileExtension),
        '${file.path} does end with $_encryptedFileExtension, '
        "so can't guarantee it was encrypted by db_infra tool",
      );

      final String encryptedFileContent = file.readAsStringSync();

      final File decryptedFile = File(
        filename.substring(0, filename.lastIndexOf(_encryptedFileExtension)),
      )..writeAsBytesSync(
          encrypter.decryptBytes(
            lib_encrypt.Encrypted.fromBase64(encryptedFileContent),
            iv: iv,
          ),
          flush: true,
          mode: FileMode.writeOnly,
        );

      decryptedFiles.add(decryptedFile);
    }

    return decryptedFiles;
  }

  @override
  JsonMap toJson() => <String, Object?>{};
}
