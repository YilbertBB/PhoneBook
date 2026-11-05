import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
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
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add),
      label: const Text(
        'Agregar departamento',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                style: TextStyle(fontSize: 14, color: Colors.grey),
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
      elevation: 0,
      color: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFE5EAF0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _textMuted),
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
                            color: Colors.orange[700],
                          ),
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
                                Icon(
                                  Icons.preview,
                                  size: 16,
                                  color: Colors.orange[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Previsualización (${_previewData.length} registros)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[700],
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

      if (mounted) {
        setState(() {
          _previewData = parsedRows;
        });
      }
    } catch (e) {
      _showSnackBar('Error al leer el archivo: $e', isError: true);
      if (mounted) {
        setState(() {
          _selectedExcelFilePath = null;
          _previewData = [];
        });
      }
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

    if (mounted) {
      setState(() {
        _isProcessingExcel = true;
      });
    }

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
        _showSnackBar(
          '✅ $successCount departamentos importados exitosamente${skippedCount > 0 ? ' ($skippedCount omitidos)' : ''}',
        );
        await departmentProvider.loadDepartments(forceRefresh: true);
      } else {
        _showSnackBar(
          '❌ No se pudo importar ningún departamento',
          isError: true,
        );
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
      final filePath = await ExcelTemplateService.generateDepartmentsTemplate();
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
              child: Text('Eliminar Departamento', softWrap: true, maxLines: 2),
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

              // setState(() {
              //   departmentProvider.loading = true;
              // });

              final success = await departmentProvider.deleteDepartment(
                department.id,
              );

              if (!mounted) return;

              // setState(() {
              //   _isDeleting = false;
              // });

              if (success) {
                _showSnackBar('🗑️ Departamento eliminado exitosamente');
              } else {
                _showSnackBar(
                  '❌ Error: ${departmentProvider.error}',
                  isError: true,
                );
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
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
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Volver',
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Departamentos',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Directorio de departamentos',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          actions: [
            Consumer<DepartmentProvider>(
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
                    provider.isOffline
                        ? Icons.cloud_off_rounded
                        : Icons.cloud_done_rounded,
                    color: provider.isOffline
                        ? Colors.orange.shade200
                        : Colors.white,
                  ),
                  tooltip: provider.isOffline
                      ? 'Modo offline - Sincronizar'
                      : 'En línea',
                  onPressed: provider.isOffline
                      ? () => _syncDepartments(provider)
                      : null,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Actualizar',
              onPressed: () {
                departmentProvider.loadDepartments(forceRefresh: true);
                _showSnackBar('Actualizando lista...');
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Stack(
          children: [
            _buildBody(departmentProvider, localProvider, isAdmin),
            if (departmentProvider.loading && departmentProvider.hasLoaded)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(
                  child: Card(
                    elevation: 8,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: _primary),
                          SizedBox(height: 16),
                          Text(
                            'Actualizando departamentos...',
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
              ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(isAdmin),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildDepartmentsHeader(DepartmentProvider provider, bool isWide) {
    final total = provider.isSearching
        ? provider.departmentLites.length
        : provider.isOffline
        ? provider.localDataCount
        : provider.totalDepartments;

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
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.business_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestión de departamentos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  provider.isOffline
                      ? 'Trabajando con información local'
                      : 'Consulta y administra los departamentos',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isWide) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Departamentos',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDepartmentSearch() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5EAF0)),
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
        builder: (context, value, child) {
          return TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o teléfono...',
              hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: _primary),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        Provider.of<DepartmentProvider>(
                          context,
                          listen: false,
                        ).clearSearch();
                      },
                      icon: const Icon(Icons.close_rounded),
                      color: _textMuted,
                      tooltip: 'Limpiar búsqueda',
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 17,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDepartmentsCounter(
    DepartmentProvider provider,
    int visibleCount,
  ) {
    final total = provider.isSearching
        ? visibleCount
        : provider.isOffline
        ? provider.localDataCount
        : provider.totalDepartments;

    return Row(
      children: [
        const Icon(Icons.business_outlined, size: 18, color: _primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            provider.isSearching
                ? '$visibleCount resultados encontrados'
                : '$total departamentos registrados',
            style: const TextStyle(
              color: _textDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (provider.isOffline)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5E5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF3D7A5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 13, color: _warning),
                SizedBox(width: 5),
                Text(
                  'Offline',
                  style: TextStyle(
                    color: _warning,
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

  Widget _buildBody(
    DepartmentProvider departmentProvider,
    LocalProvider localProvider,
    bool isAdmin,
  ) {
    if (departmentProvider.loading && !departmentProvider.hasLoaded) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _primary),
            SizedBox(height: 16),
            Text(
              'Cargando departamentos...',
              style: TextStyle(color: _textMuted),
            ),
          ],
        ),
      );
    }

    if (departmentProvider.hasError && !departmentProvider.hasLoaded) {
      return _buildDepartmentErrorState(departmentProvider);
    }

    final lites = departmentProvider.departmentLites;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        final horizontalPadding = isWide ? 32.0 : 16.0;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1250),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    22,
                    horizontalPadding,
                    12,
                  ),
                  child: _buildDepartmentsHeader(departmentProvider, isWide),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 8,
                  ),
                  child: _buildDepartmentSearch(),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    12,
                  ),
                  child: _buildDepartmentsCounter(
                    departmentProvider,
                    lites.length,
                  ),
                ),

                Expanded(
                  child: RefreshIndicator(
                    color: _primary,
                    onRefresh: () async {
                      await departmentProvider.loadDepartments(
                        forceRefresh: true,
                      );
                      _showSnackBar('Lista actualizada');
                    },
                    child: lites.isEmpty && !departmentProvider.isLoadingMore
                        ? _buildEmptyState(isAdmin, departmentProvider)
                        : ListView.builder(
                            controller: departmentProvider.scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              4,
                              horizontalPadding,
                              110,
                            ),
                            itemCount:
                                lites.length +
                                (departmentProvider.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= lites.length) {
                                return _buildLoadingIndicator(
                                  departmentProvider,
                                );
                              }

                              return _buildDepartmentCard(
                                lites[index],
                                localProvider,
                                isAdmin,
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
    );
  }

  Widget _buildLoadingIndicator(DepartmentProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: provider.isLoadingMore
            ? const Column(
                children: [
                  SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _primary,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Cargando más departamentos...',
                    style: TextStyle(color: _textMuted, fontSize: 12),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildDepartmentCard(
    DepartmentLite departmentLite,
    LocalProvider localProvider,
    bool isAdmin,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _loadAndShowDepartmentDetails(
            departmentLite.id,
            localProvider,
            isAdmin,
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    departmentLite.initials,
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        departmentLite.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 7),
                      if (departmentLite.hasPhone)
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 15,
                              color: _success,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                departmentLite.phone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: _textMuted,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Sin teléfono registrado',
                              style: TextStyle(color: _textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (isAdmin)
                  PopupMenuButton<String>(
                    tooltip: 'Opciones',
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: _textMuted,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: _primary,
                              size: 19,
                            ),
                            SizedBox(width: 10),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: _danger,
                              size: 19,
                            ),
                            SizedBox(width: 10),
                            Text('Eliminar'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      final department = await _loadDepartmentById(
                        departmentLite.id,
                      );

                      if (!mounted || department == null) return;

                      if (value == 'edit') {
                        _showEditDepartmentDialog(department);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(department);
                      }
                    },
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFADB8C5),
                  ),
              ],
            ),
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
    final isSearching = _searchController.text.trim().isNotEmpty;
    final isOffline = provider.isOffline;

    final icon = isOffline
        ? Icons.cloud_off_rounded
        : isSearching
        ? Icons.search_off_rounded
        : Icons.business_outlined;

    final title = isSearching
        ? 'No se encontraron resultados'
        : isOffline
        ? 'No hay datos locales'
        : 'No hay departamentos registrados';

    final description = isSearching
        ? 'No encontramos coincidencias con "${_searchController.text}". Prueba con otro nombre o teléfono.'
        : isOffline
        ? 'Conéctate a internet para cargar los departamentos.'
        : 'Cuando agregues departamentos aparecerán aquí.';

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 52,
                  color: _primary.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: _textMuted,
                ),
              ),
              const SizedBox(height: 25),
              if (isOffline && !isSearching)
                ElevatedButton.icon(
                  onPressed: () => _syncDepartments(provider),
                  icon: const Icon(Icons.cloud_sync_rounded),
                  label: const Text('Sincronizar ahora'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else if (isAdmin && !isSearching)
                ElevatedButton.icon(
                  onPressed: _showAddDepartmentOptions,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar departamento'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              if (isSearching)
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    provider.clearSearch();
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Limpiar búsqueda'),
                  style: TextButton.styleFrom(foregroundColor: _primary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentErrorState(DepartmentProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              provider.isOffline
                  ? Icons.cloud_off_rounded
                  : Icons.error_outline_rounded,
              size: 64,
              color: _warning,
            ),
            const SizedBox(height: 18),
            Text(
              provider.isOffline
                  ? 'Sin conexión disponible'
                  : 'No se pudieron cargar los departamentos',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              provider.isOffline && provider.hasLocalData
                  ? 'Hay ${provider.localDataCount} departamentos almacenados localmente.'
                  : provider.error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (provider.isOffline && provider.hasLocalData) ...[
              ElevatedButton.icon(
                onPressed: () => _syncDepartments(provider),
                icon: const Icon(Icons.cloud_sync),
                label: const Text('Sincronizar ahora'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () => provider.loadDepartments(),
                child: const Text('Continuar en modo offline'),
              ),
            ] else
              ElevatedButton.icon(
                onPressed: () => provider.loadDepartments(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
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
                        icon: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.orange,
                        ),
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
