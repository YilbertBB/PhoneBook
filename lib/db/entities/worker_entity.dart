class WorkerEntity {
  final int id;
  final String name;
  final String lastName;
  final String carnetID;
  final String phone;
  final String address;
  final String fechaCumpleannos;
  final int? departamentoId;
  final String? departamentoNombre;
  final int? localId;
  final String? localNombre;
  final DateTime lastSyncedAt;
  final bool isSynced;

  WorkerEntity({
    required this.id,
    required this.name,
    required this.lastName,
    required this.carnetID,
    required this.phone,
    required this.address,
    required this.fechaCumpleannos,
    this.departamentoId,
    this.departamentoNombre,
    this.localId,
    this.localNombre,
    required this.lastSyncedAt,
    required this.isSynced,
  });

  // Convertir de JSON (base de datos) a entidad
  factory WorkerEntity.fromMap(Map<String, dynamic> map) {
    return WorkerEntity(
      id: map['id'] as int,
      name: map['name'] as String,
      lastName: map['last_name'] as String,
      carnetID: map['carnet_id'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String,
      fechaCumpleannos: map['fecha_cumpleannos'] as String,
      departamentoId: map['departamento_id'] as int?,
      departamentoNombre: map['departamento_nombre'] as String?,
      localId: map['local_id'] as int?,
      localNombre: map['local_nombre'] as String?,
      lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(
        map['last_synced_at'] as int,
      ),
      isSynced: map['is_synced'] == 1,
    );
  }

  // Convertir de entidad a JSON (base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'last_name': lastName,
      'carnet_id': carnetID,
      'phone': phone,
      'address': address,
      'fecha_cumpleannos': fechaCumpleannos,
      'departamento_id': departamentoId,
      'departamento_nombre': departamentoNombre,
      'local_id': localId,
      'local_nombre': localNombre,
      'last_synced_at': lastSyncedAt.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  // Convertir desde el modelo de API (Worker) a entidad
  factory WorkerEntity.fromWorkerModel(dynamic worker) {
    return WorkerEntity(
      id: worker.id,
      name: worker.name,
      lastName: worker.lastName,
      carnetID: worker.carnetID,
      phone: worker.phone,
      address: worker.address,
      fechaCumpleannos: worker.fechaCumpleannos,
      departamentoId: worker.department?.id,
      departamentoNombre: worker.department?.name,
      localId: worker.local?.id,
      localNombre: worker.local?.name,
      lastSyncedAt: DateTime.now(),
      isSynced: true,
    );
  }

  WorkerEntity copyWith({
    int? id,
    String? name,
    String? lastName,
    String? carnetID,
    String? phone,
    String? address,
    String? fechaCumpleannos,
    int? departamentoId,
    String? departamentoNombre,
    int? localId,
    String? localNombre,
    DateTime? lastSyncedAt,
    bool? isSynced,
  }) {
    return WorkerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      carnetID: carnetID ?? this.carnetID,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      fechaCumpleannos: fechaCumpleannos ?? this.fechaCumpleannos,
      departamentoId: departamentoId ?? this.departamentoId,
      departamentoNombre: departamentoNombre ?? this.departamentoNombre,
      localId: localId ?? this.localId,
      localNombre: localNombre ?? this.localNombre,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
