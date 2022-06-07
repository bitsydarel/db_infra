import 'dart:io';

import 'package:db_infra/src/apple/bundle_id/api/appstoreconnectapi_bundle_id.dart';
import 'package:db_infra/src/apple/bundle_id/bundle_id_manager.dart';
import 'package:db_infra/src/apple/certificates/api/appstoreconnectapi_certificates.dart';
import 'package:db_infra/src/apple/certificates/certificates_manager.dart';
import 'package:db_infra/src/apple/certificates/keychains_manager.dart';
import 'package:db_infra/src/apple/device/api/appstoreconnectapi_devices.dart';
import 'package:db_infra/src/apple/device/device_manager.dart';
import 'package:db_infra/src/apple/provision_profile/api/appstoreconnectapi_profiles.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile_manager.dart';
import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/utils/network_manager.dart';

///
extension RunConfigurationExtensions on Configuration {
  ///
  ProvisionProfileManager getProfilesManager(
    CertificatesManager certificatesManager,
    Directory infraDirectory,
    Logger logger,
  ) {
    return ProvisionProfileManager(
      certificatesManager,
      infraDirectory,
      logger,
      AppStoreConnectApiProfiles(
        configuration: this,
        httpClient: networkManager,
      ),
    );
  }

  ///
  CertificatesManager getCertificatesManager(Logger logger) {
    final KeychainsManager keychainsManager =
        KeychainsManager(appKeychain: iosAppId, logger: logger);

    return CertificatesManager(
      keychainsManager,
      logger,
      AppStoreConnectApiCertificates(
        configuration: this,
        httpClient: networkManager,
      ),
    );
  }

  ///
  BundleIdManager getBundleManager() {
    return BundleIdManager(
      AppStoreConnectApiBundleId(
        configuration: this,
        httpClient: networkManager,
      ),
    );
  }

  ///
  DeviceManager getDeviceManager() {
    return DeviceManager(
      AppStoreConnectApiDevices(
        configuration: this,
        httpClient: networkManager,
      ),
    );
  }
}
