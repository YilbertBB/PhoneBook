import 'package:flutter/material.dart';

class DialogErrorHandler {
  static String getFriendlyErrorMessage(String technicalError) {
    final error = technicalError.toLowerCase();

    if (error.contains('conexión') ||
        error.contains('socket') ||
        error.contains('network') ||
        error.contains('host lookup')) {
      return '❌ No hay conexión a internet. Verifique su conexión.';
    }

    if (error.contains('timeout')) {
      return '⏰ El servidor está tardando en responder. Intente más tarde.';
    }

    if (error.contains('duplicad') || error.contains('ya existe')) {
      return '⚠️ El registro ya existe. Verifique los datos.';
    }

    if (error.contains('required') || error.contains('requerido')) {
      return '📝 Complete todos los campos requeridos.';
    }

    if (error.contains('invalid') || error.contains('inválido')) {
      return '⚠️ Datos inválidos. Verifique la información.';
    }

    if (error.contains('500') || error.contains('server error')) {
      return '🔧 Error en el servidor. Nuestro equipo ha sido notificado.';
    }

    if (error.contains('401') || error.contains('unauthorized')) {
      return '🔐 Su sesión ha expirado. Por favor, inicie sesión nuevamente.';
    }

    if (error.contains('404') || error.contains('not found')) {
      return '🔍 El recurso no existe o ha sido eliminado.';
    }

    if (error.contains('validation') || error.contains('validación')) {
      return '📋 Error de validación. Verifique los datos ingresados.';
    }

    return '❌ Ocurrió un error. Por favor, intente nuevamente.';
  }

  static bool isNetworkError(String error) {
    final e = error.toLowerCase();
    return e.contains('conexión') ||
        e.contains('socket') ||
        e.contains('network') ||
        e.contains('timeout') ||
        e.contains('host lookup');
  }

  static void showErrorDialog({
    required BuildContext context,
    required String title,
    required String technicalError,
    bool showRetryButton = false,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isNetworkError(technicalError)
                  ? Icons.wifi_off
                  : Icons.error_outline,
              color: isNetworkError(technicalError)
                  ? Colors.orange
                  : Colors.red,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isNetworkError(technicalError) ? 'Problema de Conexión' : title,
                softWrap: true,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getFriendlyErrorMessage(technicalError),
              style: const TextStyle(fontSize: 14),
            ),
            if (isNetworkError(technicalError)) const SizedBox(height: 12),
            if (isNetworkError(technicalError))
              const Text(
                '📡 Verifique su conexión a internet e intente nuevamente.',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
          ],
        ),
        actions: [
          if (showRetryButton && onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  static void showSuccessSnackbar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static void showErrorSnackbar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
