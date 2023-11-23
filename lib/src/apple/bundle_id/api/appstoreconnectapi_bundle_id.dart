import 'dart:convert';
import 'dart:io';

import 'package:db_infra/src/apple/appstoreconnectapi.dart';
import 'package:db_infra/src/apple/bundle_id/api/bundle_ids_dto.dart';
import 'package:db_infra/src/apple/bundle_id/bundle_id.dart';
import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/utils/utils.dart';
import 'package:http/http.dart';
import 'package:io/io.dart';

///
class AppStoreConnectApiBundleId extends AppStoreConnectApi<BundleId> {
  ///
  AppStoreConnectApiBundleId({
    required Client httpClient,
    required Configuration configuration,
  }) : super(httpClient: httpClient, configuration: configuration);

  ///
  Future<BundleId> create(final String appName) async {
    final Uri url = Uri.parse('${AppStoreConnectApi.baseUrl}/bundleIds');

    final CreateBundleIdRequest request = CreateBundleIdRequest(
      data: CreateBundleIdData(
        type: BundleId.bundleIdTypes,
        attributes: CreateBundleIdDataAttributes(
          identifier: configuration.iosAppId,
          name: appName,
          platform: 'IOS',
        ),
      ),
    );

    try {
      final Response response = await withClient(
        (MapHeaders headers, Client client) {
          return client.post(url, headers: headers, body: jsonEncode(request));
        },
      );

      final Object? rawJson = jsonDecode(response.body);

      if (rawJson is JsonMap && !rawJson.containsKey('errors')) {
        final GetBundleIdResponse bundleIdResponse =
            GetBundleIdResponse.fromJson(rawJson);

        return bundleIdResponse.data.toDomain();
      }

      throw UnrecoverableException(response.asError(), ExitCode.tempFail.code);
    } on ClientException catch (ce) {
      throw UnrecoverableException(ce.message, ExitCode.tempFail.code);
    }
  }

  @override
  Future<void> delete(String id) async {
    final Uri url = Uri.parse('${AppStoreConnectApi.baseUrl}/bundleIds/$id');

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

  @override
  Future<BundleId> get(String id) async {
    final Uri url = Uri.parse('${AppStoreConnectApi.baseUrl}/bundleIds/$id');

    try {
      final Response response = await withClient(
        (MapHeaders headers, Client client) {
          return client.get(url, headers: headers);
        },
      );

      final Object? rawJson = jsonDecode(response.body);

      if (rawJson is JsonMap && !rawJson.containsKey('errors')) {
        final GetBundleIdResponse bundleIdResponse =
            GetBundleIdResponse.fromJson(rawJson);

        return bundleIdResponse.data.toDomain();
      }

      throw UnrecoverableException(response.body, ExitCode.tempFail.code);
    } on ClientException catch (ce) {
      throw UnrecoverableException(ce.message, ExitCode.tempFail.code);
    }
  }

  ///
  @override
  Future<List<BundleId>> getAll() async {
    final Uri url = Uri.parse('${AppStoreConnectApi.baseUrl}/bundleIds');

    try {
      final Response response = await withClient(
        (MapHeaders headers, Client client) {
          return client.get(url, headers: headers);
        },
      );

      final Object? rawJson = jsonDecode(response.body);

      if (rawJson is JsonMap && !rawJson.containsKey('errors')) {
        final GetBundleIdsResponse bundleIdsResponse =
            GetBundleIdsResponse.fromJson(rawJson);

        return bundleIdsResponse.data
            .map((BundleIdResponse bundleId) => bundleId.toDomain())
            .toList();
      }

      throw UnrecoverableException(response.asError(), ExitCode.tempFail.code);
    } on ClientException catch (ce) {
      throw UnrecoverableException(ce.message, ExitCode.tempFail.code);
    }
  }
}
