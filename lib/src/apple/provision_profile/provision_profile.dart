import 'package:db_infra/src/apple/provision_profile/provision_profile_type.dart';
import 'package:meta/meta.dart';

///
@immutable
class ProvisionProfile {
  ///
  static const String profileType = 'profiles';

  ///
  final String id;

  ///
  final ProvisionProfileType type;

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
  final ProvisionProfileRelation bundleId;

  ///
  final List<ProvisionProfileRelation> certificates;

  ///
  final List<ProvisionProfileRelation> devices;

  ///
  const ProvisionProfile({
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

  @override
  String toString() {
    return 'Profile{id: $id, type: $type, name: $name, uuid: $uuid, '
        'createdDate: $createdDate, expirationDate: $expirationDate, '
        'content: $content, state: $state, platform: $platform, '
        'certificates: $certificates, bundleId: $bundleId, devices: $devices}';
  }
}

///
class ProvisionProfileRelation {
  ///
  final String id;

  ///
  const ProvisionProfileRelation({required this.id});

  @override
  String toString() => 'ProfileCertificate{id: $id}';
}
