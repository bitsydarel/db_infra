import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Create a certificate file with ext 'cert' from the [contentAsBase64].
///
/// The file is named with specified [filename].
File createCertificateFileFromBase64({
  required final String contentAsBase64,
  required final String filename,
}) {
  return File('${Directory.systemTemp.path}/$filename.cer')
    ..writeAsBytesSync(base64.decode(contentAsBase64), flush: true);
}

///
void copyFile(final Directory directory, final File file) {
  File(
    path.join(directory.path, path.basename(file.path)),
  ).writeAsBytesSync(file.readAsBytesSync(), flush: true);
}
