import 'base_model.dart';

class Rol implements BaseModel {
  @override
  final int id;
  final String nombre;

  Rol({required this.id, required this.nombre});

  factory Rol.fromJson(Map<String, dynamic> json) {
    return Rol(id: json['id'] ?? 0, nombre: json['rolNombre'] ?? '');
  }

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'rolNombre': nombre};
  }

  Rol copyWith({int? id, String? nombre}) {
    return Rol(id: id ?? this.id, nombre: nombre ?? this.nombre);
  }

  // Roles predefinidos según el backend
  static Rol get admin => Rol(id: 1, nombre: 'admin');
  static Rol get consult =>
      Rol(id: 2, nombre: 'consult'); // Cambiado de 'user' a 'consult'

  // Lista de todos los roles válidos
  static List<Rol> get all => [admin, consult];

  // Verificar si un string es un rol válido
  static bool isValidRol(String rolName) {
    return rolName == 'admin' || rolName == 'consult';
  }
}
