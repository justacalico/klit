import 'dart:convert';

/// Configuration for HTTP proxy
class ProxyConfig {
  final bool enabled;
  final String host;
  final int port;
  final bool useAuthentication;
  final String? username;
  final String? password;

  const ProxyConfig({
    this.enabled = false,
    this.host = '',
    this.port = 8080,
    this.useAuthentication = false,
    this.username,
    this.password,
  });

  /// Create a copy with updated values
  ProxyConfig copyWith({
    bool? enabled,
    String? host,
    int? port,
    bool? useAuthentication,
    String? username,
    String? password,
  }) {
    return ProxyConfig(
      enabled: enabled ?? this.enabled,
      host: host ?? this.host,
      port: port ?? this.port,
      useAuthentication: useAuthentication ?? this.useAuthentication,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  /// Check if the proxy configuration is valid
  bool get isValid {
    if (!enabled) return true;
    if (host.isEmpty) return false;
    if (port <= 0 || port > 65535) return false;
    if (useAuthentication && (username == null || username!.isEmpty)) {
      return false;
    }
    return true;
  }

  /// Get the proxy URL string (e.g., "http://host:port" or "http://user:pass@host:port")
  String? get proxyUrl {
    if (!enabled || host.isEmpty) return null;

    if (useAuthentication && username != null && username!.isNotEmpty) {
      final encodedUser = Uri.encodeComponent(username!);
      final encodedPass = Uri.encodeComponent(password ?? '');
      return 'http://$encodedUser:$encodedPass@$host:$port';
    }
    return 'http://$host:$port';
  }

  /// Get the PROXY directive string for Dart's HttpClient.findProxy
  /// Format: "PROXY host:port" or "DIRECT"
  String get findProxyString {
    if (!enabled || host.isEmpty) return 'DIRECT';
    return 'PROXY $host:$port';
  }

  /// Create from JSON
  factory ProxyConfig.fromJson(Map<String, dynamic> json) {
    return ProxyConfig(
      enabled: json['enabled'] as bool? ?? false,
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? 8080,
      useAuthentication: json['useAuthentication'] as bool? ?? false,
      username: json['username'] as String?,
      password: json['password'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'host': host,
      'port': port,
      'useAuthentication': useAuthentication,
      'username': username,
      'password': password,
    };
  }

  /// Create from JSON string
  factory ProxyConfig.fromJsonString(String jsonString) {
    return ProxyConfig.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }

  /// Convert to JSON string
  String toJsonString() => json.encode(toJson());

  @override
  String toString() {
    if (!enabled) return 'Proxy: Disabled';
    if (useAuthentication) {
      return 'Proxy: $username@$host:$port';
    }
    return 'Proxy: $host:$port';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProxyConfig &&
        other.enabled == enabled &&
        other.host == host &&
        other.port == port &&
        other.useAuthentication == useAuthentication &&
        other.username == username &&
        other.password == password;
  }

  @override
  int get hashCode {
    return Object.hash(
      enabled,
      host,
      port,
      useAuthentication,
      username,
      password,
    );
  }
}
