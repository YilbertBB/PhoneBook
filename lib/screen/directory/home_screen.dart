import 'package:flutter/material.dart';
import '../../screen/directory/create_user_screen.dart';
import '../../screen/directory/local_screen.dart';
import 'package:provider/provider.dart';

import '../../models/rol.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/shared/responsive_card.dart';
import '../../widgets/shared/responsive_text.dart';
import '../auth/login_screen.dart';
import '../calendar/calendar_screen.dart';
import '../setting/config_screen.dart';
import 'departments_screen.dart';
import 'workers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _initialAuthCheckDone = false;

  @override
  void initState() {
    super.initState();
    // Verificar auth solo UNA VEZ al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthOnce();
    });
  }

  void _checkAuthOnce() async {
    if (_initialAuthCheckDone) return;

    final authProvider = context.read<AuthProvider>();

    // Solo verificar si nunca se ha hecho
    if (!authProvider.hasCheckedAuth) {
      await authProvider.checkAuthStatus();
    }

    _initialAuthCheckDone = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ResponsiveText(
          text: 'Directorio Telefónico',
          size: 20,
          color: Colors.white,
        ),
        backgroundColor: Colors.blue[700],
        actions: [
          // Botón de sincronización - CON SELECTOR para evitar rebuilds innecesarios
          Selector<AuthProvider, bool>(
            selector: (_, authProvider) => authProvider.isAuthenticated,
            builder: (context, isAuthenticated, child) {
              if (isAuthenticated) {
                return IconButton(
                  icon: Icon(Icons.sync, color: Colors.white),
                  onPressed: () => _syncData(context),
                  tooltip: 'Sincronizar datos',
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Botón de configuración - SIN Consumer
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ConfigScreen()),
              );
            },
            tooltip: 'Configuración',
          ),

          // Botón de login/logout - CON SELECTOR
          Selector<AuthProvider, bool>(
            selector: (_, authProvider) => authProvider.isAuthenticated,
            builder: (context, isAuthenticated, child) {
              return IconButton(
                icon: Icon(
                  isAuthenticated ? Icons.logout : Icons.login,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (isAuthenticated) {
                    _showLogoutConfirmation(context);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  }
                },
                tooltip: isAuthenticated ? 'Cerrar sesión' : 'Iniciar sesión',
              );
            },
          ),
        ],
      ),
      body: Selector<AuthProvider, User?>(
        selector: (_, authProvider) => authProvider.user,
        builder: (context, currentUser, child) {
          return _buildBody(context, currentUser);
        },
      ),
      floatingActionButton: Selector<AuthProvider, bool>(
        selector: (_, authProvider) => authProvider.isAuthenticated,
        builder: (context, isAuthenticated, child) {
          if (isAuthenticated) {
            return FloatingActionButton(
              onPressed: () => _syncData(context),
              backgroundColor: Colors.blue[700],
              tooltip: 'Sincronizar datos',
              child: Icon(Icons.sync, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, User? currentUser) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con información del usuario
          _buildUserHeader(context, currentUser),

          const SizedBox(height: 16),

          // Grid de opciones
          Expanded(
            child: GridView.count(
              crossAxisCount: ResponsiveUtils.getResponsiveGridCount(context),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: _buildMenuItems(context, currentUser),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, User? currentUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          text: currentUser != null
              ? 'Bienvenido, ${currentUser.username}'
              : 'Bienvenido',
          size: 24,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),

        SizedBox(height: 4),

        if (currentUser != null)
          ResponsiveText(
            text: _getRoleDisplayName(currentUser.roles),
            size: 16,
            color: Colors.grey[600],
          ),

        SizedBox(height: 8),

        if (currentUser != null)
          ResponsiveText(
            text: currentUser.email,
            size: 14,
            color: Colors.grey[500],
          ),
      ],
    );
  }

  // Widget _buildConnectionStatus(BuildContext context) {
  //   return Consumer<AuthProvider>(
  //     builder: (context, authProvider, child) {
  //       final isOnline = authProvider
  //           .isAuthenticated; // Esto deberías cambiar por un connectivity check real

  //       return Container(
  //         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //         decoration: BoxDecoration(
  //           color: isOnline ? Colors.green[50] : Colors.grey[100],
  //           borderRadius: BorderRadius.circular(8),
  //           border: Border.all(
  //             color: isOnline ? Colors.green : Colors.grey,
  //             width: 1,
  //           ),
  //         ),
  //         child: Row(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Icon(
  //               isOnline ? Icons.wifi : Icons.wifi_off,
  //               size: 16,
  //               color: isOnline ? Colors.green : Colors.grey,
  //             ),
  //             SizedBox(width: 8),
  //             ResponsiveText(
  //               text: isOnline ? 'Conectado' : 'Modo offline',
  //               size: 14,
  //               color: isOnline ? Colors.green[700] : Colors.grey[700],
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  // Mostrar diálogo de confirmación para logout
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cerrar Sesión'),
        content: Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Cerrar diálogo
              await _performLogout(context);
            },
            child: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Realizar logout
  Future<void> _performLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await authProvider.logout();
    if (context.mounted) {
      Navigator.of(context).pop(); // Cerrar loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sesión cerrada exitosamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Sincronizar datos
  Future<void> _syncData(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe iniciar sesión para sincronizar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Sincronizando...'),
          ],
        ),
        content: const Text('Actualizando datos locales con el servidor'),
      ),
    );

    // Aquí deberías llamar a tu SyncService
    await Future.delayed(const Duration(seconds: 2)); // Simulación
    if (context.mounted) {
      Navigator.of(context).pop(); // Cerrar diálogo

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos sincronizados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Obtener nombre display del rol
  String _getRoleDisplayName(List<Rol> roles) {
    if (roles.isEmpty) return 'Usuario';

    final roleNames = roles.map((rol) {
      switch (rol.nombre.toLowerCase()) {
        case 'admin':
          return 'Administrador';
        case 'user':
        case 'consult':
          return 'Usuario';
        default:
          return rol.nombre;
      }
    }).toList();

    return roleNames.join(', ');
  }

  List<Widget> _buildMenuItems(BuildContext context, User? currentUser) {
    final isAdmin = currentUser?.isAdmin ?? false;
    final isAuthenticated = currentUser != null;

    final menuItems = <Widget>[
      // Opciones disponibles para todos
      _buildCategoryCard(
        context,
        'Trabajadores',
        Icons.people,
        Colors.blue,
        WorkersScreen(),
        available: true,
      ),
      _buildCategoryCard(
        context,
        'Locales',
        Icons.business,
        Colors.green,
        LocalScreen(),
        available: true,
      ),
      _buildCategoryCard(
        context,
        'Departamentos',
        Icons.work,
        Colors.orange,
        DepartmentsScreen(),
        available: true,
      ),
      _buildCategoryCard(
        context,
        'Calendario',
        Icons.calendar_month_outlined,
        Colors.purple,
        CalendarScreen(),
        available: true,
      ),
    ];

    // Opciones solo para administradores
    if (isAdmin && isAuthenticated) {
      menuItems.addAll([
        _buildCategoryCard(
          context,
          'Agregar Usuario',
          Icons.person_add_alt_1,
          Colors.red,
          CreateUserScreen(),
          available: true,
        ),
      ]);
    }

    return menuItems;
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget screen, {
    bool available = true,
  }) {
    return GestureDetector(
      onTap: available
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => screen),
              );
            }
          : null,
      child: Opacity(
        opacity: available ? 1.0 : 0.5,
        child: ResponsiveCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(
                  ResponsiveUtils.getResponsiveValue(
                    context: context,
                    mobile: 10,
                    tablet: 16,
                    desktop: 20,
                  ),
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: ResponsiveUtils.getResponsiveValue(
                    context: context,
                    mobile: 32,
                    tablet: 36,
                    desktop: 40,
                  ),
                  color: available ? color : Colors.grey,
                ),
              ),

              SizedBox(height: 12),

              ResponsiveText(
                text: title,
                size: 16,
                fontWeight: FontWeight.bold,
                color: available ? Colors.blue[700] : Colors.grey[600],
                textAlign: TextAlign.center,
              ),

              if (!available)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: ResponsiveText(
                    text: '(Requiere login)',
                    size: 12,
                    color: Colors.grey[500],
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
