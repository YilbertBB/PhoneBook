import 'department.dart';
import 'local.dart';
import 'worker.dart';

class WorkerLite {
  final int id;
  final String name;
  final String lastName;
  final String carnetID;
  final String phone;
  final String initials;
  final String fullName;
  final bool hasPhone;
  final int? departamentoID;
  final int? localId;
  final String? departmentName;
  final String? localName;
  final String? fechaCumpleannos;

  WorkerLite({
    required this.id,
    required this.name,
    required this.lastName,
    required this.carnetID,
    required this.phone,
    required this.initials,
    required this.fullName,
    this.departamentoID,
    this.localId,
    this.departmentName,
    this.localName,
    this.fechaCumpleannos,
  }) : hasPhone = phone.isNotEmpty;

  // Factory desde JSON ligero (para API paginada)
  factory WorkerLite.fromJson(Map<String, dynamic> json) {
    final name = _parseString(json['nombre']);
    final lastName = _parseString(json['apellido']);
    final carnetID = _parseString(json['carnetIdentidad']);
    final phone = _parseString(json['numeroCelular']);

    // Extraer departamento (puede venir como objeto o como ID)
    int? departamentoID;
    String? departmentName;
    if (json['departamento'] is Map) {
      departamentoID = json['departamento']['id'];
      departmentName =
          json['departamento']['nombreDepartamento'] ??
          json['departamento']['nombre'];
    } else {
      departamentoID = json['departamentoId'];
      // Si solo tenemos ID, no tenemos el nombre
    }

    // Extraer local (puede venir como objeto o como ID)
    int? localId;
    String? localName;
    if (json['local'] is Map) {
      localId = json['local']['id'];
      localName = json['local']['nombreLocal'] ?? json['local']['nombre'];
    } else {
      localId = json['localId'];
      // Si solo tenemos ID, no tenemos el nombre
    }

    return WorkerLite(
      id: json['id'] ?? 0,
      name: name,
      lastName: lastName,
      carnetID: carnetID,
      phone: phone,
      initials: _calculateInitials(name, lastName),
      fullName: '$name $lastName'.trim(),
      departamentoID: departamentoID,
      localId: localId,
      departmentName: departmentName,
      localName: localName,
      fechaCumpleannos: _parseString(json['fechaCumpleanno']),
    );
  }

  // Factory desde Worker completo (para convertir de cache)
  factory WorkerLite.fromWorker(Worker worker) {
    return WorkerLite(
      id: worker.id,
      name: worker.name,
      lastName: worker.lastName,
      carnetID: worker.carnetID,
      phone: worker.phone,
      initials: worker.initials,
      fullName: worker.fullName,
      departamentoID: worker.departamentoID,
      localId: worker.localId,
      departmentName: worker.department?.name,
      localName: worker.local?.name,
      fechaCumpleannos: worker.fechaCumpleannos,
    );
  }

  // Métodos estáticos auxiliares
  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String _calculateInitials(String name, String lastName) {
    if (name.isEmpty) return '??';
    final first = name[0];
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  // Convertir a Worker completo (cuando se necesite detalles)
  Worker toWorker({Department? department, Local? local}) {
    // Si no se pasan department/local como parámetros, intentar crearlos desde los datos disponibles
    final resolvedDepartment =
        department ??
        (departamentoID != null && departmentName != null
            ? Department(id: departamentoID!, name: departmentName!, phone: '')
            : null);

    final resolvedLocal =
        local ??
        (localId != null && localName != null
            ? Local(id: localId!, name: localName!, phone: '')
            : null);

    return Worker(
      id: id,
      name: name,
      lastName: lastName,
      carnetID: carnetID,
      phone: phone,
      address: '', // No disponible en lite
      fechaCumpleannos: fechaCumpleannos ?? '',
      department: resolvedDepartment,
      local: resolvedLocal,
    );
  }

  // Para debugging
  @override
  String toString() {
    return 'WorkerLite(id: $id, name: $fullName, phone: $phone)';
  }
}
