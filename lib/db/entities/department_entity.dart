class DepartmentEntity {
  final int id;
  final String name;
  final String phone;
  final DateTime lastSyncedAt;
  final bool isSynced;

  DepartmentEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.lastSyncedAt,
    required this.isSynced,
  });

  factory DepartmentEntity.fromMap(Map<String, dynamic> map) {
    return DepartmentEntity(
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

  factory DepartmentEntity.fromDepartmentModel(dynamic department) {
    return DepartmentEntity(
      id: department.id,
      name: department.name,
      phone: department.phone,
      lastSyncedAt: DateTime.now(),
      isSynced: true,
    );
  }

  DepartmentEntity copyWith({
    int? id,
    String? name,
    String? phone,
    DateTime? lastSyncedAt,
    bool? isSynced,
  }) {
    return DepartmentEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
