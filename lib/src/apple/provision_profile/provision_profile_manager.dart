import 'dart:convert';
import 'dart:io';

import 'package:db_infra/src/apple/bundle_id/bundle_id.dart';
import 'package:db_infra/src/apple/certificates/certificate.dart';
import 'package:db_infra/src/apple/certificates/certificates_manager.dart';
import 'package:db_infra/src/apple/device/device.dart';
import 'package:db_infra/src/apple/provision_profile/api/appstoreconnectapi_profiles.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile_type.dart';
import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/shell_runner.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;

///
class ProvisionProfileManager {
  ///
  final AppStoreConnectApiProfiles _api;

  ///
  final CertificatesManager certificatesManager;

  ///
  final Logger logger;

  ///
  final ShellRunner runner;

  ///
  final Directory _infraDirectory;

  ///
  const ProvisionProfileManager(
    this.certificatesManager,
    this._infraDirectory,
    this.logger,
    this._api, {
    this.runner = const ShellRunner(),
  });

  Directory? _getLocalProfileDirectory() {
    final String? homeDir = Platform.environment['HOME'];

    if (homeDir == null || homeDir.trim().isEmpty) {
      return null;
    }

    return Directory(
      path.join(homeDir, 'Library', 'MobileDevice', 'Provisioning Profiles'),
    )..createSync(recursive: true);
  }

  ///
  void importProvisionProfileLocally(final ProvisionProfile profile) {
    logger.logInfo(
      'Adding Provision profile ${profile.name} - ${profile.uuid} locally...',
    );

    final Directory? provisionProfileDirectory = _getLocalProfileDirectory();

    if (provisionProfileDirectory != null) {
      File(
        path.join(
          provisionProfileDirectory.path,
          '${profile.uuid}.mobileprovision',
        ),
      ).writeAsBytesSync(base64.decode(profile.content), flush: true);
    } else {
      throw UnrecoverableException(
        'HOME environment argument is not set',
        ExitCode.cantCreate.code,
      );
    }

    logger.logSuccess(
      'Added Provision Profile ${profile.name} - ${profile.uuid} locally.',
    );
  }

  ///
  void deleteProvisionProfileLocally(final ProvisionProfile profile) {
    logger.logInfo(
      'Removing Provision Profile ${profile.name} - ${profile.uuid} locally...',
    );

    final Directory? provisionProfileDirectory = _getLocalProfileDirectory();

    if (provisionProfileDirectory != null) {
      File(
        path.join(
          provisionProfileDirectory.path,
          '${profile.uuid}.mobileprovision',
        ),
      ).deleteSync();
    } else {
      throw UnrecoverableException(
        'HOME environment argument is not set',
        ExitCode.cantCreate.code,
      );
    }

    logger.logSuccess(
      'Removed Provision Profile ${profile.name} - ${profile.uuid} locally.',
    );
  }

  ///
  Future<ProvisionProfile?> getProfileWithName(final String name) async {
    final List<ProvisionProfile> profiles = await _api.getAll();

    for (final ProvisionProfile profile in profiles) {
      if (profile.name == name) {
        return profile;
      }
    }

    return null;
  }

  ///
  Future<ProvisionProfile> createProvisionProfile(
    final BundleId bundleId,
    final List<Certificate> certificates,
    final List<Device> devices,
    final ProvisionProfileType profileType,
  ) async {
    final List<ProvisionProfile> profiles = await _api.getAll();

    for (final ProvisionProfile profile in profiles) {
      if (profile.bundleId.id == bundleId.id && profile.type == profileType) {
        await _api.delete(profile.id);
      }
    }

    return _api.create(profileType, bundleId, certificates, devices);
  }

  ///
  File exportOptionsPlist(
    final String appId,
    final ProvisionProfile provisionProfile, {
    final String? certificateSha1,
  }) {
    final StringBuffer builder = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln(
        '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
        '"https://www.apple.com/DTDs/PropertyList-1.0.dtd">',
      )
      ..writeln('<plist version="1.0">')
      ..writeln('<dict>')
      ..writeln('<key>uploadSymbols</key>')
      ..writeln('<true/>')
      ..writeln('<key>uploadBitcode</key>')
      ..writeln('<false/>')
      ..writeln('<key>provisioningProfiles</key>')
      ..writeln('<dict>')
      ..writeln('<key>$appId</key>')
      ..writeln('<string>${provisionProfile.name}</string>')
      ..writeln('</dict>');

    if (certificateSha1 != null) {
      builder
        ..writeln('<key>signingCertificate</key>')
        ..writeln('<string>$certificateSha1</string>');
    }

    builder
      ..writeln('<key>signingStyle</key>')
      ..writeln('<string>manual</string>')
      ..writeln('<key>destination</key>')
      ..writeln('<string>export</string>')
      ..writeln('<key>method</key>')
      ..writeln('<string>${provisionProfile.type.exportMethod}</string>')
      ..writeln('</dict>')
      ..writeln('</plist>');

    return File(path.join(_infraDirectory.path, 'ExportOptions.plist'))
      ..writeAsStringSync(builder.toString(), flush: true);
  }

  ///
  Future<void> deleteProvisionProfile(ProvisionProfile provisionProfile) {
    return _api.delete(provisionProfile.id);
  }

  ///
  Future<List<ProvisionProfile>> getAllProvisionProfiles() {
    return _api.getAll();
  }

  ///
  Future<Certificate?> getValidCertificate(ProvisionProfile profile) async {
    for (final ProvisionProfileRelation relation in profile.certificates) {
      final Certificate? certificate =
          await certificatesManager.getCertificate(relation.id);

      if (certificate != null) {
        final bool isDevelopmentOrDistribution =
            certificate.isDevelopment() || certificate.isDistribution();

        final bool hasExpired = certificate.hasExpired();

        if (isDevelopmentOrDistribution || !hasExpired) {
          return certificate;
        }
      }
    }
    return null;
  }
}
