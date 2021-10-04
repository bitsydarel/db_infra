import 'dart:io';

///
class CertificateSigningRequest {
  ///
  final File request;

  ///
  final File privateKey;

  ///
  final File? publicKey;

  ///
  CertificateSigningRequest({
    required this.request,
    required this.privateKey,
    this.publicKey,
  });
}
