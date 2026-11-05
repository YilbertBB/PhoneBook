// import 'package:flutter/material.dart';
// import '../../screen/directory/create_user_screen.dart';
// import '../../screen/directory/local_screen.dart';
// import 'package:provider/provider.dart';

// import '../../models/rol.dart';
// import '../../models/user.dart';
// import '../../providers/auth_provider.dart';
// import '../../utils/responsive_utils.dart';
// import '../../widgets/shared/responsive_card.dart';
// import '../../widgets/shared/responsive_text.dart';
// import '../auth/login_screen.dart';
// import '../calendar/calendar_screen.dart';
// import '../setting/config_screen.dart';
// import 'departments_screen.dart';
// import 'workers_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   bool _initialAuthCheckDone = false;

//   @override
//   void initState() {
//     super.initState();
//     // Verificar auth solo UNA VEZ al iniciar
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _checkAuthOnce();
//     });
//   }

//   void _checkAuthOnce() async {
//     if (_initialAuthCheckDone) return;

//     final authProvider = context.read<AuthProvider>();

//     // Solo verificar si nunca se ha hecho
//     if (!authProvider.hasCheckedAuth) {
//       await authProvider.checkAuthStatus();
//     }

//     _initialAuthCheckDone = true;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: ResponsiveText(
//           text: 'Directorio Telefónico',
//           size: 20,
//           color: Colors.white,
//         ),
//         backgroundColor: Colors.blue[700],
//         actions: [
//           // Botón de sincronización - CON SELECTOR para evitar rebuilds innecesarios
//           Selector<AuthProvider, bool>(
//             selector: (_, authProvider) => authProvider.isAuthenticated,
//             builder: (context, isAuthenticated, child) {
//               if (isAuthenticated) {
//                 return IconButton(
//                   icon: Icon(Icons.sync, color: Colors.white),
//                   onPressed: () => _syncData(context),
//                   tooltip: 'Sincronizar datos',
//                 );
//               }
//               return const SizedBox.shrink();
//             },
//           ),

//           // Botón de configuración - SIN Consumer
//           IconButton(
//             icon: Icon(Icons.settings, color: Colors.white),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => ConfigScreen()),
//               );
//             },
//             tooltip: 'Configuración',
//           ),

//           // Botón de login/logout - CON SELECTOR
//           Selector<AuthProvider, bool>(
//             selector: (_, authProvider) => authProvider.isAuthenticated,
//             builder: (context, isAuthenticated, child) {
//               return IconButton(
//                 icon: Icon(
//                   isAuthenticated ? Icons.logout : Icons.login,
//                   color: Colors.white,
//                 ),
//                 onPressed: () {
//                   if (isAuthenticated) {
//                     _showLogoutConfirmation(context);
//                   } else {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => LoginScreen()),
//                     );
//                   }
//                 },
//                 tooltip: isAuthenticated ? 'Cerrar sesión' : 'Iniciar sesión',
//               );
//             },
//           ),
//         ],
//       ),
//       body: Selector<AuthProvider, User?>(
//         selector: (_, authProvider) => authProvider.user,
//         builder: (context, currentUser, child) {
//           return _buildBody(context, currentUser);
//         },
//       ),
//       floatingActionButton: Selector<AuthProvider, bool>(
//         selector: (_, authProvider) => authProvider.isAuthenticated,
//         builder: (context, isAuthenticated, child) {
//           if (isAuthenticated) {
//             return FloatingActionButton(
//               onPressed: () => _syncData(context),
//               backgroundColor: Colors.blue[700],
//               tooltip: 'Sincronizar datos',
//               child: Icon(Icons.sync, color: Colors.white),
//             );
//           }
//           return const SizedBox.shrink();
//         },
//       ),
//     );
//   }

//   Widget _buildBody(BuildContext context, User? currentUser) {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Encabezado con información del usuario
//           _buildUserHeader(context, currentUser),

//           const SizedBox(height: 16),

//           // Grid de opciones
//           Expanded(
//             child: GridView.count(
//               crossAxisCount: ResponsiveUtils.getResponsiveGridCount(context),
//               crossAxisSpacing: 12,
//               mainAxisSpacing: 12,
//               childAspectRatio: 0.9,
//               children: _buildMenuItems(context, currentUser),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUserHeader(BuildContext context, User? currentUser) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         ResponsiveText(
//           text: currentUser != null
//               ? 'Bienvenido, ${currentUser.username}'
//               : 'Bienvenido',
//           size: 24,
//           fontWeight: FontWeight.bold,
//           color: Colors.blue[700],
//         ),

//         SizedBox(height: 4),

//         if (currentUser != null)
//           ResponsiveText(
//             text: _getRoleDisplayName(currentUser.roles),
//             size: 16,
//             color: Colors.grey[600],
//           ),

//         SizedBox(height: 8),

//         if (currentUser != null)
//           ResponsiveText(
//             text: currentUser.email,
//             size: 14,
//             color: Colors.grey[500],
//           ),
//       ],
//     );
//   }

//   // Widget _buildConnectionStatus(BuildContext context) {
//   //   return Consumer<AuthProvider>(
//   //     builder: (context, authProvider, child) {
//   //       final isOnline = authProvider
//   //           .isAuthenticated; // Esto deberías cambiar por un connectivity check real

//   //       return Container(
//   //         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//   //         decoration: BoxDecoration(
//   //           color: isOnline ? Colors.green[50] : Colors.grey[100],
//   //           borderRadius: BorderRadius.circular(8),
//   //           border: Border.all(
//   //             color: isOnline ? Colors.green : Colors.grey,
//   //             width: 1,
//   //           ),
//   //         ),
//   //         child: Row(
//   //           mainAxisSize: MainAxisSize.min,
//   //           children: [
//   //             Icon(
//   //               isOnline ? Icons.wifi : Icons.wifi_off,
//   //               size: 16,
//   //               color: isOnline ? Colors.green : Colors.grey,
//   //             ),
//   //             SizedBox(width: 8),
//   //             ResponsiveText(
//   //               text: isOnline ? 'Conectado' : 'Modo offline',
//   //               size: 14,
//   //               color: isOnline ? Colors.green[700] : Colors.grey[700],
//   //             ),
//   //           ],
//   //         ),
//   //       );
//   //     },
//   //   );
//   // }

//   // Mostrar diálogo de confirmación para logout
//   void _showLogoutConfirmation(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Cerrar Sesión'),
//         content: Text('¿Estás seguro de que quieres cerrar sesión?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text('Cancelar'),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.of(context).pop(); // Cerrar diálogo
//               await _performLogout(context);
//             },
//             child: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   // Realizar logout
//   Future<void> _performLogout(BuildContext context) async {
//     final authProvider = context.read<AuthProvider>();

//     // Mostrar loading
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const Center(child: CircularProgressIndicator()),
//     );

//     await authProvider.logout();
//     if (context.mounted) {
//       Navigator.of(context).pop(); // Cerrar loading

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('Sesión cerrada exitosamente'),
//           backgroundColor: Colors.green,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   }

//   // Sincronizar datos
//   Future<void> _syncData(BuildContext context) async {
//     final authProvider = context.read<AuthProvider>();

//     if (!authProvider.isAuthenticated) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Debe iniciar sesión para sincronizar'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Row(
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(width: 16),
//             Text('Sincronizando...'),
//           ],
//         ),
//         content: const Text('Actualizando datos locales con el servidor'),
//       ),
//     );

//     // Aquí deberías llamar a tu SyncService
//     await Future.delayed(const Duration(seconds: 2)); // Simulación
//     if (context.mounted) {
//       Navigator.of(context).pop(); // Cerrar diálogo

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Datos sincronizados correctamente'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   }

//   // Obtener nombre display del rol
//   String _getRoleDisplayName(List<Rol> roles) {
//     if (roles.isEmpty) return 'Usuario';

//     final roleNames = roles.map((rol) {
//       switch (rol.nombre.toLowerCase()) {
//         case 'admin':
//           return 'Administrador';
//         case 'user':
//         case 'consult':
//           return 'Usuario';
//         default:
//           return rol.nombre;
//       }
//     }).toList();

//     return roleNames.join(', ');
//   }

//   List<Widget> _buildMenuItems(BuildContext context, User? currentUser) {
//     final isAdmin = currentUser?.isAdmin ?? false;
//     final isAuthenticated = currentUser != null;

//     final menuItems = <Widget>[
//       // Opciones disponibles para todos
//       _buildCategoryCard(
//         context,
//         'Trabajadores',
//         Icons.people,
//         Colors.blue,
//         WorkersScreen(),
//         available: true,
//       ),
//       _buildCategoryCard(
//         context,
//         'Locales',
//         Icons.business,
//         Colors.green,
//         LocalScreen(),
//         available: true,
//       ),
//       _buildCategoryCard(
//         context,
//         'Departamentos',
//         Icons.work,
//         Colors.orange,
//         DepartmentsScreen(),
//         available: true,
//       ),
//       _buildCategoryCard(
//         context,
//         'Calendario',
//         Icons.calendar_month_outlined,
//         Colors.purple,
//         CalendarScreen(),
//         available: true,
//       ),
//     ];

//     // Opciones solo para administradores
//     if (isAdmin && isAuthenticated) {
//       menuItems.addAll([
//         _buildCategoryCard(
//           context,
//           'Agregar Usuario',
//           Icons.person_add_alt_1,
//           Colors.red,
//           CreateUserScreen(),
//           available: true,
//         ),
//       ]);
//     }

//     return menuItems;
//   }

//   Widget _buildCategoryCard(
//     BuildContext context,
//     String title,
//     IconData icon,
//     Color color,
//     Widget screen, {
//     bool available = true,
//   }) {
//     return GestureDetector(
//       onTap: available
//           ? () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => screen),
//               );
//             }
//           : null,
//       child: Opacity(
//         opacity: available ? 1.0 : 0.5,
//         child: ResponsiveCard(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 padding: EdgeInsets.all(
//                   ResponsiveUtils.getResponsiveValue(
//                     context: context,
//                     mobile: 10,
//                     tablet: 16,
//                     desktop: 20,
//                   ),
//                 ),
//                 decoration: BoxDecoration(
//                   color: color.withValues(alpha: 0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   icon,
//                   size: ResponsiveUtils.getResponsiveValue(
//                     context: context,
//                     mobile: 32,
//                     tablet: 36,
//                     desktop: 40,
//                   ),
//                   color: available ? color : Colors.grey,
//                 ),
//               ),

//               SizedBox(height: 12),

//               ResponsiveText(
//                 text: title,
//                 size: 16,
//                 fontWeight: FontWeight.bold,
//                 color: available ? Colors.blue[700] : Colors.grey[600],
//                 textAlign: TextAlign.center,
//               ),

//               if (!available)
//                 Padding(
//                   padding: EdgeInsets.only(top: 4),
//                   child: ResponsiveText(
//                     text: '(Requiere login)',
//                     size: 12,
//                     color: Colors.grey[500],
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../screen/directory/create_user_screen.dart';
import '../../screen/directory/local_screen.dart';

import '../../models/rol.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';

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

  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color darkBlue = Color(0xFF103B82);
  static const Color background = Color(0xFFF5F8FD);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthOnce();
    });
  }

  // =========================================================
  // AUTENTICACIÓN ORIGINAL
  // =========================================================

  Future<void> _checkAuthOnce() async {
    if (_initialAuthCheckDone) return;

    final authProvider = context.read<AuthProvider>();

    if (!authProvider.hasCheckedAuth) {
      await authProvider.checkAuthStatus();
    }

    if (!mounted) return;

    setState(() {
      _initialAuthCheckDone = true;
    });
  }

  // =========================================================
  // BUILD PRINCIPAL
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: _buildAppBar(),
      body: Selector<AuthProvider, User?>(
        selector: (_, authProvider) => authProvider.user,
        builder: (context, currentUser, child) {
          return _buildBody(context, currentUser);
        },
      ),
      floatingActionButton: Selector<AuthProvider, bool>(
        selector: (_, authProvider) => authProvider.isAuthenticated,
        builder: (context, isAuthenticated, child) {
          if (!isAuthenticated) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => _syncData(context),
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            elevation: 5,
            icon: const Icon(Icons.sync_rounded),
            label: const Text(
              'Sincronizar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // APP BAR
  // =========================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      toolbarHeight: 72,
      titleSpacing: 22,
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.contact_phone_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Directorio Telefónico',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
                Text(
                  'DESOFT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: primaryBlue.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Selector<AuthProvider, bool>(
          selector: (_, authProvider) => authProvider.isAuthenticated,
          builder: (context, isAuthenticated, child) {
            if (!isAuthenticated) {
              return const SizedBox.shrink();
            }

            return _buildAppBarAction(
              icon: Icons.sync_rounded,
              tooltip: 'Sincronizar datos',
              onPressed: () => _syncData(context),
            );
          },
        ),
        _buildAppBarAction(
          icon: Icons.settings_outlined,
          tooltip: 'Configuración',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ConfigScreen()),
            );
          },
        ),
        Selector<AuthProvider, bool>(
          selector: (_, authProvider) => authProvider.isAuthenticated,
          builder: (context, isAuthenticated, child) {
            return Padding(
              padding: const EdgeInsets.only(left: 5, right: 18),
              child: _buildAppBarAction(
                icon: isAuthenticated
                    ? Icons.logout_rounded
                    : Icons.login_rounded,
                tooltip: isAuthenticated ? 'Cerrar sesión' : 'Iniciar sesión',
                color: isAuthenticated ? Colors.redAccent : primaryBlue,
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
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color color = primaryBlue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.07),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, color: color, size: 22),
      ),
    );
  }

  // =========================================================
  // CUERPO RESPONSIVE
  // =========================================================

  Widget _buildBody(BuildContext context, User? currentUser) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isMobile = width < 600;
        final isTablet = width >= 600 && width < 1100;

        final crossAxisCount = width >= 1500
            ? 5
            : width >= 1100
            ? 4
            : isTablet
            ? 3
            : 2;

        final horizontalPadding = isMobile
            ? 18.0
            : isTablet
            ? 30.0
            : 42.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            28,
            horizontalPadding,
            100,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHeader(currentUser, isMobile),

                  const SizedBox(height: 30),

                  _buildSectionHeader(),

                  const SizedBox(height: 17),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: isMobile ? 14 : 20,
                    mainAxisSpacing: isMobile ? 14 : 20,
                    childAspectRatio: isMobile
                        ? 0.98
                        : isTablet
                        ? 1.10
                        : 1.17,
                    children: _buildMenuItems(context, currentUser),
                  ),

                  const SizedBox(height: 35),

                  _buildBottomInformation(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // BIENVENIDA
  // =========================================================

  Widget _buildWelcomeHeader(User? currentUser, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 22 : 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF103B82), Color(0xFF1976D2), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -45,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 75,
            bottom: -75,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.waving_hand_rounded,
                                color: Color(0xFFFFD180),
                                size: 15,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'BIENVENIDO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      currentUser != null
                          ? 'Hola, ${currentUser.username}'
                          : 'Bienvenido',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 25 : 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Text(
                      currentUser != null
                          ? _getRoleDisplayName(currentUser.roles)
                          : 'Explora el directorio telefónico',
                      style: const TextStyle(
                        color: Color(0xFFD8EAFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    if (currentUser != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        currentUser.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFBBD9FF),
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.dashboard_rounded,
                            size: 16,
                            color: primaryBlue,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Panel principal',
                            style: TextStyle(
                              color: darkBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (!isMobile) ...[
                const SizedBox(width: 15),
                Container(
                  width: 125,
                  height: 125,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.contact_phone_rounded,
                    color: Colors.white,
                    size: 75,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SECCIÓN DE MÓDULOS
  // =========================================================

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 25,
          decoration: BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Text(
            'Módulos del sistema',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
        ),
        Icon(
          Icons.grid_view_rounded,
          color: Colors.blueGrey.shade300,
          size: 22,
        ),
      ],
    );
  }

  // =========================================================
  // INFORMACIÓN INFERIOR
  // =========================================================

  Widget _buildBottomInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EDF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: primaryBlue,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Directorio Telefónico Desoft',
                  style: TextStyle(
                    color: darkBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Sistema de gestión de información corporativa',
                  style: TextStyle(color: Colors.blueGrey, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF4CAF80),
            size: 21,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CERRAR SESIÓN
  // =========================================================

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Cerrar sesión'),
          ],
        ),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _performLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await authProvider.logout();

    if (context.mounted) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión cerrada exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // =========================================================
  // SINCRONIZACIÓN
  // =========================================================

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Flexible(child: Text('Sincronizando...')),
          ],
        ),
        content: const Text('Actualizando datos locales con el servidor'),
      ),
    );

    // Se conserva la implementación original.
    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos sincronizados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // =========================================================
  // NOMBRE DEL ROL
  // =========================================================

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

  // =========================================================
  // MÓDULOS Y PERMISOS
  // =========================================================

  List<Widget> _buildMenuItems(BuildContext context, User? currentUser) {
    final isAdmin = currentUser?.isAdmin ?? false;
    final isAuthenticated = currentUser != null;

    final menuItems = <Widget>[
      _buildCategoryCard(
        context,
        'Trabajadores',
        Icons.people_alt_rounded,
        const Color(0xFF1976D2),
        WorkersScreen(),
        subtitle: 'Gestión del personal',
      ),

      _buildCategoryCard(
        context,
        'Locales',
        Icons.business_rounded,
        const Color(0xFF26A69A),
        LocalScreen(),
        subtitle: 'Directorio de locales',
      ),

      _buildCategoryCard(
        context,
        'Departamentos',
        Icons.account_tree_rounded,
        const Color(0xFFFF9800),
        DepartmentsScreen(),
        subtitle: 'Organización interna',
      ),

      _buildCategoryCard(
        context,
        'Calendario',
        Icons.calendar_month_rounded,
        const Color(0xFF8E65D8),
        CalendarScreen(),
        subtitle: 'Eventos y actividades',
      ),
    ];

    if (isAdmin && isAuthenticated) {
      menuItems.add(
        _buildCategoryCard(
          context,
          'Agregar Usuario',
          Icons.person_add_alt_1_rounded,
          const Color(0xFFE45C72),
          CreateUserScreen(),
          subtitle: 'Administrar usuarios',
        ),
      );
    }

    return menuItems;
  }

  // =========================================================
  // TARJETAS DE MÓDULOS
  // =========================================================

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget screen, {
    String subtitle = '',
    bool available = true,
  }) {
    return Opacity(
      opacity: available ? 1 : 0.5,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          onTap: available
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => screen),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(21),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: const Color(0xFFE7EDF5), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF17365D).withValues(alpha: 0.035),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: Icon(
                    icon,
                    color: available ? color : Colors.grey,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 17),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: available ? darkBlue : Colors.grey.shade600,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  available ? subtitle : '(Requiere login)',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.blueGrey.shade400,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 13),

                Container(
                  width: 30,
                  height: 3,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
