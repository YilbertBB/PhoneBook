import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../secure_token_manager.dart';
import '../service_locator.dart';

class TokenExpiryManager {
  final SecureTokenManager _tokenManager = ServiceLocator().secureTokenManager;
  Timer? _expiryTimer;
  Timer? _warningTimer;
  BuildContext? _currentContext;

  // Configuración
  static const Duration _warningThreshold = Duration(minutes: 5);
  static const Duration _checkInterval = Duration(minutes: 1);

  void startMonitoring(BuildContext context) {
    // Guardar contexto para uso posterior
    _currentContext = context;

    // Verificar periódicamente
    _expiryTimer = Timer.periodic(_checkInterval, (_) {
      _checkTokenExpiry();
    });

    // Verificar inmediatamente al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTokenExpiry();
    });
  }

  void stopMonitoring() {
    _expiryTimer?.cancel();
    _warningTimer?.cancel();
    _expiryTimer = null;
    _warningTimer = null;
    _currentContext = null;
  }

  Future<void> _checkTokenExpiry() async {
    if (_currentContext == null) return;

    final token = await _tokenManager.getToken();
    if (token == null) return;

    final expiryInfo = _getTokenExpiryInfo(token);
    final context = _currentContext!;
    if (expiryInfo['isExpired'] == true) {
      if (context.mounted) {
        _handleTokenExpired(context);
      }
    } else if (expiryInfo['timeUntilExpiry'] <= _warningThreshold) {
      if (context.mounted) {
        _showExpiryWarning(context, expiryInfo['timeUntilExpiry']!);
      }
    }
  }

  // Resto del código permanece igual...
  Map<String, dynamic> _getTokenExpiryInfo(String token) {
    try {
      final parts = token.split('.');
      final payload = json.decode(utf8.decode(base64Url.decode(parts[1])));
      final exp = payload['exp'] as int;
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      final timeUntilExpiry = expiryTime.difference(now);

      return {
        'isExpired': timeUntilExpiry.isNegative,
        'timeUntilExpiry': timeUntilExpiry,
        'expiryTime': expiryTime,
        'minutesLeft': timeUntilExpiry.inMinutes,
      };
    } catch (e) {
      return {'isExpired': true, 'timeUntilExpiry': Duration.zero};
    }
  }

  void _handleTokenExpired(BuildContext context) {
    stopMonitoring();

    // Mostrar diálogo informativo
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Sesión Expirada'),
        content: Text(
          'Tu sesión ha expirado por seguridad. Por favor, inicia sesión nuevamente.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logoutAndRedirect(context);
            },
            child: Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showExpiryWarning(BuildContext context, Duration timeLeft) {
    final minutes = timeLeft.inMinutes;
    final seconds = timeLeft.inSeconds % 60;

    // Mostrar snackbar de advertencia (solo una vez)
    if (_warningTimer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tu sesión expirará en $minutes:${seconds.toString().padLeft(2, '0')} minutos',
          ),
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Extender',
            onPressed: () => _tryRefreshToken(context),
          ),
        ),
      );

      // Programar próximo aviso
      _warningTimer = Timer(Duration(minutes: 1), () {
        _warningTimer = null;
      });
    }
  }

  Future<void> _tryRefreshToken(BuildContext context) async {
    final authService = ServiceLocator().authService;
    final result = await authService.refreshAccessToken();

    if (result.hasError) {
      if (context.mounted) {
        _logoutAndRedirect(context);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sesión extendida exitosamente')),
        );
      }
    }
  }

  void _logoutAndRedirect(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.logout();

    // Navegar al login
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}
