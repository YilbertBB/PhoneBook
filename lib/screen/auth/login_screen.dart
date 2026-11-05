// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   LoginScreenState createState() => LoginScreenState();
// }

// class LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _usernameOrEmailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _obscurePassword = true;
//   bool _checkingCachedSession = true;
//   User? _cachedUser;

//   @override
//   void initState() {
//     super.initState();
//     _checkCachedSession();
//   }

//   // Verificar si hay sesión cacheada
//   Future<void> _checkCachedSession() async {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);

//     try {
//       // Verificar sesión cacheada usando el método getCachedUser
//       final cachedUser = authProvider.getCachedUser();

//       setState(() {
//         _checkingCachedSession = false;
//         _cachedUser = cachedUser;
//       });

//       // Si hay usuario cacheado, verificar token
//       if (cachedUser != null) {
//         final isTokenValid = authProvider.isTokenValidLocally(
//           authProvider.token ?? '',
//         );
//         if (isTokenValid) {
//           // Auto-redirigir después de un breve delay
//           await Future.delayed(Duration(milliseconds: 500));
//           if (mounted) {
//             // En lugar de llamar directamente, hacer login con usuario cacheado
//             _loginWithCachedUser();
//           }
//         }
//       }
//     } catch (e) {
//       setState(() {
//         _checkingCachedSession = false;
//       });
//     }
//   }

//   String? _validateUsernameOrEmail(String? value) {
//     return Validators.validateUsernameOrEmail(value);
//   }

//   String? _validatePassword(String? value) {
//     return Validators.validatePassword(value);
//   }

//   Future<void> _performLogin() async {
//     if (_formKey.currentState!.validate()) {
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
//       final usernameOrEmail = _usernameOrEmailController.text.trim();
//       final password = _passwordController.text;

//       // Usar el método login con parámetro forceRefresh
//       final success = await authProvider.login(
//         usernameOrEmail,
//         password,
//         forceRefresh: false,
//       );

//       if (success) {
//         if (mounted) {
//           Navigator.of(context).pop();
//           DialogErrorHandler.showSuccessSnackbar(
//             context: context,
//             message: '✅ Sesión iniciada exitosamente',
//           );
//         }
//       } else {
//         final error = authProvider.error ?? 'Error desconocido';
//         final isNetworkError =
//             error.contains('conexión') ||
//             error.contains('internet') ||
//             error.contains('red') ||
//             error.contains('Conexión');

//         if (mounted) {
//           DialogErrorHandler.showErrorDialog(
//             context: context,
//             title: 'Error de autenticación',
//             technicalError: error,
//             showRetryButton: isNetworkError,
//             onRetry: isNetworkError ? _performLogin : null,
//           );
//         }
//       }
//     }
//   }

//   // Iniciar sesión con usuario cacheado (modo offline)
//   // En _loginWithCachedUser:
//   Future<void> _loginWithCachedUser() async {
//     if (_cachedUser == null) return;

//     final authProvider = Provider.of<AuthProvider>(context, listen: false);

//     // Mostrar loading
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(width: 16),
//             Text('Restaurando sesión...'),
//           ],
//         ),
//         content: Text('Usando sesión guardada de ${_cachedUser!.username}'),
//       ),
//     );

//     final success = await authProvider.restoreCachedSession();
//     if (mounted) {
//       Navigator.of(context).pop(); // Cerrar loading
//     }

//     if (success) {
//       if (mounted) {
//         Navigator.of(context).pop();
//         DialogErrorHandler.showSuccessSnackbar(
//           context: context,
//           message: '✅ Sesión restaurada (Modo lectura)',
//         );
//       }
//     } else {
//       // No se pudo restaurar
//       setState(() {
//         _cachedUser = null;
//       });

//       if (mounted) {
//         DialogErrorHandler.showErrorDialog(
//           context: context,
//           title: 'Sesión expirada',
//           technicalError:
//               'La sesión guardada ha expirado. Se requiere conexión para iniciar sesión nuevamente.',
//         );
//       }
//     }
//   }

//   // En el texto del modo offline, cambia a:

//   // Mostrar opción de sesión cacheada
//   Widget _buildCachedSessionOption() {
//     if (_checkingCachedSession) {
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 16),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             SizedBox(
//               width: 16,
//               height: 16,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             ),
//             SizedBox(width: 8),
//             Text(
//               'Buscando sesión guardada...',
//               style: TextStyle(color: Colors.grey[600], fontSize: 12),
//             ),
//           ],
//         ),
//       );
//     }

//     if (_cachedUser != null) {
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 16),
//         child: Container(
//           decoration: BoxDecoration(
//             color: Colors.blue[50],
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.blue[200]!),
//           ),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(Icons.history, color: Colors.blue[700], size: 20),
//                   SizedBox(width: 8),
//                   Text(
//                     'Sesión guardada encontrada',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue[700],
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 12),
//               Row(
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: Colors.blue[100],
//                     child: Icon(Icons.person, color: Colors.blue[700]),
//                   ),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           _cachedUser!.username,
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         SizedBox(height: 4),
//                         Text(
//                           _cachedUser!.email,
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                         SizedBox(height: 4),
//                         Row(
//                           children: [
//                             Icon(
//                               Icons.cloud_off,
//                               size: 12,
//                               color: Colors.orange,
//                             ),
//                             SizedBox(width: 4),
//                             Text(
//                               'Solo lectura disponible',
//                               style: TextStyle(
//                                 fontSize: 11,
//                                 color: Colors.orange[700],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 16),
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       icon: Icon(Icons.login, size: 16),
//                       label: Text('Continuar offline'),
//                       onPressed: _loginWithCachedUser,
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.blue[700],
//                         side: BorderSide(color: Colors.blue[700]!),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: TextButton.icon(
//                       icon: Icon(Icons.cancel, size: 16),
//                       label: Text('Usar otra cuenta'),
//                       onPressed: () => setState(() {
//                         _cachedUser = null;
//                       }),
//                       style: TextButton.styleFrom(
//                         foregroundColor: Colors.grey[600],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return SizedBox.shrink();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: ResponsiveContainer(
//         child: Column(
//           children: [
//             // Logo/Header responsive
//             SizedBox(
//               height: ResponsiveUtils.getResponsiveValue(
//                 context: context,
//                 mobile: 40,
//                 tablet: 60,
//                 desktop: 80,
//               ),
//             ),

//             Icon(
//               Icons.contacts,
//               size: ResponsiveUtils.getResponsiveValue(
//                 context: context,
//                 mobile: 80,
//                 tablet: 100,
//                 desktop: 120,
//               ),
//               color: Colors.blue[700],
//             ),

//             const SizedBox(height: 16),

//             ResponsiveText(
//               text: 'Directorio Telefónico',
//               size: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.blue[700],
//             ),
//             ResponsiveText(
//               text: 'Desoft',
//               size: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.blue[700],
//             ),

//             const SizedBox(height: 8),

//             ResponsiveText(
//               text: 'Ingrese sus Credenciales',
//               size: 16,
//               color: Colors.grey[600],
//             ),

//             SizedBox(
//               height: ResponsiveUtils.getResponsiveValue(
//                 context: context,
//                 mobile: 20,
//                 tablet: 30,
//                 desktop: 40,
//               ),
//             ),

//             // Opción de sesión cacheada
//             _buildCachedSessionOption(),

//             SizedBox(height: 16),

//             Form(
//               key: _formKey,
//               child: Column(
//                 children: [
//                   TextFormField(
//                     controller: _usernameOrEmailController,
//                     decoration: InputDecoration(
//                       labelText: 'Usuario o Correo electrónico',
//                       prefixIcon: Icon(Icons.person, color: Colors.blue),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       hintText: 'admin o admin@empresa.com',
//                     ),
//                     validator: _validateUsernameOrEmail,
//                     textInputAction: TextInputAction.next,
//                   ),

//                   const SizedBox(height: 20),

//                   TextFormField(
//                     controller: _passwordController,
//                     obscureText: _obscurePassword,
//                     decoration: InputDecoration(
//                       labelText: 'Contraseña',
//                       prefixIcon: const Icon(Icons.lock, color: Colors.blue),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _obscurePassword
//                               ? Icons.visibility
//                               : Icons.visibility_off,
//                           color: Colors.blue,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _obscurePassword = !_obscurePassword;
//                           });
//                         },
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       hintText: 'Ingresa tu contraseña',
//                     ),
//                     validator: _validatePassword,
//                     textInputAction: TextInputAction.done,
//                     onFieldSubmitted: (_) => _performLogin(),
//                   ),

//                   const SizedBox(height: 40),

//                   // Loading y botón
//                   if (authProvider.loading || authProvider.isLoading)
//                     Column(
//                       children: [
//                         const CircularProgressIndicator(),
//                         const SizedBox(height: 16),
//                         Text(
//                           'Verificando credenciales...',
//                           style: TextStyle(color: Colors.grey[600]),
//                         ),
//                       ],
//                     )
//                   else
//                     ResponsiveButton(
//                       text: 'Iniciar Sesión',
//                       onPressed: _performLogin,
//                       backgroundColor: Colors.blue[700]!,
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _usernameOrEmailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
// }

// import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../utils/dialog_error_handler.dart';
import '../../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _checkingCachedSession = true;
  bool _isLoggingIn = false;

  User? _cachedUser;

  static const Color _primaryBlue = Color(0xFF1976D2);
  static const Color _darkBlue = Color(0xFF103B82);
  static const Color _lightBlue = Color(0xFF42A5F5);
  static const Color _background = Color(0xFFF5F8FD);

  @override
  void initState() {
    super.initState();
    _checkCachedSession();
  }

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =========================================================
  // AUTENTICACIÓN ORIGINAL
  // =========================================================

  Future<void> _checkCachedSession() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final cachedUser = authProvider.getCachedUser();

      if (!mounted) return;

      setState(() {
        _checkingCachedSession = false;
        _cachedUser = cachedUser;
      });

      if (cachedUser != null) {
        final isTokenValid = authProvider.isTokenValidLocally(
          authProvider.token ?? '',
        );

        if (isTokenValid) {
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            await _loginWithCachedUser();
          }
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _checkingCachedSession = false;
      });
    }
  }

  String? _validateUsernameOrEmail(String? value) {
    return Validators.validateUsernameOrEmail(value);
  }

  String? _validatePassword(String? value) {
    return Validators.validatePassword(value);
  }

  Future<void> _performLogin() async {
    if (_isLoggingIn) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoggingIn = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final usernameOrEmail = _usernameOrEmailController.text.trim();

      final password = _passwordController.text;

      final success = await authProvider.login(
        usernameOrEmail,
        password,
        forceRefresh: false,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();

        DialogErrorHandler.showSuccessSnackbar(
          context: context,
          message: '✅ Sesión iniciada exitosamente',
        );
      } else {
        final error = authProvider.error ?? 'Error desconocido';

        final isNetworkError =
            error.contains('conexión') ||
            error.contains('internet') ||
            error.contains('red') ||
            error.contains('Conexión');

        DialogErrorHandler.showErrorDialog(
          context: context,
          title: 'Error de autenticación',
          technicalError: error,
          showRetryButton: isNetworkError,
          onRetry: isNetworkError ? _performLogin : null,
        );
      }
    } catch (e) {
      if (!mounted) return;

      DialogErrorHandler.showErrorDialog(
        context: context,
        title: 'Error de autenticación',
        technicalError: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  // =========================================================
  // RESTAURAR SESIÓN OFFLINE
  // =========================================================

  Future<void> _loginWithCachedUser() async {
    if (_cachedUser == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Row(
          children: [
            const CircularProgressIndicator(color: _primaryBlue),
            const SizedBox(width: 18),
            Expanded(
              child: Text('Restaurando sesión de ${_cachedUser!.username}...'),
            ),
          ],
        ),
      ),
    );

    bool success = false;

    try {
      success = await authProvider.restoreCachedSession();
    } catch (e) {
      success = false;
    }

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop();

    if (success) {
      Navigator.of(context).pop();

      DialogErrorHandler.showSuccessSnackbar(
        context: context,
        message: '✅ Sesión restaurada (Modo lectura)',
      );
    } else {
      setState(() {
        _cachedUser = null;
      });

      DialogErrorHandler.showErrorDialog(
        context: context,
        title: 'Sesión expirada',
        technicalError:
            'La sesión guardada ha expirado. '
            'Se requiere conexión para iniciar sesión nuevamente.',
      );
    }
  }

  // =========================================================
  // OPCIÓN DE SESIÓN GUARDADA
  // =========================================================

  Widget _buildCachedSessionOption() {
    if (_checkingCachedSession) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _primaryBlue,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Buscando sesión guardada...',
              style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_cachedUser == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBDD9FA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, color: _primaryBlue, size: 21),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Sesión guardada encontrada',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _darkBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFD2E6FF),
                child: Icon(Icons.person_rounded, color: _primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cachedUser!.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _darkBlue,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _cachedUser!.email,
                      style: TextStyle(
                        color: Colors.blueGrey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Row(
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 13,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Solo lectura disponible',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 330) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildOfflineButton(),
                    const SizedBox(height: 5),
                    _buildOtherAccountButton(),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: _buildOfflineButton()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildOtherAccountButton()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineButton() {
    return OutlinedButton.icon(
      onPressed: _loginWithCachedUser,
      icon: const Icon(Icons.login_rounded, size: 17),
      label: const Text('Continuar offline', textAlign: TextAlign.center),
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryBlue,
        side: const BorderSide(color: _primaryBlue),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );
  }

  Widget _buildOtherAccountButton() {
    return TextButton.icon(
      onPressed: () {
        setState(() {
          _cachedUser = null;
        });
      },
      icon: const Icon(Icons.cancel_outlined, size: 17),
      label: const Text('Usar otra cuenta', textAlign: TextAlign.center),
      style: TextButton.styleFrom(
        foregroundColor: Colors.blueGrey.shade600,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
      ),
    );
  }

  // =========================================================
  // DISEÑO PRINCIPAL RESPONSIVE
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final isLoading =
        authProvider.loading || authProvider.isLoading || _isLoggingIn;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 850) {
              return _buildDesktopLayout(isLoading);
            }

            return _buildMobileLayout(isLoading);
          },
        ),
      ),
    );
  }

  // =========================================================
  // MÓVIL
  // =========================================================

  Widget _buildMobileLayout(bool isLoading) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF0F6FF)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _buildBrandHeader(isMobile: true),
                const SizedBox(height: 30),
                _buildCachedSessionOption(),
                _buildLoginForm(isLoading),
                const SizedBox(height: 35),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ESCRITORIO
  // =========================================================

  Widget _buildDesktopLayout(bool isLoading) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEAF4FF), Color(0xFFF8FBFF)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(35),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1250, minHeight: 650),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _darkBlue.withValues(alpha: 0.10),
                    blurRadius: 35,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 11, child: _buildDesktopIllustration()),
                    Expanded(
                      flex: 10,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 45,
                          vertical: 45,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildBrandHeader(isMobile: false),
                                const SizedBox(height: 28),
                                _buildCachedSessionOption(),
                                _buildLoginForm(isLoading),
                                const SizedBox(height: 30),
                                _buildFooter(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ILUSTRACIÓN ESCRITORIO
  // =========================================================

  Widget _buildDesktopIllustration() {
    return Container(
      constraints: const BoxConstraints(minHeight: 650),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: _buildCircle(350, Colors.white.withValues(alpha: 0.06)),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: _buildCircle(400, Colors.white.withValues(alpha: 0.08)),
          ),
          Positioned(top: 45, right: 45, child: _buildDots()),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(35),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.contact_phone_rounded,
                      size: 90,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 35),
                  const Text(
                    'Directorio Telefónico',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Desoft',
                    style: TextStyle(
                      color: Color(0xFFBDE3FF),
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 65,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Conectando personas,\nfacilitando la comunicación.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Text(
              'DESOFT  •  DIRECTORIO CORPORATIVO',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildDots() {
    return SizedBox(
      width: 75,
      height: 75,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(
          16,
          (_) => Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0x88FFFFFF),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ENCABEZADO
  // =========================================================

  Widget _buildBrandHeader({required bool isMobile}) {
    return Column(
      children: [
        Container(
          width: isMobile ? 112 : 95,
          height: isMobile ? 112 : 95,
          decoration: BoxDecoration(
            color: _primaryBlue,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withValues(alpha: 0.20),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.contact_phone_rounded,
            size: isMobile ? 65 : 55,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 25),
        Text(
          'Directorio Telefónico',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _darkBlue,
            fontSize: isMobile ? 27 : 29,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Desoft',
          style: TextStyle(
            color: _primaryBlue,
            fontSize: isMobile ? 29 : 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Ingrese sus Credenciales',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 16),
        ),
      ],
    );
  }

  // =========================================================
  // FORMULARIO
  // =========================================================

  Widget _buildLoginForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildInputField(
            controller: _usernameOrEmailController,
            hint: 'Usuario o Correo electrónico',
            icon: Icons.person_rounded,
            isPassword: false,
          ),
          const SizedBox(height: 22),
          _buildInputField(
            controller: _passwordController,
            hint: 'Contraseña',
            icon: Icons.lock_rounded,
            isPassword: true,
          ),
          const SizedBox(height: 38),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: isLoading ? null : _performLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _primaryBlue.withValues(alpha: 0.6),
                elevation: 5,
                shadowColor: _primaryBlue.withValues(alpha: 0.30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Verificando credenciales...'),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded, size: 23),
                        SizedBox(width: 12),
                        Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
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

  // =========================================================
  // CAMPOS DE TEXTO
  // =========================================================

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isPassword,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: isPassword
          ? TextInputType.visiblePassword
          : TextInputType.emailAddress,
      textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: isPassword ? (_) => _performLogin() : null,
      validator: isPassword ? _validatePassword : _validateUsernameOrEmail,
      style: const TextStyle(fontSize: 16, color: Color(0xFF30364A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.blueGrey.shade400, fontSize: 15),
        prefixIcon: Icon(icon, color: _lightBlue, size: 25),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: _lightBlue,
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFFAFCFF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 21,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFFD9E1EC), width: 1.3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFFD9E1EC), width: 1.3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: _primaryBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  // =========================================================
  // PIE DE PÁGINA
  // =========================================================

  Widget _buildFooter() {
    return Column(
      children: [
        Divider(color: Colors.blueGrey.shade100, thickness: 1),
        const SizedBox(height: 12),
        Text(
          'Desoft  •  Directorio Telefónico Corporativo',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
        ),
      ],
    );
  }
}
