class UpdateConfig {
  // URL del archivo JSON que contiene la información de actualización
  static const String updateJsonUrl =
      'http://ftp.scu.desoft.cu/files/PhoneBook/';

  // Tiempo en horas entre verificaciones automáticas
  static const int checkIntervalHours = 24;

  // Nombre del archivo para guardar la última verificación
  static const String lastCheckKey = 'last_update_check';

  // Clave para guardar si el usuario ignoró una actualización
  static const String ignoredUpdateKey = 'ignored_update_version';

  // Tiempo máximo de caché para la información de actualización (en segundos)
  static const int cacheDurationSeconds = 3600; // 1 hora

  static const int notificationCooldownHours = 24;

  // AGREGAR: Tiempo mínimo entre verificaciones (en segundos)
  static const int minCheckIntervalSeconds = 3600; // 1 hora

  // AGREGAR: Modo de notificación
  static const NotificationMode notificationMode = NotificationMode.system;
}

enum NotificationMode {
  dialog, // Diálogo modal (solo para obligatorias)
  system, // Notificación del sistema
  snackbar, // Snackbar en la parte inferior
}
