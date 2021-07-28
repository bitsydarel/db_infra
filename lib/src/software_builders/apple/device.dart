///
class Device {
  ///
  static const String deviceType = 'devices';

  ///
  final String id;

  ///
  final String name;

  ///
  final String platform;

  ///
  final String udid;

  ///
  final String deviceClass;

  ///
  final String status;

  ///
  final String model;

  ///
  final DateTime addedDate;

  ///
  const Device({
    required this.id,
    required this.name,
    required this.platform,
    required this.udid,
    required this.deviceClass,
    required this.status,
    required this.model,
    required this.addedDate,
  });

  @override
  String toString() {
    return 'Device{id: $id, name: $name, platform: $platform, udid: $udid, '
        'deviceClass: $deviceClass, status: $status, model: $model, '
        'addedDate: $addedDate}';
  }
}
