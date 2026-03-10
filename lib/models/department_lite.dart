import 'department.dart';
import 'worker.dart';

class DepartmentLite {
  final int id;
  final String name;
  final String phone;
  final String initials;
  final bool hasPhone;

  DepartmentLite({
    required this.id,
    required this.name,
    required this.phone,
    required this.initials,
  }) : hasPhone = phone.isNotEmpty;

  // Factory desde JSON
  factory DepartmentLite.fromJson(Map<String, dynamic> json) {
    final name = _parseString(json['nombreDepartamento']);
    final phone = _parseString(json['numeroFijoDepartamento']);

    return DepartmentLite(
      id: json['id'] ?? 0,
      name: name,
      phone: phone,
      initials: _calculateInitials(name),
    );
  }

  // Factory desde Department completo
  factory DepartmentLite.fromDepartment(Department department) {
    return DepartmentLite(
      id: department.id,
      name: department.name,
      phone: department.phone,
      initials: _calculateInitials(department.name),
    );
  }

  // Métodos estáticos auxiliares
  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String _calculateInitials(String name) {
    if (name.isEmpty) return '??';

    // Tomar las primeras 2 letras o la primera si solo hay una palabra
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  // Convertir a Department completo
  Department toDepartment({List<Worker>? workers}) {
    return Department(
      id: id,
      name: name,
      phone: phone,
      workers: workers!.map((w) => w).toList(),
    );
  }

  // Para debugging
  @override
  String toString() {
    return 'DepartmentLite(id: $id, name: $name, phone: $phone)';
  }
}
