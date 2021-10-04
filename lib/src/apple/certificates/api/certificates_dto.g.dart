// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'certificates_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCertificateRequest _$CreateCertificateRequestFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['data'],
    disallowNullValues: const ['data'],
  );
  return CreateCertificateRequest(
    data: CertificateCreateData.fromJson(json['data'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CreateCertificateRequestToJson(
        CreateCertificateRequest instance) =>
    <String, dynamic>{
      'data': instance.data.toJson(),
    };

CertificateCreateData _$CertificateCreateDataFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['type', 'attributes'],
    disallowNullValues: const ['type', 'attributes'],
  );
  return CertificateCreateData(
    type: json['type'] as String,
    attributes: CertificateCreateAttributes.fromJson(
        json['attributes'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CertificateCreateDataToJson(
        CertificateCreateData instance) =>
    <String, dynamic>{
      'type': instance.type,
      'attributes': instance.attributes.toJson(),
    };

CertificateCreateAttributes _$CertificateCreateAttributesFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['certificateType', 'csrContent'],
    disallowNullValues: const ['certificateType'],
  );
  return CertificateCreateAttributes(
    certificateType: json['certificateType'] as String,
    csrContent: json['csrContent'] as String,
  );
}

Map<String, dynamic> _$CertificateCreateAttributesToJson(
        CertificateCreateAttributes instance) =>
    <String, dynamic>{
      'certificateType': instance.certificateType,
      'csrContent': instance.csrContent,
    };

CreateCertificateResponse _$CreateCertificateResponseFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['data'],
  );
  return CreateCertificateResponse(
    CertificateResponseData.fromJson(json['data'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CreateCertificateResponseToJson(
        CreateCertificateResponse instance) =>
    <String, dynamic>{
      'data': instance.data.toJson(),
    };

GetCertificates _$GetCertificatesFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['data'],
  );
  return GetCertificates(
    (json['data'] as List<dynamic>)
        .map((e) => CertificateResponseData.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

Map<String, dynamic> _$GetCertificatesToJson(GetCertificates instance) =>
    <String, dynamic>{
      'data': instance.data,
    };

CertificateResponseData _$CertificateResponseDataFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'type', 'attributes'],
    disallowNullValues: const ['id', 'type', 'attributes'],
  );
  return CertificateResponseData(
    json['id'] as String,
    json['type'] as String,
    CertificateResponseAttributes.fromJson(
        json['attributes'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CertificateResponseDataToJson(
        CertificateResponseData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'attributes': instance.attributes.toJson(),
    };

CertificateResponseAttributes _$CertificateResponseAttributesFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'name',
      'certificateType',
      'displayName',
      'serialNumber',
      'expirationDate',
      'certificateContent'
    ],
    disallowNullValues: const [
      'name',
      'certificateType',
      'displayName',
      'serialNumber',
      'expirationDate',
      'certificateContent'
    ],
  );
  return CertificateResponseAttributes(
    json['name'] as String,
    json['certificateType'] as String,
    json['displayName'] as String,
    json['serialNumber'] as String,
    json['platform'] as String?,
    json['expirationDate'] as String,
    json['certificateContent'] as String,
  );
}

Map<String, dynamic> _$CertificateResponseAttributesToJson(
    CertificateResponseAttributes instance) {
  final val = <String, dynamic>{
    'name': instance.name,
    'certificateType': instance.certificateType,
    'displayName': instance.displayName,
    'serialNumber': instance.serialNumber,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('platform', instance.platform);
  val['expirationDate'] = instance.expirationDate;
  val['certificateContent'] = instance.certificateContent;
  return val;
}
