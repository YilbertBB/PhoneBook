import 'package:flutter/material.dart';
import '../../providers/user_provider.dart';
import '../../utils/validators.dart';
import '../../models/rol.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  CreateUserScreenState createState() => CreateUserScreenState();
}

class CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late UserProvider _userProvider;
  bool _isLoading = false;

  static const Color _primary = Color(0xFF1769AA);
  static const Color _primaryDark = Color(0xFF104C80);
  static const Color _background = Color(0xFFF4F7FB);
  static const Color _surface = Colors.white;
  static const Color _textDark = Color(0xFF243447);
  static const Color _textMuted = Color(0xFF718096);
  static const Color _success = Color(0xFF159B72);
  static const Color _danger = Color(0xFFD94B4B);

  @override
  void initState() {
    super.initState();
    _userProvider = UserProvider();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final success = await _userProvider.createUser(
        nombreUsuario: _usernameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        rol: _userProvider.selectedRol,
      );

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(_userProvider.error);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Text('Éxito'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Usuario creado exitosamente:'),
            const SizedBox(height: 12),
            Text('👤 ${_usernameController.text}'),
            Text('📧 ${_emailController.text}'),
            Text('🎯 Rol: ${_userProvider.selectedRol.nombre.toUpperCase()}'),
            const SizedBox(height: 16),
            if (_userProvider.selectedRol.nombre == 'admin')
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '⚠️ Este usuario tendrá acceso de administrador',
                  style: TextStyle(color: Colors.amber[800], fontSize: 12),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Volver a la lista'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  // En la clase _CreateUserScreenState

  String? _validateUsername(String? value) {
    return Validators.validateUsername(value);
  }

  String? _validateEmail(String? value) {
    return Validators.validateEmail(value);
  }

  String? _validatePassword(String? value) {
    return Validators.validatePassword(value);
  }

  String? _validateConfirmPassword(String? value) {
    return Validators.validateConfirmPassword(value, _passwordController.text);
  }

  Widget _buildRoleSelector() {
    final isAdmin = _userProvider.selectedRol.nombre == 'admin';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Asignación de permisos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Selecciona el nivel de acceso del nuevo usuario.',
          style: TextStyle(fontSize: 13, color: _textMuted),
        ),
        const SizedBox(height: 16),

        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 430;

            final consultCard = _buildRoleCard(
              title: 'CONSULTOR',
              subtitle: 'Solo consultas',
              description: 'Puede consultar la información del sistema.',
              icon: Icons.visibility_outlined,
              color: _success,
              selected: !isAdmin,
              onTap: () {
                _userProvider.setSelectedRol(Rol.consult);
                setState(() {});
              },
            );

            final adminCard = _buildRoleCard(
              title: 'ADMINISTRADOR',
              subtitle: 'Acceso completo',
              description: 'Puede gestionar usuarios y registros.',
              icon: Icons.admin_panel_settings_outlined,
              color: _danger,
              selected: isAdmin,
              onTap: () {
                _userProvider.setSelectedRol(Rol.admin);
                setState(() {});
              },
            );

            if (compact) {
              return Column(
                children: [consultCard, const SizedBox(height: 12), adminCard],
              );
            }

            return Row(
              children: [
                Expanded(child: consultCard),
                const SizedBox(width: 14),
                Expanded(child: adminCard),
              ],
            );
          },
        ),

        const SizedBox(height: 14),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Container(
            key: ValueKey(isAdmin),
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isAdmin
                  ? _danger.withValues(alpha: 0.07)
                  : _success.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAdmin
                    ? _danger.withValues(alpha: 0.3)
                    : _success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isAdmin
                      ? Icons.warning_amber_rounded
                      : Icons.verified_user_outlined,
                  color: isAdmin ? _danger : _success,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isAdmin
                        ? 'Atención: este usuario tendrá permisos de administrador y podrá gestionar la información del sistema.'
                        : 'Acceso de consulta: este usuario podrá visualizar la información, pero no modificarla.',
                    style: TextStyle(
                      color: isAdmin
                          ? const Color(0xFFB83232)
                          : const Color(0xFF117653),
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.07) : _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : const Color(0xFFE2E8F0),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: color, size: 23),
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? color : Colors.transparent,
                      border: Border.all(
                        color: selected ? color : const Color(0xFFCBD5E0),
                        width: 1.5,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 15)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  color: selected ? color : _textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary, size: 21),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: const TextStyle(color: _textMuted, fontSize: 14),
      floatingLabelStyle: const TextStyle(
        color: _primary,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.7),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _danger, width: 1.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crear usuario',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Administración de usuarios',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Información',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.info_outline, color: _primary),
                      SizedBox(width: 10),
                      Text('Información'),
                    ],
                  ),
                  content: const Text(
                    'Complete todos los campos para crear un nuevo usuario.\n\n'
                    '• El nombre de usuario debe ser único.\n'
                    '• El correo electrónico debe ser único.\n'
                    '• Seleccione el rol según los permisos necesarios.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Entendido'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32 : 18,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Encabezado
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primary, _primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
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
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_add_alt_1_rounded,
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
                                      'Nuevo usuario',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Registra una nueva cuenta y asigna sus permisos de acceso.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Datos de acceso
                        _buildSectionTitle(
                          icon: Icons.account_circle_outlined,
                          title: 'Datos de la cuenta',
                          subtitle: 'Información de acceso del usuario',
                        ),

                        const SizedBox(height: 18),

                        TextFormField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          decoration: _buildInputDecoration(
                            label: 'Nombre de usuario *',
                            icon: Icons.person_outline,
                          ),
                          validator: _validateUsername,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: _buildInputDecoration(
                            label: 'Correo electrónico *',
                            icon: Icons.email_outlined,
                          ),
                          validator: _validateEmail,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: _buildInputDecoration(
                            label: 'Contraseña *',
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: _textMuted,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: _validatePassword,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          decoration: _buildInputDecoration(
                            label: 'Confirmar contraseña *',
                            icon: Icons.lock_reset_outlined,
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirmPassword
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: _textMuted,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: _validateConfirmPassword,
                        ),

                        const SizedBox(height: 30),

                        // Selección de permisos
                        _buildSectionTitle(
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'Permisos del usuario',
                          subtitle: 'Define qué acciones podrá realizar',
                        ),

                        const SizedBox(height: 18),

                        _buildRoleSelector(),

                        const SizedBox(height: 32),

                        // Botones de acción
                        if (_isLoading)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: const Column(
                              children: [
                                SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    color: _primary,
                                    strokeWidth: 3,
                                  ),
                                ),
                                SizedBox(height: 14),
                                Text(
                                  'Creando usuario...',
                                  style: TextStyle(
                                    color: _textDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Por favor, espera un momento',
                                  style: TextStyle(
                                    color: _textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          LayoutBuilder(
                            builder: (context, buttonConstraints) {
                              final stacked = buttonConstraints.maxWidth < 450;

                              final createButton = SizedBox(
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: _createUser,
                                  icon: const Icon(
                                    Icons.person_add_alt_1,
                                    size: 19,
                                  ),
                                  label: const Text(
                                    'CREAR USUARIO',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              );

                              final cancelButton = SizedBox(
                                height: 52,
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 19,
                                  ),
                                  label: const Text(
                                    'CANCELAR',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _primary,
                                    side: const BorderSide(
                                      color: _primary,
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              );

                              if (stacked) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    createButton,
                                    const SizedBox(height: 12),
                                    cancelButton,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: createButton),
                                  const SizedBox(width: 14),
                                  Expanded(child: cancelButton),
                                ],
                              );
                            },
                          ),

                        const SizedBox(height: 24),

                        const Center(
                          child: Text(
                            'Administración de usuarios',
                            style: TextStyle(color: _textMuted, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(11),
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
                  color: _textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: _textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
