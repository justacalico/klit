import 'dart:convert';

/// Model representing a user account for e621 API
class Account {
  final String id;
  final String username;
  final String apiKey;
  final String host;
  final DateTime createdAt;
  final bool isActive;

  const Account({
    required this.id,
    required this.username,
    required this.apiKey,
    required this.host,
    required this.createdAt,
    this.isActive = false,
  });

  /// Create an Account from JSON
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      username: json['username'] as String,
      apiKey: json['api_key'] as String,
      host: json['host'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  /// Convert Account to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'api_key': apiKey,
      'host': host,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Create a copy with modified fields
  Account copyWith({
    String? id,
    String? username,
    String? apiKey,
    String? host,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Account(
      id: id ?? this.id,
      username: username ?? this.username,
      apiKey: apiKey ?? this.apiKey,
      host: host ?? this.host,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Get basic auth header value
  String get basicAuthHeader {
    final credentials = base64Encode(utf8.encode('$username:$apiKey'));
    return 'Basic $credentials';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Account(id: $id, username: $username, host: $host)';
}
