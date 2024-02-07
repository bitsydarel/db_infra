import 'dart:io';

///
class CertificateSigningRequest {
  ///
  final File? request;

  ///
  final File privateKey;

  ///
  final File publicKey;

  ///
  CertificateSigningRequest({
    required this.publicKey,
    required this.privateKey,
    this.request,
  });
}
