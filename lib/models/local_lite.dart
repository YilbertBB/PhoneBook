import 'local.dart';
import 'worker.dart';

class LocalLite {
  final int id;
  final String name;
  final String phone;
  final String initials;
  final bool hasPhone;

  LocalLite({
    required this.id,
    required this.name,
    required this.phone,
    required this.initials,
  }) : hasPhone = phone.isNotEmpty;

  factory LocalLite.fromJson(Map<String, dynamic> json) {
    final name = _parseString(json['nombreLocal']);
    final phone = _parseString(json['numeroFijoLocal']);

    return LocalLite(
      id: json['id'] ?? 0,
      name: name,
      phone: phone,
      initials: _calculateInitials(name),
    );
  }

  factory LocalLite.fromLocal(Local local) {
    return LocalLite(
      id: local.id,
      name: local.name,
      phone: local.phone,
      initials: _calculateInitials(local.name),
    );
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String _calculateInitials(String name) {
    if (name.isEmpty) return '??';

    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  Local toLocal({List<Worker>? workers}) {
    return Local(
      id: id,
      name: name,
      phone: phone,
      workers: workers?.map((w) => w).toList(),
    );
  }

  @override
  String toString() {
    return 'LocalLite(id: $id, name: $name, phone: $phone)';
  }
}
