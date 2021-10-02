import 'package:db_infra/src/apis/apple/bundle_id.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bundle_ids_dto.g.dart';

///
@JsonSerializable(explicitToJson: true)
class GetBundleIdsResponse {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final List<BundleIdResponse> data;

  ///
  const GetBundleIdsResponse(this.data);

  ///
  factory GetBundleIdsResponse.fromJson(JsonMap json) {
    return _$GetBundleIdsResponseFromJson(json);
  }
}

///
@JsonSerializable(explicitToJson: true)
class GetBundleIdResponse {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final BundleIdResponse data;

  ///
  const GetBundleIdResponse({required this.data});

  ///
  factory GetBundleIdResponse.fromJson(JsonMap json) {
    return _$GetBundleIdResponseFromJson(json);
  }
}

///
@JsonSerializable(explicitToJson: true)
class CreateBundleIdRequest {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final CreateBundleIdData data;

  ///
  const CreateBundleIdRequest({required this.data});

  ///
  factory CreateBundleIdRequest.fromJson(JsonMap json) {
    return _$CreateBundleIdRequestFromJson(json);
  }

  ///
  JsonMap toJson() => _$CreateBundleIdRequestToJson(this);
}

///
@JsonSerializable(explicitToJson: true)
class CreateBundleIdData {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String type;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final CreateBundleIdDataAttributes attributes;

  ///
  const CreateBundleIdData({required this.type, required this.attributes});

  ///
  factory CreateBundleIdData.fromJson(JsonMap json) {
    return _$CreateBundleIdDataFromJson(json);
  }

  ///
  JsonMap toJson() => _$CreateBundleIdDataToJson(this);
}

///
@JsonSerializable()
class CreateBundleIdDataAttributes {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String identifier;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String name;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String platform;

  ///
  const CreateBundleIdDataAttributes({
    required this.identifier,
    required this.name,
    required this.platform,
  });

  ///
  factory CreateBundleIdDataAttributes.fromJson(JsonMap json) {
    return _$CreateBundleIdDataAttributesFromJson(json);
  }

  ///
  JsonMap toJson() => _$CreateBundleIdDataAttributesToJson(this);
}

///
@JsonSerializable(explicitToJson: true)
class BundleIdResponse {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String id;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String type;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final BundleIdAttributeResponse attributes;

  ///
  const BundleIdResponse({
    required this.id,
    required this.type,
    required this.attributes,
  });

  ///
  factory BundleIdResponse.fromJson(JsonMap json) {
    return _$BundleIdResponseFromJson(json);
  }

  ///
  JsonMap toJson() => _$BundleIdResponseToJson(this);

  ///
  BundleId toDomain() {
    return BundleId(
      id: id,
      name: attributes.name,
      platform: attributes.platform,
      identifier: attributes.identifier,
      seedId: attributes.seedId,
    );
  }
}

///
@JsonSerializable()
class BundleIdAttributeResponse {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String name;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String identifier;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String platform;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String seedId;

  ///
  const BundleIdAttributeResponse({
    required this.name,
    required this.identifier,
    required this.platform,
    required this.seedId,
  });

  ///
  factory BundleIdAttributeResponse.fromJson(JsonMap json) {
    return _$BundleIdAttributeResponseFromJson(json);
  }

  ///
  JsonMap toJson() => _$BundleIdAttributeResponseToJson(this);
}
