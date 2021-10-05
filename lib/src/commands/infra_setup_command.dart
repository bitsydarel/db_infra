import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:db_infra/src/apple/bundle_id/bundle_id_manager.dart';
import 'package:db_infra/src/apple/certificates/certificates_manager.dart';
import 'package:db_infra/src/apple/device/device_manager.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile_manager.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile_type.dart';
import 'package:db_infra/src/build_output_type.dart';
import 'package:db_infra/src/commands/base_command.dart';
import 'package:db_infra/src/configurations/infra_build_configuration.dart';
import 'package:db_infra/src/configurations/infra_setup_configuration.dart';
import 'package:db_infra/src/encryptor.dart';
import 'package:db_infra/src/encryptor_type.dart';
import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/setup_executors/ios_setup_executor.dart';
import 'package:db_infra/src/storage.dart';
import 'package:db_infra/src/storage_type.dart';
import 'package:db_infra/src/utils/constants.dart';
import 'package:db_infra/src/utils/file_utils.dart';
import 'package:db_infra/src/utils/infra_extensions.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:meta/meta.dart';

///
class InfraSetupCommand extends BaseCommand {
  ///
  InfraSetupCommand() {
    argParser
      ..addOption(
        appIdArg,
        help: 'Specify the application id, '
            'that will be used for both iOS & Android.',
      )
      ..addOption(
        androidAppIdArg,
        help: 'Specify the android application id that '
            'will be used for distribution.',
      )
      ..addOption(
        iosAppIdArg,
        help: 'Specify the iOS application id (Bundle id), that '
            'will be used for distribution.',
      )
      ..addOption(
        iosAppStoreConnectKeyIdArg,
        help: 'Specify the AppStoreConnect API Key id.',
      )
      ..addOption(
        iosAppStoreConnectKeyIssuerArg,
        help: 'Specify the AppStoreConnect API Key Issuer.',
      )
      ..addOption(
        iosAppStoreConnectKeyPathArg,
        help: 'Specify the AppStoreConnect Key path.',
      )
      ..addOption(
        iosAppStoreConnectKeyBase64Arg,
        help: 'Specify the AppStoreConnect Key as Base64 encoded.',
      )
      ..addOption(
        iosCertificateSigningRequestPathArg,
        help: 'Specify the Certificate Signing Request (CSR) path.',
      )
      ..addOption(
        iosCertificateSigningRequestBase64Arg,
        help:
            'Specify the Certificate Signing Request (CSR) as base64 encoded.',
      )
      ..addOption(
        iosCertificateSigningRequestPrivateKeyPathArg,
        help: 'Specify the Certificate Signing Request (CSR) Private Key path.',
      )
      ..addOption(
        iosCertificateSigningRequestPrivateKeyBase64Arg,
        help: 'Specify the Certificate Signing Request (CSR) '
            'Private Key as base64.',
      )
      ..addOption(
        iosCertificateSigningRequestEmailArg,
        help: 'Specify the Certificate Signing Request (CSR) Email.'
            '\nWill be used to create a new CSR',
      )
      ..addOption(
        iosCertificateSigningRequestNameArg,
        help: 'Specify the Certificate Signing Request (CSR) Name.'
            '\nWill be used to create a new CSR',
      )
      ..addOption(
        iosProvisionProfileIdArg,
        help: 'Specify the distribution provision profile id to use.',
      )
      ..addOption(
        iosProvisionProfileTypeArg,
        allowed: ProvisionProfileType.values
            .map((ProvisionProfileType e) => e.key)
            .toList(),
        help: 'Specify the distribution provision profile type to use.',
      )
      ..addOption(
        iosCertificateIdArg,
        help: 'Specify the Distribution certificate id.',
      )
      ..addOption(
        infraStorageTypeArg,
        help: 'Specify the infrastructure storage type',
        allowed: StorageType.values.map(enumName),
        defaultsTo: enumName(StorageType.disk),
      )
      ..addOption(
        infraEncryptorTypeArg,
        help: 'Specify the infrastructure encryptor type',
        allowed: EncryptorType.values.map(enumName),
        defaultsTo: EncryptorType.base64.name,
      )
      ..addOption(
        infraDiskStorageLocationArg,
        help: 'Specify the infrastructure disk storage location',
        defaultsTo: '.infra_disk_storage',
      )
      ..addOption(
        infraIosBuildOutputTypeArg,
        help: 'Specify the infrastructure ios build output type',
        allowed: IosBuildOutputType.values.map(enumName),
        defaultsTo: IosBuildOutputType.ipa.name,
      )
      ..addOption(
        infraAndroidBuildOutputTypeArg,
        help: 'Specify the infrastructure android build output type',
        allowed: AndroidBuildOutputType.values.map(enumName),
        defaultsTo: AndroidBuildOutputType.apk.name,
      )
      ..addOption(
        infraFtpUsernameArg,
        help: 'Specify the infrastructure ftp storage username',
      )
      ..addOption(
        infraFtpPasswordArg,
        help: 'Specify the infrastructure ftp storage password',
      )
      ..addOption(
        infraFtpUrlArg,
        help: 'Specify the infrastructure ftp storage server url',
      )
      ..addOption(
        infraFtpPortArg,
        help: 'Specify the infrastructure ftp storage server port',
        defaultsTo: '21',
      )
      ..addOption(
        infraFtpFolderNameArg,
        help: 'Specify the infrastructure ftp storage folder name.',
      );
  }

  @override
  String get name => 'setup';

  @override
  String get description => 'Setup the infrastructure';

  @override
  FutureOr<void> run() async {
    final ArgResults globalArgs = globalResults!;
    final ArgResults commandArgs = argResults!;

    final Logger logger =
        Logger(enableLogging: globalArgs.isVerbosityEnabled());

    final File configurationFile = globalArgs.getConfigurationFile();

    final Directory projectDir = commandArgs.getProjectDirectory();

    final Directory infraDir = projectDir.createInfraDirectory();

    final InfraSetupConfiguration configuration = parseConfigurationArguments(
      commandArgs,
      infraDir,
      logger,
    );

    final CertificatesManager certificatesManager =
        configuration.getCertificatesManager(logger);

    final ProvisionProfileManager profilesManager =
        configuration.getProfilesManager(certificatesManager, infraDir, logger);

    final BundleIdManager bundleIdManager = configuration.getBundleManager();

    final DeviceManager deviceManager = configuration.getDeviceManager();

    final IosSetupExecutor iosSetupExecutor = IosSetupExecutor(
      configuration: configuration,
      infraDirectory: infraDir,
      profilesManager: profilesManager,
      certificatesManager: certificatesManager,
      bundleIdManager: bundleIdManager,
      deviceManager: deviceManager,
      logger: logger,
    );

    logger.logInfo(
      'Setting up ios infrastructure for ${configuration.iosAppId}...',
    );

    final InfraBuildConfiguration buildConfiguration =
        await iosSetupExecutor.setupInfra();

    final List<File> filesToEncrypt = <File>[
      buildConfiguration.iosCertificateSigningRequest,
      buildConfiguration.iosCertificateSigningRequestPrivateKey,
      buildConfiguration.iosExportOptionsPlist,
      buildConfiguration.iosAppStoreConnectKey,
    ];

    final List<File> encryptedFiles =
        await configuration.encryptor.encryptFiles(filesToEncrypt);

    await buildConfiguration.storage.saveFiles(encryptedFiles);

    await saveConfiguration(buildConfiguration, configurationFile);

    logger.logInfo(
      'Set up ios infrastructure for ${configuration.iosAppId} '
      'completed: ${configurationFile.path}',
    );

    await cleanup(configuration, infraDir);
  }

  ///
  @visibleForTesting
  InfraSetupConfiguration parseConfigurationArguments(
    ArgResults commandArgs,
    Directory infraDir,
    Logger logger,
  ) {
    final String? appId = commandArgs.parseOptionalString(appIdArg);

    String? androidAppId = commandArgs.parseOptionalString(androidAppIdArg);
    String? iOSAppId = commandArgs.parseOptionalString(iosAppIdArg);

    if (appId != null) {
      if (androidAppId != null || iOSAppId != null) {
        throw const FormatException(
          "$appIdArg can't be specified alongside with "
          '$androidAppIdArg or $iosAppIdArg',
        );
      }

      androidAppId = appId;
      iOSAppId = appId;
    }

    if (appId == null && (iOSAppId == null || androidAppId == null)) {
      throw const FormatException(
        '$appIdArg need to be specified or '
        'both $androidAppIdArg and $iosAppIdArg',
      );
    }

    final String iOSAppStoreConnectKeyId =
        commandArgs.parseString(iosAppStoreConnectKeyIdArg);

    final String iOSAppStoreConnectKeyIssuer =
        commandArgs.parseString(iosAppStoreConnectKeyIssuerArg);

    final File iosAppStoreConnectKeyPath =
        parseIosAppStoreConnectKeyPath(iOSAppId!);

    final String? iosCSREmail =
        commandArgs.parseOptionalString(iosCertificateSigningRequestEmailArg);

    final String? iosCSRName =
        commandArgs.parseOptionalString(iosCertificateSigningRequestNameArg);

    if ((iosCSREmail == null && iosCSRName != null) ||
        (iosCSRName == null && iosCSREmail != null)) {
      throw const FormatException(
        '$iosCertificateSigningRequestEmailArg and '
        '$iosCertificateSigningRequestNameArg need to be specified together',
      );
    }

    final String? iosCSRPrivateKeyPath = parseOptionalCertificate(
      iosCertificateSigningRequestPrivateKeyPathArg,
      iosCertificateSigningRequestPrivateKeyBase64Arg,
      '$iOSAppId-csr-private-key',
    );

    if (iosCSRPrivateKeyPath == null &&
        iosCSREmail == null &&
        iosCSRName == null) {
      throw const FormatException(
        'CSR private-key must be specified\nSpecify '
        '($iosCertificateSigningRequestPrivateKeyPathArg or '
        '$iosCertificateSigningRequestPrivateKeyBase64Arg) '
        'to use a existing certificates.'
        '\nSpecify ($iosCertificateSigningRequestEmailArg and '
        '$iosCertificateSigningRequestNameArg) '
        'to create new one CSR and certificates',
      );
    }

    final String? iosCSRPath = parseOptionalCertificate(
      iosCertificateSigningRequestPathArg,
      iosCertificateSigningRequestBase64Arg,
      '$iOSAppId-csr',
    );

    final String? iosProvisionProfileId =
        commandArgs.parseOptionalString(iosProvisionProfileIdArg);

    final String? iosCertificateId =
        commandArgs.parseOptionalString(iosCertificateIdArg);

    if (iosProvisionProfileId != null && iosCSRPrivateKeyPath == null) {
      throw const FormatException(
        '$iosProvisionProfileIdArg cannot be specified without '
        'providing ($iosCertificateSigningRequestPrivateKeyPathArg or '
        "$iosCertificateSigningRequestPrivateKeyBase64Arg)\nBecause it's "
        'needed to use the distribution certificate for code signing.',
      );
    }

    if (iosCertificateId != null && iosProvisionProfileId == null) {
      throw const FormatException(
        '$iosCertificateIdArg cannot be specified without '
        'providing $iosProvisionProfileIdArg where this '
        'certificate is associated.',
      );
    }

    final EncryptorType infraEncryptorType =
        commandArgs.getInfraEncryptorType();

    final Encryptor infraEncryptor =
        commandArgs.getInfraEncryptor(infraEncryptorType, infraDir);

    final StorageType infraStorageType = commandArgs.getInfraStorageType();

    final Storage infraStorage = commandArgs.getInfraStorage(
      infraStorageType,
      infraEncryptor,
      logger,
      infraDir,
    );

    final String iosBuildOutputType =
        commandArgs.parseString(infraIosBuildOutputTypeArg);

    final String androidBuildOutputType =
        commandArgs.parseString(infraAndroidBuildOutputTypeArg);

    final String iosProvisionProfileType =
        commandArgs.parseString(iosProvisionProfileTypeArg);

    return InfraSetupConfiguration(
      androidAppId: androidAppId!,
      iosAppId: iOSAppId,
      iosAppStoreConnectKeyId: iOSAppStoreConnectKeyId,
      iosAppStoreConnectKeyIssuer: iOSAppStoreConnectKeyIssuer,
      iosAppStoreConnectKey: iosAppStoreConnectKeyPath,
      iosCertificateSigningRequestPath: iosCSRPath,
      iosCertificateSigningRequestPrivateKeyPath: iosCSRPrivateKeyPath,
      iosCertificateSigningRequestEmail: iosCSREmail,
      iosCertificateSigningRequestName: iosCSRName,
      iosProvisionProfileId: iosProvisionProfileId,
      iosProvisionProfileType: iosProvisionProfileType.fromKey(),
      iosCertificateId: iosCertificateId,
      encryptorType: infraEncryptorType,
      encryptor: infraEncryptor,
      storageType: infraStorageType,
      storage: infraStorage,
      iosBuildOutputType: iosBuildOutputType.asIosBuildOutputType(),
      androidBuildOutputType: androidBuildOutputType.asAndroidBuildOutputType(),
    );
  }

  ///
  @visibleForTesting
  File parseIosAppStoreConnectKeyPath(String filename) {
    final String? keyPath =
        argResults?.parseOptionalString(iosAppStoreConnectKeyPathArg);

    final String? keyAs64 =
        argResults?.parseOptionalString(iosAppStoreConnectKeyBase64Arg);

    if (keyPath == null && keyAs64 == null) {
      throw const FormatException(
        '$iosAppStoreConnectKeyPathArg or'
        ' $iosAppStoreConnectKeyBase64Arg need to be specified',
      );
    }

    File? keyFile;

    if (keyPath != null) {
      keyFile = File(keyPath);
    } else if (keyAs64 != null) {
      keyFile = createCertificateFileFromBase64(
        contentAsBase64: keyAs64,
        filename: filename,
      );
    }

    if (keyFile == null || !keyFile.existsSync()) {
      throw const FormatException(
        'App store connect api key does not exist\n'
        'Please provide a valid one using $iosAppStoreConnectKeyPathArg '
        'or $iosAppStoreConnectKeyBase64Arg',
      );
    }

    return keyFile;
  }

  ///
  @visibleForTesting
  String? parseOptionalCertificate(
    final String pathArgument,
    final String base64Argument,
    final String filename,
  ) {
    final String? keyPath = argResults?.parseOptionalString(pathArgument);

    final String? keyAs64 = argResults?.parseOptionalString(base64Argument);

    final String? keyPath2 = keyAs64 != null
        ? createCertificateFileFromBase64(
            contentAsBase64: keyAs64,
            filename: filename,
          ).path
        : null;

    return keyPath ?? keyPath2;
  }
}
