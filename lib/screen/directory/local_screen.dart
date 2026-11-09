import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../models/local.dart';
import '../../models/local_lite.dart';
import '../../providers/auth_provider.dart';
import '../../providers/local_provider.dart';
import '../../services/call_service.dart';
import '../../utils/debouncer.dart';
import '../../utils/excel_import_service.dart';
import '../../utils/excel_template_service.dart';
import '../../widgets/local_dialog.dart';

class LocalScreen extends StatefulWidget {
  const LocalScreen({super.key});

  @override
  LocalScreenState createState() => LocalScreenState();
}

class LocalScreenState extends State<LocalScreen> {
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
  static const Color _warning = Color.fromRGBO(153, 155, 21, 1);
  static const Color _danger = Color(0xFFD94B4B);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localProvider = Provider.of<LocalProvider>(context, listen: false);
      localProvider.clearSearch();
      localProvider.loadInitialData();
    });
  }

  void _onSearchChanged() {
    _searchDebouncer.run(() {
      if (mounted) {
        final query = _searchController.text;
        final localProvider = Provider.of<LocalProvider>(
          context,
          listen: false,
        );

        setState(() {});

        if (query.isEmpty) {
          localProvider.clearSearch();
        } else {
          localProvider.searchLocals(query);
        }
      }
    });
  }

  // ============ MÉTODOS DE AGREGAR LOCALES ============

  // Botón flotante con opción de importar Excel
  Widget _buildFloatingActionButton(bool isAdmin) {
    if (!isAdmin) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: _showAddLocalOptions,
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add_business_rounded),
      label: const Text(
        'Agregar local',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  // Mostrar opciones de agregar
  void _showAddLocalOptions() {
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
                'Agregar Locales',
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
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _showAddLocalDialog();
                },
              ),

              const SizedBox(height: 12),

              // Opción: Importar Excel
              _buildOptionCard(
                icon: Icons.table_chart,
                title: 'Importar desde Excel',
                subtitle: 'Cargar múltiples locales desde archivo .xlsx',
                color: Colors.blue,
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
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Descargar plantilla de ejemplo',
                            style: TextStyle(
                              color: Colors.green[700],
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
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.preview,
                                  size: 16,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Previsualización (${_previewData.length} registros)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
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
      final localProvider = Provider.of<LocalProvider>(context, listen: false);

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

          final success = await localProvider.createLocal(name, phone);
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
          '✅ $successCount locales importados exitosamente${skippedCount > 0 ? ' ($skippedCount omitidos)' : ''}',
        );
        await localProvider.loadLocals(forceRefresh: true);
      } else {
        _showSnackBar('❌ No se pudo importar ningún local', isError: true);
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
      final filePath = await ExcelTemplateService.generateLocalsTemplate();
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

  // ============ MÉTODOS DE MANEJO DE LOCALES ============

  void _showAddLocalDialog() {
    final localProvider = Provider.of<LocalProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar('No tienes permisos para agregar locales', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => LocalDialog(
        onSave: (local) async {
          final success = await localProvider.createLocal(
            local.name,
            local.phone,
          );
          if (success) {
            _showSnackBar('✅ Local creado exitosamente');
          } else {
            _showSnackBar('❌ Error: ${localProvider.error}', isError: true);
          }
        },
      ),
    );
  }

  void _showEditLocalDialog(Local local) {
    final localProvider = Provider.of<LocalProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar('No tienes permisos para editar locales', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => LocalDialog(
        local: local,
        onSave: (updatedLocal) async {
          final success = await localProvider.updateLocal(
            updatedLocal.copyWith(id: local.id),
          );
          if (success) {
            _showSnackBar('✅ Local actualizado exitosamente');
          } else {
            _showSnackBar('❌ Error: ${localProvider.error}', isError: true);
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(Local local) {
    final localProvider = Provider.of<LocalProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar('No tienes permisos para eliminar locales', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.green[700]),
            const SizedBox(width: 8),
            const Flexible(
              child: Text('Eliminar Local', softWrap: true, maxLines: 2),
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
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.business, size: 40, color: Colors.green[700]),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Estás seguro de que deseas eliminar:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              local.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            if (local.phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '📞 ${local.phone}',
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

              final success = await localProvider.deleteLocal(local.id);
              if (success) {
                _showSnackBar('🗑️ Local eliminado exitosamente');
              } else {
                _showSnackBar('❌ Error: ${localProvider.error}', isError: true);
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

  Future<void> _syncLocals(LocalProvider provider) async {
    final success = await provider.syncLocals();

    if (success) {
      _showSnackBar('✅ Locales sincronizados');
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
    final localProvider = Provider.of<LocalProvider>(context);
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
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Locales',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Directorio de sedes y oficinas',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            Consumer<LocalProvider>(
              builder: (context, provider, child) {
                return IconButton(
                  tooltip: provider.isOffline
                      ? 'Modo offline - Sincronizar'
                      : 'En línea',
                  onPressed: provider.syncing
                      ? null
                      : provider.isOffline
                      ? () => _syncLocals(provider)
                      : null,
                  icon: provider.syncing
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          provider.isOffline
                              ? Icons.cloud_off
                              : Icons.cloud_done,
                          color: Colors.white,
                        ),
                );
              },
            ),
            IconButton(
              tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                localProvider.loadLocals(forceRefresh: true);
                _showSnackBar('Actualizando lista...');
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Stack(
          children: [
            _buildBody(localProvider, isAdmin),
            if (localProvider.loading && localProvider.hasLoaded)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(
                  child: Card(
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
                            'Actualizando locales...',
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

  Widget _buildBody(LocalProvider localProvider, bool isAdmin) {
    if (localProvider.loading && !localProvider.hasLoaded) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _primary),
            SizedBox(height: 16),
            Text(
              'Cargando locales...',
              style: TextStyle(color: _textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (localProvider.hasError && !localProvider.hasLoaded) {
      return _buildLocalErrorState(localProvider);
    }

    final lites = localProvider.localLites;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;
        final horizontalPadding = isWide ? 28.0 : 16.0;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1250),
            child: Column(
              children: [
                _buildLocalsHeader(localProvider, isWide, horizontalPadding),

                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    20,
                    horizontalPadding,
                    0,
                  ),
                  child: _buildLocalSearchField(),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    12,
                  ),
                  child: _buildLocalsCounter(localProvider, lites.length),
                ),

                Expanded(
                  child: RefreshIndicator(
                    color: _primary,
                    onRefresh: () async {
                      await localProvider.loadLocals(forceRefresh: true);
                      _showSnackBar('Lista actualizada');
                    },
                    child: lites.isEmpty && !localProvider.isLoadingMore
                        ? _buildEmptyState(isAdmin, localProvider)
                        : ListView.builder(
                            controller: localProvider.scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              4,
                              horizontalPadding,
                              110,
                            ),
                            itemCount:
                                lites.length + (localProvider.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= lites.length) {
                                return _buildLoadingIndicator(localProvider);
                              }

                              return _buildLocalCard(lites[index], isAdmin);
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

  Widget _buildLocalsHeader(
    LocalProvider provider,
    bool isWide,
    double horizontalPadding,
  ) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 0),
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
            blurRadius: 16,
            offset: const Offset(0, 7),
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
              borderRadius: BorderRadius.circular(15),
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
                Text(
                  'Gestión de locales',
                  style: TextStyle(
                    fontSize: isWide ? 21 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Consulta y administra las sedes registradas.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          if (isWide)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '${provider.isSearching ? provider.localLites.length : provider.totalLocals}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Locales',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocalSearchField() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _searchController,
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o teléfono...',
              hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: _primary),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Limpiar búsqueda',
                      icon: const Icon(Icons.close, color: _textMuted),
                      onPressed: () {
                        _searchController.clear();
                        Provider.of<LocalProvider>(
                          context,
                          listen: false,
                        ).clearSearch();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: _surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 17,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE6ECF3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _primary, width: 1.4),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocalsCounter(LocalProvider provider, int visibleCount) {
    final totalCount = provider.isSearching
        ? visibleCount
        : provider.isOffline
        ? provider.localDataCount
        : provider.totalLocals;

    return Row(
      children: [
        const Icon(Icons.business_outlined, size: 18, color: _primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            provider.isSearching
                ? '$visibleCount resultados encontrados'
                : '$totalCount locales registrados',
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
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD9A3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 14, color: Color(0xFFB7791F)),
                SizedBox(width: 5),
                Text(
                  'Offline',
                  style: TextStyle(
                    color: Color(0xFF9A6700),
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

  Widget _buildLoadingIndicator(LocalProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: provider.isLoadingMore
            ? const SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _primary,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildLocalCard(LocalLite localLite, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE9EEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _loadAndShowLocalDetails(localLite.id, isAdmin),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    localLite.initials,
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localLite.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 7),
                      if (localLite.hasPhone)
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 15,
                              color: _textMuted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                localLite.phone,
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
                              Icons.phone_disabled_outlined,
                              size: 15,
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
                    tooltip: 'Opciones del local',
                    icon: const Icon(Icons.more_vert, color: _textMuted),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
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
                      PopupMenuItem<String>(
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
                      final local = await _loadLocalById(localLite.id);
                      if (local != null && mounted) {
                        if (value == 'edit') {
                          _showEditLocalDialog(local);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(local);
                        }
                      }
                    },
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.chevron_right, color: Color(0xFFB0BAC7)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Local?> _loadLocalById(int id) async {
    final localProvider = Provider.of<LocalProvider>(context, listen: false);
    return await localProvider.getLocalById(id);
  }

  Future<void> _loadAndShowLocalDetails(int localId, bool isAdmin) async {
    final local = await _loadLocalById(localId);
    if (local != null && mounted) {
      _showLocalDetails(local, isAdmin);
    }
  }

  Widget _buildLocalErrorState(LocalProvider provider) {
    final hasOfflineData = provider.isOffline && provider.hasLocalData;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: (hasOfflineData ? _warning : _danger).withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasOfflineData
                      ? Icons.cloud_off_rounded
                      : Icons.error_outline_rounded,
                  color: hasOfflineData ? _warning : _danger,
                  size: 44,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                hasOfflineData
                    ? 'Modo sin conexión'
                    : 'No se pudieron cargar los locales',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                hasOfflineData
                    ? 'Hay ${provider.localDataCount} locales guardados en este dispositivo.'
                    : provider.error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              if (hasOfflineData) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _syncLocals(provider),
                    icon: const Icon(Icons.cloud_sync),
                    label: const Text('Sincronizar ahora'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => provider.loadLocals(),
                  child: const Text(
                    'Continuar en modo offline',
                    style: TextStyle(color: _primary),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => provider.loadLocals(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isAdmin, LocalProvider provider) {
    final isSearching = _searchController.text.trim().isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 56),
            child: Center(
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
                      isSearching
                          ? Icons.search_off_rounded
                          : provider.isOffline
                          ? Icons.cloud_off_rounded
                          : Icons.business_outlined,
                      size: 52,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    isSearching
                        ? 'No se encontraron resultados'
                        : provider.isOffline
                        ? 'No hay locales disponibles'
                        : 'Aún no hay locales registrados',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      isSearching
                          ? 'No encontramos coincidencias con "${_searchController.text}". Prueba con otro nombre o teléfono.'
                          : provider.isOffline
                          ? 'Conéctate a internet para cargar los locales o intenta sincronizar los datos.'
                          : 'Cuando registres un local, aparecerá aquí para que puedas consultarlo y administrarlo.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _textMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isSearching)
                    OutlinedButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        provider.clearSearch();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpiar búsqueda'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: _primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else if (provider.isOffline)
                    ElevatedButton.icon(
                      onPressed: () => _syncLocals(provider),
                      icon: const Icon(Icons.cloud_sync),
                      label: const Text('Sincronizar locales'),
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
                    )
                  else if (isAdmin)
                    ElevatedButton.icon(
                      onPressed: _showAddLocalOptions,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar primer local'),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLocalDetails(Local local, bool isAdmin) {
    const primary = Color(0xFF1769AA);
    const primaryDark = Color(0xFF104C80);
    const textDark = Color(0xFF243447);
    const textMuted = Color(0xFF718096);
    const border = Color(0xFFE4EAF2);
    const background = Color(0xFFF4F7FB);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de arrastre
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E0EA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado del local
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [primary, primaryDark],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.22),
                                    blurRadius: 18,
                                    offset: const Offset(0, 7),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                local.name.length >= 2
                                    ? local.name.substring(0, 2).toUpperCase()
                                    : local.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              local.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF3FC),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.business_outlined,
                                    size: 15,
                                    color: primary,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Local',
                                    style: TextStyle(
                                      color: primaryDark,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Información
                      const Row(
                        children: [
                          Icon(
                            Icons.contact_page_outlined,
                            color: primary,
                            size: 19,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Información del local',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _buildDetailSection(
                        icon: Icons.phone_outlined,
                        label: 'Teléfono',
                        value: local.phone.isNotEmpty
                            ? local.phone
                            : 'No disponible',
                        color: primary,
                      ),

                      const SizedBox(height: 20),

                      // Contacto rápido
                      if (local.phone.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contacto rápido',
                                style: TextStyle(
                                  color: textDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildContactAction(
                                      Icons.call_outlined,
                                      'Llamar',
                                      const Color(0xFF159B72),
                                      () {
                                        Navigator.pop(sheetContext);
                                        _makePhoneCall(local.phone);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildContactAction(
                                      Icons.copy_rounded,
                                      'Copiar',
                                      const Color(0xFFE49A27),
                                      () {
                                        Navigator.pop(sheetContext);
                                        _copyPhoneNumber(local.phone);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Administración
                      if (isAdmin) ...[
                        const Divider(color: border, height: 25),
                        const Text(
                          'Administración',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Editar'),
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                  _showEditLocalDialog(local);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primary,
                                  side: const BorderSide(color: primary),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                label: const Text('Eliminar'),
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                  _showDeleteConfirmation(local);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD94B4B),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
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
