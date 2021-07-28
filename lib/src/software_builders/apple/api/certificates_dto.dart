import 'package:db_infra/src/software_builders/apple/certificate.dart';
import 'package:json_annotation/json_annotation.dart';

part 'certificates_dto.g.dart';

///
@JsonSerializable(explicitToJson: true)
class CreateCertificateRequest {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final CertificateCreateData data;

  ///
  const CreateCertificateRequest({required this.data});

  ///
  Map<String, Object?> toJson() => _$CreateCertificateRequestToJson(this);

  @override
  String toString() => 'CreateCertificateRequest{data: $data}';
}

///
@JsonSerializable(explicitToJson: true)
class CertificateCreateData {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String type;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final CertificateCreateAttributes attributes;

  ///
  const CertificateCreateData({required this.type, required this.attributes});

  ///
  factory CertificateCreateData.fromJson(Map<String, Object?> json) {
    return _$CertificateCreateDataFromJson(json);
  }

  ///
  Map<String, Object?> toJson() => _$CertificateCreateDataToJson(this);

  @override
  String toString() {
    return 'CertificateCreateData{type: $type, attributes: $attributes}';
  }
}

///
@JsonSerializable()
class CertificateCreateAttributes {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String certificateType;

  ///
  @JsonKey(required: true, includeIfNull: true)
  final String csrContent;

  ///
  const CertificateCreateAttributes({
    required this.certificateType,
    required this.csrContent,
  });

  ///
  factory CertificateCreateAttributes.fromJson(Map<String, Object?> json) {
    return _$CertificateCreateAttributesFromJson(json);
  }

  ///
  Map<String, Object?> toJson() => _$CertificateCreateAttributesToJson(this);

  @override
  String toString() {
    return 'CertificateCreateAttributes{csrContent: $csrContent,'
        ' certificateType: $certificateType}';
  }
}

///
@JsonSerializable(explicitToJson: true)
class CreateCertificateResponse {
  ///
  @JsonKey(required: true)
  final CertificateResponseData data;

  ///
  const CreateCertificateResponse(this.data);

  ///
  factory CreateCertificateResponse.fromJson(Map<String, Object?> json) {
    return _$CreateCertificateResponseFromJson(json);
  }

  ///
  Map<String, Object?> toJson() => _$CreateCertificateResponseToJson(this);
}

///
@JsonSerializable()
class GetCertificates {
  ///
  @JsonKey(required: true)
  final List<CertificateResponseData> data;

  ///
  const GetCertificates(this.data);

  ///
  factory GetCertificates.fromJson(Map<String, Object?> json) {
    return _$GetCertificatesFromJson(json);
  }

  ///
  Map<String, Object?> toJson() => _$GetCertificatesToJson(this);

  @override
  String toString() => 'GetCertificates{data: $data}';
}

///
@JsonSerializable(explicitToJson: true)
class CertificateResponseData {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String id;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String type;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final CertificateResponseAttributes attributes;

  ///
  const CertificateResponseData(this.id, this.type, this.attributes);

  ///
  factory CertificateResponseData.fromJson(Map<String, Object?> json) {
    return _$CertificateResponseDataFromJson(json);
  }

  ///
  Map<String, Object?> toJson() => _$CertificateResponseDataToJson(this);

  ///
  Certificate toDomain() {
    return Certificate(
      id: id,
      name: attributes.name,
      type: attributes.certificateType,
      expireAt: DateTime.parse(attributes.expirationDate),
      content: attributes.certificateContent,
      serialNumber: attributes.serialNumber,
    );
  }

  @override
  String toString() {
    return 'CertificateResponseData{id: $id, '
        'type: $type, attributes: $attributes}';
  }
}

///
@JsonSerializable()
class CertificateResponseAttributes {
  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String name;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String certificateType;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String displayName;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String serialNumber;

  ///
  @JsonKey(includeIfNull: false, required: false)
  final String? platform;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String expirationDate;

  ///
  @JsonKey(disallowNullValue: true, required: true)
  final String certificateContent;

  ///
  const CertificateResponseAttributes(
    this.name,
    this.certificateType,
    this.displayName,
    this.serialNumber,
    this.platform,
    this.expirationDate,
    this.certificateContent,
  );

  ///
  factory CertificateResponseAttributes.fromJson(Map<String, Object?> json) {
    return _$CertificateResponseAttributesFromJson(json);
  }

  ///
  Map<String, Object?> toJson() => _$CertificateResponseAttributesToJson(this);

  @override
  String toString() {
    return 'CertificateResponseAttributes{'
        'name: $name, certificateType: $certificateType, '
        'displayName: $displayName, serialNumber: $serialNumber, '
        'platform: $platform, expirationDate: $expirationDate, '
        'certificateContent: $certificateContent}';
  }
}
