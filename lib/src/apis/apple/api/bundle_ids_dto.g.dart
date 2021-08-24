// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bundle_ids_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetBundleIdsResponse _$GetBundleIdsResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['data'],
    disallowNullValues: const ['data'],
  );
  return GetBundleIdsResponse(
    (json['data'] as List<dynamic>)
        .map((e) => BundleIdResponse.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$GetBundleIdsResponseToJson(
        GetBundleIdsResponse instance) =>
    <String, dynamic>{
      'data': instance.data.map((e) => e.toJson()).toList(),
    };

GetBundleIdResponse _$GetBundleIdResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['data'],
    disallowNullValues: const ['data'],
  );
  return GetBundleIdResponse(
    data: BundleIdResponse.fromJson(json['data'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$GetBundleIdResponseToJson(
        GetBundleIdResponse instance) =>
    <String, dynamic>{
      'data': instance.data.toJson(),
    };

CreateBundleIdRequest _$CreateBundleIdRequestFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['data'],
    disallowNullValues: const ['data'],
  );
  return CreateBundleIdRequest(
    data: CreateBundleIdData.fromJson(json['data'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CreateBundleIdRequestToJson(
        CreateBundleIdRequest instance) =>
    <String, dynamic>{
      'data': instance.data.toJson(),
    };

CreateBundleIdData _$CreateBundleIdDataFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['type', 'attributes'],
    disallowNullValues: const ['type', 'attributes'],
  );
  return CreateBundleIdData(
    type: json['type'] as String,
    attributes: CreateBundleIdDataAttributes.fromJson(
        json['attributes'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CreateBundleIdDataToJson(CreateBundleIdData instance) =>
    <String, dynamic>{
      'type': instance.type,
      'attributes': instance.attributes.toJson(),
    };

CreateBundleIdDataAttributes _$CreateBundleIdDataAttributesFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['identifier', 'name', 'platform'],
    disallowNullValues: const ['identifier', 'name', 'platform'],
  );
  return CreateBundleIdDataAttributes(
    identifier: json['identifier'] as String,
    name: json['name'] as String,
    platform: json['platform'] as String,
  );
}

Map<String, dynamic> _$CreateBundleIdDataAttributesToJson(
        CreateBundleIdDataAttributes instance) =>
    <String, dynamic>{
      'identifier': instance.identifier,
      'name': instance.name,
      'platform': instance.platform,
    };

BundleIdResponse _$BundleIdResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'type', 'attributes'],
    disallowNullValues: const ['id', 'type', 'attributes'],
  );
  return BundleIdResponse(
    id: json['id'] as String,
    type: json['type'] as String,
    attributes: BundleIdAttributeResponse.fromJson(
        json['attributes'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$BundleIdResponseToJson(BundleIdResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'attributes': instance.attributes.toJson(),
    };

BundleIdAttributeResponse _$BundleIdAttributeResponseFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['name', 'identifier', 'platform', 'seedId'],
    disallowNullValues: const ['name', 'identifier', 'platform', 'seedId'],
  );
  return BundleIdAttributeResponse(
    name: json['name'] as String,
    identifier: json['identifier'] as String,
    platform: json['platform'] as String,
    seedId: json['seedId'] as String,
  );
}

Map<String, dynamic> _$BundleIdAttributeResponseToJson(
        BundleIdAttributeResponse instance) =>
    <String, dynamic>{
      'name': instance.name,
      'identifier': instance.identifier,
      'platform': instance.platform,
      'seedId': instance.seedId,
    };
