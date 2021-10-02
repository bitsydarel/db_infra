import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:db_infra/src/build_distributor.dart';
import 'package:db_infra/src/build_distributor_type.dart';
import 'package:db_infra/src/build_distributors/build_distributor_factory.dart';
import 'package:db_infra/src/build_output_type.dart';
import 'package:db_infra/src/configurations/infra_build_configuration.dart';
import 'package:db_infra/src/configurations/infra_setup_configuration.dart';
import 'package:db_infra/src/encryptor.dart';
import 'package:db_infra/src/encryptor_type.dart';
import 'package:db_infra/src/encryptors/base64_encryptor.dart';
import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/storage.dart';
import 'package:db_infra/src/storage_type.dart';
import 'package:db_infra/src/storages/storage_factory.dart';
import 'package:db_infra/src/utils/constants.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:db_infra/src/utils/file_utils.dart';
import 'package:db_infra/src/utils/infra_extensions.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:io/io.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

///
extension ArgResultsExtension on ArgResults {
  ///
  bool get runSetup => wasParsed(setupProjectArg);

  ///
  bool get runBuild => wasParsed(buildProjectArg);

  ///
  Directory getProjectDirectory() {
    final Directory projectDir = _getResolvedDirectory(rest.last);

    if (!projectDir.existsSync()) {
      throw const FormatException('specified project dir does not exist');
    }

    return projectDir;
  }

  ///
  InfraSetupConfiguration toSetupConfiguration(final Directory infraDirectory) {
    final String? appId = parseOptionalString(appIdArg);

    String? androidAppId = parseOptionalString(androidAppIdArg);
    String? iOSAppId = parseOptionalString(iosAppIdArg);

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
        parseString(iosAppStoreConnectKeyIdArg);

    final String iOSAppStoreConnectKeyIssuer =
        parseString(iosAppStoreConnectKeyIssuerArg);

    final File iosAppStoreConnectKeyPath =
        parseIosAppStoreConnectKeyPath(iOSAppId!);

    final String? iosCSREmail =
        parseOptionalString(iosCertificateSigningRequestEmailArg);

    final String? iosCSRName =
        parseOptionalString(iosCertificateSigningRequestNameArg);

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

    final String? iosProvisionProfile =
        parseOptionalString(iosDistributionProvisionProfileUUIDArg);

    final String? iosCertificateId =
        parseOptionalString(iosDistributionCertificateIdArg);

    if (iosProvisionProfile != null && iosCSRPrivateKeyPath == null) {
      throw const FormatException(
        '$iosDistributionProvisionProfileUUIDArg cannot be specified without '
        'providing ($iosCertificateSigningRequestPrivateKeyPathArg or '
        "$iosCertificateSigningRequestPrivateKeyBase64Arg)\nBecause it's "
        'needed to use the distribution certificate for code signing.',
      );
    }

    if (iosCertificateId != null && iosProvisionProfile == null) {
      throw const FormatException(
        '$iosDistributionCertificateIdArg cannot be specified without '
        'providing $iosDistributionProvisionProfileUUIDArg where this '
        'certificate is associated.',
      );
    }

    final EncryptorType infraEncryptorType = getInfraEncryptorType();

    final Encryptor infraEncryptor =
        getInfraEncryptor(infraEncryptorType, infraDirectory);

    final StorageType infraStorageType = getInfraStorageType();

    final Storage infraStorage = getInfraStorage(
      infraStorageType,
      infraEncryptor,
      const Logger(enableLogging: true),
      infraDirectory,
    );

    final String iosBuildOutputType = parseString(infraIosBuildOutputTypeArg);

    final String androidBuildOutputType =
        parseString(infraAndroidBuildOutputTypeArg);

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
      iosDistributionProvisionProfileUUID: iosProvisionProfile,
      iosDistributionCertificateId: iosCertificateId,
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
    final String? keyPath = parseOptionalString(iosAppStoreConnectKeyPathArg);

    final String? keyAs64 = parseOptionalString(iosAppStoreConnectKeyBase64Arg);

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
    final String? keyPath = parseOptionalString(pathArgument);

    final String? keyAs64 = parseOptionalString(base64Argument);

    final String? keyPath2 = keyAs64 != null
        ? createCertificateFileFromBase64(
            contentAsBase64: keyAs64,
            filename: filename,
          ).path
        : null;

    return keyPath ?? keyPath2;
  }

  ///
  @visibleForTesting
  String parseString(final String argumentName) {
    final Object? argumentValue = this[argumentName];

    if (argumentValue is String && argumentValue.trim().isNotEmpty) {
      return argumentValue;
    }

    throw FormatException('$argumentName need to be specified');
  }

  ///
  @visibleForTesting
  String? parseOptionalString(final String argumentName) {
    final Object? argumentValue = this[argumentName];

    if (argumentValue is String && argumentValue.trim().isNotEmpty) {
      return argumentValue;
    }
    return null;
  }

  ///
  bool isLoggingEnabled() {
    return wasParsed(infraVerboseLoggingArg);
  }

  ///
  EncryptorType getInfraEncryptorType() {
    final String infraEncryptorType = parseString(infraEncryptorTypeArg);

    return infraEncryptorType.asEncryptorType();
  }

  ///
  Encryptor getInfraEncryptor(
    final EncryptorType infraEncryptorType,
    final Directory infraDirectory,
  ) {
    switch (infraEncryptorType) {
      case EncryptorType.base64:
        return Base64Encryptor(infraDirectory);
      default:
        throw UnsupportedError('${infraEncryptorType.name} is unsupported');
    }
  }

  ///
  StorageType getInfraStorageType() {
    final String infraStorageType = parseString(infraStorageTypeArg);

    return infraStorageType.asStorageType();
  }

  ///
  Storage getInfraStorage(
    final StorageType infraStorageType,
    final Encryptor infraEncryptor,
    final Logger logger,
    final Directory infraDirectory,
  ) {
    final String? infraDiskStorageLocation =
        parseOptionalString(infraDiskStorageLocationArg);

    final String? ftpUsername = parseOptionalString(infraFtpUsernameArg);
    final String? ftpPassword = parseOptionalString(infraFtpPasswordArg);
    final String? ftpServerUrl = parseOptionalString(infraFtpUrlArg);
    final String? ftpFolderName = parseOptionalString(infraFtpFolderNameArg);
    final String? ftpServerPort = parseOptionalString(infraFtpPortArg);

    return infraStorageType.from(
      infraLogger: logger,
      infraDirectory: infraDirectory,
      ftpUsername: ftpUsername,
      ftpPassword: ftpPassword,
      ftpServerUrl: ftpServerUrl,
      ftpServerPort: ftpServerPort != null ? int.parse(ftpServerPort) : null,
      ftpServerFolderName: ftpFolderName ?? 'credentials',
      storageDirectory: infraDiskStorageLocation?.trim().isNotEmpty == true
          ? Directory(infraDiskStorageLocation!)
          : null,
    );
  }

  /// Get the build distributor
  BuildDistributorType getBuildDistributorType() {
    final String buildDistributorType =
        parseString(infraBuildDistributorTypeArg);

    return buildDistributorType.asBuildDistributorType();
  }

  ///
  BuildDistributor getBuildDistributor(
    final Logger logger,
    final InfraBuildConfiguration configuration,
    final BuildDistributorType buildDistributorType,
  ) {
    final String? outputDirectoryPath =
        parseOptionalString(infraBuildOutputDirectoryArg);

    return buildDistributorType.toDistributor(
      infraLogger: logger,
      configuration: configuration,
      outputDirectoryPath: outputDirectoryPath,
    );
  }
}

/// Load the infrastructure configuration.
Future<InfraBuildConfiguration> loadConfiguration(
  final File configuration,
  final Directory infraDirectory, {
  required final bool enableLogging,
}) async {
  final String fileContent = configuration.readAsStringSync();

  final Object? rawJson = jsonDecode(fileContent);

  if (rawJson is JsonMap) {
    final EncryptorType infraEncryptorType = rawJson.getEncryptorType();

    final Logger logger = Logger(enableLogging: enableLogging);

    final Encryptor infraEncryptor =
        rawJson.getEncryptor(infraEncryptorType, logger, infraDirectory);

    final StorageType infraStorageType = rawJson.getStorageType();

    if (rawJson is JsonMap) {
      return InfraBuildConfiguration.fromJson(
        json: rawJson,
        infraEncryptorType: infraEncryptorType,
        infraEncryptor: infraEncryptor,
        infraStorageType: infraStorageType,
        logger: const Logger(enableLogging: true),
        infraDir: infraDirectory,
      );
    }
  }

  throw UnrecoverableException(
    "Can't load infra configuration with json\n$fileContent",
    ExitCode.config.code,
  );
}

/// Get the project [Directory] with a full path.
Directory _getResolvedDirectory(final String localDirectory) {
  return Directory(path.canonicalize(localDirectory));
}
