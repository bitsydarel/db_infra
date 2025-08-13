import 'dart:async';
import 'dart:io';

import 'package:bdlogging/bdlogging.dart';
import 'package:collection/collection.dart';
import 'package:db_infra/src/apple/bundle_id/bundle_id_manager.dart';
import 'package:db_infra/src/apple/certificates/certificate.dart';
import 'package:db_infra/src/apple/certificates/certificate_signing_request.dart';
import 'package:db_infra/src/apple/certificates/certificate_type.dart';
import 'package:db_infra/src/apple/certificates/certificates_manager.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile_manager.dart';
import 'package:db_infra/src/apple/provision_profile/provision_profile_type.dart';
import 'package:db_infra/src/apple/xcode_project/xcode_project.dart';
import 'package:db_infra/src/build_executor/build_executor.dart';
import 'package:db_infra/src/build_output_type.dart';
import 'package:db_infra/src/configuration/configuration.dart';
import 'package:db_infra/src/environment_variable_handler/environment_variable_handler.dart';
import 'package:db_infra/src/shell_runner.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;

///
class FlutterIosBuildExecutor extends BuildExecutor {
  ///
  final CertificatesManager certificatesManager;

  ///
  final ProvisionProfileManager provisionProfilesManager;

  ///
  final BundleIdManager bundleIdManager;

  ///
  final EnvironmentVariableHandler? environmentVariableHandler;

  ///
  final ShellRunner runner;

  ///
  const FlutterIosBuildExecutor({
    required this.runner,
    required this.provisionProfilesManager,
    required this.certificatesManager,
    required this.bundleIdManager,
    required Directory projectDirectory,
    required InfraBuildConfiguration configuration,
    String? buildFlavor,
    this.environmentVariableHandler,
  }) : super(
          buildFlavor: buildFlavor,
          configuration: configuration,
          projectDirectory: projectDirectory,
        );

  @override
  Future<File> build() async {
    final String? developerTeamId = configuration.iosDeveloperTeamId;

    Certificate? certificate;
    ProvisionProfile? provisionProfile;

    final File? certificatePrivateKey =
        configuration.iosCertificateSigningRequestPrivateKey;

    final File? certificatePublicKey =
        configuration.iosCertificateSigningRequestPublicKey;

    if (developerTeamId == null &&
        (certificatePrivateKey == null ||
            !certificatePrivateKey.existsSync())) {
      throw UnrecoverableException(
        'iosDeveloperTeamId is not set and '
        'iosCertificateSigningRequestPrivateKey is not set '
        'did you properly run the setup ?',
        ExitCode.config.code,
      );
    }

    if (certificatePrivateKey != null && certificatePrivateKey.existsSync()) {
      certificatesManager.importCertificateFileLocally(certificatePrivateKey);
    }

    if (developerTeamId == null &&
        (certificatePublicKey == null || !certificatePublicKey.existsSync())) {
      throw UnrecoverableException(
        'iosDeveloperTeamId is not set and '
        'iosCertificateSigningRequestPublicKey is not set '
        'did you properly run the setup ?',
        ExitCode.config.code,
      );
    }

    if (certificatePublicKey != null && certificatePublicKey.existsSync()) {
      certificatesManager.importCertificateFileLocally(certificatePublicKey);
    }

    final String? certificateId = configuration.iosCertificateId;

    if (developerTeamId == null && certificateId == null) {
      throw UnrecoverableException(
        'iosDeveloperTeamId is not set and iosCertificateId is not set, '
        'did you properly run the setup ?',
        ExitCode.config.code,
      );
    }

    if (developerTeamId == null && certificateId != null) {
      certificate = await certificatesManager.getCertificate(certificateId);

      if (certificate != null && !certificate.hasExpired()) {
        certificatesManager.importCertificateLocally(certificate);
      } else {
        throw UnrecoverableException(
          'Certificate with id $certificateId '
          'not found or has expired.\nRe-Run the setup command.',
          ExitCode.tempFail.code,
        );
      }
    }

    final String? iosProvisionProfileName =
        configuration.iosProvisionProfileName;

    if (developerTeamId == null && iosProvisionProfileName == null) {
      throw UnrecoverableException(
        'iosDeveloperTeamId is not set and iosProvisionProfileName is not set, '
        'did you properly run the setup ?',
        ExitCode.config.code,
      );
    }

    if (iosProvisionProfileName != null) {
      provisionProfile = await provisionProfilesManager.getProfileWithName(
        iosProvisionProfileName,
      );

      if (provisionProfile != null) {
        provisionProfilesManager
            .importProvisionProfileLocally(provisionProfile);
      } else {
        throw UnrecoverableException(
          'Provision Profile with uuid '
          '${configuration.iosProvisionProfileName} not found.\n'
          'Re-Run the setup command.',
          ExitCode.tempFail.code,
        );
      }
    }

    if (!configuration.iosExportOptionsPlist.existsSync()) {
      throw UnrecoverableException(
        'File ${configuration.iosExportOptionsPlist.path} does not exist',
        ExitCode.tempFail.code,
      );
    }

    final Directory iosFlutterDir = Directory(
      path.join(projectDirectory.path, 'ios/Flutter'),
    );

    final Map<String, Object>? environmentVariables =
        await environmentVariableHandler?.call();

    final Map<String, String> codeSigningArguments = createCodeSigningArguments(
      certificate: certificate,
      developerTeamId: developerTeamId,
      provisionProfile: provisionProfile,
      signingType: configuration.iosSigningType,
      provisionProfileType: configuration.iosProvisionProfileType,
    );

    BDLogger()
        .info('Code Signing Setting:\n${codeSigningArguments.toString()}');

    final File codeSigningConfig = createCodeSigningXCConfig(
      envs: environmentVariables,
      parentDirectory: iosFlutterDir,
      codeSigningArguments: codeSigningArguments,
    );

    BDLogger().info('Infra.xconfig\n${codeSigningConfig.readAsStringSync()}');

    final File releaseConfig = File(
      path.join(iosFlutterDir.path, 'Release.xcconfig'),
    );

    updateIosProjectSigningConfiguration(codeSigningConfig, releaseConfig);

    final List<String>? dartDefines =
        await environmentVariableHandler?.asDartDefines();

    final String oldPath = path.canonicalize(Directory.current.path);
    final String projectDir = path.canonicalize(projectDirectory.path);

    Directory.current = projectDir;

    final String? flutterFlavor = buildFlavor;

    // Check if automatic signing is enabled, if yes than build project
    // with xcodebuild to allow it to created the required signing config.
    if (developerTeamId != null &&
        (certificate == null && provisionProfile == null)) {
      await certificatesManager.enableAutomaticSigning();

      if (certificatePrivateKey != null) {
        await importOrGenerateCertificateRequiredForAutomaticSigning(
          appId: configuration.iosAppId,
          privateKeyFile: certificatePrivateKey,
          publicKeyFile: certificatePublicKey,
          certificateType: configuration.iosProvisionProfileType.isDevelopment()
              ? CertificateType.development
              : CertificateType.distribution,
        );
      } else {
        BDLogger().info(
          'automatic signing is enabled, but no private key is provided, '
          'skipping certificate import',
        );
      }

      Directory.current = projectDir;

      final Map<String, String> flutterCodeSigning =
          Map<String, String>.fromEntries(
        codeSigningArguments.entries.whereNot((MapEntry<String, String> entry) {
          return entry.key.startsWith(codeSignIdentityKey);
        }),
      );

      BDLogger()
          .info('Flutter Signing Setting:\n${flutterCodeSigning.toString()}');

      final ShellOutput output = await runner.executeAsync(
        'flutter',
        <String>[
          'build',
          'ipa',
          if (flutterFlavor != null) ...<String>['--flavor', flutterFlavor],
          '--release',
          '--no-codesign',
          if (dartDefines != null) ...dartDefines,
        ],
        <String, String>{
          'CI': 'true',
          ...flutterCodeSigning.map<String, String>(
            (String key, String value) => MapEntry<String, String>(
              'FLUTTER_XCODE_$key',
              value,
            ),
          ),
        },
      );

      if (output.isFailure()) {
        final UnrecoverableException exception =
            UnrecoverableException(output.stderr, ExitCode.tempFail.code);

        BDLogger()
          ..info(output.stdout)
          ..error(output.stderr, exception);

        throw exception;
      }

      BDLogger().info(output.stdout);

      Directory.current = path.join(projectDir, 'ios');

      await _buildIpa(flutterCodeSigning, scheme: flutterFlavor);

      Directory.current = projectDir;
    } else {
      final ShellOutput output = await runner.executeAsync(
        'flutter',
        <String>[
          'build',
          configuration.iosBuildOutputType.name,
          if (flutterFlavor != null) ...<String>['--flavor', flutterFlavor],
          '--release',
          '--verbose',
          '--export-options-plist',
          configuration.iosExportOptionsPlist.path,
          if (dartDefines != null) ...dartDefines,
        ],
        <String, String>{'CI': 'true'},
      );

      if (output.isFailure()) {
        cleanupProjectSigningConfiguration(codeSigningConfig, releaseConfig);

        final UnrecoverableException exception =
            UnrecoverableException(output.stderr, ExitCode.tempFail.code);

        BDLogger()
          ..info(output.stdout)
          ..error(output.stderr, exception);

        throw exception;
      }

      BDLogger().info('Flutter Build Output:\n${output.stdout}');
    }

    Directory.current = oldPath;

    cleanupProjectSigningConfiguration(codeSigningConfig, releaseConfig);

    final File? outputFile =
        configuration.iosBuildOutputType.outputFile(projectDirectory);

    if (outputFile == null || !outputFile.existsSync()) {
      throw UnrecoverableException(
        'Could not find ios build output file at ${outputFile?.path}',
        ExitCode.software.code,
      );
    }

    if (provisionProfile != null) {
      provisionProfilesManager.deleteProvisionProfileLocally(provisionProfile);
    }
    certificatesManager.cleanupLocally();

    return outputFile;
  }

  ///
  Future<void> importOrGenerateCertificateRequiredForAutomaticSigning({
    required String appId,
    required File privateKeyFile,
    required CertificateType certificateType,
    File? publicKeyFile,
  }) async {
    BDLogger().info('Fetching certificates available in the account...');

    final List<Certificate> certificates =
        await certificatesManager.getCertificates();

    BDLogger().info('Found ${certificates.length} certificates');

    final List<Certificate> importedCertificates = <Certificate>[];

    // https://github.com/fastlane/fastlane/discussions/19973
    // Automatic Signing requires at least one development certificate.
    for (final Certificate certificate in certificates) {
      final bool isSignedByPrivateKey = await certificatesManager
          .isSignedWithPrivateKey(certificate, privateKeyFile);

      if (isSignedByPrivateKey && !certificate.hasExpired()) {
        final String? certificateSha1 =
            certificatesManager.importCertificateLocally(certificate);

        importedCertificates.add(certificate);

        BDLogger().info(
          '${certificate.name} imported in keychain with sha1 $certificateSha1',
        );
      }
    }

    if (importedCertificates.isEmpty) {
      BDLogger().warning(
        'No valid certificates found signed with the specified private key',
      );
    } else if (importedCertificates.any(
      (Certificate certificate) => certificate.type == certificateType,
    )) {
      BDLogger().warning(
        'Certificate of type $certificateType imported in the keychain',
      );
    } else {
      BDLogger().warning(
        'No valid certificates found signed with the specified private key '
        'and of type $certificateType',
      );
    }

    final bool hasDevelopmentCertificate = importedCertificates
        .any((Certificate certificate) => certificate.isDevelopment());

    CertificateSigningRequest? csr;

    if (!hasDevelopmentCertificate) {
      BDLogger().warning(
        'No valid certificates found signed with the specified private key ',
      );
      BDLogger().info('Creating development certificate for $appId...');

      csr = certificatesManager.createCertificateSigningRequest(
        appId: appId,
        privateKey: privateKeyFile,
        publicKey: publicKeyFile,
      );

      final File? csrFile = csr.request;

      if (csrFile != null) {
        BDLogger()
            .info('Certificate Signing Request created at ${csrFile.path}');
        BDLogger().info('Creating development certificate for $appId...');

        final Certificate certificate = await certificatesManager
            .createCertificate(csrFile, CertificateType.development);

        final String? certificateSha1 =
            certificatesManager.importCertificateLocally(certificate);

        BDLogger().info(
          '${certificate.name} imported in keychain with sha1 $certificateSha1',
        );
      } else {
        BDLogger().warning(
          'Could not create Certificate Signing Request, '
          'will let the xcode Gods handle it',
        );
      }
    }

    final bool hasTargetCertificateType = importedCertificates
        .any((Certificate certificate) => certificate.type == certificateType);

    if (!hasTargetCertificateType &&
        certificateType != CertificateType.development) {
      BDLogger().warning(
        'No valid certificates found signed with the specified private key '
        'and of type $certificateType',
      );
      BDLogger().info('Creating $certificateType certificate for $appId...');

      csr ??= certificatesManager.createCertificateSigningRequest(
        appId: appId,
        privateKey: privateKeyFile,
        publicKey: publicKeyFile,
      );

      final File? csrFile = csr.request;

      if (csrFile != null) {
        BDLogger()
            .info('Certificate Signing Request created at ${csrFile.path}');
        BDLogger().info('Creating $certificateType certificate for $appId...');

        final Certificate certificate = await certificatesManager
            .createCertificate(csrFile, certificateType);

        final String? certificateSha1 =
            certificatesManager.importCertificateLocally(certificate);

        BDLogger().info(
          '${certificate.name} imported in keychain with sha1 $certificateSha1',
        );
      } else {
        BDLogger().warning(
          'Could not create Certificate Signing Request, '
          'will let the xcode Gods handle it',
        );
      }
    }
  }

  Future<void> _buildIpa(
    Map<String, String> flutterCodeSigning, {
    String? scheme,
  }) async {
    final Directory xcArchiveFileFromFlutterBuild =
        Directory('../build/ios/archive/Runner.xcarchive');

    final Directory xcArchiveFileFromIosBuild = Directory(
      'build/Runner.xcarchive',
    );

    final List<String> xcodeArguments = <String>[
      '-allowProvisioningUpdates',
      '-allowProvisioningDeviceRegistration',
      '-authenticationKeyPath',
      configuration.iosAppStoreConnectKey.path,
      '-authenticationKeyID',
      configuration.iosAppStoreConnectKeyId,
      '-authenticationKeyIssuerID',
      configuration.iosAppStoreConnectKeyIssuer,
      '-archivePath',
      if (xcArchiveFileFromFlutterBuild.existsSync())
        xcArchiveFileFromFlutterBuild.path
      else if (xcArchiveFileFromIosBuild.existsSync())
        xcArchiveFileFromIosBuild.path
      else
        throw UnrecoverableException(
          'Could not find the Runner.xcarchive file after flutter build',
          ExitCode.tempFail.code,
        ),
      ...flutterCodeSigning.entries.map((MapEntry<String, String> entry) {
        return '${entry.key}=${entry.value}';
      }).toList(),
    ];

    BDLogger().info('XCODE ARCHIVE STARTED');

    final ShellOutput buildArchive = await runner.executeAsync(
      'xcodebuild',
      <String>[
        '-workspace',
        'Runner.xcworkspace',
        '-scheme',
        if (scheme != null) scheme else 'Runner',
        '-configuration',
        if (scheme != null) 'Release-$scheme' else 'Release',
        '-sdk',
        'iphoneos',
        '-destination',
        'generic/platform=iOS',
        ...xcodeArguments,
        'archive',
      ],
    );

    if (!buildArchive.stdout.contains('ARCHIVE SUCCEEDED')) {
      final UnrecoverableException exception = UnrecoverableException(
        buildArchive.stderr,
        ExitCode.tempFail.code,
      );

      BDLogger()
        ..info('XCODE ARCHIVE FAILED')
        ..info(buildArchive.stdout)
        ..error(buildArchive.stderr, exception);

      throw exception;
    }

    BDLogger().info('XCODE ARCHIVE COMPLETED');

    BDLogger().info('XCODE EXPORT STARTED');

    final ShellOutput exportArchive = await runner.executeAsync(
      'xcodebuild',
      <String>[
        ...xcodeArguments,
        '-exportArchive',
        '-exportOptionsPlist',
        configuration.iosExportOptionsPlist.path,
        '-exportPath',
        path.join(projectDirectory.path, 'build/ios/ipa'),
      ],
    );

    if (!exportArchive.stdout.contains('EXPORT SUCCEEDED')) {
      final UnrecoverableException exception = UnrecoverableException(
        exportArchive.stderr,
        ExitCode.tempFail.code,
      );

      BDLogger()
        ..info('XCODE EXPORT FAILED')
        ..info(exportArchive.stdout)
        ..error(exportArchive.stderr, exception);

      throw exception;
    }

    BDLogger().info('XCODE EXPORT COMPLETED');
  }
}
