// VERSIÓN SIMPLIFICADA - SOLO PARA APN
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityManager {
  final Connectivity _connectivity = Connectivity();

  // Solo verificar si hay conexión de red (APN/WiFi)
  Future<bool> hasNetworkConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      // Si existe al menos un tipo de conexión distinto de none, hay red
      final hasConnection = connectivityResult.any(
        (result) => result != ConnectivityResult.none,
      );

      return hasConnection;
    } catch (e) {
      return false;
    }
  }

  // Escuchar cambios en la conectividad
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  // Verificar tipo específico de conexión
  Future<List<ConnectivityResult>> getConnectionType() async {
    return await _connectivity.checkConnectivity();
  }
}
