/// Apple Provision profile type.
enum ProvisionProfileType {
  ///
  iosAppDevelopment,

  ///
  iosAppStore,

  ///
  iosAppAdhoc,

  ///
  iosAppInHouse,

  ///
  other
}

///
extension ProvisionProfileTypeExtension on ProvisionProfileType {
  /// Get the provision profile apple key.
  String get key {
    switch (this) {
      case ProvisionProfileType.iosAppDevelopment:
        return 'IOS_APP_DEVELOPMENT';
      case ProvisionProfileType.iosAppStore:
        return 'IOS_APP_STORE';
      case ProvisionProfileType.iosAppAdhoc:
        return 'IOS_APP_ADHOC';
      case ProvisionProfileType.iosAppInHouse:
        return 'IOS_APP_INHOUSE';
      case ProvisionProfileType.other:
        return 'OTHER';
    }
  }

  ///
  bool isDevelopment() {
    switch (this) {
      case ProvisionProfileType.iosAppDevelopment:
        return true;
      case ProvisionProfileType.iosAppStore:
      case ProvisionProfileType.iosAppAdhoc:
      case ProvisionProfileType.iosAppInHouse:
      case ProvisionProfileType.other:
        return false;
    }
  }

  ///
  bool isDistribution() {
    switch (this) {
      case ProvisionProfileType.iosAppDevelopment:
      case ProvisionProfileType.other:
        return false;
      case ProvisionProfileType.iosAppStore:
      case ProvisionProfileType.iosAppAdhoc:
      case ProvisionProfileType.iosAppInHouse:
        return false;
    }
  }

  ///
  String get exportMethod {
    switch (this) {
      case ProvisionProfileType.iosAppDevelopment:
        return 'development';
      case ProvisionProfileType.iosAppStore:
        return 'app-store';
      case ProvisionProfileType.iosAppAdhoc:
        return 'ad-hoc';
      case ProvisionProfileType.iosAppInHouse:
        return 'enterprise';
      case ProvisionProfileType.other:
        return '';
    }
  }
}

///
extension StringProvisionProfileTypeExtension on String {
  ///
  ProvisionProfileType fromKey() {
    for (final ProvisionProfileType type in ProvisionProfileType.values) {
      if (type.key == this) {
        return type;
      }
    }

    return ProvisionProfileType.other;
  }
}
