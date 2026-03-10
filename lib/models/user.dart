import 'base_model.dart';
import 'create_usuario_dto.dart';
import 'rol.dart';

class User implements BaseModel {
  @override
  final int id;
  final String username;
  final String email;
  final String password;
  final List<Rol> roles;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.roles,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['nombreUsuario'] ?? json['username'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      roles:
          (json['roles'] as List<dynamic>?)?.map((role) {
            if (role is Map<String, dynamic>) {
              return Rol.fromJson(role);
            } else if (role is String) {
              // Si es string, buscar el rol correspondiente
              if (role.toLowerCase() == 'admin') {
                return Rol.admin;
              } else {
                return Rol.consult;
              }
            } else {
              return Rol.consult; // Por defecto
            }
          }).toList() ??
          [Rol.consult],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreUsuario': username,
      'email': email,
      'password': password,
      'roles': roles.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Método para crear DTO para registro
  CreateUsuarioDto toCreateDto(String rolNombre) {
    return CreateUsuarioDto(
      nombreUsuario: username,
      email: email,
      password: password,
      rolNombre: rolNombre,
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? password,
    List<Rol>? roles,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      roles: roles ?? this.roles,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods usando tu modelo Rol
  bool get isAdmin => roles.any((role) => role.nombre.toLowerCase() == 'admin');
  bool get isConsult =>
      roles.any((role) => role.nombre.toLowerCase() == 'consult'); // Cambiado

  String get primaryRoleName => roles.isNotEmpty
      ? roles.first.nombre
      : 'consult'; // Por defecto 'consult'

  // Método para mostrar rol en UI
  String get displayRole {
    if (isAdmin) return 'Administrador';
    if (isConsult) return 'Consultor'; // Cambiado de 'Usuario' a 'Consultor'
    return 'Consultor';
  }
}
