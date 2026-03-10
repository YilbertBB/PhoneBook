import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/error_messages.dart';
import 'api_response.dart';

class ApiClient {
  static const Duration timeout = Duration(seconds: 30);

  final String baseUrl;
  String? token;
  final http.Client _client = http.Client();

  ApiClient({required this.baseUrl, this.token});

  // Método para actualizar el token
  void updateToken(String? newToken) {
    token = newToken;
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // ✅ CAMBIADO: Solo agregar Authorization si token NO es null
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Método genérico para manejar todas las respuestas
  Future<ApiResponse<T>> _handleResponse<T>(
    Future<http.Response> request,
    T Function(dynamic)? fromJson,
  ) async {
    try {
      final response = await request.timeout(timeout);

      // Si la respuesta es exitosa (200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          if (response.body.isEmpty) {
            return ApiResponse.success(
              null as T,
              statusCode: response.statusCode,
            );
          }

          final decoded = json.decode(response.body);

          // Si hay un fromJson, convertir, si no, devolver el JSON crudo
          final data = fromJson != null ? fromJson(decoded) : decoded as T;

          return ApiResponse.success(data, statusCode: response.statusCode);
        } catch (e) {
          return ApiResponse.error(
            ErrorMessages.dataProcessingError,
            technicalError: 'JSON Parse Error: $e\nResponse: ${response.body}',
            statusCode: response.statusCode,
          );
        }
      }

      // Si hay error del servidor
      return _handleErrorResponse(response);
    } on FormatException catch (e) {
      return ApiResponse.fromException(e);
    } on http.ClientException catch (e) {
      return ApiResponse.fromException(e.message);
    } on Exception catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Manejar errores HTTP específicos
  ApiResponse<T> _handleErrorResponse<T>(http.Response response) {
    try {
      final errorJson = json.decode(response.body);
      final serverMessage =
          errorJson['message']?.toString() ?? errorJson['error']?.toString();

      return ApiResponse.error(
        serverMessage ?? ErrorMessages.fromStatusCode(response.statusCode),
        technicalError: 'HTTP ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      // Si no se puede parsear el error del servidor
      return ApiResponse.fromHttpError(response.statusCode);
    }
  }

  // MÉTODOS HTTP MEJORADOS - Ahora devuelven ApiResponse<T>

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    T Function(dynamic)? fromJson,
  }) async {
    final request = _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
    );

    return await _handleResponse<T>(request, fromJson);
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic body,
    T Function(dynamic)? fromJson,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = _getHeaders();
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    final request = _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? json.encode(body) : null,
    );

    return await _handleResponse<T>(request, fromJson);
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic body,
    T Function(dynamic)? fromJson,
  }) async {
    final request = _client.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
      body: body != null ? json.encode(body) : null,
    );

    return await _handleResponse<T>(request, fromJson);
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? fromJson,
  }) async {
    final request = _client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
    );

    return await _handleResponse<T>(request, fromJson);
  }

  void dispose() {
    _client.close();
  }
}
