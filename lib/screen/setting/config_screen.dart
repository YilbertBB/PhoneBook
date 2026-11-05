import 'package:flutter/foundation.dart';
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

  static const Color _primary = Color(0xFF1769AA);
  static const Color _primaryDark = Color(0xFF104C80);
  static const Color _background = Color(0xFFF4F7FB);
  static const Color _surface = Colors.white;
  static const Color _textDark = Color(0xFF243447);
  static const Color _textMuted = Color(0xFF718096);
  static const Color _success = Color(0xFF159B72);
  static const Color _danger = Color(0xFFD94B4B);

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

  Widget _buildSectionTitle(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 26),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: _primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF243447).withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = _primary,
    Widget? trailing,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 7,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: _textMuted,
                height: 1.35,
              ),
            ),
          ),
          trailing:
              trailing ??
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA7B7)),
          onTap: onTap,
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 70,
            endIndent: 16,
            color: Color(0xFFEDF1F6),
          ),
      ],
    );
  }

  Widget _buildProfileCard() {
    final user = _currentUser;
    final isAdmin = user?.isAdmin ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  user == null
                      ? Icons.person_outline_rounded
                      : isAdmin
                      ? Icons.admin_panel_settings_rounded
                      : Icons.person_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.username ?? 'Invitado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user?.email ?? 'Modo de solo lectura',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user == null
                          ? Icons.visibility_outlined
                          : isAdmin
                          ? Icons.verified_user_outlined
                          : Icons.visibility_outlined,
                      size: 15,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user == null
                          ? 'Invitado'
                          : isAdmin
                          ? 'Administrador'
                          : 'Consultor',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (user != null)
                IconButton(
                  tooltip: 'Información del usuario',
                  onPressed: _showUserInfo,
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                  ),
                ),
              IconButton(
                tooltip: user != null ? 'Cerrar sesión' : 'Iniciar sesión',
                onPressed: () {
                  if (user != null) {
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
                icon: Icon(
                  user != null ? Icons.logout_rounded : Icons.login_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVersionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _success.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.verified_outlined,
              color: _success,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Versión de la aplicación',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Versión $_appVersion',
                  style: const TextStyle(color: _textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _success.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Actualizada',
              style: TextStyle(
                color: _success,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'Preferencias y administración',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;
                final horizontalPadding = isDesktop ? 32.0 : 18.0;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        24,
                        horizontalPadding,
                        30,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // PERFIL
                          _buildProfileCard(),

                          // PREFERENCIAS
                          if (!kIsWeb) ...[
                            _buildSectionTitle(
                              'Preferencias',
                              'Personaliza el comportamiento de la aplicación',
                              Icons.tune_rounded,
                            ),
                            _buildSettingsCard(
                              children: [
                                SwitchListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 7,
                                  ),
                                  secondary: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: _primary.withValues(alpha: 0.09),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_active_outlined,
                                      color: _primary,
                                    ),
                                  ),
                                  title: const Text(
                                    'Notificaciones',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _textDark,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Recibir notificaciones importantes',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _textMuted,
                                    ),
                                  ),
                                  value: _notifications,
                                  onChanged: (value) {
                                    setState(() {
                                      _notifications = value;
                                    });
                                  },
                                  activeThumbColor: _primary,
                                ),
                              ],
                            ),
                          ],

                          // ALMACENAMIENTO
                          _buildSectionTitle(
                            'Almacenamiento',
                            'Consulta y administra los datos guardados localmente',
                            Icons.storage_rounded,
                          ),
                          _buildSettingsCard(
                            children: [
                              _buildSettingTile(
                                icon: Icons.storage_rounded,
                                title: 'Información de caché',
                                subtitle: _loadingCacheInfo
                                    ? 'Calculando almacenamiento...'
                                    : '${_cacheInfo['items'] ?? 0} elementos · ${_formatBytes(_cacheInfo['total'] ?? 0)}',
                                onTap: _showCacheInfoDialog,
                              ),
                              _buildSettingTile(
                                icon: Icons.cleaning_services_outlined,
                                iconColor: _danger,
                                title: 'Borrar caché',
                                subtitle:
                                    'Eliminar datos almacenados localmente',
                                onTap: _showClearCacheOptions,
                                showDivider: false,
                              ),
                            ],
                          ),

                          // INFORMACIÓN
                          _buildSectionTitle(
                            'Información',
                            'Detalles de la aplicación y condiciones de uso',
                            Icons.info_outline_rounded,
                          ),
                          _buildSettingsCard(
                            children: [
                              _buildSettingTile(
                                icon: Icons.info_outline_rounded,
                                title: 'Acerca de',
                                subtitle: 'Información de la aplicación',
                                onTap: _showAboutDialog,
                              ),
                              _buildSettingTile(
                                icon: Icons.security_rounded,
                                title: 'Privacidad y términos',
                                subtitle: 'Políticas de uso y privacidad',
                                onTap: _showPrivacyPolicy,
                                showDivider: !kIsWeb,
                              ),
                              if (!kIsWeb)
                                _buildSettingTile(
                                  icon: Icons.settings_ethernet_rounded,
                                  title: 'Configuración de red',
                                  subtitle:
                                      'Configuración APN y conexión corporativa',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const NetworkConfigScreen(),
                                      ),
                                    );
                                  },
                                  showDivider: false,
                                ),
                            ],
                          ),

                          // ACTUALIZACIONES
                          if (!kIsWeb) ...[
                            _buildSectionTitle(
                              'Actualizaciones',
                              'Comprueba si existe una nueva versión',
                              Icons.system_update_alt_rounded,
                            ),
                            _buildVersionCard(),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _checkingForUpdates
                                    ? null
                                    : _checkForUpdates,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: _primary.withValues(
                                    alpha: 0.5,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                                icon: _checkingForUpdates
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        _updateAvailable
                                            ? Icons.download_rounded
                                            : Icons.refresh_rounded,
                                      ),
                                label: Text(
                                  _checkingForUpdates
                                      ? 'VERIFICANDO ACTUALIZACIONES...'
                                      : _updateAvailable
                                      ? 'DESCARGAR ACTUALIZACIÓN'
                                      : 'BUSCAR ACTUALIZACIONES',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // PIE DE PÁGINA
                          const SizedBox(height: 38),
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [_primary, _primaryDark],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primary.withValues(alpha: 0.18),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.near_me_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 13),
                                const Text(
                                  'Directorio Telefónico',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _textDark,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Versión $_appVersion',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'Desoft Cuba · © 2025',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
