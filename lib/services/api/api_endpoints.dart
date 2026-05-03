class ApiEndpoints {
  static const String baseUrl = 'http://directorio.scu.desoft.cu/backend';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/nuevo';
  static const String refreshToken = '/auth/refresh-token';
  static const String refresh = '/auth/refresh';

  // Users
  static const String users = '/usuario';
  static String userById(int id) => '/usuario/$id';

  // Roles
  static const String roles = '/rol';
  static String roleById(int id) => '/rol/$id';

  // Workers
  static const String workers = '/trabajador';
  static String workerById(int id) => '/trabajador/$id';
  static const String workerSearch = '/trabajador?search=';

  // Departments
  static const String departments = '/departamento';
  static String departmentById(int id) => '/departamento/$id';

  // local
  static const String local = '/local';
  static String localById(int id) => '/local/$id';

  // Efemerides
  static const String efemerides = '/efemeride';
  static String efemerideById(int id) => '/efemeride/$id';

  // Cumpleaños
  static const String birthdays = '/cumpleanno';
  static String birthdayById(int id) => '/cumpleanno/$id';
}
