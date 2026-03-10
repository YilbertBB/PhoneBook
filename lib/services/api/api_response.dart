// class ApiResponse<T> {
//   final T? data;
//   final String? error;
//   final bool success;

//   ApiResponse({this.data, this.error, required this.success});

//   factory ApiResponse.success(T data) => ApiResponse(success: true, data: data);

//   factory ApiResponse.error(String error) =>
//       ApiResponse(success: false, error: error);

//   bool get hasError => !success;
//   bool get hasData => success && data != null;

//   @override
//   String toString() {
//     return 'ApiResponse{success: $success, data: $data, error: $error}';
//   }
// }

import '../../utils/error_messages.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;
  final String? technicalError; // Para debug, no mostrar al usuario
  final bool success;
  final int? statusCode;

  ApiResponse({
    this.data,
    this.error,
    this.technicalError,
    this.statusCode,
    required this.success,
  });

  factory ApiResponse.success(T data, {int? statusCode}) =>
      ApiResponse(success: true, data: data, statusCode: statusCode);

  factory ApiResponse.error(
    String error, {
    String? technicalError,
    int? statusCode,
  }) => ApiResponse(
    success: false,
    error: error,
    technicalError: technicalError,
    statusCode: statusCode,
  );

  bool get hasError => !success;
  bool get hasData => success && data != null;

  // Método útil para crear respuestas con mensajes amigables
  factory ApiResponse.fromException(dynamic exception, {int? statusCode}) {
    final friendlyMessage = ErrorMessages.fromException(exception);
    return ApiResponse.error(
      friendlyMessage,
      technicalError: exception.toString(),
      statusCode: statusCode,
    );
  }

  // Método útil para crear respuestas desde código HTTP
  factory ApiResponse.fromHttpError(int statusCode, {String? serverMessage}) {
    final friendlyMessage = ErrorMessages.fromStatusCode(statusCode);
    return ApiResponse.error(
      serverMessage ?? friendlyMessage,
      statusCode: statusCode,
      technicalError: 'HTTP $statusCode',
    );
  }

  @override
  String toString() {
    return 'ApiResponse{success: $success, statusCode: $statusCode, data: $data, error: $error}';
  }
}
