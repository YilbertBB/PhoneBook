import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/update_info.dart';
import '../../utils/notification_utils.dart';
import 'update_repository.dart';

class UpdateService {
  final UpdateRepository _repository;
  PackageInfo? _packageInfo;
  BuildContext? _currentContext;

  UpdateService() : _repository = UpdateRepository();

  UpdateRepository get repository => _repository;

  Future<void> _initializePackageInfo() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
  }

  // ==================== VERIFICACIÓN ====================

  Future<UpdateInfo?> checkUpdates({
    bool forceCheck = false,
    bool showNotification = true,
  }) async {
    try {
      await _initializePackageInfo();

      if (!forceCheck) {
        final shouldCheck = await _repository.shouldCheckForUpdates();
        if (!shouldCheck) {
          return null;
        }
      }

      final updateInfo = await _repository.checkForUpdates();
      if (updateInfo == null) {
        return null;
      }

      await _repository.saveLastCheckTime();

      // final currentVersion = _packageInfo?.version ?? '1.0.0';
      final currentVersionCode =
          int.tryParse(_packageInfo?.buildNumber ?? '1') ?? 1;

      if (updateInfo.versionCode > currentVersionCode) {
        final ignoredVersion = await _repository.getIgnoredUpdate();
        if (ignoredVersion != updateInfo.latestVersion) {
          return updateInfo;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // ==================== MÉTODO PRINCIPAL ====================
  Future<void> downloadUpdate(
    UpdateInfo updateInfo,
    BuildContext context,
  ) async {
    _currentContext = context;

    try {
      // 1. Permisos
      await _requestAndroidPermissions(context);

      // 2. Mostrar progreso inicial
      _showProgressDialog(0.0, updateInfo.latestVersion);

      // 3. Descargar
      final apkFile = await _downloadApkToDownloads(
        updateInfo.apkUrl,
        updateInfo.latestVersion,
      );

      if (apkFile == null) throw Exception('Descarga falló');

      // 4. Cerrar diálogo de progreso
      _closeProgressDialog();

      // 5. Mostrar mensaje de descarga completa CON RETRASO
      await Future.delayed(const Duration(milliseconds: 300));
      _showDownloadCompleteDialog(apkFile.path, updateInfo.latestVersion);
    } catch (e) {
      _closeProgressDialog();
      await Future.delayed(const Duration(milliseconds: 300));
      _showErrorDialog('Error al descargar: ${e.toString()}');
    } finally {
      _currentContext = null;
    }
  }

  // ==================== DESCARGA ====================

  Future<File?> _downloadApkToDownloads(String url, String version) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Error HTTP ${response.statusCode}');
      }

      // Directorio de descargas del sistema
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        final created = await downloadsDir.create(recursive: true);
        if (!(await created.exists())) {
          throw Exception('No se pudo crear Downloads');
        }
      }

      // Nombre del archivo seguro
      final fileName = 'Phonebook_v${version.replaceAll('.', '_')}.apk';
      final apkFile = File('${downloadsDir.path}/$fileName');

      // Eliminar si ya existe
      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      // Guardar archivo
      await apkFile.writeAsBytes(response.bodyBytes);

      return apkFile;
    } catch (e) {
      rethrow;
    }
  }

  // ==================== UI Y DIÁLOGOS ====================

  void _showProgressDialog(double progress, String version) {
    if (_currentContext == null || !_currentContext!.mounted) return;

    final percentage = (progress * 100).toStringAsFixed(0);

    showDialog(
      context: _currentContext!,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono animado
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: progress < 1.0
                      ? Icon(
                          Icons.download,
                          key: const ValueKey('downloading'),
                          size: 48,
                          color: Colors.blue[700],
                        )
                      : Icon(
                          Icons.check_circle,
                          key: const ValueKey('completed'),
                          size: 48,
                          color: Colors.green,
                        ),
                ),
                const SizedBox(height: 20),

                // Título
                Flexible(
                  child: Text(
                    progress < 1.0 ? 'Descargando...' : '¡Descarga Completa!',
                    softWrap: true,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Versión
                Text(
                  'Versión $version',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // Barra de progreso
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(
                    children: [
                      // Fondo
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      // Progreso
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width:
                            MediaQuery.of(_currentContext!).size.width *
                            0.6 *
                            progress,
                        decoration: BoxDecoration(
                          color: progress < 1.0
                              ? Colors.blue[600]
                              : Colors.green,
                          borderRadius: BorderRadius.circular(6),
                          gradient: progress < 1.0
                              ? LinearGradient(
                                  colors: [
                                    Colors.blue[600]!,
                                    Colors.blue[400]!,
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Porcentaje
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: progress < 1.0 ? Colors.blue[700] : Colors.green,
                  ),
                ),
                const SizedBox(height: 16),

                // Mensaje
                Text(
                  progress < 1.0
                      ? 'Por favor, no cierre la aplicación'
                      : 'La descarga se completó exitosamente',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDownloadCompleteDialog(String apkPath, String version) {
    if (_currentContext == null || !_currentContext!.mounted) return;

    final fileName = apkPath.split('/').last;
    final fileSize = File(apkPath).lengthSync() ~/ (1024 * 1024); // MB

    showDialog(
      context: _currentContext!,
      barrierDismissible: true, // Cambiado a true para que se pueda cerrar
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download_done, color: Colors.green),
            SizedBox(width: 10),
            Flexible(
              child: Text('✅ Descarga Completa', softWrap: true, maxLines: 2),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'La versión $version se descargó correctamente.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Información del archivo:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('• Nombre: $fileName'),
                    Text('• Tamaño: $fileSize MB'),
                    Text('• Ubicación: Carpeta Descargas'),
                    const SizedBox(height: 8),
                    const Text(
                      'Puedes instalarlo manualmente cuando desees.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Botón para cancelar/cerrar
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar este diálogo
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _closeProgressDialog() {
    if (_currentContext != null && _currentContext!.mounted) {
      Navigator.of(_currentContext!, rootNavigator: true).pop();
    }
  }

  void _showErrorDialog(String message) {
    if (_currentContext == null || !_currentContext!.mounted) return;

    showDialog(
      context: _currentContext!,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ==================== PERMISOS ====================

  Future<void> _requestAndroidPermissions(BuildContext context) async {
    if (!Platform.isAndroid) return;

    final permissions = await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    if (!permissions[Permission.storage]!.isGranted) {
      throw Exception('Permiso de almacenamiento necesario');
    }
  }

  // ==================== MÉTODOS PÚBLICOS ====================

  Future<void> downloadUpdateDirectly(
    BuildContext context,
    UpdateInfo updateInfo,
  ) async {
    await downloadUpdate(updateInfo, context);
  }

  Future<void> showUpdateNotification(
    BuildContext context,
    UpdateInfo updateInfo,
  ) async {
    final shouldShow = await _repository.shouldShowUpdateNotification(
      updateInfo,
    );
    if (!shouldShow) return;

    if (updateInfo.mandatory && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Actualización Obligatoria'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Versión ${updateInfo.latestVersion}'),
              if (updateInfo.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(updateInfo.releaseNotes),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => downloadUpdate(updateInfo, context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('DESCARGAR AHORA'),
            ),
          ],
        ),
      );
    } else {
      await _repository.saveIgnoredUpdate(updateInfo.latestVersion);
      await NotificationUtils.showUpdateNotification(
        title: '📱 Actualización Disponible',
        body: 'Nueva versión ${updateInfo.latestVersion} disponible',
        version: updateInfo.latestVersion,
        hasAction: true,
      );
    }
  }

  Future<void> checkAndNotifyIfNeeded(
    BuildContext context, {
    bool forceCheck = false,
  }) async {
    try {
      final updateInfo = await checkUpdates(forceCheck: forceCheck);
      if (updateInfo != null && context.mounted) {
        await showUpdateNotification(context, updateInfo);
      }
    } catch (e) {
      debugPrint('Error en checkAndNotifyIfNeeded: $e');
    }
  }

  Future<String> getCurrentVersion() async {
    await _initializePackageInfo();
    return _packageInfo?.version ?? '1.0.0';
  }

  Future<int> getCurrentVersionCode() async {
    await _initializePackageInfo();
    return int.tryParse(_packageInfo?.buildNumber ?? '1') ?? 1;
  }

  static Future<void> savePendingNotification(String payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_update_notification', payload);
  }

  static Future<String?> getPendingNotification() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pending_update_notification');
  }

  static Future<void> clearPendingNotification() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_update_notification');
  }

  void dispose() {
    _repository.dispose();
  }
}
