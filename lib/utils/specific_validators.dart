import 'error_messages.dart';

class SpecificValidators {
  // Validación específica para carnet de identidad cubano
  static String? validateCarnetID(String? value, {bool required = true}) {
    if (!required && (value == null || value.isEmpty)) {
      return null;
    }

    if (value == null || value.isEmpty) {
      return 'El carnet de identidad es requerido';
    }

    final trimmedValue = value.trim();

    // Debe tener exactamente 11 dígitos
    if (trimmedValue.length != 11) {
      return ErrorMessages.invalidCarnetFormat;
    }

    // Solo números
    final onlyNumbersRegex = RegExp(r'^[0-9]+$');
    if (!onlyNumbersRegex.hasMatch(trimmedValue)) {
      return ErrorMessages.invalidCarnetFormat;
    }

    // Validar provincia (01-16 para Cuba)
    final provinceCode = int.tryParse(trimmedValue.substring(0, 2));
    if (provinceCode == null || provinceCode < 1 || provinceCode > 16) {
      return ErrorMessages.carnetProvinceInvalid;
    }

    return null;
  }

  // Validación específica para fecha de cumpleaños
  static String? validateBirthday(String? value, {bool required = false}) {
    if (!required && (value == null || value.isEmpty)) {
      return null;
    }

    if (value == null || value.isEmpty) {
      return required ? 'La fecha de cumpleaños es requerida' : null;
    }

    final trimmedValue = value.trim();

    // Verificar formato YYYY-MM-DD
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(trimmedValue)) {
      return 'Formato inválido. Use YYYY-MM-DD';
    }

    try {
      final parts = trimmedValue.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      // Validaciones básicas
      if (year < 1900 || year > DateTime.now().year) {
        return 'Año inválido (1900-${DateTime.now().year})';
      }

      if (month < 1 || month > 12) {
        return 'Mes inválido (1-12)';
      }

      // Validar días según el mes
      final daysInMonth = DateTime(year, month + 1, 0).day;
      if (day < 1 || day > daysInMonth) {
        return 'Día inválido para el mes seleccionado';
      }

      // No permitir fechas futuras
      final birthday = DateTime(year, month, day);
      if (birthday.isAfter(DateTime.now())) {
        return ErrorMessages.birthdayFutureDate;
      }

      // No permitir edades extremas (opcional)
      final age = DateTime.now().year - year;
      if (age > 120) {
        return 'Edad no válida';
      }
    } catch (e) {
      return 'Fecha inválida';
    }

    return null;
  }

  // Validación específica para fecha de efeméride
  static String? validateEfemerideDate(int year, int month, int day) {
    try {
      final date = DateTime(year, month, day);

      // Verificar que la fecha creada coincida
      if (date.year != year || date.month != month || date.day != day) {
        return ErrorMessages.efemerideInvalidDate;
      }

      // Opcional: no permitir fechas muy antiguas o futuras extremas
      if (year < 1000 || year > 2100) {
        return 'El año debe estar entre 1000 y 2100';
      }

      return null;
    } catch (e) {
      return ErrorMessages.efemerideInvalidDate;
    }
  }
}
