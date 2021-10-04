import 'dart:io';

import 'package:db_infra/src/utils/types.dart';

///
abstract class Storage {
  ///
  const Storage();

  ///
  Future<void> saveFiles(final List<File> files);

  ///
  Future<List<File>> loadFiles();

  ///
  JsonMap toJson();
}
