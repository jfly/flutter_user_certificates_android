import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'flutter_user_certificates_android_platform_interface.dart';

class FlutterUserCertificatesAndroid {
  Future<Map<String, DERCertificate>?> getUserCertificates() {
    return FlutterUserCertificatesAndroidPlatform.instance
        .getUserCertificates();
  }

  Future<void> trustAndroidUserCertificates(SecurityContext context) async {
    // User certificates are an Android specific concept. On other platforms,
    // there's nothing to do.
    if(!Platform.isAndroid) {
      return;
    }

    final certs = await this.getUserCertificates();
    if(certs == null) {
      print("No user certificates found");
      return;
    }

    for(var entry in certs.entries) {
      final name = entry.key;
      final keyData = entry.value;
      context.setTrustedCertificatesBytes(utf8.encode(keyData.toPEM()));
    }
  }
}

typedef DERCertificate = Uint8List;

typedef PEMCertificate = String;

extension DERExt on DERCertificate {
  PEMCertificate toPEM() {
    final bin = base64Encode(this);
    return '''-----BEGIN CERTIFICATE-----
$bin
-----END CERTIFICATE-----''';
  }
}

extension PEMExt on PEMCertificate {
  DERCertificate toDER() {
    final bin = replaceAll('-----BEGIN CERTIFICATE-----', '')
        .replaceAll('-----END CERTIFICATE-----', '')
        .replaceAll('\n', '');
    return base64Decode(bin);
  }

  List<int> get bytes => codeUnits;
}
