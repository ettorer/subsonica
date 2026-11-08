import 'dart:io';

import 'package:http/http.dart' as http;

bool isUnreachable(Object error) {
  return error is SocketException || error is http.ClientException;
}

bool isTlsFailure(Object error) => error is HandshakeException;
