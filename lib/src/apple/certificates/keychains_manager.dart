import 'dart:io';

import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/shell_runner.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:io/io.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

const String _keychainExistMessage =
    'A keychain with the same name already exists.';

const String _keychainItemAlreadyExist =
    'The specified item already exists in the keychain.';

final RegExp _serialNumberFinder = RegExp('(?<="snbr"<blob>=0x)[^"]+');

final RegExp _sha1Finder = RegExp('(?<=SHA-1 hash:)[^\n]+');

final RegExp _keychainFinder = RegExp('(keychain:.*\n)+');

/// Keychains manager class.
class KeychainsManager {
  ///
  final String appKeychain;

  ///
  late final String defaultKeychain;

  ///
  final Logger logger;

  ///
  final ShellRunner runner;

  ///
  KeychainsManager({
    required this.appKeychain,
    required this.logger,
    this.runner = const ShellRunner(),
  }) {
    final List<String> keychains = listAllKeychains();

    try {
      createKeychain(appKeychain);
    } on KeychainAlreadyExistException {
      deleteKeychain(appKeychain);
      createKeychain(appKeychain);
    }

    final bool keychainExist = keychains
        .any((String keychain) => path.basename(keychain) == appKeychain);

    if (!keychainExist) {
      updateKeychainSearchPaths(<String>[...keychains, appKeychain]);
    }

    unlockKeychain(appKeychain);
    resetKeychainSettings(appKeychain);

    defaultKeychain = getDefaultKeychain();

    logger.logInfo('Default keychain for the user is $defaultKeychain');
  }

  ///
  List<String> getCertificateInDefaultKeychain(String certificateName) {
    return getCertificateWithName(certificateName, defaultKeychain);
  }

  ///
  List<String> getCertificateInAppKeychain(String certificateName) {
    return getCertificateWithName(certificateName, appKeychain);
  }

  ///
  List<String> getCertificateWithName(String name, String keychain) {
    final ShellOutput output = runner.execute(
      'security',
      <String>['find-certificate', '-a', '-c', name, keychain],
    );

    if (output.stderr.isNotEmpty) {
      throw UnrecoverableException(output.stderr, ExitCode.unavailable.code);
    }

    return output.stdout
        .split(_keychainFinder)
        .where((String certificate) => certificate.trim().isNotEmpty)
        .toList();
  }

  ///
  void importIntoAppKeychain(final File file) {
    final ShellOutput output = runner.execute(
      'security',
      <String>['import', file.path, '-k', appKeychain, '-A'],
    );

    if (output.stderr.contains(_keychainItemAlreadyExist)) {
      logger.logError(
        '${file.path} already exists in the $appKeychain keychain.',
      );
    } else if (output.stderr.isNotEmpty) {
      throw UnrecoverableException(output.stderr, ExitCode.unavailable.code);
    }
  }

  ///
  @visibleForTesting
  void createKeychain(String name) {
    logger.logInfo('Creating keychain $name...');

    final ShellOutput output = runner.execute(
      'security',
      <String>['create-keychain', '-p', name, name],
    );

    if (output.stderr.contains(_keychainExistMessage)) {
      throw const KeychainAlreadyExistException();
    } else if (output.stderr.isNotEmpty) {
      throw UnrecoverableException(output.stderr, ExitCode.unavailable.code);
    }

    logger.logSuccess('Created keychain $name.');
  }

  ///
  void deleteKeychain(String name) {
    logger.logInfo('Deleting keychain $name...');

    final ShellOutput output = runner.execute(
      'security',
      <String>['delete-keychain', name],
    );

    if (output.stderr.isNotEmpty) {
      throw UnrecoverableException(output.stderr, ExitCode.unavailable.code);
    }

    logger.logInfo('Deleted keychain $name.');
  }

  ///
  @visibleForTesting
  void unlockKeychain(final String name) {
    logger.logInfo('Unlocking keychain $name...');

    final ShellOutput output = runner.execute(
      'security',
      <String>['unlock-keychain', '-p', name, name],
    );

    if (output.stderr.isNotEmpty) {
      throw UnrecoverableException(output.stderr, ExitCode.unavailable.code);
    }

    logger.logInfo('Unlocked keychain $name');
  }

  ///
  @visibleForTesting
  void resetKeychainSettings(final String name) {
    logger.logInfo('Resetting keychain $name...');

    final ShellOutput output = runner.execute(
      'security',
      <String>['set-keychain-settings', name],
    );

    if (output.stderr.isNotEmpty) {
      throw UnrecoverableException(output.stderr, ExitCode.unavailable.code);
    }

    logger.logInfo('Reset keychain $name.');
  }

  ///
  void updateAppKeychainPartitionList() {
    final ShellOutput helpOutput = runner.execute('security', <String>['-h']);

    if (helpOutput.stdout.contains('set-key-partition-list')) {
      final ShellOutput output = runner.execute(
        'security',
        <String>[
          'set-key-partition-list',
          '-S',
          'apple-tool:,apple:,codesign:',
          '-s',
          '-k',
          appKeychain,
          appKeychain,
        ],
      );

      if (output.stderr.isNotEmpty) {
        throw UnrecoverableException(output.stderr, ExitCode.unavailable.code);
      }
    } else {
      logger.logError(
        'adding partition ids is not supported on this OS, skipping',
      );
    }
  }

  ///
  @visibleForTesting
  bool doesKeychainExist(final String name) {
    if (File(name).existsSync()) {
      return true;
    }

    final String? userHome = Platform.environment['HOME'];

    if (userHome != null) {
      return <String>['$userHome/$name', '$userHome/$name-db']
          .any((String path) => File(path).existsSync());
    }

    return false;
  }

  ///
  @visibleForTesting
  void updateKeychainSearchPaths(List<String> keychains) {
    logger.logInfo('Updating keychain search paths...');

    final ShellOutput output = runner.execute(
      'security',
      <String>['list-keychains', '-d', 'user', '-s', ...keychains],
    );

    if (output.stderr.isNotEmpty) {
      throw UnrecoverableException(output.stderr, ExitCode.unavailable.code);
    }

    logger.logInfo('Updated keychain search paths.');
  }

  ///
  @visibleForTesting
  String getDefaultKeychain() {
    final ShellOutput output = runner.execute(
      'security',
      <String>['default-keychain', '-d', 'user'],
    );

    if (output.stderr.isNotEmpty) {
      throw UnrecoverableException(output.stderr, ExitCode.unavailable.code);
    }

    final List<String> keychains = output.getKeychains();

    assert(keychains.length == 1, 'zero or more than one keychains found');

    return keychains.first;
  }

  ///
  @visibleForTesting
  List<String> listAllKeychains() {
    final List<String> keychains = <String>[];

    final ShellOutput output = runner.execute(
      'security',
      <String>['list-keychains', '-d', 'user'],
    );

    if (output.stderr.isNotEmpty) {
      throw UnrecoverableException(output.stderr, ExitCode.unavailable.code);
    }

    for (final String keychainPath in output.getKeychains()) {
      keychains.add(keychainPath.trim());
    }

    return keychains;
  }

  ///
  void makeKeychainDefault(String keychain) {
    logger.logInfo('Making keychain $keychain as default.');

    final ShellOutput output = runner.execute(
      'security',
      <String>['default-keychain', '-s', keychain],
    );

    if (output.stderr.isNotEmpty) {
      throw UnrecoverableException(output.stderr, ExitCode.unavailable.code);
    }

    logger.logInfo('$keychain is now default.');
  }

  ///
  String? getCertificateSha1Hash(String serialNumber) {
    final ShellOutput output = runner.execute(
      'security',
      <String>['find-certificate', '-a', '-Z', appKeychain],
    );

    final List<String> certificates = output.stdout
        .split('SHA-256')
        .where((String certificate) => certificate.trim().isNotEmpty)
        .toList();

    for (final String certificate in certificates) {
      String? certSerialNumber =
          _serialNumberFinder.stringMatch(certificate)?.trim();

      if (certSerialNumber?.startsWith('0') == true) {
        certSerialNumber = certSerialNumber!.substring(1);
      }

      if (certSerialNumber == serialNumber) {
        return _sha1Finder.stringMatch(certificate)?.trim();
      }
    }

    return null;
  }
}

extension _ShellOutputExtension on ShellOutput {
  List<String> getKeychains() {
    final String output = this.stdout.toString();

    return output
        .split(' ')
        .where((String line) => line.trim().isNotEmpty)
        // need to remove unnecessary " to have proper string because
        // the response look like this "/Library/Keychains/System.keychain"
        .map((String line) => line.trim().replaceAll('"', ''))
        .toList();
  }
}
