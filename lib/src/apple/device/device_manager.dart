import 'package:db_infra/src/apple/device/api/appstoreconnectapi_devices.dart';
import 'package:db_infra/src/apple/device/device.dart';

///
class DeviceManager {
  final AppStoreConnectApiDevices _api;

  ///
  DeviceManager(this._api);

  ///
  Future<List<Device>> getAllDevices() {
    return _api.getAll();
  }
}
