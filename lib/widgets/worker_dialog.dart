import 'package:flutter/material.dart';
import '../models/worker.dart';
import '../models/department.dart';
import '../models/local.dart';
import '../providers/department_provider.dart';
import '../providers/local_provider.dart';
import '../utils/validators.dart';
import '../../utils/dialog_error_handler.dart'; // <-- IMPORTAR NUEVO HELPER

class WorkerDialog extends StatefulWidget {
  final Worker? worker;
  final Future<bool> Function(Worker) onSave;
  final DepartmentProvider departmentProvider;
  final LocalProvider localProvider;

  const WorkerDialog({
    super.key,
    this.worker,
    required this.onSave,
    required this.departmentProvider,
    required this.localProvider,
  });

  @override
  WorkerDialogState createState() => WorkerDialogState();
}

class WorkerDialogState extends State<WorkerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _carnetIDController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _fechaCumpleanosController = TextEditingController();

  int? _selectedDepartmentId;
  int? _selectedLocalId;
  bool _isSaving = false; // <-- AGREGAR ESTADO DE GUARDADO

  @override
  void initState() {
    super.initState();
    if (widget.worker != null) {
      _nameController.text = widget.worker!.name;
      _lastNameController.text = widget.worker!.lastName;
      _carnetIDController.text = widget.worker!.carnetID;
      _phoneController.text = widget.worker!.phone;
      _addressController.text = widget.worker!.address;
      _fechaCumpleanosController.text = widget.worker!.fechaCumpleannos;
      _selectedDepartmentId = widget.worker!.departamentoID;
      _selectedLocalId = widget.worker!.localId;
    }
  }

  // Validación personalizada para carnet de identidad
  String? _validateCarnetID(String? value) {
    if (value == null || value.isEmpty) {
      return 'El carnet de identidad es requerido';
    }

    final trimmedValue = value.trim();

    // Debe tener exactamente 11 dígitos
    if (trimmedValue.length != 11) {
      return 'El carnet debe tener exactamente 11 dígitos';
    }

    // Solo números
    final onlyNumbersRegex = RegExp(r'^[0-9]+$');
    if (!onlyNumbersRegex.hasMatch(trimmedValue)) {
      return 'El carnet solo puede contener números';
    }

    // Validar formato básico (primeros dígitos para provincia)
    final provinceCode = int.tryParse(trimmedValue.substring(0, 2));
    if (provinceCode == null || provinceCode < 1 || provinceCode > 16) {
      return 'Los primeros dígitos no corresponden a una provincia válida';
    }

    return null;
  }

  // Validación para fecha de cumpleaños (YYYY-MM-DD)
  String? _validateBirthday(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Opcional
    }

    final trimmedValue = value.trim();

    // Verificar formato YYYY-MM-DD
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(trimmedValue)) {
      return 'Formato inválido. Use YYYY-MM-DD (Ej: 1990-05-15)';
    }

    try {
      final parts = trimmedValue.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      if (year < 1900 || year > DateTime.now().year) {
        return 'Año inválido (1900-${DateTime.now().year})';
      }

      if (month < 1 || month > 12) {
        return 'Mes inválido (1-12)';
      }

      // Validar días según el mes
      final daysInMonth = DateTime(year, month + 1, 0).day;
      if (day < 1 || day > daysInMonth) {
        return 'Día inválido para el mes seleccionado';
      }

      // No permitir fechas futuras
      final birthday = DateTime(year, month, day);
      if (birthday.isAfter(DateTime.now())) {
        return 'La fecha de cumpleaños no puede ser futura';
      }
    } catch (e) {
      debugPrint('[WorkerDialog][VALIDATION] Birthday parse exception: $e');
      return 'Fecha inválida';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final departments = widget.departmentProvider.departments;
    final locals = widget.localProvider.locals;
    final isEditMode = widget.worker != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditMode ? Icons.edit : Icons.person_add,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isEditMode ? 'Editar Trabajador' : 'Agregar Trabajador',
              softWrap: true,
              maxLines: 2,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nombre
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Juan',
                ),
                validator: (value) => Validators.validateName(value, 'Nombre'),
              ),

              const SizedBox(height: 16),

              // Apellido
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Apellido *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Pérez',
                ),
                validator: (value) =>
                    Validators.validateName(value, 'Apellido'),
              ),

              const SizedBox(height: 16),

              // Carnet de Identidad
              TextFormField(
                controller: _carnetIDController,
                decoration: const InputDecoration(
                  labelText: 'Carnet de Identidad *',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                  hintText: '11 dígitos (Ej: 91010112345)',
                ),
                keyboardType: TextInputType.number,
                validator: _validateCarnetID,
              ),

              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono *',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  hintText: 'Ej: +53 55598765',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    Validators.validatePhone(value, required: true),
              ),

              const SizedBox(height: 16),

              // Dirección
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Calle 123, Ciudad',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // Opcional
                  }
                  if (value.length > 200) {
                    return 'La dirección no puede exceder 200 caracteres';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Fecha de Cumpleaños
              TextFormField(
                controller: _fechaCumpleanosController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Cumpleaños',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                  hintText: 'YYYY-MM-DD (Ej: 1990-05-15)',
                ),
                validator: _validateBirthday,
              ),

              const SizedBox(height: 16),

              // Selector de Departamento
              if (departments.isNotEmpty)
                DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue:
                      departments.any((d) => d.id == _selectedDepartmentId)
                      ? _selectedDepartmentId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Departamento (opcional)',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                    hintText: 'Seleccione un departamento',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sin departamento'),
                    ),
                    ...departments.map((dept) {
                      return DropdownMenuItem<int?>(
                        value: dept.id,
                        child: Text(dept.name, overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedDepartmentId = newValue;
                    });
                  },
                ),

              const SizedBox(height: 16),

              // Selector de Local
              if (locals.isNotEmpty)
                DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: locals.any((l) => l.id == _selectedLocalId)
                      ? _selectedLocalId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Local (opcional)',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                    hintText: 'Seleccione un local',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sin local'),
                    ),
                    ...locals.map((local) {
                      return DropdownMenuItem<int?>(
                        value: local.id,
                        child: Text(
                          local.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedLocalId = newValue;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isEditMode ? 'Guardar Cambios' : 'Agregar',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  void _handleSave() async {
    final mode = widget.worker != null ? 'EDIT' : 'CREATE';
    debugPrint('[WorkerDialog][$mode] Save pressed');

    if (!_formKey.currentState!.validate()) {
      debugPrint('[WorkerDialog][$mode] Validation failed');
      return;
    }

    try {
      setState(() => _isSaving = true);
      debugPrint('[WorkerDialog][$mode] Validation passed');
      debugPrint(
        '[WorkerDialog][$mode] Selected departmentId=$_selectedDepartmentId localId=$_selectedLocalId',
      );

      // Obtener objetos completos si existen
      final Department? department = _selectedDepartmentId != null
          ? await widget.departmentProvider.getDepartmentById(
              _selectedDepartmentId!,
            )
          : null;

      final Local? local = _selectedLocalId != null
          ? await widget.localProvider.getLocalById(_selectedLocalId!)
          : null;

      // Crear el Worker con los objetos completos
      final worker = Worker(
        id: widget.worker?.id ?? 0,
        name: _nameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        carnetID: _carnetIDController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        fechaCumpleannos: _fechaCumpleanosController.text.trim(),
        department: department,
        local: local,
        cumpleannoId: null,
      );

      debugPrint('[WorkerDialog][$mode] Worker built: ${worker.toJson()}');
      debugPrint('[WorkerDialog][$mode] DTO: ${worker.toCreateDto()}');

      // Intentar guardar
      final success = await widget.onSave(worker);
      debugPrint('[WorkerDialog][$mode] onSave returned success=$success');

      if (success && mounted) {
        Navigator.of(context).pop();

        DialogErrorHandler.showSuccessSnackbar(
          context: context,
          message: widget.worker != null
              ? '✅ Trabajador actualizado exitosamente'
              : '✅ Trabajador creado exitosamente',
        );
      }

      if (!success) {
        debugPrint('[WorkerDialog][$mode] Save failed, dialog remains open');
      }

      // Si llega aquí, fue exitoso
    } catch (e) {
      // Manejar errores específicos de trabajadores
      debugPrint('[WorkerDialog][$mode] Exception: $e');
      String errorTitle =
          'Error al ${widget.worker != null ? 'actualizar' : 'crear'} trabajador';
      // String friendlyError = _getWorkerSpecificErrorMessage(e.toString());
      if (mounted) {
        DialogErrorHandler.showErrorDialog(
          context: context,
          title: errorTitle,
          technicalError: e.toString(),
          showRetryButton: true,
          onRetry: () => _handleSave(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // String _getWorkerSpecificErrorMessage(String technicalError) {
  //   final error = technicalError.toLowerCase();

  //   if (error.contains('carnet') && error.contains('duplicad')) {
  //     return '⚠️ El número de carnet ya está registrado. Use uno diferente.';
  //   }

  //   if (error.contains('phone') && error.contains('duplicad')) {
  //     return '📱 El número de teléfono ya está registrado.';
  //   }

  //   if (error.contains('email') && error.contains('duplicad')) {
  //     return '📧 El correo electrónico ya está registrado.';
  //   }

  //   if (error.contains('birthday') || error.contains('cumpleaños') || error.contains('fecha')) {
  //     return '📅 La fecha de cumpleaños no es válida.';
  //   }

  //   return DialogErrorHandler.getFriendlyErrorMessage(technicalError);
  // }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _carnetIDController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _fechaCumpleanosController.dispose();
    super.dispose();
  }
}
