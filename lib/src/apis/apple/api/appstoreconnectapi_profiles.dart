import 'dart:convert';
import 'dart:io';

import 'package:db_infra/src/apis/apple/api/appstoreconnectapi.dart';
import 'package:db_infra/src/apis/apple/api/profiles_dto.dart';
import 'package:db_infra/src/apis/apple/bundle_id.dart';
import 'package:db_infra/src/apis/apple/certificate.dart';
import 'package:db_infra/src/apis/apple/device.dart';
import 'package:db_infra/src/apis/apple/profile.dart';
import 'package:db_infra/src/infra_run_configuration.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:http/http.dart';
import 'package:io/io.dart';

///
class AppStoreConnectApiProfiles extends AppStoreConnectApi<Profile> {
  ///
  AppStoreConnectApiProfiles({
    required Client httpClient,
    required InfraRunConfiguration configuration,
  }) : super(httpClient: httpClient, configuration: configuration);

  ///
  Future<Profile> create(
    final BundleId bundleId,
    final List<Certificate> certificates,
    final List<Device> devices,
  ) async {
    final Uri url = Uri.parse('${AppStoreConnectApi.baseUrl}/profiles');

    final CreateProfileRequest request = CreateProfileRequest(
      data: CreateProfileRequestData(
        type: Profile.profileType,
        attributes: CreateProfileAttributes(
          name: 'CI/CD AppStore ${configuration.iosAppId}',
          profileType: 'IOS_APP_STORE',
        ),
        relationships: CreateProfileRelationships(
          bundleId: CreateProfileRelationshipBundleId(
            data: CreateProfileRelationshipData(
              id: bundleId.id,
              type: BundleId.bundleIdTypes,
            ),
          ),
          certificates: CreateProfileRelationshipList(
            data: certificates.map((Certificate certificate) {
              return CreateProfileRelationshipData(
                id: certificate.id,
                type: Certificate.certificateType,
              );
            }).toList(),
          ),
          devices: CreateProfileRelationshipList(
            data: devices.map((Device device) {
              return CreateProfileRelationshipData(
                id: device.id,
                type: Device.deviceType,
              );
            }).toList(),
          ),
        ),
      ),
    );

    try {
      final Response rawResponse = await withClient(
        (MapHeaders headers, Client client) {
          return client.post(url, headers: headers, body: jsonEncode(request));
        },
      );

      final Object? rawJson = jsonDecode(rawResponse.body);

      if (rawJson is Map<String, Object?> && !rawJson.containsKey('errors')) {
        final GetProfileResponse response =
            GetProfileResponse.fromJson(rawJson);

        return response.data.toDomain();
      }

      throw UnrecoverableException(rawResponse.body, ExitCode.tempFail.code);
    } on ClientException catch (ce) {
      throw UnrecoverableException(ce.message, ExitCode.tempFail.code);
    }
  }

  @override
  Future<void> delete(String id) async {
    final Uri url = Uri.parse('${AppStoreConnectApi.baseUrl}/profiles/$id');

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
  Future<Profile> get(String id) async {
    final Uri url = Uri.parse(
        '${AppStoreConnectApi.baseUrl}/profiles/$id?include=bundleId,certificates,devices');

    try {
      final Response rawResponse = await withClient(
        (MapHeaders headers, Client client) {
          return client.get(url, headers: headers);
        },
      );

      final Object? rawJson = jsonDecode(rawResponse.body);

      if (rawJson is JsonMap && !rawJson.containsKey('errors')) {
        final GetProfileResponse response =
            GetProfileResponse.fromJson(rawJson);

        return response.data.toDomain();
      } else {
        throw UnrecoverableException(rawResponse.body, ExitCode.tempFail.code);
      }
    } on ClientException catch (ce) {
      throw UnrecoverableException(ce.message, ExitCode.tempFail.code);
    }
  }

  @override
  Future<List<Profile>> getAll() async {
    final Uri url = Uri.parse(
      '${AppStoreConnectApi.baseUrl}/profiles'
      '?filter[profileType]=IOS_APP_STORE'
      '&include=bundleId,certificates,devices',
    );

    try {
      final Response response = await withClient(
        (MapHeaders headers, Client client) {
          return client.get(url, headers: headers);
        },
      );

      final Object? rawJson = jsonDecode(response.body);

      if (rawJson is JsonMap && !rawJson.containsKey('errors')) {
        final GetProfilesResponse profilesResponse =
            GetProfilesResponse.fromJson(rawJson);

        return profilesResponse.toDomain();
      } else {
        throw UnrecoverableException(response.body, ExitCode.tempFail.code);
      }
    } on ClientException catch (ce) {
      throw UnrecoverableException(ce.message, ExitCode.tempFail.code);
    }
  }
}

///
class CreateProfileParam {
  ///
  final BundleId bundleId;

  ///
  final List<Certificate> certificates;

  ///
  final List<Device> devices;

  ///
  const CreateProfileParam({
    required this.bundleId,
    required this.certificates,
    required this.devices,
  });
}
