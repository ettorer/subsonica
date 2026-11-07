class ServerConfig {
  const ServerConfig({
    this.id = '',
    this.name = '',
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  final String id;
  final String name;
  final String baseUrl;
  final String username;
  final String password;

  bool sameServerAs(ServerConfig other) {
    return baseUrl == other.baseUrl &&
        username == other.username &&
        password == other.password;
  }

  Map<String, String> toJson() {
    return {
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'username': username,
      'password': password,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ServerConfig &&
        other.id == id &&
        other.name == name &&
        other.baseUrl == baseUrl &&
        other.username == username &&
        other.password == password;
  }

  @override
  int get hashCode => Object.hash(id, name, baseUrl, username, password);

  @override
  String toString() => 'ServerConfig($name, $baseUrl, $username)';
}

String newProfileId() {
  return DateTime.now().microsecondsSinceEpoch.toRadixString(16);
}

String profileNameFromUrl(String baseUrl) {
  final host = Uri.tryParse(baseUrl)?.host ?? '';
  if (host.isNotEmpty) return host;
  return 'Server';
}

List<ServerConfig> decodeProfiles(Object? decoded) {
  if (decoded is! List) return const [];
  final profiles = <ServerConfig>[];
  for (final item in decoded) {
    if (item is! Map) continue;
    final json = Map<String, Object?>.from(item);
    final baseUrl = normalizeServerUrl('${json['baseUrl'] ?? ''}');
    final username = json['username'];
    final password = json['password'];
    final name = json['name'];
    final id = json['id'];
    if (baseUrl == null || username is! String || username.isEmpty) continue;
    profiles.add(
      ServerConfig(
        id: id is String && id.isNotEmpty ? id : newProfileId(),
        name: name is String && name.trim().isNotEmpty
            ? name.trim()
            : profileNameFromUrl(baseUrl),
        baseUrl: baseUrl,
        username: username,
        password: password is String ? password : '',
      ),
    );
  }
  return profiles;
}

String? normalizeServerUrl(String input) {
  var text = input.trim();
  if (text.isEmpty) return null;
  if (!text.contains('://')) text = 'http://$text';
  final uri = Uri.tryParse(text);
  if (uri == null || uri.host.isEmpty) return null;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;

  final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
  final kept = <String>[];
  for (final segment in segments) {
    if (segment == 'rest') break;
    kept.add(segment);
  }
  final path = kept.isEmpty ? '' : '/${kept.join('/')}';
  return uri
      .replace(
        scheme: scheme,
        path: path,
        query: null,
        fragment: null,
        userInfo: '',
      )
      .toString();
}
