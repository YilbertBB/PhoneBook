import 'package:flutter/material.dart';

class NetworkConfigScreen extends StatelessWidget {
  const NetworkConfigScreen({super.key});

  static const Color _primary = Color(0xFF1769AA);
  static const Color _primaryDark = Color(0xFF104C80);
  static const Color _background = Color(0xFFF4F7FB);
  static const Color _textDark = Color(0xFF243447);
  static const Color _textMuted = Color(0xFF718096);
  static const Color _warning = Color(0xFFE49A27);
  static const Color _danger = Color(0xFFD94B4B);
  static const Color _success = Color(0xFF159B72);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración de Red',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Conexión corporativa',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
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
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 24),

                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildCorporateLineSection()),
                          const SizedBox(width: 18),
                          Expanded(child: _buildAPNConfigSection()),
                        ],
                      )
                    else ...[
                      _buildCorporateLineSection(),
                      const SizedBox(height: 22),
                      _buildAPNConfigSection(),
                    ],

                    const SizedBox(height: 22),
                    _buildImportantNotesSection(),
                    const SizedBox(height: 24),
                    _buildActionButtons(context),
                    const SizedBox(height: 30),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // CABECERA
  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: const Icon(
              Icons.settings_ethernet_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Red corporativa Desoft',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Consulta las instrucciones necesarias para configurar '
                  'la conexión corporativa en tu dispositivo.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TÍTULO DE SECCIÓN
  Widget _buildSectionTitle(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 3),
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

  // TARJETA BASE
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8EDF4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF243447).withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  // LÍNEA CORPORATIVA
  Widget _buildCorporateLineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Línea corporativa',
          'Información sobre el acceso a la red',
          Icons.business_rounded,
        ),
        _buildCard(
          child: Column(
            children: [
              _buildInfoItem(
                'Propósito',
                'Conexión dedicada para el uso del Directorio Telefónico.',
                Icons.info_outline_rounded,
              ),
              _buildInfoItem(
                'Requisito',
                'Dispositivo corporativo o autorizado.',
                Icons.verified_user_outlined,
              ),
              _buildInfoItem(
                'Alcance',
                'Acceso a datos internos de la empresa.',
                Icons.language_rounded,
                showDivider: false,
              ),
              const SizedBox(height: 15),
              _buildWarningBox(
                icon: Icons.warning_amber_rounded,
                color: _warning,
                text: 'Esta configuración es exclusiva para uso corporativo.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon, {
    bool showDivider = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primary, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showDivider) ...[
            const SizedBox(height: 13),
            const Divider(height: 1, color: Color(0xFFEDF1F6)),
          ],
        ],
      ),
    );
  }

  // CONFIGURACIÓN APN
  Widget _buildAPNConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Configuración APN',
          'Pasos y parámetros de conexión',
          Icons.sim_card_rounded,
        ),
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepItem(
                1,
                'Abrir Ajustes > Conexiones > Redes móviles',
                Icons.settings_rounded,
              ),
              _buildStepItem(
                2,
                'Entrar en Nombres de punto de acceso (APN)',
                Icons.list_alt_rounded,
              ),
              _buildStepItem(
                3,
                'Agregar un nuevo APN o editar el existente',
                Icons.edit_rounded,
                showDivider: false,
              ),
              const SizedBox(height: 22),
              const Divider(color: Color(0xFFEDF1F6)),
              const SizedBox(height: 16),
              const Text(
                'Parámetros de configuración',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Introduce los siguientes valores en los campos correspondientes.',
                style: TextStyle(fontSize: 12, color: _textMuted, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FC),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFE3EBF4)),
                ),
                child: Column(
                  children: [
                    _buildConfigItem('Nombre', 'Desoft'),
                    _buildConfigItem('APN', 'desoft'),
                    _buildConfigItem('Nombre de usuario', 'desoft'),
                    _buildConfigItem('Contraseña', 'desoft'),
                    _buildConfigItem('Autenticación', 'PAP o CHAP'),
                    _buildConfigItem('Tipo de APN', 'default,supl'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: Color(0xFFDCE5EF)),
                    ),
                    _buildConfigItem('Proxy', 'No configurar'),
                    _buildConfigItem('Puerto', 'No configurar'),
                    _buildConfigItem('MMSC', 'No configurar'),
                    _buildConfigItem('MCC', 'Según país'),
                    _buildConfigItem(
                      'MNC',
                      'Según operador',
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(
    int step,
    String instruction,
    IconData icon, {
    bool showDivider = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    '$step',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, size: 20, color: _primary),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    instruction,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: _textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showDivider) ...[
            const SizedBox(height: 13),
            const Divider(height: 1, color: Color(0xFFEDF1F6)),
          ],
        ],
      ),
    );
  }

  Widget _buildConfigItem(
    String label,
    String value, {
    bool showDivider = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: value == 'No configurar' ? _textMuted : _primaryDark,
                  ),
                ),
              ),
            ],
          ),
          if (showDivider) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFE5ECF3)),
          ],
        ],
      ),
    );
  }

  // CONSIDERACIONES IMPORTANTES
  Widget _buildImportantNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Consideraciones importantes',
          'Recomendaciones para mantener una conexión segura',
          Icons.shield_outlined,
        ),
        _buildCard(
          child: Column(
            children: [
              _buildNoteItem(
                Icons.lock_outline_rounded,
                'Seguridad',
                'Esta configuración es para uso interno exclusivo de Desoft.',
              ),
              _buildNoteItem(
                Icons.wifi_rounded,
                'Conexión',
                'Verificar que el dispositivo tenga cobertura de red corporativa.',
              ),
              _buildNoteItem(
                Icons.devices_rounded,
                'Compatibilidad',
                'Configuración válida para Android e iOS, con posibles variaciones.',
              ),
              _buildNoteItem(
                Icons.sync_rounded,
                'Actualización',
                'Los parámetros pueden cambiar según las actualizaciones de infraestructura.',
              ),
              _buildNoteItem(
                Icons.support_agent_rounded,
                'Soporte',
                'Contactar al departamento de TI para problemas de conexión.',
                showDivider: false,
              ),
              const SizedBox(height: 12),
              _buildWarningBox(
                icon: Icons.error_outline_rounded,
                color: _danger,
                text:
                    'No compartir estas credenciales fuera de la organización.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteItem(
    IconData icon,
    String title,
    String text, {
    bool showDivider = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primary, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showDivider) ...[
            const SizedBox(height: 13),
            const Divider(height: 1, color: Color(0xFFEDF1F6)),
          ],
        ],
      ),
    );
  }

  Widget _buildWarningBox({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SOPORTE TÉCNICO
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.headset_mic_rounded,
              color: _primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '¿Necesitas ayuda?',
            style: TextStyle(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Nuestro equipo de soporte puede ayudarte con la configuración.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textMuted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => _showSupportInfo(context),
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text('CONTACTAR SOPORTE TÉCNICO'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_primary, _primaryDark]),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.near_me_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Directorio Telefónico',
            style: TextStyle(
              fontSize: 13,
              color: _textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Desoft Cuba · © 2025',
            style: TextStyle(fontSize: 11, color: _textMuted),
          ),
        ],
      ),
    );
  }

  // DIÁLOGO DE SOPORTE
  void _showSupportInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.support_agent_rounded, color: _primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Soporte Técnico',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Departamento de Tecnologías de la Información',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('📞 Teléfono: 123-456-7890'),
              SizedBox(height: 5),
              Text('📧 Email: soporte.ti@desoft.cu'),
              SizedBox(height: 5),
              Text('🏢 Oficina: Edificio Central, Piso 3'),
              SizedBox(height: 16),
              Text(
                'Horario de atención:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text('Lunes a Viernes: 8:00 AM - 5:00 PM'),
              Text('Sábados: 8:00 AM - 12:00 PM'),
              SizedBox(height: 16),
              Text(
                'Problemas comunes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text('• No se conecta a la red corporativa'),
              Text('• Error de autenticación'),
              Text('• Datos móviles no funcionan'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: _primary)),
          ),
        ],
      ),
    );
  }
}
