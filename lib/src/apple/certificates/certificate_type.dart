///
enum CertificateType {
  ///
  iosDevelopment,

  ///
  development,

  ///
  iosDistribution,

  ///
  distribution,

  ///
  other,
}

const String _iosDevelopmentKey = 'IOS_DEVELOPMENT';
const String _developmentKey = 'DEVELOPMENT';
const String _iosDistributionKey = 'IOS_DISTRIBUTION';
const String _distributionKey = 'DISTRIBUTION';
const String _otherKey = 'OTHER';

///
extension StringCertificateTypeExtension on String {
  ///
  CertificateType fromKey() {
    for (final CertificateType type in CertificateType.values) {
      if (type.key == this) {
        return type;
      }
    }

    return CertificateType.other;
  }
}

///
extension CertificateTypeExtension on CertificateType {
  ///
  String get key {
    switch (this) {
      case CertificateType.iosDevelopment:
        return _iosDevelopmentKey;
      case CertificateType.development:
        return _developmentKey;
      case CertificateType.iosDistribution:
        return _iosDistributionKey;
      case CertificateType.distribution:
        return _distributionKey;
      case CertificateType.other:
        return _otherKey;
    }
  }
}
