import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../utils/dialog_error_handler.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/validators.dart';
import '../../widgets/shared/responsive_button.dart';
import '../../widgets/shared/responsive_container.dart';
import '../../widgets/shared/responsive_text.dart';

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
  User? _cachedUser;

  @override
  void initState() {
    super.initState();
    _checkCachedSession();
  }

  // Verificar si hay sesión cacheada
  Future<void> _checkCachedSession() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Verificar sesión cacheada usando el método getCachedUser
      final cachedUser = authProvider.getCachedUser();

      setState(() {
        _checkingCachedSession = false;
        _cachedUser = cachedUser;
      });

      // Si hay usuario cacheado, verificar token
      if (cachedUser != null) {
        final isTokenValid = authProvider.isTokenValidLocally(
          authProvider.token ?? '',
        );
        if (isTokenValid) {
          // Auto-redirigir después de un breve delay
          await Future.delayed(Duration(milliseconds: 500));
          if (mounted) {
            // En lugar de llamar directamente, hacer login con usuario cacheado
            _loginWithCachedUser();
          }
        }
      }
    } catch (e) {
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
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final usernameOrEmail = _usernameOrEmailController.text.trim();
      final password = _passwordController.text;

      // Usar el método login con parámetro forceRefresh
      final success = await authProvider.login(
        usernameOrEmail,
        password,
        forceRefresh: false,
      );

      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
          DialogErrorHandler.showSuccessSnackbar(
            context: context,
            message: '✅ Sesión iniciada exitosamente',
          );
        }
      } else {
        final error = authProvider.error ?? 'Error desconocido';
        final isNetworkError =
            error.contains('conexión') ||
            error.contains('internet') ||
            error.contains('red') ||
            error.contains('Conexión');

        if (mounted) {
          DialogErrorHandler.showErrorDialog(
            context: context,
            title: 'Error de autenticación',
            technicalError: error,
            showRetryButton: isNetworkError,
            onRetry: isNetworkError ? _performLogin : null,
          );
        }
      }
    }
  }

  // Iniciar sesión con usuario cacheado (modo offline)
  // En _loginWithCachedUser:
  Future<void> _loginWithCachedUser() async {
    if (_cachedUser == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Restaurando sesión...'),
          ],
        ),
        content: Text('Usando sesión guardada de ${_cachedUser!.username}'),
      ),
    );

    final success = await authProvider.restoreCachedSession();
    if (mounted) {
      Navigator.of(context).pop(); // Cerrar loading
    }

    if (success) {
      if (mounted) {
        Navigator.of(context).pop();
        DialogErrorHandler.showSuccessSnackbar(
          context: context,
          message: '✅ Sesión restaurada (Modo lectura)',
        );
      }
    } else {
      // No se pudo restaurar
      setState(() {
        _cachedUser = null;
      });

      if (mounted) {
        DialogErrorHandler.showErrorDialog(
          context: context,
          title: 'Sesión expirada',
          technicalError:
              'La sesión guardada ha expirado. Se requiere conexión para iniciar sesión nuevamente.',
        );
      }
    }
  }

  // En el texto del modo offline, cambia a:

  // Mostrar opción de sesión cacheada
  Widget _buildCachedSessionOption() {
    if (_checkingCachedSession) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Buscando sesión guardada...',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_cachedUser != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: Colors.blue[700], size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Sesión guardada encontrada',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.person, color: Colors.blue[700]),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _cachedUser!.username,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _cachedUser!.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 12,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Solo lectura disponible',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.login, size: 16),
                      label: Text('Continuar offline'),
                      onPressed: _loginWithCachedUser,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        side: BorderSide(color: Colors.blue[700]!),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextButton.icon(
                      icon: Icon(Icons.cancel, size: 16),
                      label: Text('Usar otra cuenta'),
                      onPressed: () => setState(() {
                        _cachedUser = null;
                      }),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: ResponsiveContainer(
        child: Column(
          children: [
            // Logo/Header responsive
            SizedBox(
              height: ResponsiveUtils.getResponsiveValue(
                context: context,
                mobile: 40,
                tablet: 60,
                desktop: 80,
              ),
            ),

            Icon(
              Icons.contacts,
              size: ResponsiveUtils.getResponsiveValue(
                context: context,
                mobile: 80,
                tablet: 100,
                desktop: 120,
              ),
              color: Colors.blue[700],
            ),

            const SizedBox(height: 16),

            ResponsiveText(
              text: 'Directorio Telefónico',
              size: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
            ResponsiveText(
              text: 'Desoft',
              size: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),

            const SizedBox(height: 8),

            ResponsiveText(
              text: 'Ingrese sus Credenciales',
              size: 16,
              color: Colors.grey[600],
            ),

            SizedBox(
              height: ResponsiveUtils.getResponsiveValue(
                context: context,
                mobile: 20,
                tablet: 30,
                desktop: 40,
              ),
            ),

            // Opción de sesión cacheada
            _buildCachedSessionOption(),

            SizedBox(height: 16),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _usernameOrEmailController,
                    decoration: InputDecoration(
                      labelText: 'Usuario o Correo electrónico',
                      prefixIcon: Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      hintText: 'admin o admin@empresa.com',
                    ),
                    validator: _validateUsernameOrEmail,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      hintText: 'Ingresa tu contraseña',
                    ),
                    validator: _validatePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _performLogin(),
                  ),

                  const SizedBox(height: 40),

                  // Loading y botón
                  if (authProvider.loading || authProvider.isLoading)
                    Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Verificando credenciales...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    )
                  else
                    ResponsiveButton(
                      text: 'Iniciar Sesión',
                      onPressed: _performLogin,
                      backgroundColor: Colors.blue[700]!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
