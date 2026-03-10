class CreateUsuarioDto {
  final String nombreUsuario;
  final String email;
  final String password;
  final String rolNombre;

  CreateUsuarioDto({
    required this.nombreUsuario,
    required this.email,
    required this.password,
    required this.rolNombre,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombreUsuario': nombreUsuario.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'rolNombre': rolNombre,
    };
  }
}
