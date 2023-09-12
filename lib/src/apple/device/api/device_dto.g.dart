// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetDevicesResponse _$GetDevicesResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['data'],
    disallowNullValues: const ['data'],
  );
  return GetDevicesResponse(
    data: (json['data'] as List<dynamic>)
        .map((e) => DeviceResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$GetDevicesResponseToJson(GetDevicesResponse instance) =>
    <String, dynamic>{
      'data': instance.data.map((e) => e.toJson()).toList(),
    };

GetDeviceResponse _$GetDeviceResponseFromJson(Map<String, dynamic> json) =>
    GetDeviceResponse(
      data: DeviceResponse.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetDeviceResponseToJson(GetDeviceResponse instance) =>
    <String, dynamic>{
      'data': instance.data.toJson(),
    };

DeviceResponse _$DeviceResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'type', 'attributes'],
    disallowNullValues: const ['id', 'type', 'attributes'],
  );
  return DeviceResponse(
    id: json['id'] as String,
    type: json['type'] as String,
    attributes: DeviceAttributesResponse.fromJson(
        json['attributes'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$DeviceResponseToJson(DeviceResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'attributes': instance.attributes.toJson(),
    };

DeviceAttributesResponse _$DeviceAttributesResponseFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'name',
      'platform',
      'udid',
      'deviceClass',
      'status',
      'model',
      'addedDate'
    ],
    disallowNullValues: const [
      'name',
      'platform',
      'udid',
      'deviceClass',
      'status',
      'model',
      'addedDate'
    ],
  );
  return DeviceAttributesResponse(
    name: json['name'] as String,
    platform: json['platform'] as String,
    udid: json['udid'] as String,
    deviceClass: json['deviceClass'] as String,
    status: json['status'] as String,
    model: json['model'] as String,
    addedDate: json['addedDate'] as String,
  );
}

Map<String, dynamic> _$DeviceAttributesResponseToJson(
        DeviceAttributesResponse instance) =>
    <String, dynamic>{
      'name': instance.name,
      'platform': instance.platform,
      'udid': instance.udid,
      'deviceClass': instance.deviceClass,
      'status': instance.status,
      'model': instance.model,
      'addedDate': instance.addedDate,
    };
