import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:db_infra/src/infra_configuration.dart';
import 'package:db_infra/src/infra_manager.dart';
import 'package:db_infra/src/infra_managers/disk_infra_manager.dart';
import 'package:db_infra/src/run_configuration.dart';
import 'package:db_infra/src/setup_configuration.dart';
import 'package:db_infra/src/software_builders/apple/api/appstoreconnectapi_bundle_id.dart';
import 'package:db_infra/src/software_builders/apple/api/appstoreconnectapi_certificates.dart';
import 'package:db_infra/src/software_builders/apple/api/appstoreconnectapi_profiles.dart';
import 'package:db_infra/src/software_builders/apple/bundle_id_manager.dart';
import 'package:db_infra/src/software_builders/apple/certificates_manager.dart';
import 'package:db_infra/src/software_builders/apple/keychains_manager.dart';
import 'package:db_infra/src/software_builders/apple/profiles_manager.dart';
import 'package:db_infra/src/utils/constants.dart';
import 'package:db_infra/src/utils/network_manager.dart';
import 'package:io/ansi.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// Script argument parser.
final ArgParser argumentParser = ArgParser()
  ..addFlag(
    setupProjectArg,
    help: 'Setup the project.',
    negatable: false,
  )
  ..addFlag(
    buildProjectArg,
    help: 'Build the project.',
    negatable: false,
  )
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
    help: 'Specify the Certificate Signing Request (CSR) as base64 encoded.',
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
    iosDistributionProvisionProfileUUIDArg,
    help: 'Specify the distribution provision profile to use.',
  )
  ..addOption(
    iosDistributionCertificateIdArg,
    help: 'Specify the Distribution certificate id.',
  )
  ..addFlag(helpArgument, help: 'Print help message.');

/// Print help message to the console.
void printHelpMessage([final String? message]) {
  if (message != null) {
    stderr.writeln(red.wrap('$message\n'));
  }

  final String options =
      LineSplitter.split(argumentParser.usage).map((String l) => l).join('\n');

  stdout.writeln(
    'Usage: db_infra --setup|--build <required options> '
    '<local project directory>\nOptions:\n$options',
  );
}

///
extension ArgResultsExtension on ArgResults {
  ///
  bool get runSetup => wasParsed(setupProjectArg);

  ///
  bool get runBuild => wasParsed(buildProjectArg);

  ///
  SetupConfiguration toSetupConfiguration() {
    final Directory projectDirectory = parseProjectDirectory();

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

    final String? iosCSRPath = parseOptionalCertificate(
      iosCertificateSigningRequestPathArg,
      iosCertificateSigningRequestBase64Arg,
      '$iOSAppId-csr',
    );

    final String? iosCSREmail =
        parseOptionalString(iosCertificateSigningRequestEmailArg);

    final String? iosCSRName =
        parseOptionalString(iosCertificateSigningRequestNameArg);

    if (iosCSRPath == null && iosCSREmail == null && iosCSRName == null) {
      throw const FormatException(
        'No certificate signing request found'
        '\nSpecify $iosCertificateSigningRequestPathArg or '
        '$iosCertificateSigningRequestBase64Arg or '
        '($iosCertificateSigningRequestEmailArg with '
        '$iosCertificateSigningRequestNameArg together)',
      );
    }

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

    if (iosCSRPath == null && iosCSRPrivateKeyPath != null) {
      throw const FormatException(
        'CSR private-key specified but CSR not specified\nSpecify '
        '($iosCertificateSigningRequestPathArg or '
        '$iosCertificateSigningRequestBase64Arg) with '
        '($iosCertificateSigningRequestPrivateKeyPathArg or '
        '$iosCertificateSigningRequestPrivateKeyBase64Arg)',
      );
    }

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

    return SetupConfiguration(
      projectDir: projectDirectory,
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
    );
  }

  ///
  Future<InfraConfiguration> toBuildConfiguration() async {
    final Directory projectDirectory = parseProjectDirectory();

    final DiskInfraManager infraManager =
        DiskInfraManager(projectDir: projectDirectory);

    return infraManager.loadConfiguration();
  }

  ///
  @visibleForTesting
  Directory parseProjectDirectory() {
    if (rest.length != 1) {
      throw const FormatException('invalid project dir path');
    }

    final Directory projectDir = _getResolvedDirectory(rest[0]);

    if (!projectDir.existsSync()) {
      throw const FormatException('specified project dir does not exist');
    }

    return projectDir;
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
}

///
extension RunConfigurationExtensions on RunConfiguration {
  ///
  ProfilesManager getProfilesManager() {
    return ProfilesManager(
      api: AppStoreConnectApiProfiles(
        configuration: this,
        httpClient: networkManager,
      ),
    );
  }

  ///
  CertificatesManager getCertificatesManager() {
    final KeychainsManager keychainsManager =
        KeychainsManager(appKeychain: iosAppId);

    return CertificatesManager(
      keychainsManager: keychainsManager,
      httpClient: networkManager,
      api: AppStoreConnectApiCertificates(
        configuration: this,
        httpClient: networkManager,
      ),
    );
  }

  ///
  BundleIdManager getBundleManager() {
    return BundleIdManager(
      api: AppStoreConnectApiBundleId(
        configuration: this,
        httpClient: networkManager,
      ),
    );
  }

  ///
  InfraManager getInfraManager() {
    return DiskInfraManager(
      projectDir: projectDir,
      storageDirectory: Directory('${Directory.current.path}/.infra_tools'),
    );
  }
}

/// Get the project [Directory] with a full path.
Directory _getResolvedDirectory(final String localDirectory) {
  return Directory(path.canonicalize(localDirectory));
}

/// Create a certificate file with ext 'cert' from the [contentAsBase64].
///
/// The file is named with specified [filename].
File createCertificateFileFromBase64({
  required final String contentAsBase64,
  required final String filename,
}) {
  return File('${Directory.systemTemp.path}/$filename.cer')
    ..writeAsBytesSync(base64.decode(contentAsBase64));
}
