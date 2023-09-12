// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profiles_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateProfileRequest _$CreateProfileRequestFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['data'],
    disallowNullValues: const ['data'],
  );
  return CreateProfileRequest(
    data:
        CreateProfileRequestData.fromJson(json['data'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CreateProfileRequestToJson(
        CreateProfileRequest instance) =>
    <String, dynamic>{
      'data': instance.data.toJson(),
    };

CreateProfileRequestData _$CreateProfileRequestDataFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['type', 'attributes', 'relationships'],
    disallowNullValues: const ['type', 'attributes', 'relationships'],
  );
  return CreateProfileRequestData(
    type: json['type'] as String,
    attributes: CreateProfileAttributes.fromJson(
        json['attributes'] as Map<String, dynamic>),
    relationships: CreateProfileRelationships.fromJson(
        json['relationships'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CreateProfileRequestDataToJson(
        CreateProfileRequestData instance) =>
    <String, dynamic>{
      'type': instance.type,
      'attributes': instance.attributes.toJson(),
      'relationships': instance.relationships.toJson(),
    };

CreateProfileAttributes _$CreateProfileAttributesFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['name', 'profileType'],
    disallowNullValues: const ['name', 'profileType'],
  );
  return CreateProfileAttributes(
    name: json['name'] as String,
    profileType: json['profileType'] as String,
  );
}

Map<String, dynamic> _$CreateProfileAttributesToJson(
        CreateProfileAttributes instance) =>
    <String, dynamic>{
      'name': instance.name,
      'profileType': instance.profileType,
    };

CreateProfileRelationships _$CreateProfileRelationshipsFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['bundleId', 'certificates', 'devices'],
    disallowNullValues: const ['bundleId', 'certificates', 'devices'],
  );
  return CreateProfileRelationships(
    bundleId: CreateProfileRelationshipBundleId.fromJson(
        json['bundleId'] as Map<String, dynamic>),
    certificates: CreateProfileRelationshipList.fromJson(
        json['certificates'] as Map<String, dynamic>),
    devices: CreateProfileRelationshipList.fromJson(
        json['devices'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CreateProfileRelationshipsToJson(
        CreateProfileRelationships instance) =>
    <String, dynamic>{
      'bundleId': instance.bundleId.toJson(),
      'certificates': instance.certificates.toJson(),
      'devices': instance.devices.toJson(),
    };

CreateProfileRelationshipBundleId _$CreateProfileRelationshipBundleIdFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['data'],
    disallowNullValues: const ['data'],
  );
  return CreateProfileRelationshipBundleId(
    data: CreateProfileRelationshipData.fromJson(
        json['data'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CreateProfileRelationshipBundleIdToJson(
        CreateProfileRelationshipBundleId instance) =>
    <String, dynamic>{
      'data': instance.data.toJson(),
    };

CreateProfileRelationshipList _$CreateProfileRelationshipListFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['data'],
    disallowNullValues: const ['data'],
  );
  return CreateProfileRelationshipList(
    data: (json['data'] as List<dynamic>)
        .map((e) =>
            CreateProfileRelationshipData.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$CreateProfileRelationshipListToJson(
        CreateProfileRelationshipList instance) =>
    <String, dynamic>{
      'data': instance.data.map((e) => e.toJson()).toList(),
    };

CreateProfileRelationshipData _$CreateProfileRelationshipDataFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'type'],
    disallowNullValues: const ['id', 'type'],
  );
  return CreateProfileRelationshipData(
    id: json['id'] as String,
    type: json['type'] as String,
  );
}

Map<String, dynamic> _$CreateProfileRelationshipDataToJson(
        CreateProfileRelationshipData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
    };

GetProfilesResponse _$GetProfilesResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['data'],
    disallowNullValues: const ['data'],
  );
  return GetProfilesResponse(
    data: (json['data'] as List<dynamic>)
        .map((e) => ProfileResponseData.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$GetProfilesResponseToJson(
        GetProfilesResponse instance) =>
    <String, dynamic>{
      'data': instance.data.map((e) => e.toJson()).toList(),
    };

GetProfileResponse _$GetProfileResponseFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['data'],
    disallowNullValues: const ['data', 'included'],
  );
  return GetProfileResponse(
    data: ProfileResponseData.fromJson(json['data'] as Map<String, dynamic>),
    included: fromIncluded(json['included'] as List?),
  );
}

Map<String, dynamic> _$GetProfileResponseToJson(GetProfileResponse instance) {
  final val = <String, dynamic>{
    'data': instance.data.toJson(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('included', instance.included);
  return val;
}

ProfileResponseData _$ProfileResponseDataFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['type', 'id', 'attributes', 'relationships'],
    disallowNullValues: const ['type', 'id', 'attributes', 'relationships'],
  );
  return ProfileResponseData(
    type: json['type'] as String,
    id: json['id'] as String,
    attributes: ProfileResponseAttributes.fromJson(
        json['attributes'] as Map<String, dynamic>),
    relationships: ProfileResponseRelationship.fromJson(
        json['relationships'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$ProfileResponseDataToJson(
        ProfileResponseData instance) =>
    <String, dynamic>{
      'type': instance.type,
      'id': instance.id,
      'attributes': instance.attributes.toJson(),
      'relationships': instance.relationships.toJson(),
    };

ProfileResponseAttributes _$ProfileResponseAttributesFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'name',
      'uuid',
      'profileType',
      'createdDate',
      'profileState',
      'profileContent',
      'expirationDate'
    ],
    disallowNullValues: const [
      'name',
      'uuid',
      'profileType',
      'createdDate',
      'profileState',
      'profileContent',
      'expirationDate'
    ],
  );
  return ProfileResponseAttributes(
    name: json['name'] as String,
    uuid: json['uuid'] as String,
    profileType: json['profileType'] as String,
    createdDate: json['createdDate'] as String,
    profileState: json['profileState'] as String,
    profileContent: json['profileContent'] as String,
    expirationDate: json['expirationDate'] as String,
    platform: json['platform'] as String?,
  );
}

Map<String, dynamic> _$ProfileResponseAttributesToJson(
        ProfileResponseAttributes instance) =>
    <String, dynamic>{
      'name': instance.name,
      'uuid': instance.uuid,
      'platform': instance.platform,
      'profileType': instance.profileType,
      'createdDate': instance.createdDate,
      'profileState': instance.profileState,
      'profileContent': instance.profileContent,
      'expirationDate': instance.expirationDate,
    };

ProfileResponseRelationship _$ProfileResponseRelationshipFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['bundleId', 'certificates', 'devices'],
    disallowNullValues: const ['bundleId', 'certificates', 'devices'],
  );
  return ProfileResponseRelationship(
    bundleId: ProfileResponseRelationshipCategoryBundledId.fromJson(
        json['bundleId'] as Map<String, dynamic>),
    certificates: ProfileResponseRelationshipCategory.fromJson(
        json['certificates'] as Map<String, dynamic>),
    devices: ProfileResponseRelationshipCategory.fromJson(
        json['devices'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$ProfileResponseRelationshipToJson(
        ProfileResponseRelationship instance) =>
    <String, dynamic>{
      'bundleId': instance.bundleId.toJson(),
      'certificates': instance.certificates.toJson(),
      'devices': instance.devices.toJson(),
    };

ProfileResponseRelationshipCategoryBundledId
    _$ProfileResponseRelationshipCategoryBundledIdFromJson(
        Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['data'],
    disallowNullValues: const ['data'],
  );
  return ProfileResponseRelationshipCategoryBundledId(
    data: ProfileResponseRelationshipData.fromJson(
        json['data'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$ProfileResponseRelationshipCategoryBundledIdToJson(
        ProfileResponseRelationshipCategoryBundledId instance) =>
    <String, dynamic>{
      'data': instance.data.toJson(),
    };

ProfileResponseRelationshipCategory
    _$ProfileResponseRelationshipCategoryFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['data'],
    disallowNullValues: const ['data'],
  );
  return ProfileResponseRelationshipCategory(
    data: (json['data'] as List<dynamic>)
        .map((e) =>
            ProfileResponseRelationshipData.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$ProfileResponseRelationshipCategoryToJson(
        ProfileResponseRelationshipCategory instance) =>
    <String, dynamic>{
      'data': instance.data.map((e) => e.toJson()).toList(),
    };

ProfileResponseRelationshipData _$ProfileResponseRelationshipDataFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'type'],
    disallowNullValues: const ['id', 'type'],
  );
  return ProfileResponseRelationshipData(
    id: json['id'] as String,
    type: json['type'] as String,
  );
}

Map<String, dynamic> _$ProfileResponseRelationshipDataToJson(
        ProfileResponseRelationshipData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
    };
