///
class BundleId {
  ///
  static const String bundleIdTypes = 'bundleIds';

  ///
  final String id;

  ///
  final String name;

  ///
  final String platform;

  ///
  final String identifier;

  ///
  final String seedId;

  ///
  const BundleId({
    required this.id,
    required this.name,
    required this.platform,
    required this.identifier,
    required this.seedId,
  });

  @override
  String toString() {
    return 'BundleId{id: $id, name: $name, platform: $platform, '
        'identifier: $identifier, seedId: $seedId}';
  }
}
