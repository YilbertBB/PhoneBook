import 'package:flutter/material.dart';
import '../services/service_locator.dart';
import '../models/update_info.dart';

class UpdateProvider with ChangeNotifier {
  UpdateInfo? _pendingUpdate;
  bool _isChecking = false;

  UpdateInfo? get pendingUpdate => _pendingUpdate;
  bool get isChecking => _isChecking;

  Future<void> checkForUpdates({bool force = false}) async {
    if (_isChecking) return;

    _isChecking = true;
    notifyListeners();

    try {
      final updateService = ServiceLocator().updateService;
      final updateInfo = await updateService.checkUpdates(forceCheck: force);

      if (updateInfo != null) {
        _pendingUpdate = updateInfo;
      }
    } catch (e) {
      debugPrint('Error verificando actualizaciones: $e');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<void> processNotificationTap(
    BuildContext context,
    String version,
  ) async {
    // Verificar si hay actualización pendiente
    if (_pendingUpdate == null) {
      await checkForUpdates(force: true);
    }

    // Si hay actualización, mostrar diálogo
    if (_pendingUpdate != null && context.mounted) {
      final updateService = ServiceLocator().updateService;
      updateService.showUpdateNotification(context, _pendingUpdate!);
    }
  }

  void clearPendingUpdate() {
    _pendingUpdate = null;
    notifyListeners();
  }
}
