import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final Function() onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Slider data
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: '¡Bienvenido al Directorio Telefónico Desoft!',
      description:
          'Accede rápidamente a la información de contacto '
          'de todos los trabajadores de Desoft.',
      image: Icons.contacts,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Consulta sin límites',
      description:
          'Puedes buscar trabajadores, departamentos y locales '
          'sin necesidad de iniciar sesión.',
      image: Icons.search,
      color: Colors.green,
    ),
    OnboardingPage(
      title: 'Modo Administrador',
      description:
          'Inicia sesión con credenciales de administrador '
          'para agregar, editar o eliminar información.',
      image: Icons.admin_panel_settings,
      color: Colors.red,
    ),
    OnboardingPage(
      title: 'Configuración de Red Corporativa',
      description:
          'Importante: Para el correcto funcionamiento, '
          'primero debe poseer una linea coorporativa '
          'y ademas configura el APN "desoft" en tu dispositivo.',
      image: Icons.settings_cell,
      color: Colors.purple,
    ),
    OnboardingPage(
      title: 'Funcionalidades Especiales',
      description:
          '• Calendario de cumpleaños y efemérides\n'
          '• Llamadas directas desde la app\n'
          '• Copiar números de contacto\n'
          '• Acceso rápido a información',
      image: Icons.star,
      color: Colors.orange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (solo mostrar si no es la última página)
            if (_currentPage < _pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text(
                      'Saltar',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ),
              ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Indicator y botones
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildIndicator(index),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Next/Get Started button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 32,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1
                            ? 'Siguiente'
                            : '¡Comenzar!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Back button (solo mostrar si no es la primera página)
                  if (_currentPage > 0) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text(
                        'Atrás',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono
                    Container(
                      width: constraints.maxWidth * 0.3,
                      height: constraints.maxWidth * 0.3,
                      decoration: BoxDecoration(
                        color: page.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        page.image,
                        size: constraints.maxWidth * 0.15,
                        color: page.color,
                      ),
                    ),

                    SizedBox(height: constraints.maxHeight * 0.05),

                    // Título
                    Text(
                      page.title,
                      style: TextStyle(
                        fontSize: constraints.maxWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: page.color,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),

                    SizedBox(height: constraints.maxHeight * 0.03),

                    // Descripción
                    Text(
                      page.description,
                      style: TextStyle(
                        fontSize: constraints.maxWidth * 0.04,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Configuración APN (solo si es necesario)
                    if (page.image == Icons.settings_cell) ...[
                      SizedBox(height: constraints.maxHeight * 0.03),
                      _buildResponsiveAPNConfig(constraints),
                    ],

                    // Espacio flexible
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveAPNConfig(BoxConstraints constraints) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(constraints.maxWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuración APN:',
            style: TextStyle(
              fontSize: constraints.maxWidth * 0.045,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          SizedBox(height: constraints.maxHeight * 0.02),

          // Usar column o grid según el tamaño
          if (constraints.maxWidth < 400)
            _buildVerticalConfig()
          else
            _buildGridConfig(),
        ],
      ),
    );
  }

  Widget _buildVerticalConfig() {
    return Column(
      children: [
        _buildConfigRow('Nombre:', 'Desoft'),
        _buildConfigRow('APN:', 'desoft'),
        _buildConfigRow('Usuario:', 'desoft'),
        _buildConfigRow('Contraseña:', 'desoft'),
      ],
    );
  }

  Widget _buildGridConfig() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _buildConfigBox('Nombre', 'Desoft'),
        _buildConfigBox('APN', 'desoft'),
        _buildConfigBox('Usuario', 'desoft'),
        _buildConfigBox('Contraseña', 'desoft'),
      ],
    );
  }

  Widget _buildConfigBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.purple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.purple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    return Container(
      width: _currentPage == index ? 30 : 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _currentPage == index ? _pages[index].color : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    // Guardar en SharedPreferences que ya vio el onboarding
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    // Llamar al callback para continuar
    widget.onComplete();
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData image;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });
}
