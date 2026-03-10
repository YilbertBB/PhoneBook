class LocalEntity {
  final int id;
  final String name;
  final String phone;
  final DateTime lastSyncedAt;
  final bool isSynced;

  LocalEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.lastSyncedAt,
    required this.isSynced,
  });

  factory LocalEntity.fromMap(Map<String, dynamic> map) {
    return LocalEntity(
      id: map['id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String,
      lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(
        map['last_synced_at'] as int,
      ),
      isSynced: map['is_synced'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'last_synced_at': lastSyncedAt.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory LocalEntity.fromLocalModel(dynamic local) {
    return LocalEntity(
      id: local.id,
      name: local.name,
      phone: local.phone,
      lastSyncedAt: DateTime.now(),
      isSynced: true,
    );
  }

  LocalEntity copyWith({
    int? id,
    String? name,
    String? phone,
    DateTime? lastSyncedAt,
    bool? isSynced,
  }) {
    return LocalEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
