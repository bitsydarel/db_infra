import 'dart:io';

import 'package:db_infra/src/infra_logger.dart';
import 'package:db_infra/src/infra_storage.dart';
import 'package:db_infra/src/utils/types.dart';

///
class InfraGoogleCloudStorage extends InfraStorage {
  ///
  const InfraGoogleCloudStorage(
    InfraLogger logger,
    Directory infraDirectory,
  ) : super(logger, infraDirectory);

  @override
  Future<List<File>> loadFiles() async {
    // TODO: implement loadFiles
    throw UnimplementedError();
  }

  @override
  Future<void> saveFiles(List<File> files) async {
    // TODO: implement saveFiles
    throw UnimplementedError();
  }

  @override
  JsonMap toJson() {
    return <String, String>{};
  }
}
