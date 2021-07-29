import 'dart:io';

import 'package:db_infra/db_infra.dart';
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

  final ProfilesManager profilesManager = configuration.getProfilesManager();

  final CertificatesManager certificatesManager =
      configuration.getCertificatesManager();

  if (configuration is SetupConfiguration) {
    final BundleIdManager bundleIdManager = configuration.getBundleManager();

    final IosSetupExecutor iosSetupExecutor = IosSetupExecutor(
      configuration: configuration,
      profilesManager: profilesManager,
      certificatesManager: certificatesManager,
      bundleIdManager: bundleIdManager,
    );

    final InfraConfiguration infraConfiguration =
        await iosSetupExecutor.setupInfra();

    final InfraManager infraManager = configuration.getInfraManager();

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
