import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:db_infra/src/encryptor/encryptor.dart';
import 'package:db_infra/src/utils/utils.dart';
import 'package:path/path.dart' as path;

const String _base64FileExtension = '.encrypted64';

/// Infrastructure Base64 encryptor.
class Base64Encryptor extends Encryptor {
  ///
  final Directory infraDirectory;

  ///
  const Base64Encryptor(this.infraDirectory);

  @override
  Future<List<File>> encryptFiles(List<File> files) async {
    final List<File> encryptedFiles = <File>[];

    for (final File file in files) {
      assert(file.existsSync(), '${file.path} does not exist');

      final Uint8List fileContent = file.readAsBytesSync();

      final String newFilePath = path.join(
        infraDirectory.path,
        path.basename(file.path),
      );

      final File encryptedFile = File(
        '$newFilePath$_base64FileExtension',
      )..writeAsStringSync(
          base64.normalize(base64Encode(fileContent)),
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

    for (final File file in files) {
      final String filename = path.basename(file.path);

      assert(file.existsSync(), '${file.path} does not exist');

      assert(
        filename.endsWith(_base64FileExtension),
        '${file.path} does end with $_base64FileExtension, '
        "so can't guarantee it was encrypted by db_infra tool",
      );

      final String encryptedFileContent = file.readAsStringSync();

      final File decryptedFile = File(
        filename.substring(0, filename.lastIndexOf(_base64FileExtension)),
      )..writeAsBytesSync(base64Decode(encryptedFileContent), flush: true);

      decryptedFiles.add(decryptedFile);
    }

    return decryptedFiles;
  }

  @override
  Future<String> encrypt(String text) async {
    return base64.normalize(base64Encode(utf8.encode(text)));
  }

  @override
  Future<String> decrypt(String encryptedText) async {
    return utf8.decode(base64Decode(encryptedText));
  }

  @override
  JsonMap toJson() => <String, Object?>{};
}
