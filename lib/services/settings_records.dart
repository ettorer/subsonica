import '../models/server_config.dart';

class StoredConnections {
  const StoredConnections({required this.profiles, this.activeId});

  final List<ServerConfig> profiles;
  final String? activeId;
}
