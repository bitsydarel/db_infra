import 'package:db_infra/src/setup_configuration.dart';

///
abstract class Storage {
  ///
  Future<SetupConfiguration> load();

  ///
  Future<void> save(SetupConfiguration configuration);
}
