import 'dart:io';

import 'package:flutter/services.dart';

const karaokeCertAsset = 'assets/karaoke/server.crt';
const karaokeKeyAsset = 'assets/karaoke/server.key';

/// A security context when this build bundled both PEM files.
/// A missing or unreadable file leaves the secure server off.
Future<SecurityContext?> loadKaraokeSecurityContext() async {
  final cert = await _asset(karaokeCertAsset);
  final key = await _asset(karaokeKeyAsset);
  if (cert == null || key == null) return null;
  try {
    return SecurityContext()
      ..useCertificateChainBytes(cert)
      ..usePrivateKeyBytes(key);
  } catch (_) {
    return null;
  }
}

Future<List<int>?> _asset(String name) async {
  try {
    final data = await rootBundle.load(name);
    if (data.lengthInBytes == 0) return null;
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } catch (_) {
    return null;
  }
}
