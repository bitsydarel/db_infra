import 'dart:io';

import 'package:db_infra/src/run_configuration.dart';
import 'package:http/http.dart';
import 'package:jose/jose.dart';
import 'package:meta/meta.dart';
import 'package:db_infra/src/utils/network_manager.dart';

const Duration _defaultJwtTokenExp = Duration(minutes: 19);

///
abstract class AppStoreConnectApi<R> {
  ///
  @protected
  static const String baseUrl = 'https://api.appstoreconnect.apple.com/v1';

  ///
  static const String certificatesType = 'certificates';

  ///
  static const String bundleIdsType = 'bundleIds';

  ///
  static const String devicesType = 'devices';

  ///
  @protected
  final Client httpClient;

  ///
  @protected
  final RunConfiguration configuration;

  ///
  String? _token;

  ///
  AppStoreConnectApi({
    required this.httpClient,
    required this.configuration,
  });

  ///
  Future<void> delete(final String id);

  ///
  Future<R> get(final String id);

  ///
  Future<List<R>> getAll();

  ///
  @protected
  Future<Response> withClient(
    Future<Response> Function(MapHeaders headers, Client client) request,
  ) {
    final String? currentToken = _token;

    if (currentToken != null) {
      final JsonWebToken tokenDetail = JsonWebToken.unverified(currentToken);

      final DateTime? expiration = tokenDetail.claims.expiry;

      if (expiration != null && DateTime.now().isBefore(expiration)) {
        return request(
          <String, String>{
            'Authorization': 'Bearer $currentToken',
            'content-type': 'application/json',
          },
          httpClient,
        );
      }
    }

    final JsonWebSignatureBuilder signature = JsonWebSignatureBuilder()
      ..addHeader(configuration)
      ..addPayload(configuration)
      ..sign(configuration);

    final String jwt = signature.build().toCompactSerialization();

    _token = jwt;

    return request(
      <String, String>{
        'Authorization': 'Bearer $jwt',
        'content-type': 'application/json',
      },
      httpClient,
    );
  }
}

///
extension _JWTExtension on JsonWebSignatureBuilder {
  void addHeader(final RunConfiguration configuration) {
    setProtectedHeader('typ', 'JWT');

    setProtectedHeader('kid', configuration.iosAppStoreConnectKeyId);
  }

  void addPayload(final RunConfiguration configuration) {
    final String issuer = configuration.iosAppStoreConnectKeyIssuer;

    final double inSeconds =
        DateTime.now().add(_defaultJwtTokenExp).millisecondsSinceEpoch / 1000;

    final JsonWebTokenClaims claims = JsonWebTokenClaims.fromJson(
      <String, Object>{
        'iss': issuer,
        'exp': inSeconds.round(),
        'aud': 'appstoreconnect-v1'
      },
    );

    jsonContent = claims.toJson();
  }

  void sign(final RunConfiguration configuration) {
    final File privateKey = configuration.iosAppStoreConnectKey;

    if (!privateKey.existsSync()) {
      throw ArgumentError('AppStoreConnect api key file not found');
    }

    final String privateKeyContent = privateKey.readAsStringSync();

    addRecipient(
      JsonWebKey.fromPem(
        privateKeyContent,
        keyId: configuration.iosAppStoreConnectKeyId,
      ),
      algorithm: 'ES256',
    );
  }
}
