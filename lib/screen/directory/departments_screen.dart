// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:provider/provider.dart';
// import '../../models/department.dart';
// import '../../models/department_lite.dart';
// import '../../providers/auth_provider.dart';
// import '../../providers/department_provider.dart';
// import '../../providers/local_provider.dart';
// import '../../services/call_service.dart';
// import '../../utils/debouncer.dart';
// import '../../widgets/department_dialog.dart';

// class DepartmentsScreen extends StatefulWidget {
//   const DepartmentsScreen({super.key});

//   @override
//   DepartmentsScreenState createState() => DepartmentsScreenState();
// }

// class DepartmentsScreenState extends State<DepartmentsScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
//       GlobalKey<ScaffoldMessengerState>();
//   final Debouncer _searchDebouncer = Debouncer(milliseconds: 300);

//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(_onSearchChanged);
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final departmentProvider = Provider.of<DepartmentProvider>(
//         context,
//         listen: false,
//       );
//       final localProvider = Provider.of<LocalProvider>(context, listen: false);

//       departmentProvider.clearSearch();
//       departmentProvider.loadInitialData();

//       if (!localProvider.hasLoaded) {
//         localProvider.loadLocals();
//       }
//     });
//   }

//   void _onSearchChanged() {
//     _searchDebouncer.run(() {
//       if (mounted) {
//         final query = _searchController.text;
//         final departmentProvider = Provider.of<DepartmentProvider>(
//           context,
//           listen: false,
//         );

//         setState(() {});

//         if (query.isEmpty) {
//           departmentProvider.clearSearch();
//         } else {
//           departmentProvider.searchDepartments(query);
//         }
//       }
//     });
//   }

//   void _showAddDepartmentDialog() {
//     final departmentProvider = Provider.of<DepartmentProvider>(
//       context,
//       listen: false,
//     );
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);

//     if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
//       _showSnackBar(
//         'No tienes permisos para agregar departamentos',
//         isError: true,
//       );
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (context) => DepartmentDialog(
//         onSave: (department) async {
//           debugPrint(
//             '[DepartmentsScreen][CREATE] Starting create: ${department.toJson()}',
//           );
//           final success = await departmentProvider.createDepartment(
//             department.name,
//             department.phone,
//           );
//           if (success) {
//             _showSnackBar('✅ Departamento creado exitosamente');
//           } else {
//             _showSnackBar(
//               '❌ Error: ${departmentProvider.error}',
//               isError: true,
//             );
//           }
//           return success;
//         },
//         departmentProvider: departmentProvider,
//       ),
//     );
//   }

//   void _showEditDepartmentDialog(Department department) {
//     final departmentProvider = Provider.of<DepartmentProvider>(
//       context,
//       listen: false,
//     );
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);

//     if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
//       _showSnackBar(
//         'No tienes permisos para editar departamentos',
//         isError: true,
//       );
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (context) => DepartmentDialog(
//         department: department,
//         onSave: (updatedDepartment) async {
//           final success = await departmentProvider.updateDepartment(
//             updatedDepartment.copyWith(id: department.id),
//           );
//           if (success) {
//             _showSnackBar('✅ Departamento actualizado exitosamente');
//           } else {
//             _showSnackBar(
//               '❌ Error: ${departmentProvider.error}',
//               isError: true,
//             );
//           }
//           return success;
//         },

//         departmentProvider: departmentProvider,
//       ),
//     );
//   }

//   void _showDeleteConfirmation(Department department) {
//     final departmentProvider = Provider.of<DepartmentProvider>(
//       context,
//       listen: false,
//     );
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);

//     if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
//       _showSnackBar(
//         'No tienes permisos para eliminar departamentos',
//         isError: true,
//       );
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(Icons.warning, color: Colors.orange[700]),
//             SizedBox(width: 8),
//             Flexible(
//               child: Text('Eliminar Departamento', softWrap: true, maxLines: 2),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 80,
//               height: 80,
//               decoration: BoxDecoration(
//                 color: Colors.orange[100],
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(Icons.work, size: 40, color: Colors.orange[700]),
//             ),
//             SizedBox(height: 16),
//             Text(
//               '¿Estás seguro de que deseas eliminar:',
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey[600]),
//             ),
//             SizedBox(height: 8),
//             Text(
//               department.name,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.orange[700],
//               ),
//             ),
//             if (department.phone.isNotEmpty) ...[
//               SizedBox(height: 8),
//               Text(
//                 '📞 ${department.phone}',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Colors.grey[600]),
//               ),
//             ],
//             SizedBox(height: 16),
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.red[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.red[200]!),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.error_outline, color: Colors.red[700], size: 20),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       'Esta acción no se puede deshacer',
//                       style: TextStyle(color: Colors.red[700], fontSize: 13),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             ),
//             onPressed: () async {
//               Navigator.of(context).pop();

//               final success = await departmentProvider.deleteDepartment(
//                 department.id,
//               );
//               if (success) {
//                 _showSnackBar('🗑️ Departamento eliminado exitosamente');
//               } else {
//                 _showSnackBar(
//                   '❌ Error: ${departmentProvider.error}',
//                   isError: true,
//                 );
//               }
//             },
//             child: Text('Eliminar', style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showSnackBar(String message, {bool isError = false}) {
//     _scaffoldMessengerKey.currentState?.showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(
//               isError ? Icons.error : Icons.check_circle,
//               color: Colors.white,
//               size: 20,
//             ),
//             SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: isError ? Colors.red : Colors.green,
//         duration: Duration(seconds: 3),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final departmentProvider = Provider.of<DepartmentProvider>(context);
//     final authProvider = Provider.of<AuthProvider>(context);
//     final localProvider = Provider.of<LocalProvider>(context);
//     final isAdmin = authProvider.user?.isAdmin ?? false;

//     return ScaffoldMessenger(
//       key: _scaffoldMessengerKey,
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(
//             'Departamentos',
//             style: TextStyle(color: Colors.white, fontSize: 20),
//           ),
//           backgroundColor: Colors.orange[700],
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
//             onPressed: () => Navigator.pop(context),
//           ),
//           actions: [
//             // Botón de sincronización offline
//             Consumer<DepartmentProvider>(
//               builder: (context, provider, child) {
//                 if (provider.syncing) {
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 8),
//                     child: SizedBox(
//                       width: 24,
//                       height: 24,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: Colors.white,
//                       ),
//                     ),
//                   );
//                 }

//                 return IconButton(
//                   icon: Icon(
//                     provider.isOffline ? Icons.cloud_off : Icons.cloud_done,
//                     color: provider.isOffline
//                         ? Colors.orange[100]
//                         : Colors.white,
//                     size: 24,
//                   ),
//                   onPressed: provider.isOffline
//                       ? () => _syncDepartments(departmentProvider)
//                       : null,
//                   tooltip: provider.isOffline
//                       ? 'Modo offline - Toque para sincronizar'
//                       : 'En línea',
//                 );
//               },
//             ),

//             if (isAdmin)
//               IconButton(
//                 icon: Icon(
//                   Icons.add_circle_outline,
//                   color: Colors.white,
//                   size: 24,
//                 ),
//                 onPressed: _showAddDepartmentDialog,
//                 tooltip: 'Agregar Departamento',
//               ),
//             IconButton(
//               icon: Icon(Icons.refresh, color: Colors.white, size: 24),
//               onPressed: () {
//                 departmentProvider.loadDepartments(forceRefresh: true);
//                 _showSnackBar('🔄 Actualizando lista...');
//               },
//               tooltip: 'Actualizar',
//             ),
//           ],
//         ),
//         body: _buildBody(departmentProvider, localProvider, isAdmin),
//       ),
//     );
//   }

//   // NUEVO: Método para sincronizar departamentos
//   Future<void> _syncDepartments(DepartmentProvider provider) async {
//     final success = await provider.syncDepartments();

//     if (success) {
//       _showSnackBar('✅ Departamentos sincronizados');
//     } else {
//       _showSnackBar(
//         '❌ Error en sincronización: ${provider.error}',
//         isError: true,
//       );
//     }
//   }

//   // MODIFICADO COMPLETAMENTE: _buildBody optimizado
//   Widget _buildBody(
//     DepartmentProvider departmentProvider,
//     LocalProvider localProvider,
//     bool isAdmin,
//   ) {
//     // Estado de carga inicial
//     if (departmentProvider.loading && !departmentProvider.hasLoaded) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(color: Colors.orange[700]),
//             SizedBox(height: 16),
//             Text(
//               'Cargando departamentos...',
//               style: TextStyle(color: Colors.grey[600]),
//             ),
//           ],
//         ),
//       );
//     }

//     // Estado de error
//     if (departmentProvider.hasError && !departmentProvider.hasLoaded) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               departmentProvider.isOffline
//                   ? Icons.cloud_off
//                   : Icons.error_outline,
//               size: 64,
//               color: departmentProvider.isOffline ? Colors.orange : Colors.red,
//             ),
//             SizedBox(height: 16),
//             Text(
//               departmentProvider.isOffline
//                   ? 'Modo offline'
//                   : 'Error al cargar departamentos',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.grey[700],
//               ),
//             ),
//             SizedBox(height: 8),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 32),
//               child: Text(
//                 departmentProvider.isOffline && departmentProvider.hasLocalData
//                     ? 'Mostrando ${departmentProvider.localDataCount} departamentos almacenados localmente.'
//                     : departmentProvider.error,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Colors.grey[600]),
//               ),
//             ),
//             SizedBox(height: 24),

//             // Mostrar diferentes botones según el estado
//             if (departmentProvider.isOffline && departmentProvider.hasLocalData)
//               Column(
//                 children: [
//                   ElevatedButton.icon(
//                     icon: Icon(Icons.cloud_upload, color: Colors.white),
//                     label: Text(
//                       'Sincronizar ahora',
//                       style: TextStyle(color: Colors.white),
//                     ),
//                     onPressed: () => _syncDepartments(departmentProvider),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange[700],
//                       padding: EdgeInsets.symmetric(
//                         horizontal: 24,
//                         vertical: 12,
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 12),
//                   TextButton(
//                     onPressed: () => departmentProvider.loadDepartments(),
//                     child: Text('Continuar en modo offline'),
//                   ),
//                 ],
//               )
//             else
//               ElevatedButton.icon(
//                 icon: Icon(Icons.refresh, color: Colors.white),
//                 label: Text(
//                   'Reintentar',
//                   style: TextStyle(color: Colors.white),
//                 ),
//                 onPressed: () => departmentProvider.loadDepartments(),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.orange[700],
//                   padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 ),
//               ),
//           ],
//         ),
//       );
//     }

//     // Usar departmentLites en lugar de departments para mejor rendimiento
//     final lites = departmentProvider.departmentLites;

//     return Column(
//       children: [
//         // Barra de búsqueda optimizada
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(30),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 4,
//                   offset: Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Buscar por nombre o teléfono...',
//                 prefixIcon: Icon(Icons.search, color: Colors.orange),
//                 suffixIcon: _searchController.text.isNotEmpty
//                     ? IconButton(
//                         icon: Icon(Icons.close, color: Colors.grey[600]),
//                         onPressed: () {
//                           _searchController.clear();
//                           setState(() {});
//                           departmentProvider.clearSearch();
//                         },
//                         tooltip: 'Limpiar búsqueda',
//                       )
//                     : null,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//                 contentPadding: EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 16,
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//               ),
//             ),
//           ),
//         ),

//         SizedBox(height: 12),

//         // Contador y estadísticas optimizado
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   Icon(Icons.work, size: 16, color: Colors.orange[700]),
//                   SizedBox(width: 6),
//                   Consumer<DepartmentProvider>(
//                     builder: (context, provider, child) {
//                       final totalCount = provider.isSearching
//                           ? lites.length
//                           : (provider.isOffline
//                                 ? provider.localDataCount
//                                 : provider.totalDepartments);

//                       return Text(
//                         '$totalCount departamentos${provider.isOffline ? ' (offline)' : ''}',
//                         style: TextStyle(
//                           color: provider.isOffline
//                               ? Colors.orange[700]
//                               : Colors.grey[700],
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),

//               Consumer<DepartmentProvider>(
//                 builder: (context, provider, child) {
//                   if (provider.isOffline) {
//                     return Container(
//                       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.orange[50],
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: Colors.orange[200]!),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.cloud_off,
//                             size: 12,
//                             color: Colors.orange[700],
//                           ),
//                           SizedBox(width: 4),
//                           Text(
//                             'Offline',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.orange[700],
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   }

//                   return SizedBox.shrink();
//                 },
//               ),
//             ],
//           ),
//         ),

//         SizedBox(height: 12),

//         // Lista de departamentos OPTIMIZADA CON PAGINACIÓN
//         Expanded(
//           child: RefreshIndicator(
//             onRefresh: () async {
//               await departmentProvider.loadDepartments(forceRefresh: true);
//               _showSnackBar('✅ Lista actualizada');
//             },
//             color: Colors.orange[700],
//             child: lites.isEmpty && !departmentProvider.isLoadingMore
//                 ? _buildEmptyState(isAdmin, departmentProvider)
//                 : ListView.builder(
//                     controller: departmentProvider.scrollController,
//                     padding: const EdgeInsets.all(16),
//                     itemCount:
//                         lites.length + (departmentProvider.hasMore ? 1 : 0),
//                     itemExtent:
//                         96, // ALTURA FIJA para optimización de rendimiento
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     itemBuilder: (context, index) {
//                       // Loading indicator al final si hay más elementos
//                       if (index >= lites.length) {
//                         return _buildLoadingIndicator(departmentProvider);
//                       }

//                       final departmentLite = lites[index];
//                       return _buildDepartmentCard(
//                         departmentLite,
//                         localProvider,
//                         isAdmin,
//                       );
//                     },
//                   ),
//           ),
//         ),
//       ],
//     );
//   }

//   // NUEVO: Widget para loading indicator de paginación
//   Widget _buildLoadingIndicator(DepartmentProvider provider) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 16),
//       child: Center(
//         child: provider.isLoadingMore
//             ? CircularProgressIndicator(color: Colors.orange[700])
//             : SizedBox.shrink(),
//       ),
//     );
//   }

//   // MODIFICADO: Usar DepartmentLite para mejor rendimiento
//   Widget _buildDepartmentCard(
//     DepartmentLite departmentLite,
//     LocalProvider localProvider,
//     bool isAdmin,
//   ) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       margin: EdgeInsets.only(bottom: 12),
//       child: InkWell(
//         onTap: () => _loadAndShowDepartmentDetails(
//           departmentLite.id,
//           localProvider,
//           isAdmin,
//         ),
//         borderRadius: BorderRadius.circular(12),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               // Icono optimizado
//               Container(
//                 width: 48,
//                 height: 48,
//                 decoration: BoxDecoration(
//                   color: Colors.orange[100],
//                   shape: BoxShape.circle,
//                 ),
//                 child: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         departmentLite.initials,
//                         style: TextStyle(
//                           color: Colors.orange[700],
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               SizedBox(width: 16),

//               // Información optimizada
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       departmentLite.name,
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                         color: Colors.grey[800],
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     SizedBox(height: 4),
//                     if (departmentLite.hasPhone)
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.phone,
//                             size: 14,
//                             color: Colors.orange[600],
//                           ),
//                           SizedBox(width: 4),
//                           Text(
//                             departmentLite.phone,
//                             style: TextStyle(
//                               fontSize: 13,
//                               color: Colors.orange[600],
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),
//               ),

//               // Menú de acciones (solo para admin)
//               if (isAdmin)
//                 PopupMenuButton<String>(
//                   icon: Icon(
//                     Icons.more_vert,
//                     color: Colors.orange[700],
//                     size: 20,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   itemBuilder: (context) => [
//                     PopupMenuItem<String>(
//                       value: 'edit',
//                       child: Row(
//                         children: [
//                           Icon(Icons.edit, color: Colors.blue[700], size: 18),
//                           SizedBox(width: 8),
//                           Text('Editar'),
//                         ],
//                       ),
//                     ),
//                     PopupMenuItem<String>(
//                       value: 'delete',
//                       child: Row(
//                         children: [
//                           Icon(Icons.delete, color: Colors.red, size: 18),
//                           SizedBox(width: 8),
//                           Text('Eliminar'),
//                         ],
//                       ),
//                     ),
//                   ],
//                   onSelected: (value) async {
//                     final department = await _loadDepartmentById(
//                       departmentLite.id,
//                     );
//                     if (department != null) {
//                       if (value == 'edit') {
//                         _showEditDepartmentDialog(department);
//                       } else if (value == 'delete') {
//                         _showDeleteConfirmation(department);
//                       }
//                     }
//                   },
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // NUEVO: Cargar department completo por ID
//   Future<Department?> _loadDepartmentById(int id) async {
//     final departmentProvider = Provider.of<DepartmentProvider>(
//       context,
//       listen: false,
//     );
//     return await departmentProvider.getDepartmentById(id);
//   }

//   // NUEVO: Cargar y mostrar detalles
//   Future<void> _loadAndShowDepartmentDetails(
//     int departmentId,
//     LocalProvider localProvider,
//     bool isAdmin,
//   ) async {
//     final department = await _loadDepartmentById(departmentId);
//     if (department != null && mounted) {
//       _showDepartmentDetails(department, localProvider, isAdmin);
//     }
//   }

//   Widget _buildEmptyState(bool isAdmin, DepartmentProvider provider) {
//     return Center(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Consumer<DepartmentProvider>(
//               builder: (context, provider, child) {
//                 return Column(
//                   children: [
//                     Container(
//                       width: 120,
//                       height: 120,
//                       decoration: BoxDecoration(
//                         color: provider.isOffline
//                             ? Colors.orange[50]
//                             : Colors.orange[50],
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         provider.isOffline
//                             ? Icons.cloud_off
//                             : _searchController.text.isEmpty
//                             ? Icons.work_outline
//                             : Icons.search_off,
//                         size: 60,
//                         color: provider.isOffline
//                             ? Colors.orange[300]
//                             : Colors.orange[300],
//                       ),
//                     ),
//                     SizedBox(height: 16),
//                     if (provider.isOffline)
//                       Container(
//                         padding: EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.orange[50],
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: Colors.orange[200]!),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(
//                               Icons.info,
//                               color: Colors.orange[700],
//                               size: 20,
//                             ),
//                             SizedBox(width: 8),
//                             Text(
//                               'Modo offline',
//                               style: TextStyle(color: Colors.orange[700]),
//                             ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 );
//               },
//             ),

//             SizedBox(height: 24),

//             Consumer<DepartmentProvider>(
//               builder: (context, provider, child) {
//                 return Column(
//                   children: [
//                     Text(
//                       _searchController.text.isEmpty
//                           ? provider.isOffline
//                                 ? 'No hay datos locales de departamentos'
//                                 : 'No hay departamentos registrados'
//                           : 'No se encontraron resultados',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey[700],
//                       ),
//                       textAlign: TextAlign.center,
//                     ),

//                     SizedBox(height: 12),

//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 32),
//                       child: Text(
//                         _searchController.text.isEmpty
//                             ? provider.isOffline
//                                   ? 'Conéctate a internet para cargar los departamentos.'
//                                   : ''
//                             : 'No encontramos coincidencias con "${_searchController.text}". Intenta con otros términos.',
//                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             ),

//             SizedBox(height: 24),

//             Consumer<DepartmentProvider>(
//               builder: (context, provider, child) {
//                 // Mostrar botón de sincronizar si está offline
//                 if (provider.isOffline && _searchController.text.isEmpty) {
//                   return Column(
//                     children: [
//                       ElevatedButton.icon(
//                         icon: Icon(Icons.cloud_download, color: Colors.white),
//                         label: Text('Sincronizar desde internet'),
//                         onPressed: () => _syncDepartments(provider),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.orange[700],
//                           padding: EdgeInsets.symmetric(
//                             horizontal: 24,
//                             vertical: 14,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 12),
//                       Text(
//                         'O verifica tu conexión a internet',
//                         style: TextStyle(fontSize: 12, color: Colors.grey[500]),
//                       ),
//                     ],
//                   );
//                 }

//                 // Mostrar botón de agregar solo para admin
//                 if (isAdmin && _searchController.text.isEmpty) {
//                   return ElevatedButton.icon(
//                     icon: Icon(Icons.add),
//                     label: Text('Agregar Primer Departamento'),
//                     onPressed: _showAddDepartmentDialog,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange[700],
//                       padding: EdgeInsets.symmetric(
//                         horizontal: 24,
//                         vertical: 14,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   );
//                 }

//                 return SizedBox.shrink();
//               },
//             ),

//             if (_searchController.text.isNotEmpty)
//               TextButton.icon(
//                 icon: Icon(Icons.clear_all),
//                 label: Text('Limpiar búsqueda'),
//                 onPressed: () {
//                   _searchController.clear();
//                   setState(() {});
//                   provider.clearSearch();
//                 },
//                 style: TextButton.styleFrom(
//                   foregroundColor: Colors.orange[700],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showDepartmentDetails(
//     Department department,
//     LocalProvider localProvider,
//     bool isAdmin,
//   ) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(24),
//             topRight: Radius.circular(24),
//           ),
//         ),
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Handle para arrastrar
//               Center(
//                 child: Container(
//                   width: 40,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 16),

//               // Header con icono
//               Center(
//                 child: Column(
//                   children: [
//                     Container(
//                       width: 80,
//                       height: 80,
//                       decoration: BoxDecoration(
//                         color: Colors.orange[100],
//                         shape: BoxShape.circle,
//                       ),
//                       child: Center(
//                         child: Text(
//                           department.name.length >= 2
//                               ? department.name.substring(0, 2).toUpperCase()
//                               : department.name.toUpperCase(),
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.orange[700],
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 16),
//                     Text(
//                       department.name,
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey[800],
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: 24),
//               Divider(color: Colors.grey[200]),

//               // Información detallada
//               _buildDetailSection(
//                 icon: Icons.phone,
//                 label: 'Teléfono',
//                 value: department.phone.isNotEmpty
//                     ? department.phone
//                     : 'No disponible',
//                 color: Colors.orange[700]!,
//               ),

//               SizedBox(height: 20),

//               // Acciones de contacto
//               if (department.phone.isNotEmpty) ...[
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.orange[50],
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       _buildContactAction(
//                         Icons.phone,
//                         'Llamar',
//                         Colors.green,
//                         () {
//                           Navigator.pop(context);
//                           _makePhoneCall(department.phone);
//                         },
//                       ),
//                       _buildContactAction(
//                         Icons.copy,
//                         'Copiar',
//                         Colors.orange,
//                         () {
//                           Navigator.pop(context);
//                           _copyPhoneNumber(department.phone);
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 16),
//               ],

//               // Acciones administrativas
//               if (isAdmin) ...[
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton.icon(
//                         icon: Icon(Icons.edit, size: 18, color: Colors.orange),
//                         label: Text(
//                           'Editar',
//                           style: TextStyle(color: Colors.orange),
//                         ),
//                         onPressed: () {
//                           Navigator.pop(context);
//                           _showEditDepartmentDialog(department);
//                         },
//                         style: OutlinedButton.styleFrom(
//                           padding: EdgeInsets.symmetric(vertical: 12),
//                           side: BorderSide(color: Colors.orange),
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         icon: Icon(Icons.delete, size: 18, color: Colors.white),
//                         label: Text(
//                           'Eliminar',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                         onPressed: () {
//                           Navigator.pop(context);
//                           _showDeleteConfirmation(department);
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                           padding: EdgeInsets.symmetric(vertical: 12),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],

//               SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailSection({
//     required IconData icon,
//     required String label,
//     required String value,
//     required Color color,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: color.withValues(alpha: 0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, size: 20, color: color),
//           ),
//           SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: TextStyle(fontSize: 16, color: Colors.grey[800]),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildContactAction(
//     IconData icon,
//     String label,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return Column(
//       children: [
//         IconButton(
//           icon: Icon(icon, size: 28),
//           color: color,
//           onPressed: onTap,
//           style: IconButton.styleFrom(
//             backgroundColor: Colors.white,
//             padding: EdgeInsets.all(12),
//           ),
//         ),
//         SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: color,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }

//   void _makePhoneCall(String phoneNumber) async {
//     if (phoneNumber.isEmpty) return;

//     // Verificar permiso primero
//     var status = await Permission.phone.status;

//     if (!status.isGranted) {
//       status = await Permission.phone.request();
//     }

//     if (status.isGranted) {
//       _showSnackBar('📞 Llamando a $phoneNumber...');
//       CallService.directCall(phoneNumber);
//     } else {
//       _showSnackBar('❌ Permiso denegado para hacer llamadas');
//       // Aquí podrías abrir la configuración de la app
//       // await openAppSettings();
//     }
//   }

//   void _copyPhoneNumber(String phoneNumber) {
//     Navigator.of(context).pop();

//     final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
//     if (mounted) {
//       Clipboard.setData(ClipboardData(text: cleanPhoneNumber))
//           .then((value) {
//             if (mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('Número copiado: $cleanPhoneNumber'),
//                   backgroundColor: Colors.green,
//                   duration: Duration(seconds: 2),
//                 ),
//               );
//             }
//           })
//           .catchError((error) {
//             if (mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('Error al copiar el número'),
//                   backgroundColor: Colors.red,
//                   duration: Duration(seconds: 2),
//                 ),
//               );
//             }
//           });
//     }
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _searchDebouncer.dispose();
//     super.dispose();
//   }
// }



import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../models/department.dart';
import '../../models/department_lite.dart';
import '../../providers/auth_provider.dart';
import '../../providers/department_provider.dart';
import '../../providers/local_provider.dart';
import '../../services/call_service.dart';
import '../../utils/debouncer.dart';
import '../../utils/excel_import_service.dart';
import '../../utils/excel_template_service.dart';
import '../../widgets/department_dialog.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  DepartmentsScreenState createState() => DepartmentsScreenState();
}

class DepartmentsScreenState extends State<DepartmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 300);

  // Variables para importación Excel
  String? _selectedExcelFilePath;
  List<Map<String, dynamic>> _previewData = [];
  bool _isProcessingExcel = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final departmentProvider = Provider.of<DepartmentProvider>(
        context,
        listen: false,
      );
      final localProvider = Provider.of<LocalProvider>(context, listen: false);

      departmentProvider.clearSearch();
      departmentProvider.loadInitialData();

      if (!localProvider.hasLoaded) {
        localProvider.loadLocals();
      }
    });
  }

  void _onSearchChanged() {
    _searchDebouncer.run(() {
      if (mounted) {
        final query = _searchController.text;
        final departmentProvider = Provider.of<DepartmentProvider>(
          context,
          listen: false,
        );

        setState(() {});

        if (query.isEmpty) {
          departmentProvider.clearSearch();
        } else {
          departmentProvider.searchDepartments(query);
        }
      }
    });
  }

  // ============ MÉTODOS DE AGREGAR DEPARTAMENTOS ============

  // Botón flotante con opción de importar Excel
  Widget _buildFloatingActionButton(bool isAdmin) {
    if (!isAdmin) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: _showAddDepartmentOptions,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Agregar',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.orange[700],
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  // Mostrar opciones de agregar
  void _showAddDepartmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Agregar Departamentos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                'Selecciona cómo deseas agregar',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 24),

              // Opción: Agregar manual
              _buildOptionCard(
                icon: Icons.business_center,
                title: 'Agregar Manual',
                subtitle: 'Ingresar datos uno por uno',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _showAddDepartmentDialog();
                },
              ),

              const SizedBox(height: 12),

              // Opción: Importar Excel
              _buildOptionCard(
                icon: Icons.table_chart,
                title: 'Importar desde Excel',
                subtitle: 'Cargar múltiples departamentos desde archivo .xlsx',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _showExcelImportDialog();
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // Widget para cada opción
  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ============ DIÁLOGO DE IMPORTACIÓN EXCEL ============

  void _showExcelImportDialog() {
    _selectedExcelFilePath = null;
    _previewData = [];
    _isProcessingExcel = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.upload_file, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  const Text('Importar Excel'),
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxHeight: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecciona un archivo Excel (.xlsx) con la estructura requerida',
                      style: TextStyle(color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 16),

                    // Área de selección de archivo
                    GestureDetector(
                      onTap: _isProcessingExcel
                          ? null
                          : () => _pickExcelFile(setState),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedExcelFilePath != null
                                ? Colors.green
                                : Colors.grey[300]!,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: _selectedExcelFilePath != null
                              ? Colors.green[50]
                              : Colors.grey[50],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedExcelFilePath != null
                                  ? Icons.check_circle
                                  : Icons.cloud_upload,
                              size: 48,
                              color: _selectedExcelFilePath != null
                                  ? Colors.green
                                  : Colors.green[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedExcelFilePath != null
                                  ? _selectedExcelFilePath!.split('/').last
                                  : 'Toca para seleccionar archivo',
                              style: TextStyle(
                                color: _selectedExcelFilePath != null
                                    ? Colors.green[700]
                                    : Colors.grey[600],
                                fontWeight: _selectedExcelFilePath != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_selectedExcelFilePath == null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Formatos soportados: .xlsx, .xls',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Descargar plantilla
                    InkWell(
                      onTap: _downloadExcelTemplate,
                      child: Row(
                        children: [
                          Icon(Icons.file_download, size: 18, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Descargar plantilla de ejemplo',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_isProcessingExcel) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text(
                              'Procesando archivo...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Previsualización de datos
                    if (_previewData.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.preview, size: 16, color: Colors.orange[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Previsualización (${_previewData.length} registros)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 100,
                              child: ListView.builder(
                                itemCount: _previewData.length > 5 ? 5 : _previewData.length,
                                itemBuilder: (context, index) {
                                  final item = _previewData[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      '${index + 1}. ${item['nombre'] ?? 'Sin nombre'} - ${item['telefono'] ?? 'Sin teléfono'}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isProcessingExcel ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed: _isProcessingExcel || _selectedExcelFilePath == null
                      ? null
                      : () => _processExcelFile(context, setState),
                  icon: const Icon(Icons.cloud_upload, size: 18),
                  label: const Text('Importar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Seleccionar archivo Excel
  Future<void> _pickExcelFile(StateSetter setState) async {
    try {
      if (Platform.isAndroid) {
        final storagePermission = await Permission.storage.request();
        if (!storagePermission.isGranted && !await Permission.manageExternalStorage.isGranted) {
          _showSnackBar('Se necesitan permisos de almacenamiento para importar archivos.', isError: true);
          return;
        }
      }

      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedExcelFilePath = result.files.single.path;
          _previewData = [];
        });

        // Leer y previsualizar el archivo
        await _previewExcelFile(result.files.single.path!, setState);
      }
    } catch (e) {
      _showSnackBar('Error al seleccionar archivo: $e', isError: true);
    }
  }

  // Previsualizar archivo Excel
  Future<void> _previewExcelFile(String filePath, StateSetter setState) async {
    try {
      final rows = await ExcelImportService.readRowsFromFile(filePath);
      final parsedRows = ExcelImportService.parseSimpleRows(
        rows: rows,
        requiredColumns: ['nombre', 'telefono'],
      );

      if (parsedRows.isEmpty) {
        throw Exception('No se encontraron registros válidos en el archivo.');
      }

      setState(() {
        _previewData = parsedRows;
      });
    } catch (e) {
      _showSnackBar('Error al leer el archivo: $e', isError: true);
      setState(() {
        _selectedExcelFilePath = null;
        _previewData = [];
      });
    }
  }

  // Procesar archivo Excel
  Future<void> _processExcelFile(BuildContext context, StateSetter setState) async {
    if (_selectedExcelFilePath == null || _previewData.isEmpty) {
      _showSnackBar('No hay datos para importar', isError: true);
      return;
    }

    setState(() {
      _isProcessingExcel = true;
    });

    try {
      final departmentProvider = Provider.of<DepartmentProvider>(
        context,
        listen: false,
      );

      int successCount = 0;
      int skippedCount = 0;

      for (var data in _previewData) {
        try {
          final name = data['nombre']?.toString().trim() ?? '';
          final phone = data['telefono']?.toString().trim() ?? '';

          if (name.isEmpty) {
            skippedCount++;
            continue;
          }

          final success = await departmentProvider.createDepartment(
            name,
            phone,
          );
          if (success) {
            successCount++;
          } else {
            skippedCount++;
          }
        } catch (e) {
          skippedCount++;
        }
      }

      if (!mounted) return;
      Navigator.pop(context);

      if (successCount > 0) {
        _showSnackBar('✅ $successCount departamentos importados exitosamente${skippedCount > 0 ? ' ($skippedCount omitidos)' : ''}');
        await departmentProvider.loadDepartments(forceRefresh: true);
      } else {
        _showSnackBar('❌ No se pudo importar ningún departamento', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('❌ Error al importar: ${e.toString()}', isError: true);
    }
  }

  // Descargar plantilla de ejemplo
  Future<void> _downloadExcelTemplate() async {
    try {
      if (Platform.isAndroid) {
        final storagePermission = await Permission.storage.request();
        if (!storagePermission.isGranted && !await Permission.manageExternalStorage.isGranted) {
          _showSnackBar('Se necesitan permisos de almacenamiento para descargar archivos.', isError: true);
          return;
        }
      }

      _showSnackBar('📥 Generando plantilla...');
      final filePath = await ExcelTemplateService.generateDepartmentsTemplate();
      if (!mounted) return;

      if (filePath != null && filePath.isNotEmpty) {
        _showSnackBar('✅ Plantilla lista en: $filePath');
      } else {
        _showSnackBar('❌ No se pudo generar la plantilla', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('❌ Error al generar plantilla: ${e.toString()}', isError: true);
    }
  }

  // ============ MÉTODOS DE MANEJO DE DEPARTAMENTOS ============

  void _showAddDepartmentDialog() {
    final departmentProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar(
        'No tienes permisos para agregar departamentos',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => DepartmentDialog(
        onSave: (department) async {
          debugPrint(
            '[DepartmentsScreen][CREATE] Starting create: ${department.toJson()}',
          );
          final success = await departmentProvider.createDepartment(
            department.name,
            department.phone,
          );
          if (success) {
            _showSnackBar('✅ Departamento creado exitosamente');
          } else {
            _showSnackBar(
              '❌ Error: ${departmentProvider.error}',
              isError: true,
            );
          }
          return success;
        },
        departmentProvider: departmentProvider,
      ),
    );
  }

  void _showEditDepartmentDialog(Department department) {
    final departmentProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar(
        'No tienes permisos para editar departamentos',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => DepartmentDialog(
        department: department,
        onSave: (updatedDepartment) async {
          final success = await departmentProvider.updateDepartment(
            updatedDepartment.copyWith(id: department.id),
          );
          if (success) {
            _showSnackBar('✅ Departamento actualizado exitosamente');
          } else {
            _showSnackBar(
              '❌ Error: ${departmentProvider.error}',
              isError: true,
            );
          }
          return success;
        },
        departmentProvider: departmentProvider,
      ),
    );
  }

  void _showDeleteConfirmation(Department department) {
    final departmentProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar(
        'No tienes permisos para eliminar departamentos',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Eliminar Departamento',
                softWrap: true,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.work, size: 40, color: Colors.orange[700]),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Estás seguro de que deseas eliminar:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              department.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            if (department.phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '📞 ${department.phone}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              Navigator.of(context).pop();

              final success = await departmentProvider.deleteDepartment(
                department.id,
              );
              if (success) {
                _showSnackBar('🗑️ Departamento eliminado exitosamente');
              } else {
                _showSnackBar(
                  '❌ Error: ${departmentProvider.error}',
                  isError: true,
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ============ MÉTODOS DE SINCRONIZACIÓN ============

  Future<void> _syncDepartments(DepartmentProvider provider) async {
    final success = await provider.syncDepartments();

    if (success) {
      _showSnackBar('✅ Departamentos sincronizados');
    } else {
      _showSnackBar(
        '❌ Error en sincronización: ${provider.error}',
        isError: true,
      );
    }
  }

  // ============ BUILD PRINCIPAL ============

  @override
  Widget build(BuildContext context) {
    final departmentProvider = Provider.of<DepartmentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final localProvider = Provider.of<LocalProvider>(context);
    final isAdmin = authProvider.user?.isAdmin ?? false;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Departamentos',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          backgroundColor: Colors.orange[700],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // Botón de sincronización offline
            Consumer<DepartmentProvider>(
              builder: (context, provider, child) {
                if (provider.syncing) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  );
                }

                return IconButton(
                  icon: Icon(
                    provider.isOffline ? Icons.cloud_off : Icons.cloud_done,
                    color: provider.isOffline
                        ? Colors.orange[100]
                        : Colors.white,
                    size: 24,
                  ),
                  onPressed: provider.isOffline
                      ? () => _syncDepartments(departmentProvider)
                      : null,
                  tooltip: provider.isOffline
                      ? 'Modo offline - Toque para sincronizar'
                      : 'En línea',
                );
              },
            ),

            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
              onPressed: () {
                departmentProvider.loadDepartments(forceRefresh: true);
                _showSnackBar('🔄 Actualizando lista...');
              },
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body: _buildBody(departmentProvider, localProvider, isAdmin),
        floatingActionButton: _buildFloatingActionButton(isAdmin),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildBody(
    DepartmentProvider departmentProvider,
    LocalProvider localProvider,
    bool isAdmin,
  ) {
    if (departmentProvider.loading && !departmentProvider.hasLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange[700]),
            const SizedBox(height: 16),
            Text(
              'Cargando departamentos...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (departmentProvider.hasError && !departmentProvider.hasLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              departmentProvider.isOffline
                  ? Icons.cloud_off
                  : Icons.error_outline,
              size: 64,
              color: departmentProvider.isOffline ? Colors.orange : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              departmentProvider.isOffline
                  ? 'Modo offline'
                  : 'Error al cargar departamentos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                departmentProvider.isOffline && departmentProvider.hasLocalData
                    ? 'Mostrando ${departmentProvider.localDataCount} departamentos almacenados localmente.'
                    : departmentProvider.error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),

            if (departmentProvider.isOffline && departmentProvider.hasLocalData)
              Column(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload, color: Colors.white),
                    label: const Text(
                      'Sincronizar ahora',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => _syncDepartments(departmentProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => departmentProvider.loadDepartments(),
                    child: const Text('Continuar en modo offline'),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Reintentar',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () => departmentProvider.loadDepartments(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      );
    }

    final lites = departmentProvider.departmentLites;

    return Column(
      children: [
        // Barra de búsqueda optimizada
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o teléfono...',
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          departmentProvider.clearSearch();
                        },
                        tooltip: 'Limpiar búsqueda',
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Contador y estadísticas optimizado
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.work, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 6),
                  Consumer<DepartmentProvider>(
                    builder: (context, provider, child) {
                      final totalCount = provider.isSearching
                          ? lites.length
                          : (provider.isOffline
                                ? provider.localDataCount
                                : provider.totalDepartments);

                      return Text(
                        '$totalCount departamentos${provider.isOffline ? ' (offline)' : ''}',
                        style: TextStyle(
                          color: provider.isOffline
                              ? Colors.orange[700]
                              : Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),

              Consumer<DepartmentProvider>(
                builder: (context, provider, child) {
                  if (provider.isOffline) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 12,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Lista de departamentos
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await departmentProvider.loadDepartments(forceRefresh: true);
              _showSnackBar('✅ Lista actualizada');
            },
            color: Colors.orange[700],
            child: lites.isEmpty && !departmentProvider.isLoadingMore
                ? _buildEmptyState(isAdmin, departmentProvider)
                : ListView.builder(
                    controller: departmentProvider.scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        lites.length + (departmentProvider.hasMore ? 1 : 0),
                    itemExtent: 96,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      if (index >= lites.length) {
                        return _buildLoadingIndicator(departmentProvider);
                      }

                      final departmentLite = lites[index];
                      return _buildDepartmentCard(
                        departmentLite,
                        localProvider,
                        isAdmin,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator(DepartmentProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: provider.isLoadingMore
            ? CircularProgressIndicator(color: Colors.orange[700])
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildDepartmentCard(
    DepartmentLite departmentLite,
    LocalProvider localProvider,
    bool isAdmin,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _loadAndShowDepartmentDetails(
          departmentLite.id,
          localProvider,
          isAdmin,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        departmentLite.initials,
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      departmentLite.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (departmentLite.hasPhone)
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: Colors.orange[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            departmentLite.phone,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              if (isAdmin)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    final department = await _loadDepartmentById(
                      departmentLite.id,
                    );
                    if (department != null) {
                      if (value == 'edit') {
                        _showEditDepartmentDialog(department);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(department);
                      }
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Department?> _loadDepartmentById(int id) async {
    final departmentProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );
    return await departmentProvider.getDepartmentById(id);
  }

  Future<void> _loadAndShowDepartmentDetails(
    int departmentId,
    LocalProvider localProvider,
    bool isAdmin,
  ) async {
    final department = await _loadDepartmentById(departmentId);
    if (department != null && mounted) {
      _showDepartmentDetails(department, localProvider, isAdmin);
    }
  }

  Widget _buildEmptyState(bool isAdmin, DepartmentProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<DepartmentProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: provider.isOffline
                            ? Colors.orange[50]
                            : Colors.orange[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        provider.isOffline
                            ? Icons.cloud_off
                            : _searchController.text.isEmpty
                            ? Icons.work_outline
                            : Icons.search_off,
                        size: 60,
                        color: provider.isOffline
                            ? Colors.orange[300]
                            : Colors.orange[300],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (provider.isOffline)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info,
                              color: Colors.orange[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Modo offline',
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            Consumer<DepartmentProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    Text(
                      _searchController.text.isEmpty
                          ? provider.isOffline
                                ? 'No hay datos locales de departamentos'
                                : 'No hay departamentos registrados'
                          : 'No se encontraron resultados',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _searchController.text.isEmpty
                            ? provider.isOffline
                                  ? 'Conéctate a internet para cargar los departamentos.'
                                  : ''
                            : 'No encontramos coincidencias con "${_searchController.text}". Intenta con otros términos.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            Consumer<DepartmentProvider>(
              builder: (context, provider, child) {
                if (provider.isOffline && _searchController.text.isEmpty) {
                  return Column(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_download, color: Colors.white),
                        label: const Text('Sincronizar desde internet'),
                        onPressed: () => _syncDepartments(provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'O verifica tu conexión a internet',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  );
                }

                if (isAdmin && _searchController.text.isEmpty) {
                  return ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Primer Departamento'),
                    onPressed: _showAddDepartmentOptions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            if (_searchController.text.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar búsqueda'),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                  provider.clearSearch();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange[700],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDepartmentDetails(
    Department department,
    LocalProvider localProvider,
    bool isAdmin,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle para arrastrar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header con icono
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          department.name.length >= 2
                              ? department.name.substring(0, 2).toUpperCase()
                              : department.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      department.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Divider(color: Colors.grey[200]),

              // Información detallada
              _buildDetailSection(
                icon: Icons.phone,
                label: 'Teléfono',
                value: department.phone.isNotEmpty
                    ? department.phone
                    : 'No disponible',
                color: Colors.orange[700]!,
              ),

              const SizedBox(height: 20),

              // Acciones de contacto
              if (department.phone.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildContactAction(
                        Icons.phone,
                        'Llamar',
                        Colors.green,
                        () {
                          Navigator.pop(context);
                          _makePhoneCall(department.phone);
                        },
                      ),
                      _buildContactAction(
                        Icons.copy,
                        'Copiar',
                        Colors.orange,
                        () {
                          Navigator.pop(context);
                          _copyPhoneNumber(department.phone);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Acciones administrativas
              if (isAdmin) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit, size: 18, color: Colors.orange),
                        label: const Text(
                          'Editar',
                          style: TextStyle(color: Colors.orange),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditDepartmentDialog(department);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                        label: const Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation(department);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 28),
          color: color,
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;

    var status = await Permission.phone.status;

    if (!status.isGranted) {
      status = await Permission.phone.request();
    }

    if (status.isGranted) {
      _showSnackBar('📞 Llamando a $phoneNumber...');
      CallService.directCall(phoneNumber);
    } else {
      _showSnackBar('❌ Permiso denegado para hacer llamadas');
    }
  }

  void _copyPhoneNumber(String phoneNumber) {
    Navigator.of(context).pop();

    final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (mounted) {
      Clipboard.setData(ClipboardData(text: cleanPhoneNumber))
          .then((value) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Número copiado: $cleanPhoneNumber'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          })
          .catchError((error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al copiar el número'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }
}