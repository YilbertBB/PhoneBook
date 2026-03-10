import 'package:flutter/material.dart';

class NetworkConfigScreen extends StatelessWidget {
  const NetworkConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración de Red',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header informativo
            _buildHeaderSection(),

            const SizedBox(height: 24),

            // Línea corporativa
            _buildCorporateLineSection(),

            const SizedBox(height: 24),

            // Configuración APN
            _buildAPNConfigSection(),

            const SizedBox(height: 24),

            // Consideraciones importantes
            _buildImportantNotesSection(),

            const SizedBox(height: 32),

            // Botones de acción
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.settings_cell, size: 40, color: Colors.blue[700]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuración de Red Corporativa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sigue estos pasos para configurar correctamente '
                  'la conexión a la red de Desoft',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorporateLineSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Text(
                  'Línea Corporativa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              'Propósito:',
              'Conexión dedicada para el uso del Directorio Telefónico',
              Icons.info,
            ),
            _buildInfoItem(
              'Requisito:',
              'Dispositivo corporativo o autorizado',
              Icons.security,
            ),
            _buildInfoItem(
              'Alcance:',
              'Acceso a datos internos de la empresa',
              Icons.network_check,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta configuración es exclusiva para uso corporativo',
                      style: TextStyle(
                        color: Colors.amber[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAPNConfigSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sim_card, color: Colors.green[700]),
                const SizedBox(width: 12),
                Text(
                  'Configuración APN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Paso 1
            _buildStepItem(
              1,
              'Ajustes > Conexiones > Redes móviles',
              Icons.settings,
            ),

            // Paso 2
            _buildStepItem(2, 'Nombres de punto de acceso (APN)', Icons.add),

            // Paso 3
            _buildStepItem(
              3,
              'Agregar nuevo APN o editar existente',
              Icons.edit,
            ),

            const SizedBox(height: 16),

            // Configuración específica
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parámetros de configuración:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildConfigItem('Nombre:', 'Desoft'),
                  _buildConfigItem('APN:', 'desoft'),
                  _buildConfigItem('Nombre de usuario:', 'desoft'),
                  _buildConfigItem('Contraseña:', 'desoft'),
                  _buildConfigItem('Autenticación:', 'PAP o CHAP'),
                  _buildConfigItem('Tipo de APN:', 'default,supl'),

                  const SizedBox(height: 8),
                  Divider(color: Colors.green[200]),
                  const SizedBox(height: 8),

                  _buildConfigItem('Proxy:', 'No configurar'),
                  _buildConfigItem('Puerto:', 'No configurar'),
                  _buildConfigItem('MMSC:', 'No configurar'),
                  _buildConfigItem('MCC:', 'Según país'),
                  _buildConfigItem('MNC:', 'Según operador'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportantNotesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.important_devices, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Consideraciones importantes',
                    softWrap: true,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildNoteItem(
              '🔒 Seguridad',
              'Esta configuración es para uso interno exclusivo de Desoft.',
            ),

            _buildNoteItem(
              '📶 Conexión',
              'Verificar que el dispositivo tenga cobertura de red corporativa.',
            ),

            _buildNoteItem(
              '⚙️ Compatibilidad',
              'Configuración válida para Android e iOS (con variaciones menores).',
            ),

            _buildNoteItem(
              '🔄 Actualización',
              'Los parámetros pueden cambiar según actualizaciones de infraestructura.',
            ),

            _buildNoteItem(
              '📞 Soporte',
              'Contactar al departamento de TI para problemas de conexión.',
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No compartir estas credenciales fuera de la organización',
                      style: TextStyle(
                        color: Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () {
            _showSupportInfo(context);
          },
          child: const Text(
            '¿Necesitas ayuda? Contacta a Soporte Técnico',
            style: TextStyle(
              color: Colors.grey,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  // Widgets auxiliares
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String instruction, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(instruction, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.green[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String iconText, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(iconText, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  void _showSupportInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: Colors.blue),
            SizedBox(width: 8),
            Text('Soporte Técnico'),
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
              Text('📧 Email: soporte.ti@desoft.cu'),
              Text('🏢 Oficina: Edificio Central, Piso 3'),
              SizedBox(height: 12),
              Text(
                'Horario de atención:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Lunes a Viernes: 8:00 AM - 5:00 PM'),
              Text('Sábados: 8:00 AM - 12:00 PM'),
              SizedBox(height: 12),
              Text(
                'Problemas comunes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• No se conecta a la red corporativa'),
              Text('• Error de autenticación'),
              Text('• Datos móviles no funcionan'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
