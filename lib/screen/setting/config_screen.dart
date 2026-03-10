import 'package:flutter/material.dart';
import '../../screen/directory/home_screen.dart';
import 'package:provider/provider.dart';
import '../../models/rol.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_locator.dart';
import '../auth/login_screen.dart';
import 'network_config_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConfigScreenState createState() => ConfigScreenState();
}

class ConfigScreenState extends State<ConfigScreen> {
  bool _notifications = true;
  String _appVersion = '1.0.0';
  final bool _updateAvailable = false;
  late User? _currentUser;
  bool _isLoading = true;
  Map<String, dynamic> _cacheInfo = {};
  bool _loadingCacheInfo = false;
  bool _checkingForUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAppInfo();
    _loadCacheInfo();
  }

  Future<void> _loadUserData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.user == null) {
        await authProvider.checkAuthStatus();
      }

      setState(() {
        _currentUser = authProvider.user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentUser = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAppInfo() async {
    try {
      final updateService = ServiceLocator().updateService;
      final currentVersion = await updateService.getCurrentVersion();

      setState(() {
        _appVersion = currentVersion;
      });
    } catch (e) {
      debugPrint('Error al cargar información de la app: $e');
    }
  }

  Future<void> _loadCacheInfo() async {
    setState(() {
      _loadingCacheInfo = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final info = await authProvider.getCacheInfo();

      setState(() {
        _cacheInfo = info;
        _loadingCacheInfo = false;
      });
    } catch (e) {
      setState(() {
        _cacheInfo = {'total': 0, 'items': 0, 'details': {}, 'categories': {}};
        _loadingCacheInfo = false;
      });
    }
  }

  void _showUserInfo() {
    final user = _currentUser ?? _getExampleUser();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person, color: Colors.blue),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Información del Usuario',
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
            _buildInfoRow('Usuario:', user.username),
            _buildInfoRow('Email:', user.email),
            _buildInfoRow('Rol:', user.isAdmin ? 'Administrador' : 'Consultor'),
            _buildInfoRow(
              'Registrado:',
              '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.isAdmin
                    ? '🔐 Este usuario tiene permisos de administrador'
                    : '👁️ Este usuario tiene permisos de consulta',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  User _getExampleUser() {
    return User(
      id: 0,
      username: 'Usuario',
      email: 'usuario@ejemplo.com',
      password: '',
      roles: [Rol(id: 2, nombre: 'consult')],
      createdAt: DateTime.now(),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('Acerca de'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Directorio de Trabajadores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aplicación para la gestión y consulta de información laboral.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildAboutInfo('Versión', _appVersion),
            _buildAboutInfo('Desarrollador', 'Desoft Cuba'),
            _buildAboutInfo('Año', '2024'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '© Todos los derechos reservados. '
                'Esta aplicación es para uso interno.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.blue),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Política de Privacidad',
                softWrap: true,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Protección de Datos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '• La información personal se maneja de forma confidencial.\n'
                '• Solo el personal autorizado tiene acceso a los datos.\n'
                '• Los datos no se comparten con terceros.\n'
                '• Se implementan medidas de seguridad adecuadas.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Términos de Uso',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '• Uso exclusivo para fines laborales.\n'
                '• Prohibido compartir credenciales.\n'
                '• Reportar actividades sospechosas.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _checkingForUpdates = true;
    });

    try {
      final updateService = ServiceLocator().updateService;

      final updateInfo = await updateService.checkUpdates(
        forceCheck: true,
        showNotification: false,
      );

      if (updateInfo != null) {
        // Esperar un poco para que el botón cambie de estado
        await Future.delayed(const Duration(milliseconds: 300));
        // ✅ Llamar al método de descarga
        if (!mounted) return;

        await updateService.downloadUpdate(updateInfo, context);

        // Mostrar mensaje de éxito (pero no actualizar la versión automáticamente)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Actualización descargada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // No hay actualizaciones
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Ya tienes la última versión'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ ConfigScreen Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _checkingForUpdates = false;
        });
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.logout();
              setState(() {
                _currentUser = null;
              });
            },
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showCacheInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.storage, color: Colors.blue),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Información de Almacenamiento Local',
                softWrap: true,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: _loadingCacheInfo
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCacheInfoRow(
                    '💾 Uso total:',
                    _formatBytes(_cacheInfo['total'] ?? 0),
                  ),
                  _buildCacheInfoRow(
                    '📁 Archivos:',
                    '${_cacheInfo['items'] ?? 0}',
                  ),

                  if (_cacheInfo['categories'] != null &&
                      (_cacheInfo['categories'] as Map).isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        const Text(
                          '📊 Por categorías:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._buildCategoryDetails(),
                      ],
                    ),

                  if (_cacheInfo['details'] != null &&
                      (_cacheInfo['details'] as Map).isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          '📋 Detalles por archivo:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.3,
                          ),
                          child: SingleChildScrollView(
                            child: Column(children: _buildCacheDetails()),
                          ),
                        ),
                      ],
                    ),

                  if ((_cacheInfo['details'] == null ||
                          (_cacheInfo['details'] as Map).isEmpty) &&
                      (_cacheInfo['categories'] == null ||
                          (_cacheInfo['categories'] as Map).isEmpty))
                    const Text('📭 No hay datos almacenados localmente'),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showClearCacheOptions();
            },
            child: const Text(
              'Gestionar',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryDetails() {
    final categories = _cacheInfo['categories'] as Map<String, dynamic>?;
    if (categories == null || categories.isEmpty) return [];

    return categories.entries
        .map((entry) {
          if (entry.value > 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('• ${_getCategoryName(entry.key)}:'),
                  Text(_formatBytes(entry.value as int)),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        })
        .where((widget) => widget != const SizedBox.shrink())
        .toList();
  }

  String _getCategoryName(String key) {
    switch (key) {
      case 'shared_preferences':
        return 'Preferencias';
      case 'cache_files':
        return 'Archivos Cache';
      case 'database':
        return 'Base de datos';
      default:
        return key;
    }
  }

  List<Widget> _buildCacheDetails() {
    final details = _cacheInfo['details'] as Map<String, dynamic>?;
    if (details == null || details.isEmpty) return [const SizedBox()];

    final entries = details.entries.toList();

    return entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '• ${entry.key}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatBytes(entry.value as int),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showClearCacheOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cleaning_services, color: Colors.blue),
            SizedBox(width: 8),
            Flexible(
              child: Text('Opciones de Limpieza', softWrap: true, maxLines: 2),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona qué quieres limpiar:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.orange),
              title: const Text('Limpiar Cache Temporal'),
              subtitle: const Text(
                'Archivos temporales, sin afectar datos principales',
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showClearCacheConfirmation(tipo: 'cache');
              },
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Eliminar Todos los Datos'),
              subtitle: const Text(
                'Base de datos completa, archivos y preferencias',
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showClearAllDataConfirmation();
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheConfirmation({String tipo = 'cache'}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Borrar Caché'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Estás seguro de que quieres borrar la caché?'),
            const SizedBox(height: 12),
            const Text(
              'Esto eliminará:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Archivos temporales'),
            const Text('• Datos cache del sistema'),
            const Text('• Configuraciones temporales'),
            if (tipo == 'all')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• Base de datos local'),
                  const Text('• Preferencias guardadas'),
                ],
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tipo == 'cache'
                    ? '⚠️ No se eliminarán tus datos principales.'
                    : '⚠️ La aplicación se reiniciará y perderás toda la información local.',
                style: TextStyle(color: Colors.orange[800], fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearCache(tipo: tipo);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: tipo == 'cache' ? Colors.orange : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(tipo == 'cache' ? 'Limpiar Cache' : 'Eliminar Todo'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDataConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                '⚠️ Eliminar Todos los Datos',
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
            const Text('Esta acción eliminará:'),
            const SizedBox(height: 12),
            const Text('• Base de datos completa'),
            const Text('• Todos los archivos cache'),
            const Text('• Preferencias de la aplicación'),
            const Text('• Configuraciones guardadas'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ La aplicación se reiniciará y perderás toda la información local.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearCache(tipo: 'all');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache({String tipo = 'cache'}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Procesando...'),
            ],
          ),
        ),
      ),
    );

    try {
      bool success;

      if (tipo == 'cache') {
        success = await authProvider.clearAppCache();
      } else {
        success = await authProvider.clearAllData();
      }

      if (mounted) {
        Navigator.of(context).pop(); // Cerrar loading

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tipo == 'cache'
                    ? '✅ Caché borrada exitosamente'
                    : '✅ Todos los datos fueron eliminados',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          await _loadCacheInfo();
          await _loadUserData();

          if (tipo != 'cache' && !authProvider.isAuthenticated && mounted) {
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al procesar la solicitud'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.blue[50],
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue[100],
                          child: Icon(
                            _currentUser != null && _currentUser!.isAdmin
                                ? Icons.admin_panel_settings
                                : _currentUser != null
                                ? Icons.person
                                : Icons.person_outline,
                            size: 30,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentUser?.username ?? 'Invitado',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                _currentUser?.email ?? 'Modo de solo lectura',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Chip(
                                label: Text(
                                  _currentUser != null
                                      ? (_currentUser!.isAdmin
                                            ? 'Administrador'
                                            : 'Consultor')
                                      : 'Invitado',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor:
                                    _currentUser != null &&
                                        _currentUser!.isAdmin
                                    ? Colors.red[100]
                                    : Colors.green[100],
                                labelStyle: TextStyle(
                                  color:
                                      _currentUser != null &&
                                          _currentUser!.isAdmin
                                      ? Colors.red[800]
                                      : Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_currentUser != null)
                          IconButton(
                            icon: const Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                            ),
                            onPressed: _showUserInfo,
                            tooltip: 'Ver información',
                          ),
                        IconButton(
                          icon: Icon(
                            _currentUser != null ? Icons.logout : Icons.login,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            if (_currentUser != null) {
                              _showLogoutConfirmation();
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            }
                          },
                          tooltip: _currentUser != null
                              ? 'Cerrar sesión'
                              : 'Iniciar sesión',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'PREFERENCIAS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Notificaciones'),
                          subtitle: const Text(
                            'Recibir notificaciones importantes',
                          ),
                          value: _notifications,
                          onChanged: (value) {
                            setState(() {
                              _notifications = value;
                            });
                          },
                          activeThumbColor: Colors.blue[700],
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'ALMACENAMIENTO',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.storage,
                            color: Colors.blue,
                          ),
                          title: const Text('Información de Caché'),
                          subtitle: _loadingCacheInfo
                              ? const Text('Calculando...')
                              : Text(
                                  '${_cacheInfo['items'] ?? 0} items • ${_formatBytes(_cacheInfo['total'] ?? 0)}',
                                ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showCacheInfoDialog,
                        ),
                        const Divider(height: 1, indent: 16),
                        ListTile(
                          leading: const Icon(
                            Icons.delete_sweep,
                            color: Colors.red,
                          ),
                          title: const Text('Borrar Caché'),
                          subtitle: const Text(
                            'Eliminar datos almacenados localmente',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showClearCacheOptions(),
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'INFORMACIÓN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info, color: Colors.blue),
                          title: const Text('Acerca de'),
                          subtitle: const Text('Información de la aplicación'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showAboutDialog,
                        ),
                        const Divider(height: 1, indent: 16),
                        ListTile(
                          leading: const Icon(
                            Icons.security,
                            color: Colors.blue,
                          ),
                          title: const Text('Privacidad y Términos'),
                          subtitle: const Text('Políticas de uso y privacidad'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showPrivacyPolicy,
                        ),
                        const Divider(height: 1, indent: 16),
                        ListTile(
                          leading: const Icon(
                            Icons.settings_cell,
                            color: Colors.blue,
                          ),
                          title: const Text('Configuración de Red'),
                          subtitle: const Text(
                            'Configuración APN y conexión corporativa',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NetworkConfigScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'ACTUALIZACIONES',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.update,
                        color: _updateAvailable ? Colors.green : Colors.blue,
                      ),
                      title: const Text('Versión de la App'),
                      subtitle: Text('Versión $_appVersion'),
                      trailing: _updateAvailable
                          ? const Chip(
                              label: Text('NUEVO'),
                              backgroundColor: Colors.green,
                              labelStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : const Icon(Icons.check_circle, color: Colors.green),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _checkingForUpdates ? null : _checkForUpdates,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: _checkingForUpdates
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _updateAvailable
                                  ? Icons.download
                                  : Icons.system_update,
                              size: 24,
                            ),
                      label: Text(
                        _checkingForUpdates
                            ? 'VERIFICANDO...'
                            : _updateAvailable
                            ? 'DESCARGAR ACTUALIZACIÓN'
                            : 'BUSCAR ACTUALIZACIONES',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
