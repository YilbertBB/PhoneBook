import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../providers/user_provider.dart';
import './create_user_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  // PALETA CORPORATIVA
  static const Color _primary = Color(0xFF1769AA);
  static const Color _primaryDark = Color(0xFF104C80);
  static const Color _background = Color(0xFFF4F7FB);
  static const Color _surface = Colors.white;
  static const Color _textDark = Color(0xFF243447);
  static const Color _textMuted = Color(0xFF718096);
  static const Color _border = Color(0xFFE4EAF2);
  static const Color _success = Color(0xFF159B72);
  static const Color _danger = Color(0xFFD94B4B);

  final UserProvider _userProvider = UserProvider();

  String _filterRole = 'todos';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // CARGAR USUARIOS
  Future<void> _loadUsers() async {
    await _userProvider.loadUsers();

    if (mounted) {
      setState(() {});
    }
  }

  // ACTUALIZAR USUARIOS
  Future<void> _refreshUsers() async {
    await _userProvider.refreshUsers();

    if (mounted) {
      setState(() {});
    }
  }

  // NAVEGAR A CREAR USUARIO
  Future<void> _navigateToCreateUser() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateUserScreen()),
    );

    if (mounted) {
      await _refreshUsers();
    }
  }

  // FILTRAR USUARIOS
  List<User> get _filteredUsers {
    if (_filterRole == 'todos') {
      return _userProvider.users;
    }

    return _userProvider.users.where((user) {
      return user.roles.any((role) => role.nombre == _filterRole);
    }).toList();
  }

  // ESTADÍSTICAS
  Map<String, dynamic> get _roleStats {
    return _userProvider.getRoleStats();
  }

  int get _adminCount {
    return _roleStats['admin'] ?? 0;
  }

  int get _consultCount {
    return _roleStats['user'] ?? _roleStats['consult'] ?? 0;
  }

  // PANTALLA PRINCIPAL
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usuarios',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(
              'Administración de cuentas',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar usuarios',
            onPressed: _userProvider.loading ? null : _refreshUsers,
            icon: const Icon(Icons.refresh_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Crear usuario',
              onPressed: _navigateToCreateUser,
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    // ENCABEZADO
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isWide ? 28 : 16,
                        22,
                        isWide ? 28 : 16,
                        14,
                      ),
                      child: _buildHeader(),
                    ),

                    // ESTADÍSTICAS
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 28 : 16,
                      ),
                      child: _buildStatistics(isWide),
                    ),

                    const SizedBox(height: 20),

                    // FILTRO
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 28 : 16,
                      ),
                      child: _buildFilter(),
                    ),

                    const SizedBox(height: 12),

                    // CONTADOR
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 28 : 16,
                      ),
                      child: _buildResultsHeader(),
                    ),

                    const SizedBox(height: 8),

                    // LISTA DE USUARIOS
                    Expanded(
                      child: _userProvider.loading
                          ? const Center(
                              child: CircularProgressIndicator(color: _primary),
                            )
                          : RefreshIndicator(
                              color: _primary,
                              onRefresh: _refreshUsers,
                              child: _filteredUsers.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: EdgeInsets.fromLTRB(
                                        isWide ? 28 : 16,
                                        6,
                                        isWide ? 28 : 16,
                                        30,
                                      ),
                                      itemCount: _filteredUsers.length,
                                      itemBuilder: (context, index) {
                                        return _buildUserCard(
                                          _filteredUsers[index],
                                        );
                                      },
                                    ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateUser,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Nuevo usuario',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ENCABEZADO
  Widget _buildHeader() {
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
            color: _primary.withValues(alpha: 0.17),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.manage_accounts_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de usuarios',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Consulta y administra las cuentas del directorio.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ESTADÍSTICAS
  Widget _buildStatistics(bool isWide) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Mostrados',
            value: '${_filteredUsers.length}',
            icon: Icons.groups_rounded,
            color: _primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: 'Administradores',
            value: '$_adminCount',
            icon: Icons.admin_panel_settings_rounded,
            color: _danger,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: 'Consultores',
            value: '$_consultCount',
            icon: Icons.search_rounded,
            color: _success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 9),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // FILTRO POR ROL
  Widget _buildFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _filterRole,
        isExpanded: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          labelText: 'Filtrar por rol',
          prefixIcon: Icon(Icons.filter_list_rounded, color: _primary),
          labelStyle: TextStyle(color: _textMuted, fontSize: 13),
        ),
        items: const [
          DropdownMenuItem(
            value: 'todos',
            child: Row(
              children: [
                Icon(Icons.groups_rounded, color: _primary, size: 19),
                SizedBox(width: 10),
                Text('Todos los roles'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'admin',
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_rounded,
                  color: _danger,
                  size: 19,
                ),
                SizedBox(width: 10),
                Text('Administradores'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'consult',
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: _success, size: 19),
                SizedBox(width: 10),
                Text('Consultores'),
              ],
            ),
          ),
        ],
        onChanged: (value) {
          if (value == null) return;

          setState(() {
            _filterRole = value;
          });
        },
      ),
    );
  }

  // ENCABEZADO DE RESULTADOS
  Widget _buildResultsHeader() {
    return Row(
      children: [
        const Icon(Icons.people_alt_outlined, color: _primary, size: 19),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Listado de cuentas',
            style: TextStyle(
              color: _textDark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_filteredUsers.length} registros',
            style: const TextStyle(
              color: _primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // TARJETA DE USUARIO
  Widget _buildUserCard(User user) {
    final isAdmin = user.isAdmin;
    final isConsult = user.isConsult;

    final Color roleColor = isAdmin
        ? _danger
        : isConsult
        ? _success
        : _primary;

    final IconData roleIcon = isAdmin
        ? Icons.admin_panel_settings_rounded
        : isConsult
        ? Icons.search_rounded
        : Icons.person_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _textDark.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AVATAR
            Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(roleIcon, color: roleColor, size: 25),
            ),

            const SizedBox(width: 13),

            // INFORMACIÓN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        color: _textMuted,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          user.email,
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (user.roles.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: user.roles.map((role) {
                        final isAdminRole = role.nombre == 'admin';
                        final isConsultRole = role.nombre == 'consult';

                        final color = isAdminRole
                            ? _danger
                            : isConsultRole
                            ? _success
                            : _primary;

                        final label = isAdminRole
                            ? 'ADMIN'
                            : isConsultRole
                            ? 'CONSULTOR'
                            : role.nombre.toUpperCase();

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 5),

            // INDICADOR
            Icon(
              Icons.verified_user_outlined,
              size: 19,
              color: roleColor.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  // ESTADO VACÍO
  Widget _buildEmptyState() {
    final isFiltered = _filterRole != 'todos';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 25),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.09),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.07),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.group_off_rounded, color: _primary, size: 43),
        ),
        const SizedBox(height: 20),
        Text(
          isFiltered
              ? 'No hay usuarios con este rol'
              : 'No hay usuarios registrados',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _textDark,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          isFiltered
              ? 'Prueba seleccionando otro filtro para consultar las cuentas disponibles.'
              : 'Todavía no existen cuentas registradas en el directorio.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _textMuted, fontSize: 13, height: 1.5),
        ),
        if (!isFiltered) ...[
          const SizedBox(height: 22),
          Center(
            child: ElevatedButton.icon(
              onPressed: _navigateToCreateUser,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Crear primer usuario'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
