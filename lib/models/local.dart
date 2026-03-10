import 'base_model.dart';
import 'worker.dart';

class Local implements BaseModel {
  @override
  final int id;
  final String name;
  final String phone;
  final List<Worker>? workers;

  Local({
    required this.id,
    required this.name,
    required this.phone,
    this.workers,
  });

  factory Local.fromJson(Map<String, dynamic> json) {
    return Local(
      id: json['id'] ?? 0,
      name: json['nombreLocal'] ?? '',
      phone: json['numeroFijoLocal'] ?? '',
      workers: (json['trabajadores'] as List<dynamic>?)
          ?.map((w) => Worker.fromJson(w))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreLocal': name,
      'numeroFijoLocal': phone,
      'trabajadores': workers?.map((w) => w.toJson()).toList(),
    };
  }

  Local copyWith({
    int? id,
    String? name,
    String? phone,
    List<Worker>? workers,
  }) {
    return Local(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      workers: workers ?? this.workers,
    );
  }

  // Helper methods
  int get workersCount => workers?.length ?? 0;
  bool get hasWorkers => workersCount > 0;

  // En local.dart, añade estos métodos:

  // Para crear un nuevo Local (POST) - solo lo que el backend espera
  Map<String, dynamic> toCreateDto() {
    final dto = <String, dynamic>{'nombreLocal': name};

    // Solo incluir numeroFijoLocal si tiene valor
    if (phone.isNotEmpty) {
      dto['numeroFijoLocal'] = phone;
    }

    return dto;
  }

  // Para actualizar un Local existente (PUT)
  Map<String, dynamic> toUpdateDto() {
    final dto = <String, dynamic>{};

    // Ambos campos son opcionales en update (PartialType)
    if (name.isNotEmpty) {
      dto['nombreLocal'] = name;
    }

    // Enviar phone incluso si está vacío (para limpiarlo)
    dto['numeroFijoLocal'] = phone;

    return dto;
  }
}
