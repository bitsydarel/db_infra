import 'dart:convert';
import 'dart:io';

import 'package:db_infra/src/apple/appstoreconnectapi.dart';
import 'package:db_infra/src/apple/certificates/api/certificates_dto.dart';
import 'package:db_infra/src/apple/certificates/certificate.dart';
import 'package:db_infra/src/apple/certificates/certificate_type.dart';
import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/utils/utils.dart';
import 'package:http/http.dart';
import 'package:io/io.dart';

///
class AppStoreConnectApiCertificates extends AppStoreConnectApi<Certificate> {
  ///
  AppStoreConnectApiCertificates({
    required Client httpClient,
    required Configuration configuration,
  }) : super(httpClient: httpClient, configuration: configuration);

  ///
  Future<Certificate> create(
    final String parameter,
    CertificateType certificateType,
  ) async {
    final Uri url = Uri.parse('${AppStoreConnectApi.baseUrl}/certificates');

    final CreateCertificateRequest requestBody = CreateCertificateRequest(
      data: CertificateCreateData(
        type: 'certificates',
        attributes: CertificateCreateAttributes(
          csrContent: parameter,
          certificateType: certificateType.key,
        ),
      ),
    );

    try {
      final Response response = await withClient(
        (MapHeaders headers, Client client) => client.post(
          url,
          headers: headers,
          body: jsonEncode(requestBody),
        ),
      );

      final Object? rawJson = jsonDecode(response.body);

      if (rawJson is Map<String, Object?> && !rawJson.containsKey('errors')) {
        final CreateCertificateResponse certificate =
            CreateCertificateResponse.fromJson(rawJson);

        return certificate.data.toDomain();
      }

      throw UnrecoverableException(response.asError(), ExitCode.tempFail.code);
    } on ClientException catch (ce) {
      throw UnrecoverableException(ce.message, ExitCode.tempFail.code);
    }
  }

  ///
  @override
  Future<void> delete(final String id) async {
    final Uri url = Uri.parse('${AppStoreConnectApi.baseUrl}/certificates/$id');

    try {
      final Response response = await withClient(
        (MapHeaders headers, Client client) {
          return client.delete(url, headers: headers);
        },
      );

      if (response.statusCode != HttpStatus.noContent) {
        throw UnrecoverableException(
          response.asError(),
          ExitCode.tempFail.code,
        );
      }
    } on ClientException catch (ce) {
      throw UnrecoverableException(ce.message, ExitCode.tempFail.code);
    }
  }

  ///
  @override
  Future<List<Certificate>> getAll() async {
    final List<String> types = CertificateType.values
        .where((CertificateType type) => type != CertificateType.other)
        .map((CertificateType type) => type.key)
        .toList();

    final Uri url = Uri.parse(
      '${AppStoreConnectApi.baseUrl}/certificates'
      '?filter[certificateType]=${types.join(',')}&limit=20',
    );

    try {
      final Response response = await withClient(
        (MapHeaders headers, Client client) {
          return client.get(url, headers: headers);
        },
      );

      final Object? rawJson = jsonDecode(response.body);

      if (rawJson is Map<String, Object?> && !rawJson.containsKey('errors')) {
        final GetCertificates certificates = GetCertificates.fromJson(rawJson);

        return certificates.data
            .map(
              (CertificateResponseData certificate) => certificate.toDomain(),
            )
            .toList();
      }

      throw UnrecoverableException(response.asError(), ExitCode.tempFail.code);
    } on ClientException catch (ce) {
      throw UnrecoverableException(ce.message, ExitCode.tempFail.code);
    }
  }

  ///
  @override
  Future<Certificate> get(final String id) async {
    final Uri url = Uri.parse('${AppStoreConnectApi.baseUrl}/certificates/$id');

    try {
      final Response response = await withClient(
        (MapHeaders headers, Client client) {
          return client.get(url, headers: headers);
        },
      );

      final Object? rawJson = jsonDecode(response.body);

      if (rawJson is Map<String, Object?> && !rawJson.containsKey('errors')) {
        return CreateCertificateResponse.fromJson(rawJson).data.toDomain();
      }

      throw UnrecoverableException(response.asError(), ExitCode.tempFail.code);
    } on ClientException catch (ce) {
      throw UnrecoverableException(ce.message, ExitCode.tempFail.code);
    }
  }
}
