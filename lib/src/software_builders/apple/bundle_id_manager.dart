import 'package:db_infra/src/shell_runner.dart';
import 'package:db_infra/src/software_builders/apple/api/appstoreconnectapi_bundle_id.dart';
import 'package:db_infra/src/software_builders/apple/bundle_id.dart';

///
class BundleIdManager {
  ///
  final ShellRunner runner;

  ///
  final AppStoreConnectApiBundleId api;

  ///
  const BundleIdManager({
    required this.api,
    this.runner = const ShellRunner(),
  });

  ///
  Future<BundleId?> getBundleId(final String appId) async {
    final List<BundleId> bundleIds = await api.getAll();

    for (final BundleId bundleId in bundleIds) {
      if (bundleId.identifier == appId) {
        return bundleId;
      }
    }

    return null;
  }

  ///
  Future<BundleId> getOrCreateBundleId(final String appId) async {
    final BundleId? bundleId = await getBundleId(appId);

    return bundleId ?? await api.create('Flutter iOS ${appId.split('.').last}');
  }
}
