class Validators {
  // Valida si es un email válido
  static String? validateEmail(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'El email es requerido' : null;
    }

    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return required ? 'El email es requerido' : null;
    }

    // Expresión regular mejorada para email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]{1,64}@[a-zA-Z0-9.-]{1,255}\.[a-zA-Z]{2,63}$',
    );

    if (!emailRegex.hasMatch(trimmedValue)) {
      return 'Ingrese un email válido (ejemplo: usuario@dominio.com)';
    }

    // Validación adicional de estructura
    if (trimmedValue.contains('..')) {
      return 'El email no puede contener puntos consecutivos';
    }

    if (trimmedValue.startsWith('.') || trimmedValue.endsWith('.')) {
      return 'El email no puede comenzar o terminar con punto';
    }

    final parts = trimmedValue.split('@');
    if (parts.length != 2) {
      return 'Formato de email inválido';
    }

    final localPart = parts[0];
    final domainPart = parts[1];

    // Validar longitud del local part
    if (localPart.length > 64) {
      return 'La parte local del email no puede exceder 64 caracteres';
    }

    // Validar que el dominio tenga al menos un punto
    if (!domainPart.contains('.')) {
      return 'El dominio del email debe contener un punto';
    }

    return null;
  }

  // Valida username (para registro)
  static String? validateUsername(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'El nombre de usuario es requerido' : null;
    }

    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return required ? 'El nombre de usuario es requerido' : null;
    }

    // Longitud
    if (trimmedValue.length < 3) {
      return 'El nombre de usuario debe tener al menos 3 caracteres';
    }

    if (trimmedValue.length > 30) {
      return 'El nombre de usuario no puede exceder 30 caracteres';
    }

    // Caracteres permitidos: letras, números, guiones bajos y puntos
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_.]+$');
    if (!usernameRegex.hasMatch(trimmedValue)) {
      return 'Solo se permiten letras, números, puntos y guiones bajos (_)';
    }

    // No puede comenzar o terminar con punto o guión bajo
    if (trimmedValue.startsWith('.') || trimmedValue.startsWith('_')) {
      return 'No puede comenzar con punto o guión bajo';
    }

    if (trimmedValue.endsWith('.') || trimmedValue.endsWith('_')) {
      return 'No puede terminar con punto o guión bajo';
    }

    // No puede tener puntos o guiones bajos consecutivos
    if (trimmedValue.contains('..') || trimmedValue.contains('__')) {
      return 'No puede tener puntos o guiones bajos consecutivos';
    }

    // No puede ser solo números
    final onlyNumbersRegex = RegExp(r'^[0-9]+$');
    if (onlyNumbersRegex.hasMatch(trimmedValue)) {
      return 'El nombre de usuario no puede ser solo números';
    }

    return null;
  }

  // Valida campo de login (puede ser username o email)
  static String? validateUsernameOrEmail(
    String? value, {
    bool required = true,
  }) {
    if (value == null || value.isEmpty) {
      return required ? 'Usuario o email es requerido' : null;
    }

    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return required ? 'Usuario o email es requerido' : null;
    }

    // Longitud mínima
    if (trimmedValue.length < 3) {
      return 'Debe tener al menos 3 caracteres';
    }

    // Longitud máxima
    if (trimmedValue.length > 254) {
      // Longitud máxima para email según RFC
      return 'No puede exceder 254 caracteres';
    }

    // Si parece un email, validar como email
    if (trimmedValue.contains('@')) {
      return validateEmail(trimmedValue, required: required);
    }

    // Si no contiene @, validar como username (pero con reglas más flexibles para login)
    if (trimmedValue.length > 50) {
      return 'El nombre de usuario no puede exceder 50 caracteres';
    }

    // Para login, ser más permisivo con el username
    final loginUsernameRegex = RegExp(r'^[a-zA-Z0-9_.@\-+]+$');
    if (!loginUsernameRegex.hasMatch(trimmedValue)) {
      return 'Caracteres no válidos detectados';
    }

    return null;
  }

  // Valida contraseña
  static String? validatePassword(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'La contraseña es requerida' : null;
    }

    // Longitud
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    if (value.length > 128) {
      return 'La contraseña no puede exceder 128 caracteres';
    }

    // Seguridad básica (opcional, puedes ajustar según necesidades)
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);

    if (!hasLetter || !hasNumber) {
      return 'Para mayor seguridad, incluye letras y números';
    }

    // Verificar espacios
    if (value.contains(' ')) {
      return 'La contraseña no puede contener espacios';
    }

    return null;
  }

  // Valida confirmación de contraseña
  static String? validateConfirmPassword(
    String? value,
    String password, {
    bool required = true,
  }) {
    if (value == null || value.isEmpty) {
      return required ? 'Confirme la contraseña' : null;
    }

    if (value != password) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  // Valida campo requerido genérico
  static String? validateRequired(
    String? value,
    String fieldName, {
    int? minLength,
    int? maxLength,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }

    final trimmedValue = value.trim();

    if (minLength != null && trimmedValue.length < minLength) {
      return '$fieldName debe tener al menos $minLength caracteres';
    }

    if (maxLength != null && trimmedValue.length > maxLength) {
      return '$fieldName no puede exceder $maxLength caracteres';
    }

    return null;
  }

  // Valida teléfono
  static String? validatePhone(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'El teléfono es requerido' : null;
    }

    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty && !required) {
      return null;
    }

    // Eliminar espacios, guiones y paréntesis para validación
    final cleanPhone = trimmedValue.replaceAll(RegExp(r'[\s\-()]'), '');

    // Solo números y posible signo + al inicio
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');

    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Ingrese un número de teléfono válido (7-15 dígitos)';
    }

    // Validar que no sea todo el mismo número
    final allSameDigits = RegExp(
      r'^(\d)\1+$',
    ).hasMatch(cleanPhone.replaceAll('+', ''));
    if (allSameDigits) {
      return 'El número de teléfono no parece válido';
    }

    return null;
  }

  // Valida formato de nombre (para nombres de personas)
  static String? validateName(
    String? value,
    String fieldName, {
    bool required = true,
  }) {
    if (value == null || value.isEmpty) {
      return required ? '$fieldName es requerido' : null;
    }

    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return required ? '$fieldName es requerido' : null;
    }

    // Longitud
    if (trimmedValue.length < 2) {
      return '$fieldName debe tener al menos 2 caracteres';
    }

    if (trimmedValue.length > 50) {
      return '$fieldName no puede exceder 50 caracteres';
    }

    // Solo letras, espacios y algunos caracteres especiales permitidos
    final nameRegex = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s'\-.,]+$");
    if (!nameRegex.hasMatch(trimmedValue)) {
      return '$fieldName solo puede contener letras y espacios';
    }

    // No puede tener múltiples espacios consecutivos
    if (trimmedValue.contains('  ')) {
      return '$fieldName no puede tener múltiples espacios consecutivos';
    }

    return null;
  }
}
