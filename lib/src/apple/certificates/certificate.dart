import 'package:db_infra/src/apple/certificates/certificate_type.dart';

///
class Certificate {
  ///
  static const String certificateType = 'certificates';

  ///
  final String id;

  ///
  final String name;

  ///
  final String serialNumber;

  ///
  final DateTime expireAt;

  ///
  final CertificateType type;

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

  @override
  String toString() {
    return 'Certificate{id: $id, type: $type, name: $name, '
        'serialNumber: $serialNumber, expireAt: $expireAt, content: $content}';
  }
}

///
extension CertificateExtension on Certificate {
  ///
  bool hasExpired() {
    final DateTime now = DateTime.now();

    return now.isAfter(expireAt);
  }

  ///
  bool isDistribution() {
    return type == CertificateType.distribution ||
        type == CertificateType.iosDistribution;
  }

  ///
  bool isDevelopment() {
    return type == CertificateType.development ||
        type == CertificateType.iosDevelopment;
  }
}
