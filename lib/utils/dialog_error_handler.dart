import 'package:flutter/material.dart';

class DialogErrorHandler {
  // ============================================================
  // PALETA CORPORATIVA
  // ============================================================

  static const Color _primary = Color(0xFF1769AA);
  static const Color _primaryDark = Color(0xFF104C80);
  static const Color _success = Color(0xFF159B72);
  static const Color _warning = Color(0xFFE49A27);
  static const Color _danger = Color(0xFFD94B4B);
  static const Color _textDark = Color(0xFF243447);
  static const Color _textMuted = Color(0xFF718096);
  static const Color _border = Color(0xFFE4EAF2);
  static const Color _background = Color(0xFFF4F7FB);

  // ============================================================
  // MENSAJES DE ERROR
  // ============================================================

  static String getFriendlyErrorMessage(String technicalError) {
    final error = technicalError.toLowerCase();

    if (error.contains('conexión') ||
        error.contains('socket') ||
        error.contains('network') ||
        error.contains('host lookup')) {
      return 'No hay conexión a internet. Verifique su conexión.';
    }

    if (error.contains('timeout')) {
      return 'El servidor está tardando en responder. Intente más tarde.';
    }

    if (error.contains('duplicad') || error.contains('ya existe')) {
      return 'El registro ya existe. Verifique los datos.';
    }

    if (error.contains('required') || error.contains('requerido')) {
      return 'Complete todos los campos requeridos.';
    }

    if (error.contains('invalid') || error.contains('inválido')) {
      return 'Datos inválidos. Verifique la información.';
    }

    if (error.contains('500') || error.contains('server error')) {
      return 'Error en el servidor. Intente nuevamente más tarde.';
    }

    if (error.contains('401') || error.contains('unauthorized')) {
      return 'Su sesión ha expirado. Por favor, inicie sesión nuevamente.';
    }

    if (error.contains('404') || error.contains('not found')) {
      return 'El recurso no existe o ha sido eliminado.';
    }

    if (error.contains('validation') || error.contains('validación')) {
      return 'Error de validación. Verifique los datos ingresados.';
    }

    return 'Ocurrió un error. Por favor, intente nuevamente.';
  }

  // ============================================================
  // DETECCIÓN DE ERRORES DE RED
  // ============================================================

  static bool isNetworkError(String error) {
    final e = error.toLowerCase();

    return e.contains('conexión') ||
        e.contains('socket') ||
        e.contains('network') ||
        e.contains('timeout') ||
        e.contains('host lookup');
  }

  // ============================================================
  // DIÁLOGO DE ERROR
  // ============================================================

  static void showErrorDialog({
    required BuildContext context,
    required String title,
    required String technicalError,
    bool showRetryButton = false,
    VoidCallback? onRetry,
  }) {
    final bool networkError = isNetworkError(technicalError);

    final Color accentColor = networkError ? _warning : _danger;

    final IconData errorIcon = networkError
        ? Icons.wifi_off_rounded
        : Icons.error_outline_rounded;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ICONO
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(errorIcon, size: 34, color: accentColor),
                    ),

                    const SizedBox(height: 20),

                    // TÍTULO
                    Text(
                      networkError ? 'Problema de conexión' : title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // MENSAJE
                    Text(
                      getFriendlyErrorMessage(technicalError),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: _textMuted,
                      ),
                    ),

                    if (networkError) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: _background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 19,
                              color: _primary,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Verifique su conexión a internet e intente nuevamente.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: _textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // BOTONES
                    Row(
                      children: [
                        if (showRetryButton && onRetry != null) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onRetry,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primary,
                                side: const BorderSide(color: _primary),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Reintentar',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Aceptar',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SNACKBAR DE ÉXITO
  // ============================================================

  static void showSuccessSnackbar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;

    _showCustomSnackbar(
      context: context,
      message: message,
      icon: Icons.check_circle_rounded,
      color: _success,
      duration: duration,
    );
  }

  // ============================================================
  // SNACKBAR DE ERROR
  // ============================================================

  static void showErrorSnackbar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    _showCustomSnackbar(
      context: context,
      message: message,
      icon: Icons.error_outline_rounded,
      color: _danger,
      duration: duration,
    );
  }

  // ============================================================
  // COMPONENTE COMPARTIDO DE SNACKBAR
  // ============================================================

  static void _showCustomSnackbar({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color color,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          elevation: 4,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }
}
