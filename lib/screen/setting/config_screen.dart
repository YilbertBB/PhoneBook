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
  static const Color _border = Color(0xFFE4EAF2);

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

    const primary = Color(0xFF1769AA);
    const primaryDark = Color(0xFF104C80);
    const textDark = Color(0xFF243447);
    const textMuted = Color(0xFF718096);
    const background = Color(0xFFF4F7FB);
    const border = Color(0xFFE4EAF2);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          user.isAdmin
                              ? Icons.admin_panel_settings_rounded
                              : Icons.person_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información del usuario',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Datos de la cuenta y permisos',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Usuario', user.username),
                      const Divider(height: 20, color: border),
                      _buildInfoRow('Correo electrónico', user.email),
                      const Divider(height: 20, color: border),
                      _buildInfoRow(
                        'Rol',
                        user.isAdmin ? 'Administrador' : 'Consultor',
                      ),
                      const Divider(height: 20, color: border),
                      _buildInfoRow(
                        'Registrado',
                        '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                      ),

                      const SizedBox(height: 18),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: user.isAdmin
                              ? primary.withValues(alpha: 0.07)
                              : const Color(0xFF159B72).withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: user.isAdmin
                                ? primary.withValues(alpha: 0.15)
                                : const Color(
                                    0xFF159B72,
                                  ).withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              user.isAdmin
                                  ? Icons.verified_user_rounded
                                  : Icons.visibility_rounded,
                              color: user.isAdmin
                                  ? primary
                                  : const Color(0xFF159B72),
                              size: 21,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                user.isAdmin
                                    ? 'Este usuario tiene permisos de administrador.'
                                    : 'Este usuario tiene permisos de consulta.',
                                style: const TextStyle(
                                  color: textDark,
                                  fontSize: 12,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text('Cerrar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF718096),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF243447),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    const primary = Color(0xFF1769AA);
    const primaryDark = Color(0xFF104C80);
    const textDark = Color(0xFF243447);
    const textMuted = Color(0xFF718096);
    const background = Color(0xFFF4F7FB);
    const border = Color(0xFFE4EAF2);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Acerca de',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Información de la aplicación',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.business_center_rounded,
                          color: primary,
                          size: 36,
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'Directorio de Trabajadores',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 7),

                      const Text(
                        'Aplicación para la gestión y consulta de información laboral.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 22),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          children: [
                            _buildAboutInfo('Versión', _appVersion),
                            const Divider(height: 18, color: border),
                            _buildAboutInfo('Desarrollador', 'Desoft Cuba'),
                            const Divider(height: 18, color: border),
                            _buildAboutInfo('Año', '2024'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.copyright_rounded,
                              color: primary,
                              size: 17,
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Todos los derechos reservados. Esta aplicación es para uso interno.',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 11,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text('Cerrar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutInfo(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF718096),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Color(0xFF243447),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  void _showPrivacyPolicy() {
    const primary = Color(0xFF1769AA);
    const primaryDark = Color(0xFF104C80);
    const textDark = Color(0xFF243447);
    const textMuted = Color(0xFF718096);
    const background = Color(0xFFF4F7FB);
    const border = Color(0xFFE4EAF2);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 19, 14, 19),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Política de privacidad',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Protección de datos y condiciones de uso',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPrivacySection(
                          icon: Icons.lock_outline_rounded,
                          title: 'Protección de datos',
                          description:
                              'La información personal se maneja de forma confidencial.\n'
                              'Solo el personal autorizado tiene acceso a los datos.\n'
                              'Los datos no se comparten con terceros.\n'
                              'Se implementan medidas de seguridad adecuadas.',
                        ),

                        const SizedBox(height: 18),

                        _buildPrivacySection(
                          icon: Icons.gavel_rounded,
                          title: 'Términos de uso',
                          description:
                              'Uso exclusivo para fines laborales.\n'
                              'Prohibido compartir credenciales.\n'
                              'Reportar actividades sospechosas.',
                        ),

                        const SizedBox(height: 18),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: border),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: primary,
                                size: 19,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'El acceso y uso de esta aplicación implica el cumplimiento de las condiciones descritas.',
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: background,
                    border: Border(top: BorderSide(color: border)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: const Text(
                        'Aceptar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFF1769AA).withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF1769AA), size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF243447),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...description
              .split('\n')
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Icon(
                          Icons.circle,
                          color: Color(0xFF1769AA),
                          size: 6,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
    const primary = Color(0xFF1769AA);
    const textDark = Color(0xFF243447);
    const textMuted = Color(0xFF718096);
    const danger = Color(0xFFD94B4B);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: danger.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: danger,
                  size: 31,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                '¿Estás seguro de que quieres cerrar sesión? '
                'Tendrás que volver a iniciar sesión para acceder a tu cuenta.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textDark,
                        side: const BorderSide(color: Color(0xFFE4EAF2)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(dialogContext);

                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );

                        await authProvider.logout();

                        if (!mounted) return;

                        setState(() {
                          _currentUser = null;
                        });
                      },
                      icon: const Icon(Icons.logout_rounded, size: 17),
                      label: const Text('Salir'),
                      style: FilledButton.styleFrom(
                        backgroundColor: danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCacheInfoDialog() {
    const primary = Color(0xFF1769AA);
    const primaryDark = Color(0xFF104C80);
    const background = Color(0xFFF4F7FB);
    const textDark = Color(0xFF243447);
    const textMuted = Color(0xFF718096);
    const border = Color(0xFFE4EAF2);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Encabezado
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 19, 14, 19),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.storage_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Almacenamiento local',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Información de caché y archivos',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido
                Expanded(
                  child: _loadingCacheInfo
                      ? const Center(
                          child: CircularProgressIndicator(color: primary),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Resumen
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCacheSummaryCard(
                                      icon: Icons.data_usage_rounded,
                                      label: 'Uso total',
                                      value: _formatBytes(
                                        _cacheInfo['total'] ?? 0,
                                      ),
                                      color: primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildCacheSummaryCard(
                                      icon: Icons.folder_copy_rounded,
                                      label: 'Archivos',
                                      value: '${_cacheInfo['items'] ?? 0}',
                                      color: const Color(0xFF159B72),
                                    ),
                                  ),
                                ],
                              ),

                              // Categorías
                              if (_cacheInfo['categories'] != null &&
                                  (_cacheInfo['categories'] as Map)
                                      .isNotEmpty) ...[
                                const SizedBox(height: 22),
                                _buildCacheSectionTitle(
                                  'Distribución por categorías',
                                  Icons.pie_chart_outline_rounded,
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: background,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: border),
                                  ),
                                  child: Column(
                                    children: _buildCategoryDetails(),
                                  ),
                                ),
                              ],

                              // Detalles
                              if (_cacheInfo['details'] != null &&
                                  (_cacheInfo['details'] as Map)
                                      .isNotEmpty) ...[
                                const SizedBox(height: 22),
                                _buildCacheSectionTitle(
                                  'Detalles por archivo',
                                  Icons.description_outlined,
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(
                                          dialogContext,
                                        ).size.height *
                                        0.30,
                                  ),
                                  decoration: BoxDecoration(
                                    color: background,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: border),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: _buildCacheDetails(),
                                    ),
                                  ),
                                ),
                              ],

                              // Sin datos
                              if ((_cacheInfo['details'] == null ||
                                      (_cacheInfo['details'] as Map).isEmpty) &&
                                  (_cacheInfo['categories'] == null ||
                                      (_cacheInfo['categories'] as Map)
                                          .isEmpty)) ...[
                                const SizedBox(height: 24),
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        size: 42,
                                        color: textMuted.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'No hay datos almacenados localmente',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: textMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),

                // Acciones
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 13, 20, 16),
                  decoration: const BoxDecoration(
                    color: background,
                    border: Border(top: BorderSide(color: border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textDark,
                            side: const BorderSide(color: border),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text('Cerrar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _showClearCacheOptions();
                          },
                          icon: const Icon(
                            Icons.cleaning_services_rounded,
                            size: 17,
                          ),
                          label: const Text('Gestionar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCacheSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF718096),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1769AA), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF243447),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCacheInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF718096),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF243447),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryDetails() {
    final categories = _cacheInfo['categories'] as Map<String, dynamic>?;

    if (categories == null || categories.isEmpty) return [];

    final entries = categories.entries
        .where((entry) => (entry.value as num) > 0)
        .toList();

    if (entries.isEmpty) {
      return [
        const Text(
          'No hay categorías con datos almacenados.',
          style: TextStyle(color: Color(0xFF718096), fontSize: 12),
        ),
      ];
    }

    return entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF1769AA).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.folder_outlined,
                color: Color(0xFF1769AA),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _getCategoryName(entry.key),
                style: const TextStyle(
                  color: Color(0xFF243447),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              _formatBytes((entry.value as num).toInt()),
              style: const TextStyle(
                color: Color(0xFF1769AA),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
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

    if (details == null || details.isEmpty) {
      return [const SizedBox.shrink()];
    }

    final entries = details.entries.toList();

    return entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            const Icon(
              Icons.insert_drive_file_outlined,
              color: Color(0xFF718096),
              size: 16,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                entry.key,
                style: const TextStyle(color: Color(0xFF243447), fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatBytes((entry.value as num).toInt()),
              style: const TextStyle(
                color: Color(0xFF1769AA),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
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

  // ============================================================
  // OPCIONES DE LIMPIEZA
  // ============================================================

  void _showClearCacheOptions() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE4EAF2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1769AA).withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cleaning_services_rounded,
                    color: Color(0xFF1769AA),
                    size: 30,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Opciones de limpieza',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF243447),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Selecciona qué deseas limpiar en tu dispositivo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF718096),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 22),

                // LIMPIEZA DE CACHÉ
                _buildCacheOptionCard(
                  icon: Icons.delete_outline_rounded,
                  title: 'Limpiar caché temporal',
                  description:
                      'Elimina archivos temporales sin afectar tus datos principales.',
                  color: const Color(0xFFE49A27),
                  background: const Color(0xFFFFF7E9),
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _showClearCacheConfirmation(tipo: 'cache');
                  },
                ),

                const SizedBox(height: 12),

                // ELIMINAR TODOS LOS DATOS
                _buildCacheOptionCard(
                  icon: Icons.delete_forever_rounded,
                  title: 'Eliminar todos los datos',
                  description:
                      'Elimina la base de datos, archivos y preferencias guardadas.',
                  color: const Color(0xFFD94B4B),
                  background: const Color(0xFFFFEEEE),
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _showClearAllDataConfirmation();
                  },
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF718096),
                      side: const BorderSide(color: Color(0xFFE4EAF2)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TARJETA DE OPCIÓN DE LIMPIEZA
  // ============================================================

  Widget _buildCacheOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.20)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 25),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF243447),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              Icon(Icons.chevron_right_rounded, color: color, size: 23),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONFIRMACIÓN DE LIMPIEZA DE CACHÉ
  // ============================================================

  void _showClearCacheConfirmation({String tipo = 'cache'}) {
    final bool isFullDelete = tipo == 'all';

    final Color accentColor = isFullDelete
        ? const Color(0xFFD94B4B)
        : const Color(0xFFE49A27);

    final IconData icon = isFullDelete
        ? Icons.delete_forever_rounded
        : Icons.warning_amber_rounded;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE4EAF2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 32),
                ),

                const SizedBox(height: 17),

                Text(
                  isFullDelete
                      ? 'Eliminar todos los datos'
                      : 'Borrar caché temporal',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF243447),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  isFullDelete
                      ? '¿Estás seguro de que deseas eliminar toda la información local?'
                      : '¿Estás seguro de que deseas borrar la caché temporal?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF718096),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 20),

                _buildCacheWarningList(
                  color: accentColor,
                  items: [
                    'Archivos temporales',
                    'Datos de caché del sistema',
                    'Configuraciones temporales',
                    if (isFullDelete) 'Base de datos local',
                    if (isFullDelete) 'Preferencias guardadas',
                  ],
                ),

                const SizedBox(height: 16),

                _buildCacheWarningBox(
                  color: accentColor,
                  message: isFullDelete
                      ? 'La aplicación se reiniciará y perderás toda la información local.'
                      : 'Tus datos principales no serán eliminados.',
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF718096),
                          side: const BorderSide(color: Color(0xFFE4EAF2)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await _clearCache(tipo: tipo);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isFullDelete ? 'Eliminar todo' : 'Limpiar caché',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
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
  }

  // ============================================================
  // CONFIRMACIÓN DE ELIMINACIÓN COMPLETA
  // ============================================================

  void _showClearAllDataConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE4EAF2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ICONO DE PELIGRO
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD94B4B).withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Color(0xFFD94B4B),
                    size: 36,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Eliminar todos los datos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF243447),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Esta acción eliminará permanentemente la información almacenada localmente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF718096),
                  ),
                ),

                const SizedBox(height: 20),

                _buildCacheWarningList(
                  color: const Color(0xFFD94B4B),
                  items: const [
                    'Base de datos completa',
                    'Todos los archivos de caché',
                    'Preferencias de la aplicación',
                    'Configuraciones guardadas',
                  ],
                ),

                const SizedBox(height: 16),

                _buildCacheWarningBox(
                  color: const Color(0xFFD94B4B),
                  message:
                      'La aplicación se reiniciará y perderás toda la información local.',
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF718096),
                          side: const BorderSide(color: Color(0xFFE4EAF2)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await _clearCache(tipo: 'all');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD94B4B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Eliminar todo',
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
  }

  // ============================================================
  // LISTA DE ELEMENTOS QUE SE ELIMINARÁN
  // ============================================================

  Widget _buildCacheWarningList({
    required Color color,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Se eliminará:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF243447),
            ),
          ),

          const SizedBox(height: 10),

          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 17,
                    color: color,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF526477),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADVERTENCIA DE SEGURIDAD
  // ============================================================

  Widget _buildCacheWarningBox({
    required Color color,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
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
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  user == null
                      ? Icons.person_outline_rounded
                      : isAdmin
                      ? Icons.admin_panel_settings_rounded
                      : Icons.person_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 15),
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
                        letterSpacing: 0.2,
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
              if (user != null)
                IconButton(
                  tooltip: 'Información del usuario',
                  onPressed: _showUserInfo,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 21),
                ),
            ],
          ),

          const SizedBox(height: 20),

          Container(height: 1, color: Colors.white.withValues(alpha: 0.17)),

          const SizedBox(height: 16),

          Row(
            children: [
              // Indicador de rol
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
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
                    const SizedBox(width: 7),
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

              // Acción de sesión
              Material(
                color: Colors.white.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user != null
                              ? Icons.logout_rounded
                              : Icons.login_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          user != null ? 'Salir' : 'Iniciar sesión',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
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
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _success.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: _success,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Versión de la aplicación',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Versión $_appVersion',
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _success.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _success.withValues(alpha: 0.12)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 13, color: _success),
                SizedBox(width: 5),
                Text(
                  'Actualizada',
                  style: TextStyle(
                    color: _success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
