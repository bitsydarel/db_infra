import 'dart:convert';
import 'dart:io';

import 'package:db_infra/src/apis/apple/api/appstoreconnectapi.dart';
import 'package:db_infra/src/apis/apple/api/certificates_dto.dart';
import 'package:db_infra/src/apis/apple/certificate.dart';
import 'package:db_infra/src/run_configuration.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:http/http.dart';
import 'package:io/io.dart';

///
class AppStoreConnectApiCertificates extends AppStoreConnectApi<Certificate> {
  ///
  AppStoreConnectApiCertificates({
    required Client httpClient,
    required RunConfiguration configuration,
  }) : super(httpClient: httpClient, configuration: configuration);

  ///
  Future<Certificate> create(final String parameter) async {
    final Uri url = Uri.parse('${AppStoreConnectApi.baseUrl}/certificates');

    final CreateCertificateRequest requestBody = CreateCertificateRequest(
      data: CertificateCreateData(
        type: 'certificates',
        attributes: CertificateCreateAttributes(
          csrContent: parameter,
          certificateType: 'IOS_DISTRIBUTION',
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

      throw UnrecoverableException(response.body, ExitCode.tempFail.code);
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
        throw UnrecoverableException(response.body, ExitCode.tempFail.code);
      }
    } on ClientException catch (ce) {
      throw UnrecoverableException(ce.message, ExitCode.tempFail.code);
    }
  }

  ///
  @override
  Future<List<Certificate>> getAll() async {
    final Uri url = Uri.parse(
      '${AppStoreConnectApi.baseUrl}/certificates'
      '?filter[certificateType]=IOS_DISTRIBUTION,DISTRIBUTION&limit=20',
    );

    try {
      final Response response = await withClient(
        (MapHeaders headers, Client client) {
          return client.get(url, headers: headers);
        },
      );

      final Object? rawJson = jsonDecode(response.body);

      if (rawJson is Map<String, Object?>) {
        final GetCertificates certificates = GetCertificates.fromJson(rawJson);

        return certificates.data
            .map(
              (CertificateResponseData certificate) => certificate.toDomain(),
            )
            .toList();
      }

      throw UnrecoverableException(response.body, ExitCode.tempFail.code);
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

      throw UnrecoverableException(response.body, ExitCode.tempFail.code);
    } on ClientException catch (ce) {
      throw UnrecoverableException(ce.message, ExitCode.tempFail.code);
    }
  }
}
