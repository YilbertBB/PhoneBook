import 'base_model.dart';

class Efemeride implements BaseModel {
  @override
  final int id;
  final DateTime fecha;
  final String dato;
  final String detalle;

  Efemeride({
    required this.id,
    required this.fecha,
    required this.dato,
    required this.detalle,
  });

  factory Efemeride.fromJson(Map<String, dynamic> json) {
    return Efemeride(
      id: json['id'] ?? 0,
      fecha: json['fechaEfemeride'] != null
          ? DateTime.parse(json['fechaEfemeride'])
          : DateTime.now(),
      dato: json['datoEfemeride'] ?? '',
      detalle: json['detalleEfemeride'] ?? '',
    );
  }

  // Para uso interno en la app
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fechaEfemeride': fecha.toIso8601String().split('T')[0],
      'datoEfemeride': dato,
      'detalleEfemeride': detalle,
    };
  }

  // Para crear en el backend (POST)
  Map<String, dynamic> toCreateDto() {
    return {
      'fechaEfemeride': fecha.toIso8601String().split('T')[0],
      'datoEfemeride': dato,
      'detalleEfemeride': detalle,
    };
  }

  // Para actualizar en el backend (PUT)
  Map<String, dynamic> toUpdateDto() {
    return {
      'fechaEfemeride': fecha.toIso8601String().split('T')[0],
      'datoEfemeride': dato,
      'detalleEfemeride': detalle,
    };
  }

  Efemeride copyWith({
    int? id,
    DateTime? fecha,
    String? dato,
    String? detalle,
  }) {
    return Efemeride(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      dato: dato ?? this.dato,
      detalle: detalle ?? this.detalle,
    );
  }

  // Helper methods
  String get formattedDate => "${fecha.day}/${fecha.month}/${fecha.year}";

  String get isoDate => fecha.toIso8601String().split('T')[0];

  bool get isToday {
    final now = DateTime.now();
    return fecha.day == now.day &&
        fecha.month == now.month &&
        fecha.year == now.year;
  }

  bool get isThisMonth {
    final now = DateTime.now();
    return fecha.month == now.month && fecha.year == now.year;
  }

  // Para mostrar en UI con nombres de meses en español
  String get displayDate {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${fecha.day} de ${months[fecha.month - 1]} de ${fecha.year}';
  }

  // Método para obtener la fecha sin año (para calendario anual)
  String get dateWithoutYear {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${fecha.day} ${months[fecha.month - 1]}';
  }

  // Para comparar por fecha (ignorando hora)
  bool isSameDate(DateTime other) {
    return fecha.year == other.year &&
        fecha.month == other.month &&
        fecha.day == other.day;
  }
}
