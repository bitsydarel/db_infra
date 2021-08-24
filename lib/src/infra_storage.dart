import 'dart:io';

import 'package:db_infra/src/infra_logger.dart';
import 'package:db_infra/src/utils/types.dart';

///
abstract class InfraStorage {
  ///
  final InfraLogger logger;

  ///
  final Directory infraDirectory;

  ///
  const InfraStorage(this.logger, this.infraDirectory);

  ///
  Future<void> saveFiles(final List<File> files);

  ///
  Future<List<File>> loadFiles();

  ///
  JsonMap toJson();
}
