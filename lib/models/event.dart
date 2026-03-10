import 'efemeride.dart';
import 'worker.dart';

enum EventType { birthday, efemeride }

class Event {
  final String title;
  final EventType type;
  final DateTime date;
  final Worker? worker;
  final Efemeride? efemeride;

  Event({
    required this.title,
    required this.type,
    required this.date,
    this.worker,
    this.efemeride,
  });

  // Helper methods
  bool get isToday {
    final now = DateTime.now();
    return date.day == now.day && date.month == now.month;
  }

  String get formattedDate {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String get displayDate => "${date.day}/${date.month}/${date.year}";
}
