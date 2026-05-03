import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/worker.dart';
import '../../models/worker_lite.dart';
import '../../providers/auth_provider.dart';
import '../../providers/department_provider.dart';
import '../../providers/local_provider.dart';
import '../../providers/worker_provider.dart';
import '../../services/call_service.dart';
import '../../widgets/worker_dialog.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  WorkersScreenState createState() => WorkersScreenState();
}

class WorkersScreenState extends State<WorkersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    // Search con debounce optimizado
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), _onSearchChanged);
    });

    // Scroll listener para paginación
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkerProvider>(context, listen: false).clearSearch();
      _loadInitialData();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMoreData();
    }
  }

  void _onSearchChanged() {
    if (mounted) {
      Provider.of<WorkerProvider>(
        context,
        listen: false,
      ).searchWorkers(_searchController.text);
    }
  }

  void _loadInitialData() {
    if (!mounted) return;

    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final departmentProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );
    final localProvider = Provider.of<LocalProvider>(context, listen: false);

    workerProvider.loadInitialData();

    if (!departmentProvider.hasLoaded) {
      departmentProvider.loadDepartments();
    }
    if (!localProvider.hasLoaded) {
      localProvider.loadLocals();
    }
  }

  Future<void> _loadMoreData() async {
    if (!mounted) return;

    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);

    // Evitar múltiples llamadas simultáneas
    if (workerProvider.isLoadingMore || !workerProvider.hasMore) {
      return;
    }

    final success = await workerProvider.loadMoreWorkers();

    if (success && mounted) {
      // Mostrar mensaje sutil (opcional)
      if (workerProvider.hasMore) {
        _showSnackBar('Cargando más trabajadores...');
      }
    }
  }

  // ============ MÉTODOS DE UI (DECLARADOS PRIMERO) ============

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
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showAddWorkerDialog() {
    if (!mounted) return;

    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final departmentProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );
    final localProvider = Provider.of<LocalProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar(
        'No tienes permisos para agregar trabajadores',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => WorkerDialog(
        onSave: (worker) => _handleCreateWorker(worker, workerProvider),
        departmentProvider: departmentProvider,
        localProvider: localProvider,
      ),
    );
  }

  Future<bool> _handleCreateWorker(
    Worker worker,
    WorkerProvider provider,
  ) async {
    debugPrint('[WorkersScreen][CREATE] Starting create: ${worker.toJson()}');
    final success = await provider.createWorker(worker);
    debugPrint(
      '[WorkersScreen][CREATE] Finished success=$success error="${provider.error}"',
    );

    if (mounted) {
      if (success) {
        _showSnackBar('✅ Trabajador creado exitosamente');
      } else {
        _showSnackBar('❌ Error: ${provider.error}', isError: true);
      }
    }

    return success;
  }

  void _showEditWorkerDialog(Worker worker) {
    if (!mounted) return;

    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final departmentProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );
    final localProvider = Provider.of<LocalProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar(
        'No tienes permisos para editar trabajadores',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => WorkerDialog(
        worker: worker,
        onSave: (updatedWorker) =>
            _handleUpdateWorker(worker.id, updatedWorker, workerProvider),
        departmentProvider: departmentProvider,
        localProvider: localProvider,
      ),
    );
  }

  Future<bool> _handleUpdateWorker(
    int workerId,
    Worker updatedWorker,
    WorkerProvider provider,
  ) async {
    final worker = updatedWorker.copyWith(id: workerId);
    debugPrint('[WorkersScreen][EDIT] Starting update: ${worker.toJson()}');
    final success = await provider.updateWorker(worker);
    debugPrint(
      '[WorkersScreen][EDIT] Finished success=$success error="${provider.error}"',
    );

    if (mounted) {
      if (success) {
        _showSnackBar('✅ Trabajador actualizado exitosamente');
      } else {
        _showSnackBar('❌ Error: ${provider.error}', isError: true);
      }
    }

    return success;
  }

  void _showDeleteConfirmation(Worker worker) {
    if (!mounted) return;

    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar(
        'No tienes permisos para eliminar trabajadores',
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
            SizedBox(width: 8),
            Text('Eliminar Trabajador'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              radius: 40,
              child: Icon(Icons.person, size: 40, color: Colors.blue[700]),
            ),
            SizedBox(height: 16),
            Text(
              '¿Estás seguro de que deseas eliminar a:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              worker.fullName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Carnet: ${worker.carnetID}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: TextStyle(color: Colors.red[700], fontSize: 13),
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
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => _handleDeleteWorker(worker.id, workerProvider),
            child: Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteWorker(
    int workerId,
    WorkerProvider provider,
  ) async {
    if (!mounted) return;

    Navigator.of(context).pop();

    // Mostrar loading
    _showSnackBar('⏳ Eliminando trabajador...');

    final success = await provider.deleteWorker(workerId);

    if (success) {
      _showSnackBar('🗑️ Trabajador eliminado exitosamente');
    } else {
      _showSnackBar('❌ Error: ${provider.error}', isError: true);
    }
  }

  // Método para sincronizar trabajadores
  Future<void> _syncWorkers(WorkerProvider provider) async {
    final success = await provider.syncWorkers();

    if (success) {
      _showSnackBar('✅ Sincronización completada');
    } else {
      _showSnackBar(
        '❌ Error en sincronización: ${provider.error}',
        isError: true,
      );
    }
  }

  // Método para verificar y forzar reconexión
  // Future<void> _checkAndRetryConnection(WorkerProvider provider) async {
  //   _showSnackBar('🔍 Verificando conexión...');

  //   // Forzar recarga con refresh
  //   await provider.loadWorkers(forceRefresh: true);

  //   if (!provider.isOffline) {
  //     _showSnackBar('✅ Conectado y datos cargados');
  //   } else {
  //     _showSnackBar('❌ Sin conexión. Verifica tu APN empresarial');
  //   }
  // }

  // ============ MÉTODOS DE DETALLES (DECLARADOS ANTES DE USARLOS) ============

  void _showWorkerDetails(Worker worker, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
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
              SizedBox(height: 16),

              // Header con avatar
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          worker.initials,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      worker.fullName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Carnet: ${worker.carnetID}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),
              Divider(color: Colors.grey[200]),

              // Información detallada
              _buildDetailSection(
                icon: Icons.phone,
                label: 'Teléfono',
                value: worker.phone.isNotEmpty ? worker.phone : 'No disponible',
                color: Colors.blue[700]!,
              ),

              if (worker.address.isNotEmpty)
                _buildDetailSection(
                  icon: Icons.home,
                  label: 'Dirección',
                  value: worker.address,
                  color: Colors.green[700]!,
                ),

              if (worker.hasBirthday)
                _buildDetailSection(
                  icon: Icons.cake,
                  label: 'Fecha de Cumpleaños',
                  value: worker.formattedBirthday,
                  color: Colors.pink[700]!,
                ),

              if (worker.hasDepartment)
                _buildClickableDetail(
                  icon: Icons.work,
                  label: 'Departamento',
                  value: worker.department!.name,
                  color: Colors.orange[700]!,
                  onTap: () {
                    Navigator.pop(context);
                    _showDepartmentDetails(worker.department!.id);
                  },
                ),

              if (worker.hasLocal)
                _buildClickableDetail(
                  icon: Icons.business,
                  label: 'Local',
                  value: worker.local!.name,
                  color: Colors.green[700]!,
                  onTap: () {
                    Navigator.pop(context);
                    _showLocalDetails(worker.local!.id);
                  },
                ),

              SizedBox(height: 20),

              // Acciones de contacto (si tiene teléfono)
              if (worker.phone.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
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
                          _makePhoneCall(worker.phone);
                        },
                      ),
                      _buildContactAction(
                        Icons.copy,
                        'Copiar',
                        Colors.orange,
                        () {
                          Navigator.pop(context);
                          _copyPhoneNumber(worker.phone);
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Acciones administrativas
              if (isAdmin) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.edit, size: 18, color: Colors.blue),
                        label: Text(
                          'Editar',
                          style: TextStyle(color: Colors.blue),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditWorkerDialog(worker);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.delete, size: 18, color: Colors.white),
                        label: Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation(worker);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 12),
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

  // Método para cargar detalles desde WorkerLite
  void _showWorkerDetailsFromLite(WorkerLite workerLite, bool isAdmin) async {
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);

    // Mostrar loading

    // Obtener worker completo
    final worker = await workerProvider.getWorkerById(workerLite.id);

    if (worker != null && mounted) {
      _showWorkerDetails(worker, isAdmin);
    } else {
      _showSnackBar('Error al cargar detalles', isError: true);
    }
  }

  // Método para menú de acciones desde WorkerLite
  void _showActionMenuFromLite(WorkerLite workerLite, bool isAdmin) async {
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar('No tienes permisos para esta acción', isError: true);
      return;
    }

    // Cargar worker completo para las acciones
    final worker = await workerProvider.getWorkerById(workerLite.id);

    if (worker != null && mounted) {
      _showActionMenu(worker);
    }
  }

  // Método para menú de acciones
  void _showActionMenu(Worker worker) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditWorkerDialog(worker);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Eliminar'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(worker);
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: Colors.grey),
                title: Text('Cancelar'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============ WIDGETS AUXILIARES ============

  Widget _buildStatusBadge(String text, MaterialColor color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info, size: 12, color: color.shade700),
          SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color.shade700)),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator(WorkerProvider provider) {
    return Container(
      padding: EdgeInsets.all(16),
      alignment: Alignment.center,
      child: provider.isLoadingMore
          ? CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            )
          : Text(
              'Toque para cargar más',
              style: TextStyle(color: Colors.grey[600]),
            ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue[700]),
          SizedBox(height: 16),
          Text(
            'Cargando trabajadores...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WorkerProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            provider.isOffline ? Icons.cloud_off : Icons.error_outline,
            size: 64,
            color: provider.isOffline ? Colors.orange : Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            provider.isOffline
                ? 'Modo offline'
                : 'Error al cargar trabajadores',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              provider.isOffline && provider.hasLocalData
                  ? 'Mostrando ${provider.localDataCount} trabajadores almacenados localmente.'
                  : provider.error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: 24),

          // Mostrar diferentes botones según el estado
          if (provider.isOffline && provider.hasLocalData)
            Column(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.cloud_upload, color: Colors.white),
                  label: Text(
                    'Sincronizar ahora',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () => _syncWorkers(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                SizedBox(height: 12),
                TextButton(
                  onPressed: () => provider.loadWorkers(),
                  child: Text('Continuar en modo offline'),
                ),
              ],
            )
          else
            ElevatedButton.icon(
              icon: Icon(Icons.refresh, color: Colors.white),
              label: Text('Reintentar', style: TextStyle(color: Colors.white)),
              onPressed: () => provider.loadWorkers(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isAdmin, WorkerProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchController.text.isEmpty
                    ? Icons.people_outline
                    : Icons.search_off,
                size: 60,
                color: Colors.blue[300],
              ),
            ),
            SizedBox(height: 24),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay trabajadores registrados'
                  : 'No se encontraron resultados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _searchController.text.isEmpty
                    ? ''
                    : 'No encontramos coincidencias con "${_searchController.text}". Intenta con otros términos.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24),
            if (isAdmin && _searchController.text.isEmpty)
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Agregar Primer Trabajador'),
                onPressed: _showAddWorkerDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            if (_searchController.text.isNotEmpty)
              TextButton.icon(
                icon: Icon(Icons.clear_all),
                label: Text('Limpiar búsqueda'),
                onPressed: () {
                  _searchController.clear();
                  Provider.of<WorkerProvider>(
                    context,
                    listen: false,
                  ).clearSearch();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.blue[700]),
              ),
          ],
        ),
      ),
    );
  }

  // CARD OPTIMIZADA CON WorkerLite
  Widget _buildWorkerCardLite(WorkerLite worker, bool isAdmin) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showWorkerDetailsFromLite(worker, isAdmin),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar optimizado
              CircleAvatar(
                backgroundColor: Colors.blue[100],
                radius: 20,
                child: Text(
                  worker.initials,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              SizedBox(width: 12),

              // Información básica
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      worker.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (worker.hasPhone) ...[
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: Colors.blue[600]),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              worker.phone,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Mostrar Departamento y Local si existen
                  ],
                ),
              ),

              // Menú de acciones optimizado
              if (isAdmin)
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: Colors.blue[700],
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  onPressed: () => _showActionMenuFromLite(worker, isAdmin),
                ),
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
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          SizedBox(width: 12),
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
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableDetail({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            SizedBox(width: 12),
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
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          style: TextStyle(fontSize: 16, color: color),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: color, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDepartmentDetails(int departmentId) async {
    final departmentProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );

    // Cargar departamento completo desde el provider
    final department = await departmentProvider.getDepartmentById(departmentId);

    if (department == null) {
      _showSnackBar('Departamento no encontrado', isError: true);
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.work_outline,
                  size: 40,
                  color: Colors.orange[700],
                ),
              ),
              SizedBox(height: 16),
              Text(
                department.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              if (department.phone.isNotEmpty) ...[
                SizedBox(height: 16),
                _buildDialogDetailItem('Teléfono', department.phone),
              ],
            ],
          ),
        ),
        actions: [
          if (department.phone.isNotEmpty)
            ElevatedButton.icon(
              icon: Icon(Icons.phone, size: 18),
              label: Text('Llamar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _makePhoneCall(department.phone);
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showLocalDetails(int localId) async {
    final localProvider = Provider.of<LocalProvider>(context, listen: false);

    // Cargar local completo desde el provider
    final local = await localProvider.getLocalById(localId);

    if (local == null) {
      _showSnackBar('Local no encontrado', isError: true);
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.business_outlined,
                  size: 40,
                  color: Colors.green[700],
                ),
              ),
              SizedBox(height: 16),
              Text(
                local.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              if (local.phone.isNotEmpty) ...[
                SizedBox(height: 16),
                _buildDialogDetailItem('Teléfono', local.phone),
              ],
            ],
          ),
        ),
        actions: [
          if (local.phone.isNotEmpty)
            ElevatedButton.icon(
              icon: Icon(Icons.phone, size: 18),
              label: Text('Llamar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _makePhoneCall(local.phone);
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
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
            padding: EdgeInsets.all(12),
          ),
        ),
        SizedBox(height: 4),
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

  // ============ MÉTODOS DE CONTACTO ============

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      return;
    }
    _showSnackBar('📞 Llamando a $phoneNumber...');

    try {
      await CallService.directCall(phoneNumber);
    } catch (e) {
      _showSnackBar('❌ Error al iniciar llamada');
    }
  }

  void _copyPhoneNumber(String phoneNumber) {
    Navigator.of(context).pop();

    final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    Clipboard.setData(ClipboardData(text: cleanPhoneNumber))
        .then((value) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Número copiado: $cleanPhoneNumber'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        })
        .catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al copiar el número'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
  }

  // ============ BUILD PRINCIPAL ============

  @override
  Widget build(BuildContext context) {
    final workerProvider = Provider.of<WorkerProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.isAdmin ?? false;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Trabajadores',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          backgroundColor: Colors.blue[700],
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Consumer<WorkerProvider>(
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
                    color: provider.isOffline ? Colors.orange : Colors.white,
                    size: 24,
                  ),
                  onPressed: provider.isOffline
                      ? () => _syncWorkers(provider)
                      : null,
                  tooltip: provider.isOffline
                      ? 'Modo offline - Toque para sincronizar'
                      : 'En línea',
                );
              },
            ),

            if (isAdmin) ...[
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: _showAddWorkerDialog,
                tooltip: 'Agregar Trabajador',
              ),
            ],

            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white, size: 24),
              onPressed: () {
                workerProvider.loadWorkers(forceRefresh: true);
                _showSnackBar('🔄 Actualizando lista...');
              },
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body: _buildBody(workerProvider, isAdmin),
      ),
    );
  }

  Widget _buildBody(WorkerProvider workerProvider, bool isAdmin) {
    if (workerProvider.loading && !workerProvider.hasLoaded) {
      return _buildLoadingIndicator();
    }

    if (workerProvider.hasError && !workerProvider.hasLoaded) {
      return _buildErrorState(workerProvider);
    }

    final visibleWorkers = workerProvider.visibleWorkers;

    return Column(
      children: [
        // Barra de búsqueda
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
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, carnet o teléfono...',
                prefixIcon: Icon(Icons.search, color: Colors.blue),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<WorkerProvider>(
                            context,
                            listen: false,
                          ).clearSearch();
                        },
                        tooltip: 'Limpiar búsqueda',
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),

        // Contador optimizado
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.blue[700]),
                  SizedBox(width: 6),
                  Consumer<WorkerProvider>(
                    builder: (context, provider, child) {
                      return Text(
                        '${visibleWorkers.length} de ${provider.totalWorkers}${provider.isOffline ? ' (offline)' : ''}',
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

              Consumer<WorkerProvider>(
                builder: (context, provider, child) {
                  if (provider.isOffline) {
                    return _buildStatusBadge('Offline', Colors.orange);
                  }
                  if (_searchController.text.isNotEmpty) {
                    return _buildStatusBadge('Búsqueda activa', Colors.blue);
                  }
                  if (provider.hasMore) {
                    return _buildStatusBadge('Más disponible', Colors.green);
                  }
                  return SizedBox.shrink();
                },
              ),
            ],
          ),
        ),

        SizedBox(height: 8),

        // Lista con paginación
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await workerProvider.refreshWorkers();
              _showSnackBar('✅ Lista actualizada');
            },
            color: Colors.blue[700],
            child: visibleWorkers.isEmpty
                ? _buildEmptyState(isAdmin, workerProvider)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        visibleWorkers.length +
                        (workerProvider.hasMore ? 1 : 0),
                    itemExtent: 80, // ALTURA FIJA para mejor rendimiento
                    itemBuilder: (context, index) {
                      // Índice para loading indicator
                      if (index >= visibleWorkers.length) {
                        return _buildLoadMoreIndicator(workerProvider);
                      }

                      final workerLite = visibleWorkers[index];
                      return _buildWorkerCardLite(workerLite, isAdmin);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
