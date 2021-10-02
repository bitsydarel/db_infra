import 'dart:convert';
import 'dart:io';

import 'package:db_infra/src/apis/apple/api/appstoreconnectapi_profiles.dart';
import 'package:db_infra/src/apis/apple/bundle_id.dart';
import 'package:db_infra/src/apis/apple/certificate.dart';
import 'package:db_infra/src/apis/apple/device.dart';
import 'package:db_infra/src/apis/apple/profile.dart';
import 'package:db_infra/src/shell_runner.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';

///
class ProfilesManager {
  ///
  final AppStoreConnectApiProfiles api;

  ///
  final ShellRunner runner;

  ///
  const ProfilesManager({
    required this.api,
    this.runner = const ShellRunner(),
  });

  ///
  Future<void> importProfile(final Profile profile) async {
    final String? homeDir = Platform.environment['HOME'];

    if (homeDir != null && homeDir.trim().isNotEmpty) {
      File(
        '$homeDir/Library/MobileDevice/'
        'Provisioning Profiles/${profile.uuid}.mobileprovision',
      ).writeAsBytesSync(base64.decode(profile.content), flush: true);
    } else {
      throw UnrecoverableException(
        'HOME environment argument is not set',
        ExitCode.cantCreate.code,
      );
    }

    stdout.writeln(
      green.wrap(
        'Added profile ${profile.name} - ${profile.uuid}  to computer',
      ),
    );
  }

  ///
  Future<Profile?> getProfileWithUUID(final String uuid) async {
    final List<Profile> profiles = await api.getAll();

    for (final Profile profile in profiles) {
      if (profile.uuid == uuid) {
        return profile;
      }
    }

    return null;
  }

  ///
  Future<Profile> reCreateDistribution(
    final BundleId bundleId,
    final List<Certificate> certificates,
    final List<Device> devices,
  ) async {
    final List<Profile> profiles = await api.getAll();

    for (final Profile profile in profiles) {
      if (profile.bundleId.id == bundleId.id) {
        await api.delete(profile.id);
      }
    }

    return api.create(bundleId, certificates, devices);
  }
}
