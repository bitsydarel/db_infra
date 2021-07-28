import 'dart:io';

import 'package:meta/meta.dart';

///
@immutable
class Profile {
  ///
  static const String profileType = 'profiles';

  ///
  final String id;

  ///
  final ProfileType type;

  ///
  final String name;

  ///
  final String uuid;

  ///
  final DateTime createdDate;

  ///
  final DateTime expirationDate;

  ///
  final String content;

  ///
  final String state;

  ///
  final String? platform;

  ///
  final ProfileRelation bundleId;

  ///
  final List<ProfileRelation> certificates;

  ///
  final List<ProfileRelation> devices;

  ///
  const Profile({
    required this.id,
    required this.type,
    required this.name,
    required this.uuid,
    required this.createdDate,
    required this.expirationDate,
    required this.content,
    required this.state,
    required this.bundleId,
    required this.certificates,
    required this.devices,
    this.platform,
  });

  ///
  static ProfileType toProfileType(final String type) {
    switch (type) {
      case 'IOS_APP_DEVELOPMENT':
        return ProfileType.iosAppDevelopment;
      case 'IOS_APP_STORE':
        return ProfileType.iosAppStore;
      default:
        return ProfileType.invalid;
    }
  }

  @override
  String toString() {
    return 'Profile{id: $id, type: $type, name: $name, uuid: $uuid, '
        'createdDate: $createdDate, expirationDate: $expirationDate, '
        'content: $content, state: $state, platform: $platform, '
        'certificates: $certificates, bundleId: $bundleId, devices: $devices}';
  }
}

///
class ProfileRelation {
  ///
  final String id;

  ///
  const ProfileRelation({required this.id});

  @override
  String toString() => 'ProfileCertificate{id: $id}';
}

///
enum ProfileType {
  ///
  iosAppDevelopment,

  ///
  iosAppStore,

  ///
  invalid
}

///
extension ProfileExtension on Profile {
  ///
  File generateExportOptionsPlist(
    final String appId, {
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
      ..writeln('<false/>');

    addProvisioningProfiles(appId, builder);

    if (certificateSha1 != null) {
      addSigningCertificate(certificateSha1, builder);
    }

    builder
      ..writeln('<key>signingStyle</key>')
      ..writeln('<string>manual</string>')
      ..writeln('<key>destination</key>')
      ..writeln('<string>export</string>')
      ..writeln('<key>method</key>')
      ..writeln('<string>app-store</string>')
      ..writeln('</dict>')
      ..writeln('</plist>');

    return File('ExportOptions.plist')..writeAsStringSync(builder.toString());
  }

  ///
  void addProvisioningProfiles(final String appId, final StringBuffer buffer) {
    buffer
      ..writeln('<key>provisioningProfiles</key>')
      ..writeln('<dict>')
      ..writeln('<key>$appId</key>')
      ..writeln('<string>$uuid</string>')
      ..writeln('</dict>');
  }

  ///
  void addSigningCertificate(
    final String certificateSha1,
    final StringBuffer buffer,
  ) {
    buffer
      ..writeln('<key>signingCertificate</key>')
      ..writeln('<string>$certificateSha1</string>');
  }
}
