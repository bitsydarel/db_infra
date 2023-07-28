import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path_util;

/// Provide utility methods such as operating with the `.zip` format.
extension FileExtensions on File {
  /// Unzip the current file and output the result to the given path.
  ///
  /// [File] must be a `.zip` file.
  Future<void> unzip(final String outputPath) async {
    String dst = outputPath;
    if (!dst.endsWith('/')) {
      dst += '/';
    }

    final Archive archive = ZipDecoder().decodeBytes(await readAsBytes());
    for (final ArchiveFile file in archive) {
      final String filename = file.name;
      if (file.isFile) {
        final List<int> data = file.content as List<int>;
        final File f = File(dst + filename);
        await f.create(recursive: true);
        await f.writeAsBytes(data);
      } else {
        final Directory dir = Directory(dst + filename);
        await dir.create(recursive: true);
      }
    }
  }

  /// Archive the input files in the [File] using `.zip` format.
  Future<void> zip(List<File> intputFiles) async {
    final List<String> paths =
        intputFiles.map((File file) => file.path).toList();
    // zipFile.path,
    final ZipFileEncoder encoder = ZipFileEncoder()..create(path);
    for (final String path in paths) {
      final FileSystemEntityType type = FileSystemEntity.typeSync(path);
      if (type == FileSystemEntityType.directory) {
        encoder.addDirectory(Directory(path));
      } else if (type == FileSystemEntityType.file) {
        encoder.addFile(File(path));
      }
    }
    encoder.close();
    throw UnimplementedError();
  }
}

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
