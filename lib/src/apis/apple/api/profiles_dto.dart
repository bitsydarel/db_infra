import 'package:db_infra/src/apis/apple/api/appstoreconnectapi.dart';
import 'package:db_infra/src/apis/apple/api/bundle_ids_dto.dart';
import 'package:db_infra/src/apis/apple/api/certificates_dto.dart';
import 'package:db_infra/src/apis/apple/profile.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:io/io.dart';
import 'package:json_annotation/json_annotation.dart';

part 'profiles_dto.g.dart';

///
List<Object> fromIncluded(List<Object?>? json) {
  return json == null
      ? <Object>[]
      : json
          .map((dynamic item) {
            if (item is JsonMap) {
              final Object? type = item['type'];

              if (type == AppStoreConnectApi.certificatesType) {
                return CertificateResponseData.fromJson(item);
              } else if (type == AppStoreConnectApi.bundleIdsType) {
                return BundleIdResponse.fromJson(item);
              }
            }
            throw UnrecoverableException(
                json.toString(), ExitCode.tempFail.code);
          })
          .cast<Object>()
          .toList();
}

///
@JsonSerializable(explicitToJson: true)
class CreateProfileRequest {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final CreateProfileRequestData data;

  ///
  const CreateProfileRequest({required this.data});

  ///
  JsonMap toJson() => _$CreateProfileRequestToJson(this);
}

///
@JsonSerializable(explicitToJson: true)
class CreateProfileRequestData {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String type;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final CreateProfileAttributes attributes;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final CreateProfileRelationships relationships;

  ///
  const CreateProfileRequestData({
    required this.type,
    required this.attributes,
    required this.relationships,
  });

  ///
  factory CreateProfileRequestData.fromJson(JsonMap json) {
    return _$CreateProfileRequestDataFromJson(json);
  }

  ///
  JsonMap toJson() => _$CreateProfileRequestDataToJson(this);
}

///
@JsonSerializable()
class CreateProfileAttributes {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String name;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String profileType;

  ///
  const CreateProfileAttributes({
    required this.name,
    required this.profileType,
  });

  ///
  factory CreateProfileAttributes.fromJson(JsonMap json) {
    return _$CreateProfileAttributesFromJson(json);
  }

  ///
  JsonMap toJson() => _$CreateProfileAttributesToJson(this);
}

///
@JsonSerializable(explicitToJson: true)
class CreateProfileRelationships {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final CreateProfileRelationshipBundleId bundleId;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final CreateProfileRelationshipList certificates;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final CreateProfileRelationshipList devices;

  ///
  const CreateProfileRelationships({
    required this.bundleId,
    required this.certificates,
    required this.devices,
  });

  ///
  factory CreateProfileRelationships.fromJson(JsonMap json) {
    return _$CreateProfileRelationshipsFromJson(json);
  }

  ///
  JsonMap toJson() => _$CreateProfileRelationshipsToJson(this);
}

///
@JsonSerializable(explicitToJson: true)
class CreateProfileRelationshipBundleId {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final CreateProfileRelationshipData data;

  ///
  const CreateProfileRelationshipBundleId({required this.data});

  ///
  factory CreateProfileRelationshipBundleId.fromJson(JsonMap json) {
    return _$CreateProfileRelationshipBundleIdFromJson(json);
  }

  ///
  JsonMap toJson() => _$CreateProfileRelationshipBundleIdToJson(this);
}

///
@JsonSerializable(explicitToJson: true)
class CreateProfileRelationshipList {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final List<CreateProfileRelationshipData> data;

  ///
  const CreateProfileRelationshipList({required this.data});

  ///
  factory CreateProfileRelationshipList.fromJson(JsonMap json) {
    return _$CreateProfileRelationshipListFromJson(json);
  }

  ///
  JsonMap toJson() => _$CreateProfileRelationshipListToJson(this);
}

///
@JsonSerializable()
class CreateProfileRelationshipData {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String id;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String type;

  ///
  const CreateProfileRelationshipData({
    required this.id,
    required this.type,
  });

  ///
  factory CreateProfileRelationshipData.fromJson(JsonMap json) {
    return _$CreateProfileRelationshipDataFromJson(json);
  }

  ///
  JsonMap toJson() => _$CreateProfileRelationshipDataToJson(this);
}

///
@JsonSerializable(explicitToJson: true)
class GetProfilesResponse {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final List<ProfileResponseData> data;

  ///
  const GetProfilesResponse({required this.data});

  ///
  factory GetProfilesResponse.fromJson(JsonMap json) {
    return _$GetProfilesResponseFromJson(json);
  }

  ///
  List<Profile> toDomain() {
    return data.map(
      (ProfileResponseData profile) {
        return profile.toDomain();
      },
    ).toList();
  }
}

///
@JsonSerializable(explicitToJson: true)
class GetProfileResponse {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final ProfileResponseData data;

  ///
  @JsonKey(disallowNullValue: true, required: false, fromJson: fromIncluded)
  final List<Object>? included;

  ///
  const GetProfileResponse({required this.data, required this.included});

  ///
  factory GetProfileResponse.fromJson(JsonMap json) {
    return _$GetProfileResponseFromJson(json);
  }

  ///
  JsonMap toJson() => _$GetProfileResponseToJson(this);
}

///
@JsonSerializable(explicitToJson: true)
class ProfileResponseData {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String type;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String id;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final ProfileResponseAttributes attributes;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final ProfileResponseRelationship relationships;

  ///
  const ProfileResponseData({
    required this.type,
    required this.id,
    required this.attributes,
    required this.relationships,
  });

  ///
  factory ProfileResponseData.fromJson(JsonMap json) {
    return _$ProfileResponseDataFromJson(json);
  }

  ///
  JsonMap toJson() => _$ProfileResponseDataToJson(this);

  ///
  Profile toDomain() {
    return Profile(
      id: id,
      type: Profile.toProfileType(attributes.profileType),
      name: attributes.name,
      uuid: attributes.uuid,
      createdDate: DateTime.parse(attributes.createdDate),
      expirationDate: DateTime.parse(attributes.expirationDate),
      content: attributes.profileContent,
      state: attributes.profileState,
      platform: attributes.platform,
      bundleId: ProfileRelation(id: relationships.bundleId.data.id),
      certificates: relationships.certificates.data.map(
        (ProfileResponseRelationshipData relation) {
          return ProfileRelation(id: relation.id);
        },
      ).toList(),
      devices: const <ProfileRelation>[],
    );
  }
}

///
@JsonSerializable()
class ProfileResponseAttributes {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String name;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String uuid;

  ///
  @JsonKey(disallowNullValue: false, required: false)
  final String? platform;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String profileType;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String createdDate;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String profileState;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String profileContent;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String expirationDate;

  ///
  const ProfileResponseAttributes({
    required this.name,
    required this.uuid,
    required this.profileType,
    required this.createdDate,
    required this.profileState,
    required this.profileContent,
    required this.expirationDate,
    this.platform,
  });

  ///
  factory ProfileResponseAttributes.fromJson(JsonMap json) {
    return _$ProfileResponseAttributesFromJson(json);
  }

  ///
  JsonMap toJson() => _$ProfileResponseAttributesToJson(this);
}

///
@JsonSerializable(explicitToJson: true)
class ProfileResponseRelationship {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final ProfileResponseRelationshipCategoryBundledId bundleId;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final ProfileResponseRelationshipCategory certificates;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final ProfileResponseRelationshipCategory devices;

  ///
  const ProfileResponseRelationship({
    required this.bundleId,
    required this.certificates,
    required this.devices,
  });

  ///
  factory ProfileResponseRelationship.fromJson(JsonMap json) {
    return _$ProfileResponseRelationshipFromJson(json);
  }

  ///
  JsonMap toJson() => _$ProfileResponseRelationshipToJson(this);
}

///
@JsonSerializable(explicitToJson: true)
class ProfileResponseRelationshipCategoryBundledId {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final ProfileResponseRelationshipData data;

  ///
  const ProfileResponseRelationshipCategoryBundledId({required this.data});

  ///
  factory ProfileResponseRelationshipCategoryBundledId.fromJson(JsonMap json) {
    return _$ProfileResponseRelationshipCategoryBundledIdFromJson(json);
  }

  ///
  JsonMap toJson() {
    return _$ProfileResponseRelationshipCategoryBundledIdToJson(this);
  }
}

///
@JsonSerializable(explicitToJson: true)
class ProfileResponseRelationshipCategory {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final List<ProfileResponseRelationshipData> data;

  ///
  const ProfileResponseRelationshipCategory({required this.data});

  ///
  factory ProfileResponseRelationshipCategory.fromJson(JsonMap json) {
    return _$ProfileResponseRelationshipCategoryFromJson(json);
  }

  ///
  JsonMap toJson() => _$ProfileResponseRelationshipCategoryToJson(this);
}

///
@JsonSerializable(explicitToJson: true)
class ProfileResponseRelationshipData {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String id;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String type;

  ///
  const ProfileResponseRelationshipData({
    required this.id,
    required this.type,
  });

  ///
  factory ProfileResponseRelationshipData.fromJson(JsonMap json) {
    return _$ProfileResponseRelationshipDataFromJson(json);
  }

  ///
  JsonMap toJson() => _$ProfileResponseRelationshipDataToJson(this);
}
