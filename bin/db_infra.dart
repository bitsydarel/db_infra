import 'dart:io';

import 'package:db_infra/db_infra.dart';
import 'package:db_infra/src/infra_managers/disk_infra_manager.dart';
import 'package:db_infra/src/run_configuration.dart';
import 'package:db_infra/src/infra_configuration.dart';
import 'package:db_infra/src/setup_executors/ios_setup_executor.dart';
import 'package:db_infra/src/software_builders/apple/api/appstoreconnectapi_certificates.dart';
import 'package:db_infra/src/software_builders/apple/api/appstoreconnectapi_bundle_id.dart';
import 'package:db_infra/src/software_builders/apple/api/appstoreconnectapi_profiles.dart';
import 'package:db_infra/src/software_builders/flutter_ios_build_executor.dart';
import 'package:db_infra/src/software_builders/apple/certificates_manager.dart';
import 'package:db_infra/src/software_builders/apple/bundle_id_manager.dart';
import 'package:db_infra/src/software_builders/apple/keychains_manager.dart';
import 'package:db_infra/src/software_builders/apple/profiles_manager.dart';
import 'package:db_infra/src/utils/constants.dart';
import 'package:db_infra/src/utils/network_manager.dart';
import 'package:args/args.dart';

Future<void> main(List<String> arguments) async {
  final RunConfiguration configuration;

  try {
    final ArgResults argResult = argumentParser.parse(arguments);

    if (argResult.wasParsed(helpArgument)) {
      printHelpMessage();
      exitCode = 0;
      return;
    }

    if (argResult.runSetup && argResult.runBuild) {
      throw const FormatException(
        "Can't run --$setupProjectArg with --$buildProjectArg",
      );
    }

    if (!argResult.runSetup && !argResult.runBuild) {
      throw const FormatException(
        '--$setupProjectArg or '
        '--$buildProjectArg need to be specified',
      );
    }

    configuration = argResult.runSetup
        ? argResult.toSetupConfiguration()
        : await argResult.toBuildConfiguration();
  } on Exception catch (e) {
    printHelpMessage(e is FormatException ? e.message : null);
    return;
  }

  final KeychainsManager keychainsManager =
      KeychainsManager(appKeychain: configuration.iosAppId);

  final ProfilesManager profilesManager = ProfilesManager(
    api: AppStoreConnectApiProfiles(
      configuration: configuration,
      httpClient: networkManager,
    ),
  );

  final CertificatesManager certificatesManager = CertificatesManager(
    keychainsManager: keychainsManager,
    httpClient: networkManager,
    api: AppStoreConnectApiCertificates(
      httpClient: networkManager,
      configuration: configuration,
    ),
  );

  if (configuration is SetupConfiguration) {
    final BundleIdManager bundleIdManager = BundleIdManager(
      api: AppStoreConnectApiBundleId(
        configuration: configuration,
        httpClient: networkManager,
      ),
    );

    final IosSetupExecutor iosSetupExecutor = IosSetupExecutor(
      configuration: configuration,
      profilesManager: profilesManager,
      certificatesManager: certificatesManager,
      bundleIdManager: bundleIdManager,
    );

    final InfraConfiguration infraConfiguration =
        await iosSetupExecutor.setupInfra();

    final DiskInfraManager infraManager = DiskInfraManager(
      projectDir: configuration.projectDir,
      storageDirectory: Directory('${Directory.current.path}/.infra_tools'),
    );

    await infraManager.saveConfiguration(infraConfiguration);
  } else if (configuration is InfraConfiguration) {
    final FlutterIosBuildExecutor executor = FlutterIosBuildExecutor(
      configuration: configuration,
      certificatesManager: certificatesManager,
      profilesManager: profilesManager,
    );

    await executor.build();
  }
}

SetupConfiguration _createDemoConfiguration({final bool teg = false}) {
  const String appId = 'com.infra.example';

  if (teg) {
    return SetupConfiguration(
      projectDir: Directory('${Directory.current.path}/example'),
      iosAppId: appId,
      androidAppId: appId,
      iosAppStoreConnectKeyId: 'X77F74SH94',
      iosAppStoreConnectKeyIssuer: '69a6de90-4155-47e3-e053-5b8c7c11a4d1',
      iosAppStoreConnectKey: File('keys/app_store_connect_api_key.p8'),
      iosCertificateSigningRequestEmail:
          'darel.bitsy@transportgroupexchange.com',
      iosCertificateSigningRequestName: 'Darel Bitsy',
    );
  } else {
    return SetupConfiguration(
      projectDir: Directory('${Directory.current.path}/example'),
      iosAppId: appId,
      androidAppId: appId,
      iosAppStoreConnectKeyId: 'A4FTFYJ5FW',
      iosAppStoreConnectKeyIssuer: '71f7317b-4ac9-4073-a21d-936e37f728da',
      iosAppStoreConnectKey: File('keys/AuthKey_A4FTFYJ5FW.p8'),
      iosCertificateSigningRequestEmail: 'bitsydarel@gmail.com',
      iosCertificateSigningRequestName: 'Darel Bitsy',
    );
  }
}
