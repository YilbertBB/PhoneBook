import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'generated/l10n.dart';
import 'navigation/app_navigator.dart';
import 'providers/update_provider.dart';
import 'screen/directory/home_screen.dart';
import 'screen/directory/onboarding_screen.dart';
import 'services/notification_handler.dart';
import 'services/service_locator.dart';
import 'providers/auth_provider.dart';
import 'providers/worker_provider.dart';
import 'providers/department_provider.dart';
import 'providers/local_provider.dart';
import 'providers/efemeride_provider.dart';
import 'utils/notification_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationUtils.initialize();

  // Inicializar servicios
  await ServiceLocator().initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WorkerProvider()),
        ChangeNotifierProvider(create: (_) => DepartmentProvider()),
        ChangeNotifierProvider(create: (_) => LocalProvider()),
        ChangeNotifierProvider(create: (_) => EfemerideProvider()),
        ChangeNotifierProvider(create: (_) => UpdateProvider()),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        title: 'Directorio Telefónico',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: FutureBuilder<bool>(
          future: _checkOnboardingStatus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen();
            }

            if (snapshot.hasData && snapshot.data == false) {
              // Mostrar onboarding si no lo ha visto
              return OnboardingScreen(
                onComplete: () {
                  // Después del onboarding, mostrar el flujo normal
                  _showMainApp(context);
                },
              );
            }

            // Si ya vio el onboarding, mostrar app normal
            return _buildMainApp();
          },
        ),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
              ),
            ),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final widget = child ?? Container();

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (authProvider.isAuthenticated) {
                    ServiceLocator().tokenExpiryManager.startMonitoring(
                      context,
                    );

                    // ========== AGREGAR VERIFICACIÓN DE ACTUALIZACIONES ==========
                    // Esperar un poco para que la app termine de cargar
                    Future.delayed(const Duration(seconds: 3), () {
                      if (context.mounted) {
                        final updateService = ServiceLocator().updateService;
                        // Solo verificar una vez por día
                        updateService.checkAndNotifyIfNeeded(context);
                      }
                    });
                  }
                });

                return widget;
              },
              child: child,
            ),
          );
        },
      ),
    );
  }

  // Método para verificar si ya vio el onboarding
  static Future<bool> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('has_seen_onboarding') ?? false;
    } catch (e) {
      // En caso de error, asumir que no ha visto el onboarding
      return false;
    }
  }

  // Pantalla de loading mientras verifica
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        color: Colors.blue[700],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                'Directorio Telefónico',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Desoft',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withAlpha(128),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget principal de la app
  Widget _buildMainApp() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Verificar estado de autenticación al iniciar
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!authProvider.isLoading) {
            authProvider.checkAuthStatus();

            // ✅ VERIFICAR NOTIFICACIONES PENDIENTES
            final pendingNotification =
                await NotificationHandler.getPendingNotification();
            if (pendingNotification != null) {
              await NotificationHandler.clearPendingNotification();

              // Esperar y procesar
              Future.delayed(Duration(seconds: 2), () async {
                if (context.mounted) {
                  final updateService = ServiceLocator().updateService;

                  // Verificar actualización forzadamente
                  final updateInfo = await updateService.checkUpdates(
                    forceCheck: true,
                  );
                  if (updateInfo != null && context.mounted) {
                    updateService.showUpdateNotification(context, updateInfo);
                  }
                }
              });
            }

            // Verificación normal de actualizaciones (sin forzar)
            Future.delayed(Duration(seconds: 5), () {
              if (context.mounted) {
                final updateService = ServiceLocator().updateService;
                updateService.checkAndNotifyIfNeeded(context);
              }
            });
          }
        });

        // Mientras verifica, muestra loading
        if (authProvider.isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Verificando sesión...'),
                ],
              ),
            ),
          );
        }

        // ✅ SIEMPRE mostrar HomeScreen (sin forzar login)
        return HomeScreen();
      },
    );
  }

  // Método para navegar al main app después del onboarding
  void _showMainApp(BuildContext context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => _buildMainApp()));
  }
}
