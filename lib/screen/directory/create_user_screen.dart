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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seleccionar Rol *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),

        // Mostrar los roles disponibles
        Row(
          children: [
            // Botón para CONSULT
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _userProvider.setSelectedRol(Rol.consult);
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _userProvider.selectedRol.nombre == 'consult'
                        ? Colors.green[50]
                        : Colors.white,
                    border: Border.all(
                      color: _userProvider.selectedRol.nombre == 'consult'
                          ? Colors.green
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search, // Icono para consultor
                        color: _userProvider.selectedRol.nombre == 'consult'
                            ? Colors.green
                            : Colors.grey,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CONSULTOR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _userProvider.selectedRol.nombre == 'consult'
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Solo consultas',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Botón para ADMIN
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _userProvider.setSelectedRol(Rol.admin);
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _userProvider.selectedRol.nombre == 'admin'
                        ? Colors.red[50]
                        : Colors.white,
                    border: Border.all(
                      color: _userProvider.selectedRol.nombre == 'admin'
                          ? Colors.red
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: _userProvider.selectedRol.nombre == 'admin'
                            ? Colors.red
                            : Colors.grey,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ADMINISTRADOR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _userProvider.selectedRol.nombre == 'admin'
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Acceso completo',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Información según el rol seleccionado
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _userProvider.selectedRol.nombre == 'admin'
              ? Container(
                  key: const ValueKey('admin-info'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Acceso completo: Puede gestionar usuarios, trabajadores y toda la información del sistema',
                          style: TextStyle(
                            color: Colors.red[800],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  key: const ValueKey('consult-info'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Solo consultas: Puede ver información pero no modificarla',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 13,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crear Usuario',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_outlined, color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Información'),
                  content: const Text(
                    'Complete todos los campos para crear un nuevo usuario.\n\n'
                    '• El nombre de usuario debe ser único\n'
                    '• El email debe ser único\n'
                    '• Seleccione el rol según los permisos necesarios',
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Título
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.blue[700], size: 32),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nuevo Usuario',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Registre un nuevo usuario en el sistema',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Usuario
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de Usuario *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: _validateUsername,
              ),

              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico *',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              // Contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: _validatePassword,
              ),

              const SizedBox(height: 16),

              // Confirmar Contraseña
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña *',
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: _validateConfirmPassword,
              ),

              const SizedBox(height: 24),

              // Selector de Rol
              _buildRoleSelector(),

              const SizedBox(height: 32),

              // Botones
              if (_isLoading)
                Column(
                  children: [
                    CircularProgressIndicator(color: Colors.blue[700]),
                    const SizedBox(height: 16),
                    const Text('Creando usuario...'),
                  ],
                )
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _createUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'CREAR USUARIO',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'CANCELAR',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
