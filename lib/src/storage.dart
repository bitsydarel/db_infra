import 'dart:io';

import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/utils/types.dart';

///
abstract class Storage {
  ///
  final Logger logger;

  ///
  final Directory infraDirectory;

  ///
  const Storage(this.logger, this.infraDirectory);

  ///
  Future<void> saveFiles(final List<File> files);

  ///
  Future<List<File>> loadFiles();

  ///
  JsonMap toJson();
}
