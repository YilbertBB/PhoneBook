class EfemerideEntity {
  final int id;
  final DateTime fecha;
  final String dato;
  final String detalle;
  final DateTime lastSyncedAt;
  final bool isSynced;

  EfemerideEntity({
    required this.id,
    required this.fecha,
    required this.dato,
    required this.detalle,
    required this.lastSyncedAt,
    required this.isSynced,
  });

  factory EfemerideEntity.fromMap(Map<String, dynamic> map) {
    return EfemerideEntity(
      id: map['id'] as int,
      fecha: DateTime.fromMillisecondsSinceEpoch(map['fecha'] as int),
      dato: map['dato'] as String,
      detalle: map['detalle'] as String,
      lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(
        map['last_synced_at'] as int,
      ),
      isSynced: map['is_synced'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fecha': fecha.millisecondsSinceEpoch,
      'dato': dato,
      'detalle': detalle,
      'last_synced_at': lastSyncedAt.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory EfemerideEntity.fromEfemerideModel(dynamic efemeride) {
    return EfemerideEntity(
      id: efemeride.id,
      fecha: efemeride.fecha,
      dato: efemeride.dato,
      detalle: efemeride.detalle,
      lastSyncedAt: DateTime.now(),
      isSynced: true,
    );
  }

  EfemerideEntity copyWith({
    int? id,
    DateTime? fecha,
    String? dato,
    String? detalle,
    DateTime? lastSyncedAt,
    bool? isSynced,
  }) {
    return EfemerideEntity(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      dato: dato ?? this.dato,
      detalle: detalle ?? this.detalle,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // Helper para obtener año, mes y día separados
  int get year => fecha.year;
  int get month => fecha.month;
  int get day => fecha.day;
}
