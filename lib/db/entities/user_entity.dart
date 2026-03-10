class UserEntity {
  final int id;
  final String username;
  final String email;
  final String displayRole;
  final bool isAdmin;
  final DateTime lastSyncedAt;
  final bool isSynced;

  UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.displayRole,
    required this.isAdmin,
    required this.lastSyncedAt,
    required this.isSynced,
  });

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'] as int,
      username: map['username'] as String,
      email: map['email'] as String,
      displayRole: map['display_role'] as String,
      isAdmin: map['is_admin'] == 1,
      lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(
        map['last_synced_at'] as int,
      ),
      isSynced: map['is_synced'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_role': displayRole,
      'is_admin': isAdmin ? 1 : 0,
      'last_synced_at': lastSyncedAt.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory UserEntity.fromUserModel(dynamic user) {
    return UserEntity(
      id: user.id,
      username: user.username,
      email: user.email,
      displayRole: user.displayRole,
      isAdmin: user.isAdmin,
      lastSyncedAt: DateTime.now(),
      isSynced: true,
    );
  }

  UserEntity copyWith({
    int? id,
    String? username,
    String? email,
    String? displayRole,
    bool? isAdmin,
    DateTime? lastSyncedAt,
    bool? isSynced,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayRole: displayRole ?? this.displayRole,
      isAdmin: isAdmin ?? this.isAdmin,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

// Entidad para guardar sesión de usuario actual
class SessionEntity {
  final int userId;
  final String token;
  final String refreshToken;
  final DateTime expiresAt;
  final DateTime loggedInAt;

  SessionEntity({
    required this.userId,
    required this.token,
    required this.refreshToken,
    required this.expiresAt,
    required this.loggedInAt,
  });

  factory SessionEntity.fromMap(Map<String, dynamic> map) {
    return SessionEntity(
      userId: map['user_id'] as int,
      token: map['token'] as String,
      refreshToken: map['refresh_token'] as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expires_at'] as int),
      loggedInAt: DateTime.fromMillisecondsSinceEpoch(
        map['logged_in_at'] as int,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'token': token,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.millisecondsSinceEpoch,
      'logged_in_at': loggedInAt.millisecondsSinceEpoch,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired;

  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());
}
