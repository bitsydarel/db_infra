import 'dart:convert';
import 'dart:io';

import 'package:db_infra/src/run_configuration.dart';
import 'package:db_infra/src/software_builders/apple/api/appstoreconnectapi.dart';
import 'package:db_infra/src/software_builders/apple/api/device_dto.dart';
import 'package:db_infra/src/software_builders/apple/device.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:db_infra/src/utils/network_manager.dart';
import 'package:http/http.dart';
import 'package:io/io.dart';

///
class AppStoreConnectApiDevices extends AppStoreConnectApi<Device> {
  ///
  AppStoreConnectApiDevices({
    required Client httpClient,
    required RunConfiguration configuration,
  }) : super(httpClient: httpClient, configuration: configuration);

  @override
  Future<void> delete(String id) async {
    final Uri url = Uri.parse('${AppStoreConnectApi.baseUrl}/devices/$id');

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
  Future<Device> get(String id) async {
    final Uri url = Uri.parse('${AppStoreConnectApi.baseUrl}/devices/$id');

    try {
      final Response rawResponse = await withClient(
        (MapHeaders headers, Client client) {
          return client.get(url, headers: headers);
        },
      );

      final Object? rawJson = jsonDecode(rawResponse.body);

      if (rawJson is Map<String, Object?> && !rawJson.containsKey('errors')) {
        final GetDeviceResponse response = GetDeviceResponse.fromJson(rawJson);

        return response.data.toDomain();
      }

      throw UnrecoverableException(rawResponse.body, ExitCode.tempFail.code);
    } on ClientException catch (ce) {
      throw UnrecoverableException(ce.message, ExitCode.tempFail.code);
    }
  }

  @override
  Future<List<Device>> getAll() async {
    final Uri url = Uri.parse('${AppStoreConnectApi.baseUrl}/devices');

    try {
      final Response rawResponse = await withClient(
        (MapHeaders headers, Client client) {
          return client.get(url, headers: headers);
        },
      );

      final Object? rawJson = jsonDecode(rawResponse.body);

      if (rawJson is Map<String, Object?> && !rawJson.containsKey('errors')) {
        final GetDevicesResponse response =
            GetDevicesResponse.fromJson(rawJson);

        return response.data
            .map((DeviceResponse device) => device.toDomain())
            .toList();
      }

      throw UnrecoverableException(rawResponse.body, ExitCode.tempFail.code);
    } on ClientException catch (ce) {
      throw UnrecoverableException(ce.message, ExitCode.tempFail.code);
    }
  }
}
