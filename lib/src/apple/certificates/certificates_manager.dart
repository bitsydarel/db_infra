import 'dart:io';

import 'package:db_infra/src/apple/certificates/api/appstoreconnectapi_certificates.dart';
import 'package:db_infra/src/apple/certificates/certificate.dart';
import 'package:db_infra/src/apple/certificates/certificate_signing_request.dart';
import 'package:db_infra/src/apple/certificates/certificate_type.dart';
import 'package:db_infra/src/apple/certificates/keychains_manager.dart';
import 'package:db_infra/src/logger.dart';
import 'package:db_infra/src/shell_runner.dart';
import 'package:db_infra/src/utils/exceptions.dart';
import 'package:db_infra/src/utils/file_utils.dart';
import 'package:io/io.dart';
import 'package:meta/meta.dart';

const String _privateKeyKeyword = 'BEGIN PRIVATE KEY';
const String _csrKeyword = 'BEGIN CERTIFICATE REQUEST';
const String _rsaPrivateKeyKeyword = 'BEGIN RSA PRIVATE KEY';
const String _publicKeyKeyword = 'BEGIN PUBLIC KEY';

// const String _appleWWDRCAName =
//     'Apple Worldwide Developer Relations Certification Authority';

// const String _appleWWDRCA =
//     'https://developer.apple.com/certificationauthority/AppleWWDRCA.cer';

// const String _appleWWDRCAG3 =
//     'https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer';

///
class CertificatesManager {
  ///
  final KeychainsManager _keychainsManager;

  ///
  final AppStoreConnectApiCertificates _api;

  ///
  final Logger logger;

  ///
  final ShellRunner runner;

  ///
  CertificatesManager(
    this._keychainsManager,
    this.logger,
    this._api, {
    this.runner = const ShellRunner(),
  });

  ///
  Future<Certificate?> getCertificate(String certificateId) async {
    final List<Certificate> certificates = await _api.getAll();

    for (final Certificate certificate in certificates) {
      if (certificate.id == certificateId) {
        return certificate;
      }
    }

    return null;
  }

  ///
  String? importCertificateLocally(final Certificate certificate) {
    final File certificateFile = createCertificateFileFromBase64(
      contentAsBase64: certificate.content,
      filename: certificate.id,
    );

    importCertificateFileLocally(certificateFile);

    logger.logSuccess(
      'Added certificate ${certificate.id} - ${certificate.name} '
      'of type ${certificate.type} locally',
    );

    return _keychainsManager.getCertificateSha1Hash(certificate.serialNumber);
  }

  ///
  void importCertificateFileLocally(File certificateFile) {
    _keychainsManager.importIntoAppKeychain(certificateFile);
  }

  ///
  Future<Certificate> createCertificate(
    final File csr,
    final CertificateType certificateType,
  ) {
    return _api.create(csr.readAsStringSync(), certificateType);
  }

  ///
  Future<void> deleteCertificateOfType(CertificateType type) async {
    final List<Certificate> certificates = await _api.getAll();

    return Future.forEach(certificates, (Certificate certificate) async {
      if (certificate.isDistribution()) {
        await _api.delete(certificate.id);
        logger.logSuccess(
          'Deleted certificate ${certificate.id} - ${certificate.name} '
          'of type ${certificate.type}',
        );
      }
    });
  }

  ///
  Future<bool> isSignedWithPrivateKey(
    final Certificate certificate,
    final File privateKey,
  ) async {
    final File certificateFile = createCertificateFileFromBase64(
      contentAsBase64: certificate.content,
      filename: certificate.id,
    );

    final String? certificateMd5 =
        await getMd5ForCertificate(certificateFile, certType: CertType.der);

    final String? privateKeyMd5 = await getMd5ForCertificate(privateKey);

    return certificateMd5 != null &&
        privateKeyMd5 != null &&
        certificateMd5 == privateKeyMd5;
  }

  ///
  Future<Certificate?> findCertificateSignedByKey(File privateKey) async {
    final List<Certificate> certificates = await _api.getAll();

    for (final Certificate certificate in certificates) {
      final bool isSignedByKey =
          await isSignedWithPrivateKey(certificate, privateKey);

      if (isSignedByKey) {
        return certificate;
      }
    }
    return null;
  }

  ///
  @visibleForTesting
  Future<String?> getMd5ForCertificate(
    final File certificate, {
    CertType? certType,
  }) async {
    certType ??= getCertificateTypeFromFile(certificate);

    switch (certType) {
      case CertType.rsa:
        return getRsaMd5(certificate);
      case CertType.csr:
        return getCsrMd5(certificate);
      case CertType.pkey:
        return getPKeyMd5(certificate);
      case CertType.der:
        return getDerMd5(certificate);
      case CertType.unknown:
        return null;
    }
  }

  ///
  @visibleForTesting
  Future<String?> getRsaMd5(final File certificate) async {
    final ShellOutput output = runner.execute(
      'openssl',
      <String>[
        'rsa',
        '-in',
        certificate.path,
        '-pubout',
        '-outform',
        'pem',
      ],
    );

    return getMd5FromOutput(output);
  }

  ///
  @visibleForTesting
  Future<String?> getCsrMd5(final File certificate) async {
    final ShellOutput output = runner.execute(
      'openssl',
      <String>[
        'req',
        '-in',
        certificate.path,
        '-pubkey',
        '-noout',
        '-outform',
        'pem',
      ],
    );

    return getMd5FromOutput(output);
  }

  ///
  @visibleForTesting
  Future<String?> getPKeyMd5(final File certificate) async {
    final ShellOutput output = runner.execute(
      'openssl',
      <String>[
        'pkey',
        '-in',
        certificate.path,
        '-pubout',
        '-outform',
        'pem',
      ],
    );

    return getMd5FromOutput(output);
  }

  ///
  @visibleForTesting
  Future<String?> getDerMd5(final File certificate) async {
    final ShellOutput pubKeyOutput = runner.execute(
      'openssl',
      <String>[
        'x509',
        '-inform',
        'DER',
        '-in',
        certificate.path,
        '-pubkey',
        '-noout',
        '-outform',
        'pem',
      ],
    );

    return getMd5FromOutput(pubKeyOutput);
  }

  ///
  @visibleForTesting
  Future<String?> getMd5FromOutput(final ShellOutput output) async {
    if (!output.stdout.contains(_publicKeyKeyword)) {
      throw UnrecoverableException(output.stderr, ExitCode.tempFail.code);
    }

    final File tempFileWithOutput = File(
      '${Directory.systemTemp.path}/certificate_pubkey',
    )..writeAsStringSync(output.stdout, flush: true);

    final ShellOutput md5Output = runner.execute(
      'openssl',
      <String>['md5', tempFileWithOutput.path],
    );

    if (md5Output.stderr.isNotEmpty) {
      throw UnrecoverableException(md5Output.stderr, ExitCode.tempFail.code);
    }

    final Iterable<String> lines = md5Output.stdout
        .split(' ')
        .where((String line) => line.trim().isNotEmpty);

    return lines.isNotEmpty ? lines.last.trim() : null;
  }

  ///
  @visibleForTesting
  CertType getCertificateTypeFromFile(final File file) {
    final String fileContent = file.readAsStringSync();

    if (fileContent.contains(_csrKeyword)) {
      return CertType.csr;
    }

    if (fileContent.contains(_privateKeyKeyword)) {
      return CertType.pkey;
    }

    if (fileContent.contains(_rsaPrivateKeyKeyword)) {
      return CertType.rsa;
    }

    return CertType.unknown;
  }

  ///
  Future<void> deleteAllCertificates() async {
    final List<Certificate> certificates = await _api.getAll();

    for (final Certificate certificate in certificates) {
      await _api.delete(certificate.id);
    }
  }

  ///
  CertificateSigningRequest createCertificateSigningRequest(
    final String appId, [
    final String? csrEmail,
    final String? csrName,
    final File? privateKey,
  ]) {
    final String privateKeyFileName = '$appId-private.pem';
    final String publicKeyFileName = '$appId-public.pem';
    final String csrKeyFileName = '$appId.certSigningRequest';

    _getOrCreatePrivateKey(privateKey, privateKeyFileName);

    _createCsrKey(
      privateKeyFileName: privateKeyFileName,
      csrKeyFileName: csrKeyFileName,
      csrEmail: csrEmail,
      csrName: csrName,
    );

    _createPublicRsaKey(privateKeyFileName, publicKeyFileName);

    final File csrFile = File(csrKeyFileName);
    final File privateKeyFile = File(privateKeyFileName);
    final File publicKeyFile = File(publicKeyFileName);

    if (!csrFile.existsSync() ||
        !privateKeyFile.existsSync() ||
        !publicKeyFile.existsSync()) {
      throw UnrecoverableException(
        'Certificate signing request could not be created',
        ExitCode.cantCreate.code,
      );
    }

    return CertificateSigningRequest(
      request: csrFile,
      privateKey: privateKeyFile,
      publicKey: publicKeyFile,
    );
  }

  void _getOrCreatePrivateKey(File? privateKey, String privateKeyFileName) {
    if (privateKey != null && privateKey.existsSync()) {
      logger.logInfo('Reusing CSR Private Key $privateKeyFileName.');

      File(privateKeyFileName).writeAsBytesSync(
        privateKey.readAsBytesSync(),
        mode: FileMode.writeOnly,
        flush: true,
      );
    } else {
      logger.logInfo('Creating CSR Private Key $privateKeyFileName...');

      final ShellOutput rsaOutput = runner.execute(
        'openssl',
        <String>['genrsa', '-out', privateKeyFileName, '2048'],
      );

      if (rsaOutput.stderr.isNotEmpty &&
          !rsaOutput.stderr.contains('Generating RSA private key')) {
        throw UnrecoverableException(rsaOutput.stderr, ExitCode.tempFail.code);
      }

      logger.logSuccess('Created CSR Private Key $privateKeyFileName.');
    }
  }

  void _createCsrKey({
    required String privateKeyFileName,
    required String csrKeyFileName,
    String? csrEmail,
    String? csrName,
  }) {
    logger.logInfo(
      'Creating $csrKeyFileName from Private Key $privateKeyFileName...',
    );

    final List<String> arguments = <String>[
      'req',
      '-new',
      '-key',
      privateKeyFileName,
      '-out',
      csrKeyFileName,
    ];

    final String subject;

    if (csrEmail != null && csrName != null) {
      subject = '/emailAddress=$csrEmail/CN=$csrName';
    } else {
      subject = '/';
    }

    arguments.addAll(<String>['-subj', subject]);

    final ShellOutput csrOutput = runner.execute('openssl', arguments);

    if (csrOutput.stderr.isNotEmpty) {
      throw UnrecoverableException(csrOutput.stderr, ExitCode.tempFail.code);
    }

    logger.logSuccess(
      'Created $csrKeyFileName from Private Key $privateKeyFileName',
    );
  }

  void _createPublicRsaKey(
    String privateKeyFileName,
    String publicKeyFileName,
  ) {
    logger.logInfo(
      'Creating $publicKeyFileName from Private Key $privateKeyFileName...',
    );

    final ShellOutput publicRsaOutput = runner.execute(
      'openssl',
      <String>[
        'rsa',
        '-in',
        privateKeyFileName,
        '-outform',
        'PEM',
        '-pubout',
        '-out',
        publicKeyFileName,
      ],
    );

    if (publicRsaOutput.stderr.isNotEmpty &&
        !publicRsaOutput.stderr.contains('writing RSA key')) {
      throw UnrecoverableException(
        publicRsaOutput.stderr,
        ExitCode.tempFail.code,
      );
    }

    logger.logSuccess(
      'Created $publicKeyFileName from Private Key $privateKeyFileName',
    );
  }

  ///
  Future<void> cleanupLocally() async {
    _keychainsManager.deleteKeychain(_keychainsManager.appKeychain);
  }
}

///
@visibleForTesting
enum CertType {
  ///
  rsa,

  ///
  csr,

  ///
  pkey,

  ///
  der,

  ///
  unknown,
}
