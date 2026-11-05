import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/department.dart';
import '../../models/local.dart';
import '../../models/worker.dart';
import '../../models/worker_lite.dart';
import '../../providers/auth_provider.dart';
import '../../providers/department_provider.dart';
import '../../providers/local_provider.dart';
import '../../providers/worker_provider.dart';
import '../../services/call_service.dart';
import '../../utils/excel_import_service.dart';
import '../../utils/excel_template_service.dart';
import '../../widgets/worker_dialog.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  WorkersScreenState createState() => WorkersScreenState();
}

class WorkersScreenState extends State<WorkersScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Filtro por departamento/área
  int? _selectedDepartmentId;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  // Variables para importación Excel
  String? _selectedExcelFilePath;
  List<Map<String, dynamic>> _previewData = [];
  bool _isProcessingExcel = false;

  // ============ ESTILO VISUAL ============
  static const Color _primary = Color(0xFF1769AA);
  static const Color _primaryDark = Color(0xFF104C80);
  static const Color _background = Color(0xFFF4F7FB);
  static const Color _surface = Colors.white;
  static const Color _textDark = Color(0xFF243447);
  static const Color _textMuted = Color(0xFF718096);
  static const Color _success = Color(0xFF159B72);
  static const Color _warning = Color(0xFFE49A27);
  static const Color _danger = Color(0xFFD94B4B);

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

    if (workerProvider.isLoadingMore || !workerProvider.hasMore) {
      return;
    }

    final success = await workerProvider.loadMoreWorkers();

    if (success && mounted) {
      if (workerProvider.hasMore) {
        _showSnackBar('Cargando más trabajadores...');
      }
    }
  }

  // ============ MÉTODOS DE UI ============

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    final messenger = _scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.showSnackBar(
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

  void _safeDialogSetState(StateSetter setState, VoidCallback update) {
    try {
      setState(update);
    } catch (_) {}
  }

  // ============ MÉTODOS DE AGREGAR TRABAJADORES ============

  // Botón flotante con opción de importar Excel
  Widget _buildFloatingActionButton(bool isAdmin) {
    if (!isAdmin) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: _showAddWorkerOptions,
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      elevation: 5,
      icon: const Icon(Icons.person_add_alt_1_rounded),
      label: const Text(
        'Agregar trabajador',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  // Mostrar opciones de agregar
  void _showAddWorkerOptions() {
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
                'Agregar Trabajadores',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                'Selecciona cómo deseas agregar',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              // Opción: Agregar manual
              _buildOptionCard(
                icon: Icons.person_add,
                title: 'Agregar Manual',
                subtitle: 'Ingresar datos uno por uno',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _showAddWorkerDialog();
                },
              ),

              const SizedBox(height: 12),

              // Opción: Importar Excel
              _buildOptionCard(
                icon: Icons.table_chart,
                title: 'Importar desde Excel',
                subtitle: 'Cargar múltiples trabajadores desde archivo .xlsx',
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  color: color.withValues(alpha: 0.1),
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
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                          Icon(
                            Icons.file_download,
                            size: 18,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Descargar plantilla de ejemplo',
                            style: TextStyle(
                              color: Colors.blue[700],
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
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.preview,
                                  size: 16,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Previsualización (${_previewData.length} registros)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                itemCount: _previewData.length > 5
                                    ? 5
                                    : _previewData.length,
                                itemBuilder: (context, index) {
                                  final item = _previewData[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      '${index + 1}. ${item['nombre'] ?? 'Sin nombre'} - ${item['carnet'] ?? 'Sin carnet'}',
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
                  onPressed: _isProcessingExcel
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed:
                      _isProcessingExcel || _selectedExcelFilePath == null
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
        if (!storagePermission.isGranted &&
            !await Permission.manageExternalStorage.isGranted) {
          _showSnackBar(
            'Se necesitan permisos de almacenamiento para importar archivos.',
            isError: true,
          );
          return;
        }
      }

      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null) {
        _safeDialogSetState(setState, () {
          _selectedExcelFilePath = result.files.single.path;
          _previewData = [];
        });

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
        requiredColumns: [
          'nombre',
          'apellido',
          'carnet',
          'telefono',
          'direccion',
          'departamento',
          'local',
          'fechacumpleannos',
        ],
      );

      if (parsedRows.isEmpty) {
        throw Exception('No se encontraron registros válidos en el archivo.');
      }

      _safeDialogSetState(setState, () {
        _previewData = parsedRows;
      });
    } catch (e) {
      _showSnackBar('Error al leer el archivo: $e', isError: true);
      _safeDialogSetState(setState, () {
        _selectedExcelFilePath = null;
        _previewData = [];
      });
    }
  }

  // Procesar archivo Excel
  Future<void> _processExcelFile(
    BuildContext context,
    StateSetter setState,
  ) async {
    if (_selectedExcelFilePath == null || _previewData.isEmpty) {
      _showSnackBar('No hay datos para importar', isError: true);
      return;
    }

    _safeDialogSetState(setState, () {
      _isProcessingExcel = true;
    });

    try {
      final workerProvider = Provider.of<WorkerProvider>(
        context,
        listen: false,
      );
      final departmentProvider = Provider.of<DepartmentProvider>(
        context,
        listen: false,
      );
      final localProvider = Provider.of<LocalProvider>(context, listen: false);

      int successCount = 0;
      int skippedCount = 0;

      for (final data in _previewData) {
        try {
          final rawName = data['nombre']?.toString().trim() ?? '';
          final rawLastName = data['apellido']?.toString().trim() ?? '';
          final carnetID = data['carnet']?.toString().trim() ?? '';
          final phone = data['telefono']?.toString().trim() ?? '';
          final address = data['direccion']?.toString().trim() ?? '';
          final birthday = data['fechacumpleannos']?.toString().trim() ?? '';

          final nameParts = rawName.split(RegExp(r'\s+'));
          final firstName = nameParts.isNotEmpty ? nameParts.first : '';
          final lastName = nameParts.length > 1
              ? nameParts.sublist(1).join(' ')
              : rawLastName;

          Department? department;
          if (data['departamento'] != null &&
              data['departamento'].toString().isNotEmpty) {
            final deptName = data['departamento'].toString().trim();
            try {
              final dept = departmentProvider.departments.firstWhere(
                (d) => d.name.toLowerCase() == deptName.toLowerCase(),
              );
              department = Department(
                id: dept.id,
                name: dept.name,
                phone: dept.phone,
              );
            } catch (_) {}
          }

          Local? local;
          if (data['local'] != null && data['local'].toString().isNotEmpty) {
            final localName = data['local'].toString().trim();
            try {
              final loc = localProvider.locals.firstWhere(
                (l) => l.name.toLowerCase() == localName.toLowerCase(),
              );
              local = Local(id: loc.id, name: loc.name, phone: loc.phone);
            } catch (_) {}
          }

          if (firstName.isEmpty || carnetID.isEmpty) {
            skippedCount++;
            continue;
          }

          final success = await workerProvider.createWorker(
            Worker(
              id: 0,
              name: firstName,
              lastName: lastName,
              carnetID: carnetID,
              phone: phone,
              address: address,
              fechaCumpleannos: birthday,
              department: department,
              local: local,
              cumpleannoId: null,
            ),
          );

          if (success) {
            successCount++;
          } else {
            skippedCount++;
          }
        } catch (_) {
          skippedCount++;
        }
      }

      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }

      if (successCount > 0) {
        _showSnackBar(
          '✅ $successCount trabajadores importados exitosamente${skippedCount > 0 ? ' ($skippedCount omitidos)' : ''}',
        );
        await workerProvider.refreshWorkers();
      } else {
        _showSnackBar(
          '❌ No se pudo importar ningún trabajador${skippedCount > 0 ? ' ($skippedCount omitidos)' : ''}',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      _showSnackBar('❌ Error al importar: ${e.toString()}', isError: true);
    } finally {
      _safeDialogSetState(setState, () {
        _isProcessingExcel = false;
      });
    }
  }

  // Descargar plantilla de ejemplo
  Future<void> _downloadExcelTemplate() async {
    try {
      if (Platform.isAndroid) {
        final storagePermission = await Permission.storage.request();
        if (!storagePermission.isGranted &&
            !await Permission.manageExternalStorage.isGranted) {
          _showSnackBar(
            'Se necesitan permisos de almacenamiento para descargar archivos.',
            isError: true,
          );
          return;
        }
      }

      _showSnackBar('📥 Generando plantilla...');
      final filePath = await ExcelTemplateService.generateWorkersTemplate();
      if (!mounted) return;

      if (filePath != null && filePath.isNotEmpty) {
        _showSnackBar('✅ Plantilla lista en: $filePath');
      } else {
        _showSnackBar('❌ No se pudo generar la plantilla', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        '❌ Error al generar plantilla: ${e.toString()}',
        isError: true,
      );
    }
  }

  // ============ MÉTODOS DE MANEJO DE TRABAJADORES ============

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
            const SizedBox(width: 8),
            Expanded(child: const Text('Eliminar Trabajador')),
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
            const SizedBox(height: 16),
            Text(
              '¿Estás seguro de que deseas eliminar a:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              worker.fullName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Carnet: ${worker.carnetID}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
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
            onPressed: () => _handleDeleteWorker(worker.id, workerProvider),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
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

    _showSnackBar('⏳ Eliminando trabajador...');

    final success = await provider.deleteWorker(workerId);

    if (success) {
      _showSnackBar('🗑️ Trabajador eliminado exitosamente');
    } else {
      _showSnackBar('❌ Error: ${provider.error}', isError: true);
    }
  }

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

  // ============ MÉTODOS DE DETALLES ============

  void _showWorkerDetails(Worker worker, bool isAdmin) {
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
                    const SizedBox(height: 16),
                    Text(
                      worker.fullName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Carnet: ${worker.carnetID}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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

              const SizedBox(height: 20),

              // Acciones de contacto
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
                const SizedBox(height: 16),
              ],

              // Acciones administrativas
              if (isAdmin) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.blue,
                        ),
                        label: const Text(
                          'Editar',
                          style: TextStyle(color: Colors.blue),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditWorkerDialog(worker);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation(worker);
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

  void _showWorkerDetailsFromLite(WorkerLite workerLite, bool isAdmin) async {
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);

    final worker = await workerProvider.getWorkerById(workerLite.id);

    if (worker != null && mounted) {
      _showWorkerDetails(worker, isAdmin);
    } else {
      _showSnackBar('Error al cargar detalles', isError: true);
    }
  }

  void _showActionMenuFromLite(WorkerLite workerLite, bool isAdmin) async {
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar('No tienes permisos para esta acción', isError: true);
      return;
    }

    final worker = await workerProvider.getWorkerById(workerLite.id);

    if (worker != null && mounted) {
      _showActionMenu(worker);
    }
  }

  void _showActionMenu(Worker worker) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditWorkerDialog(worker);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(worker);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.grey),
                title: const Text('Cancelar'),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info, size: 12, color: color.shade700),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color.shade700)),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator(WorkerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 8),
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
          const SizedBox(height: 24),

          if (provider.isOffline && provider.hasLocalData)
            Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload, color: Colors.white),
                  label: const Text(
                    'Sincronizar ahora',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () => _syncWorkers(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => provider.loadWorkers(),
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
              onPressed: () => provider.loadWorkers(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
            const SizedBox(height: 24),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 24),
            if (isAdmin && _searchController.text.isEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Agregar Primer Trabajador',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: _showAddWorkerOptions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            if (_searchController.text.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar búsqueda'),
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

  Widget _buildWorkerCardLite(WorkerLite worker, bool isAdmin) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _showWorkerDetailsFromLite(worker, isAdmin),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8EDF4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  worker.initials,
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(width: 13),

              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (worker.hasPhone) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 13,
                            color: _primary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              worker.phone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Acciones
              if (isAdmin)
                IconButton(
                  onPressed: () => _showActionMenuFromLite(worker, isAdmin),
                  icon: const Icon(Icons.more_vert_rounded, color: _textMuted),
                  tooltip: 'Acciones',
                  visualDensity: VisualDensity.compact,
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFABB6C5),
                  size: 23,
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
              const SizedBox(height: 16),
              Text(
                department.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (department.phone.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildDialogDetailItem('Teléfono', department.phone),
              ],
            ],
          ),
        ),
        actions: [
          if (department.phone.isNotEmpty)
            ElevatedButton.icon(
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Llamar'),
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
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showLocalDetails(int localId) async {
    final localProvider = Provider.of<LocalProvider>(context, listen: false);

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
              const SizedBox(height: 16),
              Text(
                local.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (local.phone.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildDialogDetailItem('Teléfono', local.phone),
              ],
            ],
          ),
        ),
        actions: [
          if (local.phone.isNotEmpty)
            ElevatedButton.icon(
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Llamar'),
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
            child: const Text('Cerrar'),
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
              style: const TextStyle(fontWeight: FontWeight.bold),
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

  // ============ BUILD PRINCIPAL ============

  @override
  Widget build(BuildContext context) {
    final workerProvider = Provider.of<WorkerProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.isAdmin ?? false;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Volver',
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trabajadores',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'Directorio de personal',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          actions: [
            Consumer<WorkerProvider>(
              builder: (context, provider, child) {
                if (provider.syncing) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }

                return IconButton(
                  icon: Icon(
                    provider.isOffline ? Icons.cloud_off : Icons.cloud_done,
                    color: provider.isOffline
                        ? const Color(0xFFFFC66D)
                        : Colors.white,
                  ),
                  tooltip: provider.isOffline
                      ? 'Modo offline - Sincronizar'
                      : 'Conectado',
                  onPressed: provider.isOffline
                      ? () => _syncWorkers(provider)
                      : null,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar trabajadores',
              onPressed: () {
                workerProvider.loadWorkers(forceRefresh: true);
                _showSnackBar('Actualizando lista...');
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Stack(
          children: [
            _buildBody(workerProvider, isAdmin),
            if (workerProvider.loading && workerProvider.hasLoaded) ...[
              const ModalBarrier(dismissible: false, color: Color(0x66000000)),
              const Center(
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: _primary),
                        SizedBox(height: 16),
                        Text(
                          'Actualizando lista...',
                          style: TextStyle(
                            color: _textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(isAdmin),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return Container(
          color: _background,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1250),
              child: Column(
                children: [
                  // Encabezado de la sección
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 28 : 18,
                      22,
                      isWide ? 28 : 18,
                      16,
                    ),
                    child: _buildWorkersHeader(
                      workerProvider,
                      isAdmin,
                      visibleWorkers.length,
                    ),
                  ),

                  // Buscador
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 28 : 18),
                    child: _buildSearchField(),
                  ),

                  const SizedBox(height: 14),

                  // Filtros por departamento
                  Consumer<DepartmentProvider>(
                    builder: (context, departmentProvider, _) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 28 : 18,
                        ),
                        child: _buildDepartmentFilter(departmentProvider),
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // Contador y estado
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 28 : 18),
                    child: _buildWorkersCounter(
                      workerProvider,
                      visibleWorkers.length,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Listado
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await workerProvider.refreshWorkers();
                        _showSnackBar('Lista actualizada');
                      },
                      color: _primary,
                      child: visibleWorkers.isEmpty
                          ? _buildEmptyState(isAdmin, workerProvider)
                          : ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.fromLTRB(
                                isWide ? 28 : 18,
                                6,
                                isWide ? 28 : 18,
                                100,
                              ),
                              itemCount:
                                  visibleWorkers.length +
                                  (workerProvider.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= visibleWorkers.length) {
                                  return _buildLoadMoreIndicator(
                                    workerProvider,
                                  );
                                }

                                final worker = visibleWorkers[index];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildWorkerCardLite(worker, isAdmin),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkersHeader(
    WorkerProvider provider,
    bool isAdmin,
    int visibleCount,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;

          return Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestión de personal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      provider.isOffline
                          ? 'Consulta de datos almacenados localmente'
                          : 'Consulta y administra el directorio de trabajadores',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$visibleCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Visibles',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _searchController,
        builder: (context, value, _) {
          return TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, carnet o teléfono...',
              hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: _primary,
                size: 23,
              ),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: _textMuted),
                      onPressed: () {
                        _searchController.clear();
                        Provider.of<WorkerProvider>(
                          context,
                          listen: false,
                        ).clearSearch();
                      },
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 17,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkersCounter(WorkerProvider provider, int visibleCount) {
    String statusText = '';
    Color statusColor = _success;
    IconData statusIcon = Icons.check_circle_outline;

    if (provider.isOffline) {
      statusText = 'Sin conexión';
      statusColor = _warning;
      statusIcon = Icons.cloud_off;
    } else if (_searchController.text.isNotEmpty) {
      statusText = 'Búsqueda activa';
      statusColor = _primary;
      statusIcon = Icons.search;
    } else if (provider.hasMore) {
      statusText = 'Más disponibles';
      statusColor = _success;
      statusIcon = Icons.more_horiz;
    }

    return Row(
      children: [
        const Icon(Icons.people_alt_outlined, color: _primary, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$visibleCount de ${provider.totalWorkers} trabajadores',
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        if (statusText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 13),
                const SizedBox(width: 5),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDepartmentFilter(DepartmentProvider departmentProvider) {
    final departments = departmentProvider.departments;

    if (departments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 9),
          child: Row(
            children: [
              Icon(Icons.filter_list_rounded, size: 17, color: _textMuted),
              SizedBox(width: 7),
              Text(
                'Filtrar por departamento',
                style: TextStyle(
                  color: _textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 39,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildDepartmentChip(
                label: 'Todos',
                selected: _selectedDepartmentId == null,
                onSelected: () {
                  setState(() => _selectedDepartmentId = null);
                  Provider.of<WorkerProvider>(
                    context,
                    listen: false,
                  ).filterByDepartment(null);
                },
              ),
              ...departments.map((dept) {
                final isSelected = _selectedDepartmentId == dept.id;

                return _buildDepartmentChip(
                  label: dept.name,
                  selected: isSelected,
                  onSelected: () {
                    final newValue = isSelected ? null : dept.id;

                    setState(() => _selectedDepartmentId = newValue);

                    Provider.of<WorkerProvider>(
                      context,
                      listen: false,
                    ).filterByDepartment(newValue);
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? _primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? _primary : const Color(0xFFE0E6EF),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : _textMuted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
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
