import 'package:db_infra/src/apple/bundle_id/api/appstoreconnectapi_bundle_id.dart';
import 'package:db_infra/src/apple/bundle_id/bundle_id.dart';
import 'package:db_infra/src/shell_runner.dart';

///
class BundleIdManager {
  ///
  final ShellRunner runner;

  ///
  final AppStoreConnectApiBundleId _api;

  ///
  const BundleIdManager(this._api, {this.runner = const ShellRunner()});

  ///
  Future<BundleId?> getBundleIdByAppId(final String appId) async {
    final List<BundleId> bundleIds = await _api.getAll();

    for (final BundleId bundleId in bundleIds) {
      if (bundleId.identifier == appId) {
        return bundleId;
      }
    }
    return null;
  }

  ///
  Future<BundleId?> getBundleId(final String bundleId) {
    return _api.get(bundleId);
  }

  ///
  Future<BundleId> getOrCreateBundleId(final String appId) async {
    final BundleId? bundleId = await getBundleIdByAppId(appId);

    return bundleId ??
        await _api.create('Flutter iOS ${appId.split('.').last}');
  }

  ///
  Future<List<BundleId>> getAll() {
    return _api.getAll();
  }
}
