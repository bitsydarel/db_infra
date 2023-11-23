import 'dart:convert';
import 'dart:io';

import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/utils/utils.dart';
import 'package:http/http.dart';
import 'package:jose/jose.dart';
import 'package:meta/meta.dart';

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
  final Configuration configuration;

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
  void addHeader(final Configuration configuration) {
    setProtectedHeader('typ', 'JWT');

    setProtectedHeader('kid', configuration.iosAppStoreConnectKeyId);
  }

  void addPayload(final Configuration configuration) {
    final String issuer = configuration.iosAppStoreConnectKeyIssuer;

    final double issuedAtInSeconds =
        DateTime.now().millisecondsSinceEpoch / 1000;

    final double expireAtInSeconds =
        DateTime.now().add(_defaultJwtTokenExp).millisecondsSinceEpoch / 1000;

    final JsonWebTokenClaims claims = JsonWebTokenClaims.fromJson(
      <String, Object>{
        'iss': issuer,
        'iat': issuedAtInSeconds.round(),
        'exp': expireAtInSeconds.round(),
        'aud': 'appstoreconnect-v1'
      },
    );

    jsonContent = claims.toJson();
  }

  void sign(final Configuration configuration) {
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

///
extension ResponseExtensions on Response {
  ///
  String asError() {
    final StringBuffer builder = StringBuffer();

    final Map<String, String>? requestHeader = request?.headers;

    if (requestHeader != null) {
      builder
        ..writeln('REQUEST HEADERS:')
        ..writeln(
          requestHeader.entries.map((MapEntry<String, String> keyValue) {
            return base64Encode(
              utf8.encode('${keyValue.key}: ${keyValue.value}'),
            );
          }).join('\n'),
        );
    }

    builder
      ..writeln('RESPONSE HEADERS:')
      ..writeln(
        headers.entries.map((MapEntry<String, String> keyValue) {
          return '${keyValue.key}: ${keyValue.value}';
        }).join('\n'),
      )
      ..writeln('RESPONSE STATUS CODE: $statusCode')
      ..writeln('RESPONSE BODY:')
      ..writeln(body);

    return builder.toString();
  }
}
