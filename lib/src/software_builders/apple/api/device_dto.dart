import 'package:db_infra/src/software_builders/apple/device.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:db_infra/src/utils/network_manager.dart';

part 'device_dto.g.dart';

///
@JsonSerializable(explicitToJson: true)
class GetDevicesResponse {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final List<DeviceResponse> data;

  ///
  const GetDevicesResponse({required this.data});

  ///
  factory GetDevicesResponse.fromJson(JsonMap json) {
    return _$GetDevicesResponseFromJson(json);
  }

  ///
  JsonMap toJson() => _$GetDevicesResponseToJson(this);
}

///
@JsonSerializable(explicitToJson: true)
class GetDeviceResponse {
  ///
  final DeviceResponse data;

  ///
  const GetDeviceResponse({required this.data});

  ///
  factory GetDeviceResponse.fromJson(JsonMap json) {
    return _$GetDeviceResponseFromJson(json);
  }

  ///
  JsonMap toJson() => _$GetDeviceResponseToJson(this);
}

///
@JsonSerializable(explicitToJson: true)
class DeviceResponse {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String id;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String type;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final DeviceAttributesResponse attributes;

  ///
  const DeviceResponse({
    required this.id,
    required this.type,
    required this.attributes,
  });

  ///
  factory DeviceResponse.fromJson(JsonMap json) {
    return _$DeviceResponseFromJson(json);
  }

  ///
  JsonMap toJson() => _$DeviceResponseToJson(this);

  ///
  Device toDomain() {
    return Device(
      id: id,
      name: attributes.name,
      platform: attributes.platform,
      udid: attributes.udid,
      deviceClass: attributes.deviceClass,
      status: attributes.status,
      model: attributes.model,
      addedDate: DateTime.parse(attributes.addedDate),
    );
  }
}

///
@JsonSerializable()
class DeviceAttributesResponse {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String name;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String platform;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String udid;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String deviceClass;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String status;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String model;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String addedDate;

  ///
  const DeviceAttributesResponse({
    required this.name,
    required this.platform,
    required this.udid,
    required this.deviceClass,
    required this.status,
    required this.model,
    required this.addedDate,
  });

  ///
  factory DeviceAttributesResponse.fromJson(JsonMap json) {
    return _$DeviceAttributesResponseFromJson(json);
  }

  ///
  JsonMap toJson() => _$DeviceAttributesResponseToJson(this);
}
