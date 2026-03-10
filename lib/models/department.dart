import 'base_model.dart';
import 'worker.dart';

class Department implements BaseModel {
  @override
  final int id;
  final String name;
  final String phone;
  final List<Worker>? workers;

  Department({
    required this.id,
    required this.name,
    required this.phone,
    this.workers,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      name: json['nombreDepartamento'] ?? '',
      phone: json['numeroFijoDepartamento'] ?? '',
      workers: (json['trabajadores'] as List<dynamic>?)
          ?.map((w) => Worker.fromJson(w))
          .toList(),
    );
  }

  Department copyWith({
    int? id,
    String? name,
    String? phone,
    List<Worker>? workers,
  }) {
    return Department(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      workers: workers ?? this.workers,
    );
  }

  // Helper methods
  int get workersCount => workers?.length ?? 0;
  bool get hasWorkers => workersCount > 0;

  // En department.dart, añade métodos DTO específicos:

  // Para crear un nuevo Departamento (POST)
  Map<String, dynamic> toCreateDto() {
    final dto = <String, dynamic>{'nombreDepartamento': name};

    // Solo incluir numeroFijoDepartamento si tiene valor
    if (phone.isNotEmpty) {
      dto['numeroFijoDepartamento'] = phone;
    }

    return dto;
  }

  // Para actualizar un Departamento existente (PUT)
  Map<String, dynamic> toUpdateDto() {
    final dto = <String, dynamic>{};

    // Ambos campos son opcionales en update (PartialType)
    if (name.isNotEmpty) {
      dto['nombreDepartamento'] = name;
    }

    // Enviar phone incluso si está vacío (para limpiarlo)
    dto['numeroFijoDepartamento'] = phone;

    return dto;
  }

  // Mantén toJson() para otros usos internos
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreDepartamento': name,
      'numeroFijoDepartamento': phone,
      'trabajadores': workers?.map((w) => w.toJson()).toList(),
    };
  }
}
