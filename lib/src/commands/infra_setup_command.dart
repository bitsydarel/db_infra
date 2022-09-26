import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:db_infra/src/apple/bundle_id/bundle_id_manager.dart';
import 'package:db_infra/src/apple/certificates/certificates_manager.dart';
import 'package:db_infra/src/apple/device/device_manager.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile_manager.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile_type.dart';
import 'package:db_infra/src/build_output_type.dart';
import 'package:db_infra/src/build_signing_type.dart';
import 'package:db_infra/src/commands/base_command.dart';
import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/encryptor/encryptor.dart';
import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/setup_executor/android_setup_executor.dart';
import 'package:db_infra/src/setup_executor/setup_executor.dart';
import 'package:db_infra/src/storage/storage.dart';
import 'package:db_infra/src/utils/utils.dart';
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
        iosProvisionProfileNameArg,
        help: "Specify the provision profile name, so it's can be used.",
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
        iosDevelopmentTeamIdArg,
        help: 'Specify the infrastructure ios development team id',
      )
      ..addOption(
        infraIosBuildOutputTypeArg,
        help: 'Specify the infrastructure ios build output type.',
        allowed: IosBuildOutputType.values.asNameList(),
        defaultsTo: IosBuildOutputType.ipa.name,
      )
      ..addOption(
        androidAppIdArg,
        help: 'Specify the android application id that '
            'will be used for distribution.',
      )
      ..addOption(
        infraAndroidKeyAliasArg,
        help: 'Specify the infrastructure android key alias.',
      )
      ..addOption(
        infraAndroidKeyPasswordArg,
        help: 'Specify the infrastructure android key password.',
      )
      ..addOption(
        infraAndroidStoreFileArg,
        help: 'Specify the infrastructure android store file.',
      )
      ..addOption(
        infraAndroidStorePasswordArg,
        help: 'Specify the infrastructure android store password.',
      )
      ..addOption(
        infraAndroidBuildOutputTypeArg,
        help: 'Specify the infrastructure android build output type',
        allowed: AndroidBuildOutputType.values.asNameList(),
        defaultsTo: AndroidBuildOutputType.apk.name,
      )
      ..addOption(
        infraStorageTypeArg,
        help: 'Specify the infrastructure storage type',
        allowed: StorageType.values.asNameList(),
        defaultsTo: StorageType.disk.name,
      )
      ..addOption(
        infraEncryptorTypeArg,
        help: 'Specify the infrastructure encryptor type',
        allowed: EncryptorType.values.asNameList(),
        defaultsTo: EncryptorType.base64.name,
      )
      ..addOption(
        infraAesEncryptorPasswordArg,
        help: 'Specify the infrastructure AES encryptor password.',
      )
      ..addOption(
        infraDiskStorageLocationArg,
        help: 'Specify the infrastructure disk storage location',
        defaultsTo: '.infra_disk_storage',
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
      )
      ..addOption(
        infraGcloudProjectIdArg,
        help: 'Specify the infrastructure gcloud project id.',
      )
      ..addOption(
        infraGcloudProjectBucketNameArg,
        help: 'Specify the infrastructure gcloud project bucket name.',
      )
      ..addOption(
        infraGcloudProjectServiceAccountFileArg,
        help: 'Specify the infrastructure gcloud project service account.',
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
      commandArgs: commandArgs,
      infraDir: infraDir,
      logger: logger,
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

    final InfraBuildConfiguration iosBuildConfiguration =
        await iosSetupExecutor.setupInfra();

    final AndroidSetupExecutor androidSetupExecutor = AndroidSetupExecutor(
      configuration: configuration,
      infraDirectory: infraDir,
      logger: logger,
    );

    logger.logInfo(
      'Setting up android infrastructure for ${configuration.androidAppId}...',
    );

    final InfraBuildConfiguration androidBuildConfiguration =
        await androidSetupExecutor.setupInfra();

    final File? iosCertificateSigningRequest =
        iosBuildConfiguration.iosCertificateSigningRequest;

    final File? iosCertificateSigningRequestPrivateKey =
        iosBuildConfiguration.iosCertificateSigningRequestPrivateKey;

    final List<File> filesToEncrypt = <File>[
      if (iosCertificateSigningRequest != null) iosCertificateSigningRequest,
      if (iosCertificateSigningRequestPrivateKey != null)
        iosCertificateSigningRequestPrivateKey,
      iosBuildConfiguration.iosExportOptionsPlist,
      iosBuildConfiguration.iosAppStoreConnectKey,
      androidBuildConfiguration.androidStoreFile,
    ];

    final List<File> encryptedFiles =
        await configuration.encryptor.encryptFiles(filesToEncrypt);

    await configuration.storage.saveFiles(encryptedFiles);

    await saveConfiguration(
      InfraBuildConfiguration(
        iosAppId: iosBuildConfiguration.iosAppId,
        iosSigningType: iosBuildConfiguration.iosSigningType,
        iosBuildOutputType: iosBuildConfiguration.iosBuildOutputType,
        iosAppStoreConnectKey: iosBuildConfiguration.iosAppStoreConnectKey,
        iosExportOptionsPlist: iosBuildConfiguration.iosExportOptionsPlist,
        iosAppStoreConnectKeyId: iosBuildConfiguration.iosAppStoreConnectKeyId,
        iosProvisionProfileType: iosBuildConfiguration.iosProvisionProfileType,
        iosAppStoreConnectKeyIssuer:
            iosBuildConfiguration.iosAppStoreConnectKeyIssuer,
        iosCertificateSigningRequest:
            iosBuildConfiguration.iosCertificateSigningRequest,
        iosCertificateSigningRequestPrivateKey:
            iosBuildConfiguration.iosCertificateSigningRequestPrivateKey,
        iosCertificateSigningRequestName:
            iosBuildConfiguration.iosCertificateSigningRequestName,
        iosCertificateSigningRequestEmail:
            iosBuildConfiguration.iosCertificateSigningRequestEmail,
        iosProvisionProfileName: iosBuildConfiguration.iosProvisionProfileName,
        iosCertificateId: iosBuildConfiguration.iosCertificateId,
        iosDeveloperTeamId: iosBuildConfiguration.iosDeveloperTeamId,
        androidAppId: androidBuildConfiguration.androidAppId,
        androidKeyAlias: androidBuildConfiguration.androidKeyAlias,
        androidKeyPassword: androidBuildConfiguration.androidKeyPassword,
        androidStoreFile: androidBuildConfiguration.androidStoreFile,
        androidStorePassword: androidBuildConfiguration.androidStorePassword,
        androidBuildOutputType:
            androidBuildConfiguration.androidBuildOutputType,
        storage: configuration.storage,
        encryptor: configuration.encryptor,
        storageType: configuration.storageType,
        encryptorType: configuration.encryptorType,
      ),
      configurationFile,
    );

    logger.logInfo(
      'Completed set up ios infrastructure for ${configuration.iosAppId} '
      'completed: ${configurationFile.path}',
    );

    await cleanup(configuration, infraDir);
  }

  ///
  @visibleForTesting
  InfraSetupConfiguration parseConfigurationArguments({
    required ArgResults commandArgs,
    required Directory infraDir,
    required Logger logger,
  }) {
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
        '$iosCertificateSigningRequestNameArg need to be '
        'specified together',
      );
    }

    final String? iosCSRPrivateKeyPath = parseOptionalCertificate(
      iosCertificateSigningRequestPrivateKeyPathArg,
      iosCertificateSigningRequestPrivateKeyBase64Arg,
      '$iOSAppId-csr-private-key',
    );

    final String iosProvisionProfileType =
        commandArgs.parseString(iosProvisionProfileTypeArg);

    final String? iosDevelopmentTeamId =
        commandArgs.parseOptionalString(iosDevelopmentTeamIdArg);

    if (iosCSRPrivateKeyPath == null &&
        iosCSREmail == null &&
        iosCSRName == null &&
        iosDevelopmentTeamId == null) {
      throw const FormatException(
        'CSR private-key must be specified\nSpecify '
        '($iosCertificateSigningRequestPrivateKeyPathArg or '
        '$iosCertificateSigningRequestPrivateKeyBase64Arg) '
        'to use a existing certificates.'
        '\nSpecify ($iosCertificateSigningRequestEmailArg and '
        '$iosCertificateSigningRequestNameArg) '
        'to create new one CSR and certificates or '
        'use automatic signing by specifying the team id',
      );
    }

    final String? iosCSRPath = parseOptionalCertificate(
      iosCertificateSigningRequestPathArg,
      iosCertificateSigningRequestBase64Arg,
      '$iOSAppId-csr',
    );

    final String? iosProvisionProfileName =
        commandArgs.parseOptionalString(iosProvisionProfileNameArg);

    final String? iosCertificateId =
        commandArgs.parseOptionalString(iosCertificateIdArg);

    if (iosProvisionProfileName != null && iosCSRPrivateKeyPath == null) {
      throw const FormatException(
        '$iosProvisionProfileNameArg cannot be specified without '
        'providing ($iosCertificateSigningRequestPrivateKeyPathArg or '
        "$iosCertificateSigningRequestPrivateKeyBase64Arg)\nBecause it's "
        'needed to use the distribution certificate for code signing.',
      );
    }

    if (iosCertificateId != null && iosProvisionProfileName == null) {
      throw const FormatException(
        '$iosCertificateIdArg cannot be specified without '
        'providing $iosProvisionProfileNameArg where this '
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

    final String androidKeyAlias =
        commandArgs.parseString(infraAndroidKeyAliasArg);

    final String androidKeyPassword =
        commandArgs.parseString(infraAndroidKeyPasswordArg);

    final File androidStoreFile = parseAndroidStoreFilePath();

    final String androidStorePassword =
        commandArgs.parseString(infraAndroidStorePasswordArg);

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
      iosProvisionProfileName: iosProvisionProfileName,
      iosProvisionProfileType: iosProvisionProfileType.fromKey(),
      androidKeyAlias: androidKeyAlias,
      androidKeyPassword: androidKeyPassword,
      androidStoreFile: androidStoreFile,
      androidStorePassword: androidStorePassword,
      iosCertificateId: iosCertificateId,
      encryptorType: infraEncryptorType,
      encryptor: infraEncryptor,
      storageType: infraStorageType,
      storage: infraStorage,
      iosBuildOutputType: iosBuildOutputType.asIosBuildOutputType(),
      androidBuildOutputType: androidBuildOutputType.asAndroidBuildOutputType(),
      iosDeveloperTeamId: iosDevelopmentTeamId,
      iosBuildSigningType: iosDevelopmentTeamId != null
          ? IosBuildSigningType.automatic
          : IosBuildSigningType.manuel,
    );
  }

  ///
  @visibleForTesting
  File parseAndroidStoreFilePath() {
    final String? androidStoreFilePath =
        argResults?.parseString(infraAndroidStoreFileArg);

    if (androidStoreFilePath == null) {
      throw const FormatException(
        '$infraAndroidStoreFileArg need to be specified',
      );
    }

    final File androidStoreFile = File(androidStoreFilePath);

    if (!androidStoreFile.existsSync()) {
      throw const FormatException(
        'Android store file does not exist\n'
        'Please provide a valid one using $infraAndroidStoreFileArg ',
      );
    }

    return androidStoreFile;
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
