import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path_util;

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
extension DirectoryExtensions on Directory {
  ///
  File copyFile(final File file) {
    return File(
      path_util.join(path, path_util.basename(file.path)),
    )..writeAsBytesSync(file.readAsBytesSync(), flush: true);
  }

  ///
  Directory createInfraDirectory() {
    return Directory('$path/.infra')..createSync();
  }
}

/// Get the project [Directory] with a full path.
Directory getResolvedDirectory(String localDirectory) {
  return Directory(path_util.canonicalize(localDirectory));
}
