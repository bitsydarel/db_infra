///
class Certificate {
  ///
  static const String iosDistribution = 'IOS_DISTRIBUTION';

  ///
  static const String appleDistribution = 'DISTRIBUTION';

  ///
  static const String certificateType = 'certificates';

  ///
  final String id;

  ///
  final String type;

  ///
  final String name;

  ///
  final String serialNumber;

  ///
  final DateTime expireAt;

  ///
  final String content;

  ///
  const Certificate({
    required this.id,
    required this.type,
    required this.name,
    required this.expireAt,
    required this.content,
    required this.serialNumber,
  });

  ///
  bool isDistribution() => type == iosDistribution || type == appleDistribution;

  ///
  bool hasExpired() {
    final DateTime now = DateTime.now();

    return now.isAfter(expireAt);
  }

  @override
  String toString() {
    return 'Certificate{id: $id, type: $type, name: $name, '
        'serialNumber: $serialNumber, expireAt: $expireAt, content: $content}';
  }
}
