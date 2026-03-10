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
    this.fechaCumpleannos,
  }) : hasPhone = phone.isNotEmpty;

  // Factory desde JSON ligero (para API paginada)
  factory WorkerLite.fromJson(Map<String, dynamic> json) {
    final name = _parseString(json['nombre']);
    final lastName = _parseString(json['apellido']);
    final carnetID = _parseString(json['carnetIdentidad']);
    final phone = _parseString(json['numeroCelular']);

    return WorkerLite(
      id: json['id'] ?? 0,
      name: name,
      lastName: lastName,
      carnetID: carnetID,
      phone: phone,
      initials: _calculateInitials(name, lastName),
      fullName: '$name $lastName'.trim(),
      departamentoID: json['departamentoId'] ?? json['departamento']?['id'],
      localId: json['localId'] ?? json['local']?['id'],
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
    return Worker(
      id: id,
      name: name,
      lastName: lastName,
      carnetID: carnetID,
      phone: phone,
      address: '', // No disponible en lite
      fechaCumpleannos: fechaCumpleannos ?? '',
      department: department,
      local: local,
    );
  }

  // Para debugging
  @override
  String toString() {
    return 'WorkerLite(id: $id, name: $fullName, phone: $phone)';
  }
}
