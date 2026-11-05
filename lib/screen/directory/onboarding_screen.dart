import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final Function() onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  static const Color _primary = Color(0xFF1769AA);
  static const Color _primaryDark = Color(0xFF104C80);
  static const Color _background = Color(0xFFF4F7FB);
  static const Color _textDark = Color(0xFF243447);
  static const Color _textMuted = Color(0xFF718096);
  static const Color _border = Color(0xFFE4EAF2);

  final PageController _pageController = PageController();

  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: '¡Bienvenido al Directorio Telefónico Desoft!',
      description:
          'Accede rápidamente a la información de contacto '
          'de todos los trabajadores de Desoft.',
      image: Icons.contacts_rounded,
      color: _primary,
    ),
    OnboardingPage(
      title: 'Consulta sin límites',
      description:
          'Puedes buscar trabajadores, departamentos y locales '
          'sin necesidad de iniciar sesión.',
      image: Icons.search_rounded,
      color: _primary,
    ),
    OnboardingPage(
      title: 'Modo Administrador',
      description:
          'Inicia sesión con credenciales de administrador '
          'para agregar, editar o eliminar información.',
      image: Icons.admin_panel_settings_rounded,
      color: _primary,
    ),
    OnboardingPage(
      title: 'Configuración de Red Corporativa',
      description:
          'Importante: Para el correcto funcionamiento, '
          'debes disponer de una línea corporativa y configurar '
          'el APN "desoft" en tu dispositivo.',
      image: Icons.settings_cell_rounded,
      color: _primary,
    ),
    OnboardingPage(
      title: 'Funcionalidades Especiales',
      description:
          '• Calendario de cumpleaños y efemérides\n'
          '• Llamadas directas desde la app\n'
          '• Copiar números de contacto\n'
          '• Acceso rápido a información',
      image: Icons.stars_rounded,
      color: _primary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            // BARRA SUPERIOR
            SizedBox(
              height: 58,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primary, _primaryDark],
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.near_me_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Text(
                          'DESOFT',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!isLastPage)
                      TextButton(
                        onPressed: _completeOnboarding,
                        style: TextButton.styleFrom(
                          foregroundColor: _textMuted,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'Saltar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // CONTENIDO DE LAS PÁGINAS
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

            // INDICADORES Y BOTONES
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 15, 24, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: _border)),
                boxShadow: [
                  BoxShadow(
                    color: _textDark.withValues(alpha: 0.035),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // PROGRESO
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${_currentPage + 1}',
                            style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                          const Text(
                            ' / ',
                            style: TextStyle(color: _textMuted, fontSize: 12),
                          ),
                          Text(
                            '${_pages.length}',
                            style: const TextStyle(
                              color: _textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // INDICADORES
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => _buildIndicator(index),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // BOTÓN PRINCIPAL
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            if (!isLastPage) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOutCubic,
                              );
                            } else {
                              _completeOnboarding();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLastPage ? '¡Comenzar!' : 'Siguiente',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Icon(
                                isLastPage
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // BOTÓN ATRÁS
                      if (_currentPage > 0) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOutCubic,
                            );
                          },
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: const Text('Atrás'),
                          style: TextButton.styleFrom(
                            foregroundColor: _textMuted,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CONTENIDO DE CADA DIAPOSITIVA
  Widget _buildPage(OnboardingPage page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        final iconSize = (constraints.maxWidth * 0.23).clamp(85.0, 155.0);

        final titleSize = (constraints.maxWidth * 0.055).clamp(21.0, 32.0);

        final descriptionSize = (constraints.maxWidth * 0.034).clamp(
          14.0,
          18.0,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ICONO PRINCIPAL
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _primary.withValues(alpha: 0.12),
                            _primary.withValues(alpha: 0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _primary.withValues(alpha: 0.12),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          page.image,
                          size: iconSize * 0.48,
                          color: _primary,
                        ),
                      ),
                    ),

                    SizedBox(height: isWide ? 35 : 28),

                    // ETIQUETA
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'DIRECTORIO TELEFÓNICO DESOFT',
                        style: TextStyle(
                          color: _primary,
                          fontSize: isWide ? 11 : 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 17),

                    // TÍTULO
                    Text(
                      page.title,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        color: _textDark,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // DESCRIPCIÓN
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        page.description,
                        style: TextStyle(
                          fontSize: descriptionSize,
                          color: _textMuted,
                          height: 1.65,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // CONFIGURACIÓN APN
                    if (page.image == Icons.settings_cell_rounded) ...[
                      const SizedBox(height: 26),
                      _buildResponsiveAPNConfig(constraints),
                    ],

                    if (page.image == Icons.stars_rounded) ...[
                      const SizedBox(height: 24),
                      _buildFeaturesPreview(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // CONFIGURACIÓN APN
  Widget _buildResponsiveAPNConfig(BoxConstraints constraints) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _textDark.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings_ethernet_rounded, color: _primary, size: 21),
              SizedBox(width: 9),
              Text(
                'Configuración APN',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, boxConstraints) {
              final columns = boxConstraints.maxWidth >= 400 ? 2 : 1;
              final itemWidth = columns == 2
                  ? (boxConstraints.maxWidth - 10) / 2
                  : boxConstraints.maxWidth;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _buildConfigBox('Nombre', 'Desoft'),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildConfigBox('APN', 'desoft'),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildConfigBox('Usuario', 'desoft'),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildConfigBox('Contraseña', 'desoft'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfigBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: _primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // FUNCIONALIDADES ESPECIALES
  Widget _buildFeaturesPreview() {
    final features = [
      (Icons.cake_outlined, 'Cumpleaños y efemérides'),
      (Icons.call_outlined, 'Llamadas directas'),
      (Icons.copy_rounded, 'Copiar contactos'),
      (Icons.flash_on_rounded, 'Acceso rápido'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: features.map((feature) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(feature.$1, color: _primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature.$2,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  color: _primary,
                  size: 18,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // INDICADORES
  Widget _buildIndicator(int index) {
    final isActive = _currentPage == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isActive ? 29 : 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? _primary : const Color(0xFFDCE3EC),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // FINALIZAR ONBOARDING
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;

    widget.onComplete();
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData image;
  final Color color;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });
}
