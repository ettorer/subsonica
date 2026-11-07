import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:subsonica/models/server_config.dart';

void main() {
  test('profile json keeps the name and drops a blank address', () {
    const home = ServerConfig(
      id: 'home',
      name: 'Home',
      baseUrl: 'https://music.example.com',
      username: 'ada',
      password: 'secret',
    );
    final decoded = decodeProfiles(
      jsonDecode(
        jsonEncode([
          home.toJson(),
          {
            'id': 'bad',
            'name': 'Broken',
            'baseUrl': 'ftp://nope',
            'username': 'ada',
            'password': 'secret',
          },
        ]),
      ),
    );
    expect(decoded, [home]);
  });

  test('a saved profile without a name uses the server host', () {
    final decoded = decodeProfiles([
      {
        'id': 'one',
        'baseUrl': 'https://subsonica.flydesktophome.stream/rest',
        'username': 'ada',
        'password': 'secret',
      },
    ]);
    expect(decoded.single.name, 'subsonica.flydesktophome.stream');
    expect(decoded.single.baseUrl, 'https://subsonica.flydesktophome.stream');
  });
}
