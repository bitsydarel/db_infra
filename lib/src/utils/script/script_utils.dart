import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:db_infra/src/build_distributor_type.dart';
import 'package:db_infra/src/build_output_type.dart';
import 'package:db_infra/src/encryptor_type.dart';
import 'package:db_infra/src/storage_type.dart';
import 'package:db_infra/src/utils/constants.dart';
import 'package:db_infra/src/utils/types.dart';
import 'package:io/ansi.dart';

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
    help: 'Specify the distribution provision profile uuid to use.',
  )
  ..addOption(
    iosDistributionCertificateIdArg,
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
  )
  ..addOption(
    infraBuildDistributorTypeArg,
    help: 'Specify the infrastructure build distributor type.',
    allowed: BuildDistributorType.values.map(enumName),
    defaultsTo: BuildDistributorType.directory.name,
  )
  ..addOption(
    infraBuildOutputDirectoryArg,
    help: 'Specify the output directory.',
  )
  ..addFlag(
    infraVerboseLoggingArg,
    defaultsTo: true,
    help: 'Enable verbosity in the execution of the script.',
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
