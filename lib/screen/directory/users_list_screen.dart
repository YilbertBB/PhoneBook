// import 'package:flutter/material.dart';
// import '../../models/user.dart';
// import '../../providers/user_provider.dart';
// import './create_user_screen.dart';

// class UsersListScreen extends StatefulWidget {
//   const UsersListScreen({super.key});

//   @override
//   _UsersListScreenState createState() => _UsersListScreenState();
// }

// class _UsersListScreenState extends State<UsersListScreen> {
//   final UserProvider _userProvider = UserProvider();
//   String _filterRole = 'todos';

//   // List<String> get _filterOptions => ['todos', 'admin', 'consult'];

//   @override
//   void initState() {
//     super.initState();
//     _loadUsers();
//   }

//   Future<void> _loadUsers() async {
//     await _userProvider.loadUsers();
//   }

//   Future<void> _refreshUsers() async {
//     await _userProvider.refreshUsers();
//   }

//   void _navigateToCreateUser() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const CreateUserScreen()),
//     ).then((_) => _refreshUsers());
//   }

//   List<User> get _filteredUsers {
//     if (_filterRole == 'todos') return _userProvider.users;
//     return _userProvider.users.where((user) {
//       return user.roles.any((role) => role.nombre == _filterRole);
//     }).toList();
//   }

//   Widget _buildUserCard(User user) {
//     final isAdmin = user.isAdmin;
//     final isConsult = user.isConsult;

//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       elevation: 2,
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: isAdmin
//               ? Colors.red[100]
//               : isConsult
//               ? Colors.green[100]
//               : Colors.grey[100],
//           child: Icon(
//             isAdmin
//                 ? Icons.admin_panel_settings
//                 : isConsult
//                 ? Icons.search
//                 : Icons.person,
//             color: isAdmin
//                 ? Colors.red[700]
//                 : isConsult
//                 ? Colors.green[700]
//                 : Colors.grey[700],
//           ),
//         ),
//         title: Text(
//           user.username,
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(user.email),
//             const SizedBox(height: 4),
//             Wrap(
//               spacing: 4,
//               children: user.roles.map((role) {
//                 final isAdminRole = role.nombre == 'admin';
//                 final isConsultRole = role.nombre == 'consult';

//                 return Chip(
//                   label: Text(
//                     isAdminRole
//                         ? 'ADMIN'
//                         : isConsultRole
//                         ? 'CONSULTOR'
//                         : role.nombre.toUpperCase(),
//                     style: const TextStyle(fontSize: 10),
//                   ),
//                   backgroundColor: isAdminRole
//                       ? Colors.red[100]
//                       : isConsultRole
//                       ? Colors.green[100]
//                       : Colors.grey[100],
//                   labelStyle: TextStyle(
//                     color: isAdminRole
//                         ? Colors.red[800]
//                         : isConsultRole
//                         ? Colors.green[800]
//                         : Colors.grey[800],
//                   ),
//                 );
//               }).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final roleStats = _userProvider.getRoleStats();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Usuarios'),
//         backgroundColor: Colors.blue[700],
//         actions: [
//           IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshUsers),
//           IconButton(
//             icon: const Icon(Icons.person_add),
//             onPressed: _navigateToCreateUser,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Filtros
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: DropdownButtonFormField<String>(
//                     initialValue: _filterRole,
//                     decoration: const InputDecoration(
//                       labelText: 'Filtrar por rol',
//                       border: OutlineInputBorder(),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 12),
//                     ),
//                     items: [
//                       DropdownMenuItem(
//                         value: 'todos',
//                         child: Row(
//                           children: [
//                             Icon(Icons.all_inclusive, color: Colors.blue),
//                             const SizedBox(width: 8),
//                             const Text('Todos los roles'),
//                           ],
//                         ),
//                       ),
//                       DropdownMenuItem(
//                         value: 'admin',
//                         child: Row(
//                           children: [
//                             Icon(Icons.admin_panel_settings, color: Colors.red),
//                             const SizedBox(width: 8),
//                             const Text('Administradores'),
//                           ],
//                         ),
//                       ),
//                       DropdownMenuItem(
//                         value: 'user',
//                         child: Row(
//                           children: [
//                             Icon(Icons.person, color: Colors.blue),
//                             const SizedBox(width: 8),
//                             const Text('Usuarios'),
//                           ],
//                         ),
//                       ),
//                     ],
//                     onChanged: (value) {
//                       setState(() {
//                         _filterRole = value!;
//                       });
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Estadísticas
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             color: Colors.grey[50],
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 Column(
//                   children: [
//                     Text(
//                       '${_filteredUsers.length}',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue,
//                       ),
//                     ),
//                     const Text('Mostrados', style: TextStyle(fontSize: 12)),
//                   ],
//                 ),
//                 Column(
//                   children: [
//                     Text(
//                       '${roleStats['admin'] ?? 0}',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.red,
//                       ),
//                     ),
//                     const Text(
//                       'Administradores',
//                       style: TextStyle(fontSize: 12),
//                     ),
//                   ],
//                 ),
//                 Column(
//                   children: [
//                     Text(
//                       '${roleStats['user'] ?? 0}',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green,
//                       ),
//                     ),
//                     const Text('Usuarios', style: TextStyle(fontSize: 12)),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Lista
//           Expanded(
//             child: _userProvider.loading
//                 ? const Center(child: CircularProgressIndicator())
//                 : RefreshIndicator(
//                     onRefresh: _refreshUsers,
//                     child: _filteredUsers.isEmpty
//                         ? Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(
//                                   Icons.group_off,
//                                   size: 64,
//                                   color: Colors.grey[300],
//                                 ),
//                                 const SizedBox(height: 16),
//                                 Text(
//                                   _filterRole == 'todos'
//                                       ? 'No hay usuarios registrados'
//                                       : 'No hay usuarios con este rol',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     color: Colors.grey[500],
//                                   ),
//                                 ),
//                                 if (_filterRole == 'todos')
//                                   Padding(
//                                     padding: const EdgeInsets.only(top: 16),
//                                     child: ElevatedButton.icon(
//                                       onPressed: _navigateToCreateUser,
//                                       icon: const Icon(Icons.person_add),
//                                       label: const Text('Crear primer usuario'),
//                                     ),
//                                   ),
//                               ],
//                             ),
//                           )
//                         : ListView.builder(
//                             itemCount: _filteredUsers.length,
//                             itemBuilder: (context, index) =>
//                                 _buildUserCard(_filteredUsers[index]),
//                           ),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
