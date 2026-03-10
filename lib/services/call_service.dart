import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CallService {
  static const MethodChannel _channel = MethodChannel('direct_call_channel');

  static Future<void> directCall(String number) async {
    try {
      final result = await _channel.invokeMethod("directCall", {
        "number": number,
      });

      // Verificar qué nos devuelve Android
      if (result == "permission_requested") {
        debugPrint("Se solicitó permiso en Android");
      } else if (result == "ok") {
        debugPrint("Llamada iniciada exitosamente");
      }
    } catch (e) {
      debugPrint("Error al hacer llamada directa: $e");
    }
  }
}
