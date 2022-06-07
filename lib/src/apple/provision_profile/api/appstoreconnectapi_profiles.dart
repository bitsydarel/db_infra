import 'dart:convert';
import 'dart:io';

import 'package:db_infra/src/apple/appstoreconnectapi.dart';
import 'package:db_infra/src/apple/bundle_id/bundle_id.dart';
import 'package:db_infra/src/apple/certificates/certificate.dart';
import 'package:db_infra/src/apple/device/device.dart';
import 'package:db_infra/src/apple/provision_profile/api/profiles_dto.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile_type.dart';
import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/utils/utils.dart';
import 'package:http/http.dart';
import 'package:io/io.dart';

///
class AppStoreConnectApiProfiles extends AppStoreConnectApi<ProvisionProfile> {
  ///
  AppStoreConnectApiProfiles({
    required Client httpClient,
    required Configuration configuration,
  }) : super(httpClient: httpClient, configuration: configuration);

  ///
  Future<ProvisionProfile> create(
    final ProvisionProfileType profileType,
    final BundleId bundleId,
    final List<Certificate> certificates,
    final List<Device> devices,
  ) async {
    final Uri url = Uri.parse('${AppStoreConnectApi.baseUrl}/profiles');

    final String provisionProfileTypeName =
        configuration.iosProvisionProfileType.exportMethod.toUpperCase();

    final CreateProfileRequest request = CreateProfileRequest(
      data: CreateProfileRequestData(
        type: ProvisionProfile.profileType,
        attributes: CreateProfileAttributes(
          name: 'CI/CD $provisionProfileTypeName ${configuration.iosAppId}',
          profileType: profileType.key,
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
  Future<ProvisionProfile> get(String id) async {
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
  Future<List<ProvisionProfile>> getAll() async {
    final List<String> types = ProvisionProfileType.values
        .where((ProvisionProfileType type) {
          return type != ProvisionProfileType.other;
        })
        .map((ProvisionProfileType e) => e.key)
        .toList();

    final Uri url = Uri.parse(
      '${AppStoreConnectApi.baseUrl}/profiles'
      '?filter[profileType]=${types.join(',')}'
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
