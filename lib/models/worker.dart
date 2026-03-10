import 'package:flutter/material.dart';

import 'base_model.dart';
import 'department.dart';
import 'local.dart';
import 'worker_lite.dart'; // Para la factory fromLite

class Worker implements BaseModel {
  @override
  final int id;
  final String name;
  final String lastName;
  final String carnetID;
  final String phone;
  final String address;
  final String fechaCumpleannos;
  final Department? department;
  final Local? local;
  final int? cumpleannoId;

  DateTime? _cachedBirthdayDate;
  String? _cachedFormattedBirthday;
  String? _cachedFullName;
  String? _cachedInitials;
  String? _cachedPosition;
  String? _cachedSubdirection;
  bool? _cachedHasPhone;
  bool? _cachedHasDepartment;
  bool? _cachedHasLocal;
  bool? _cachedHasBirthday;

  // Constructor NORMAL (no const)
  Worker({
    required this.id,
    required this.name,
    required this.lastName,
    required this.carnetID,
    required this.phone,
    required this.address,
    required this.fechaCumpleannos,
    this.department,
    this.local,
    this.cumpleannoId,
  });

  // FACTORY desde JSON - MÁS EFICIENTE
  factory Worker.fromJson(Map<String, dynamic> json) {
    final worker = Worker(
      id: json['id'] ?? 0,
      name: _parseString(json['nombre']),
      lastName: _parseString(json['apellido']),
      carnetID: _parseString(json['carnetIdentidad']),
      address: _parseString(json['direccion']),
      phone: _parseString(json['numeroCelular']),
      fechaCumpleannos: _parseString(json['fechaCumpleanno']),
      department: json['departamento'] != null
          ? Department.fromJson(Map<String, dynamic>.from(json['departamento']))
          : null,
      local: json['local'] != null
          ? Local.fromJson(Map<String, dynamic>.from(json['local']))
          : null,
      cumpleannoId: json['cumpleannoId'],
    );

    // Inicializar caché después de crear la instancia
    worker._initializeCache();

    return worker;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  // Factory para crear desde entidad
  factory Worker.fromEntity(Map<String, dynamic> entity) {
    final worker = Worker(
      id: entity['id'] ?? 0,
      name: _parseString(entity['nombre']),
      lastName: _parseString(entity['apellido']),
      carnetID: _parseString(entity['carnetIdentidad']),
      address: _parseString(entity['direccion']),
      phone: _parseString(entity['numeroCelular']),
      fechaCumpleannos: _parseString(entity['fechaCumpleanno']),
    );

    worker._initializeCache();
    return worker;
  }

  // Factory desde WorkerLite
  factory Worker.fromLite(
    WorkerLite lite, {
    Department? department,
    Local? local,
  }) {
    final worker = Worker(
      id: lite.id,
      name: lite.name,
      lastName: lite.lastName,
      carnetID: lite.carnetID,
      phone: lite.phone,
      address: '', // No disponible en lite
      fechaCumpleannos: lite.fechaCumpleannos ?? '',
      department: department,
      local: local,
    );

    worker._initializeCache();
    return worker;
  }

  // MÉTODO PARA INICIALIZAR CACHÉ (llamar después de construir)
  void _initializeCache() {
    // Calcular y cachear propiedades una sola vez
    _cachedFullName = '$name $lastName'.trim();
    _cachedInitials = _calculateInitials();
    _cachedBirthdayDate = _parseBirthdayDateOptimized();
    _cachedFormattedBirthday = _formatBirthdayOptimized();
    _cachedPosition = department?.name ?? 'Sin departamento';
    _cachedSubdirection = local?.name ?? 'Sin local';
    _cachedHasPhone = phone.isNotEmpty;
    _cachedHasDepartment = department != null;
    _cachedHasLocal = local != null;
    _cachedHasBirthday = fechaCumpleannos.isNotEmpty;
  }

  // MÉTODOS PRIVADOS DE CÁLCULO
  String _calculateInitials() {
    if (name.isEmpty) return '??';
    final first = name[0];
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  DateTime? _parseBirthdayDateOptimized() {
    if (fechaCumpleannos.isEmpty) return null;

    // FORMATO 1: Texto español "17 de septiembre"
    try {
      final parts = fechaCumpleannos.toLowerCase().split(' de ');
      if (parts.length == 2) {
        final dayStr = parts[0].trim();
        final monthStr = parts[1].trim();

        final day = int.tryParse(dayStr);
        if (day == null) return null;

        // Mapeo de meses en español
        final monthMap = {
          'enero': 1,
          'febrero': 2,
          'marzo': 3,
          'abril': 4,
          'mayo': 5,
          'junio': 6,
          'julio': 7,
          'agosto': 8,
          'septiembre': 9,
          'octubre': 10,
          'noviembre': 11,
          'diciembre': 12,
          'ene': 1,
          'feb': 2,
          'mar': 3,
          'abr': 4,
          'may': 5,
          'jun': 6,
          'jul': 7,
          'ago': 8,
          'sep': 9,
          'oct': 10,
          'nov': 11,
          'dic': 12,
        };

        final month = monthMap[monthStr];
        if (month != null) {
          final now = DateTime.now();
          final year = now.year; // Usar año actual para calendario

          return DateTime(year, month, day);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error parseando español: $e');
    }

    // FORMATO 2: YYYY-MM-DD (ISO)
    try {
      final date = DateTime.parse(fechaCumpleannos);
      return date;
    } catch (_) {
      // Continuar con otros formatos
    }

    // FORMATO 3: dd/MM/yyyy
    try {
      final parts = fechaCumpleannos.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {
      // No se pudo parsear
    }

    // FORMATO 4: dd-MM-yyyy
    try {
      final parts = fechaCumpleannos.split('-');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {
      // No se pudo parsear
    }

    return null;
  }

  String _formatBirthdayOptimized() {
    if (fechaCumpleannos.isEmpty) return 'Fecha no disponible';

    final date = _cachedBirthdayDate;
    if (date == null) {
      // Si ya está en formato texto español, devolver tal cual
      if (_isSpanishTextFormat(fechaCumpleannos)) {
        return fechaCumpleannos;
      }
      return fechaCumpleannos;
    }

    // Convertir a formato texto español
    final monthNames = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${date.day} de ${monthNames[date.month - 1]}';
  }

  bool _isSpanishTextFormat(String date) {
    final lowercase = date.toLowerCase();
    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return months.any((month) => lowercase.contains(month)) &&
        lowercase.contains(' de ');
  }

  // GETTERS QUE USAN CACHÉ
  String get fullName => _cachedFullName ?? '$name $lastName'.trim();
  String get initials => _cachedInitials ?? _calculateInitials();
  String get position =>
      _cachedPosition ?? department?.name ?? 'Sin departamento';
  String get subdirection => _cachedSubdirection ?? local?.name ?? 'Sin local';
  DateTime? get birthdayDate =>
      _cachedBirthdayDate ?? _parseBirthdayDateOptimized();
  String get formattedBirthday =>
      _cachedFormattedBirthday ?? _formatBirthdayOptimized();
  bool get hasPhone => _cachedHasPhone ?? phone.isNotEmpty;
  bool get hasDepartment => _cachedHasDepartment ?? (department != null);
  bool get hasLocal => _cachedHasLocal ?? (local != null);
  bool get hasBirthday => _cachedHasBirthday ?? fechaCumpleannos.isNotEmpty;

  String get formattedBirthdayWithYear {
    final date = birthdayDate;
    if (date == null) return formattedBirthday;

    final monthNames = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${date.day} de ${monthNames[date.month - 1]} de ${date.year}';
  }

  bool get hasBirthdayThisMonth {
    final now = DateTime.now();
    final birthday = birthdayDate;
    return birthday != null && birthday.month == now.month;
  }

  bool get hasBirthdayToday {
    final now = DateTime.now();
    final birthday = birthdayDate;
    return birthday != null &&
        birthday.month == now.month &&
        birthday.day == now.day;
  }

  // Métodos de utilidad para IDs
  int? get departamentoID => department?.id;
  int? get localId => local?.id;

  // Para crear DTOs para el backend
  Map<String, dynamic> toCreateDto() {
    final dto = <String, dynamic>{};
    dto['nombre'] = name;
    dto['apellido'] = lastName;
    dto['carnetIdentidad'] = carnetID;
    if (address.isNotEmpty) dto['direccion'] = address;
    if (phone.isNotEmpty) dto['numeroCelular'] = phone;
    if (fechaCumpleannos.isNotEmpty) dto['fechaCumpleanno'] = fechaCumpleannos;
    if (departamentoID != null && departamentoID! > 0) {
      dto['departamentoId'] = departamentoID;
    }
    if (localId != null && localId! > 0) {
      dto['localId'] = localId;
    }
    return dto;
  }

  Map<String, dynamic> toUpdateDto() {
    final dto = toCreateDto();
    return dto;
  }

  Worker copyWith({
    int? id,
    String? name,
    String? lastName,
    String? carnetID,
    String? phone,
    String? address,
    String? fechaCumpleannos,
    Department? department,
    Local? local,
    int? cumpleannoId,
  }) {
    final worker = Worker(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      carnetID: carnetID ?? this.carnetID,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      fechaCumpleannos: fechaCumpleannos ?? this.fechaCumpleannos,
      department: department ?? this.department,
      local: local ?? this.local,
      cumpleannoId: cumpleannoId ?? this.cumpleannoId,
    );

    worker._initializeCache();
    return worker;
  }

  // Validaciones
  bool get isValid => carnetID.isNotEmpty && name.isNotEmpty;

  List<String> validate() {
    final errors = <String>[];
    if (name.isEmpty) errors.add('El nombre es requerido');
    if (carnetID.isEmpty) errors.add('El carnet de identidad es requerido');
    if (carnetID.length != 11) errors.add('El carnet debe tener 11 dígitos');
    return errors;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'apellido': lastName,
      'carnetIdentidad': carnetID,
      'direccion': address,
      'numeroCelular': phone,
      'fechaCumpleanno': fechaCumpleannos,
      'departamento': department?.toJson(),
      'local': local?.toJson(),
      'cumpleannoId': cumpleannoId,
    };
  }

  // En worker.dart, agregar método optimizado para calendario:
  DateTime? get birthdayDateForCalendar {
    if (_cachedBirthdayDate != null) return _cachedBirthdayDate;

    // Versión optimizada solo para calendario (sin prints)
    if (fechaCumpleannos.isEmpty) return null;

    // Formato texto español (prioridad)
    final parts = fechaCumpleannos.toLowerCase().split(' de ');
    if (parts.length == 2) {
      final dayStr = parts[0].trim();
      final monthStr = parts[1].trim();

      final day = int.tryParse(dayStr);
      if (day == null) return null;

      final monthMap = {
        'enero': 1,
        'febrero': 2,
        'marzo': 3,
        'abril': 4,
        'mayo': 5,
        'junio': 6,
        'julio': 7,
        'agosto': 8,
        'septiembre': 9,
        'octubre': 10,
        'noviembre': 11,
        'diciembre': 12,
      };

      final month = monthMap[monthStr];
      if (month != null) {
        final now = DateTime.now();
        return DateTime(now.year, month, day);
      }
    }

    return _cachedBirthdayDate; // Fallback al caché existente
  }

  @override
  String toString() {
    return 'Worker(id: $id, name: $fullName)';
  }
}
