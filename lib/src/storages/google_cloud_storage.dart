import 'dart:io';

import 'package:db_infra/src/storage.dart';
import 'package:db_infra/src/utils/types.dart';

///
class GoogleCloudStorage extends Storage {
  ///
  const GoogleCloudStorage() : super();

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
