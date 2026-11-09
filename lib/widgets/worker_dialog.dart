import 'package:flutter/material.dart';

import '../models/worker.dart';
import '../models/department.dart';
import '../models/local.dart';
import '../providers/department_provider.dart';
import '../providers/local_provider.dart';
import '../utils/validators.dart';
import '../../utils/dialog_error_handler.dart';

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

  bool _isSaving = false;

  static const Color _primary = Color(0xFF1769AA);
  static const Color _primaryDark = Color(0xFF104C80);
  static const Color _background = Color(0xFFF4F7FB);
  static const Color _textDark = Color(0xFF243447);
  static const Color _textMuted = Color(0xFF718096);
  static const Color _border = Color(0xFFE4EAF2);
  static const Color _success = Color(0xFF159B72);
  static const Color _danger = Color(0xFFD94B4B);

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

  // VALIDACIÓN DEL CARNET DE IDENTIDAD
  String? _validateCarnetID(String? value) {
    if (value == null || value.isEmpty) {
      return 'El carnet de identidad es requerido';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length != 11) {
      return 'El carnet debe tener exactamente 11 dígitos';
    }

    final onlyNumbersRegex = RegExp(r'^[0-9]+$');

    if (!onlyNumbersRegex.hasMatch(trimmedValue)) {
      return 'El carnet solo puede contener números';
    }

    final provinceCode = int.tryParse(trimmedValue.substring(0, 2));

    if (provinceCode == null || provinceCode < 1 || provinceCode > 16) {
      return 'Los primeros dígitos no corresponden a una provincia válida';
    }

    return null;
  }

  // VALIDACIÓN DE FECHA DE CUMPLEAÑOS
  String? _validateBirthday(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final trimmedValue = value.trim();

    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

    if (!dateRegex.hasMatch(trimmedValue)) {
      return 'Formato inválido. Use YYYY-MM-DD (Ej: 1990-05-15)';
    }

    try {
      final parts = trimmedValue.split('-');

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      final currentYear = DateTime.now().year;

      if (year < 1900 || year > currentYear) {
        return 'Año inválido (1900-$currentYear)';
      }

      if (month < 1 || month > 12) {
        return 'Mes inválido (1-12)';
      }

      final daysInMonth = DateTime(year, month + 1, 0).day;

      if (day < 1 || day > daysInMonth) {
        return 'Día inválido para el mes seleccionado';
      }

      final birthday = DateTime(year, month, day);
      final today = DateTime.now();

      if (birthday.isAfter(DateTime(today.year, today.month, today.day))) {
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 750),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isEditMode),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(
                          'Información personal',
                          Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 18),

                        _buildFieldLabel('Nombre'),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: _buildInputDecoration(
                            hint: 'Ej: Juan',
                            icon: Icons.person_outline_rounded,
                          ),
                          validator: (value) =>
                              Validators.validateName(value, 'Nombre'),
                        ),

                        const SizedBox(height: 17),

                        _buildFieldLabel('Apellido'),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: _lastNameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: _buildInputDecoration(
                            hint: 'Ej: Pérez',
                            icon: Icons.person_rounded,
                          ),
                          validator: (value) =>
                              Validators.validateName(value, 'Apellido'),
                        ),

                        const SizedBox(height: 17),

                        _buildFieldLabel('Carnet de identidad'),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: _carnetIDController,
                          keyboardType: TextInputType.number,
                          maxLength: 11,
                          textInputAction: TextInputAction.next,
                          decoration: _buildInputDecoration(
                            hint: '11 dígitos (Ej: 91010112345)',
                            icon: Icons.badge_outlined,
                          ).copyWith(counterText: ''),
                          validator: _validateCarnetID,
                        ),

                        const SizedBox(height: 24),

                        _buildSectionTitle(
                          'Información de contacto',
                          Icons.contact_phone_outlined,
                        ),
                        const SizedBox(height: 18),

                        _buildFieldLabel('Teléfono'),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: _buildInputDecoration(
                            hint: 'Ej: +53 55598765',
                            icon: Icons.phone_rounded,
                          ),
                          validator: (value) =>
                              Validators.validatePhone(value, required: true),
                        ),

                        const SizedBox(height: 17),

                        _buildFieldLabel('Dirección'),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: _addressController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 2,
                          maxLines: 3,
                          maxLength: 200,
                          decoration: _buildInputDecoration(
                            hint: 'Ej: Calle 123, Ciudad',
                            icon: Icons.home_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return null;
                            }

                            if (value.length > 200) {
                              return 'La dirección no puede exceder 200 caracteres';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 17),

                        _buildFieldLabel(
                          'Fecha de cumpleaños',
                          required: false,
                        ),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: _fechaCumpleanosController,
                          keyboardType: TextInputType.datetime,
                          textInputAction: TextInputAction.next,
                          decoration: _buildInputDecoration(
                            hint: 'YYYY-MM-DD (Ej: 1990-05-15)',
                            icon: Icons.cake_outlined,
                          ),
                          validator: _validateBirthday,
                        ),

                        const SizedBox(height: 24),

                        _buildSectionTitle(
                          'Organización',
                          Icons.account_tree_outlined,
                        ),
                        const SizedBox(height: 18),

                        if (departments.isNotEmpty) ...[
                          _buildFieldLabel('Departamento', required: false),
                          const SizedBox(height: 7),
                          DropdownButtonFormField<int?>(
                            isExpanded: true,
                            initialValue:
                                departments.any(
                                  (d) => d.id == _selectedDepartmentId,
                                )
                                ? _selectedDepartmentId
                                : null,
                            decoration: _buildInputDecoration(
                              hint: 'Seleccione un departamento',
                              icon: Icons.business_outlined,
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Sin departamento'),
                              ),
                              ...departments.map((dept) {
                                return DropdownMenuItem<int?>(
                                  value: dept.id,
                                  child: Text(
                                    dept.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (int? newValue) {
                              setState(() {
                                _selectedDepartmentId = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 17),
                        ],

                        if (locals.isNotEmpty) ...[
                          _buildFieldLabel('Local', required: false),
                          const SizedBox(height: 7),
                          DropdownButtonFormField<int?>(
                            isExpanded: true,
                            initialValue:
                                locals.any((l) => l.id == _selectedLocalId)
                                ? _selectedLocalId
                                : null,
                            decoration: _buildInputDecoration(
                              hint: 'Seleccione un local',
                              icon: Icons.location_on_outlined,
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
                      ],
                    ),
                  ),
                ),
              ),
              _buildFooter(isEditMode),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader(bool isEditMode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            ),
            child: Icon(
              isEditMode ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditMode ? 'Editar trabajador' : 'Nuevo trabajador',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditMode
                      ? 'Actualiza los datos del trabajador'
                      : 'Registra un nuevo trabajador',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.badge_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  // TÍTULOS DE SECCIÓN
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _primary, size: 20),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: _textDark,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ETIQUETAS
  Widget _buildFieldLabel(String label, {bool required = true}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: _danger,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  // DECORACIÓN DE CAMPOS
  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: _primary, size: 20),
      filled: true,
      fillColor: _background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _danger, width: 1.5),
      ),
    );
  }

  // FOOTER
  Widget _buildFooter(bool isEditMode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: _textMuted,
                side: const BorderSide(color: _border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _primary.withValues(alpha: 0.6),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isEditMode ? Icons.save_rounded : Icons.add_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            isEditMode ? 'Guardar cambios' : 'Agregar',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // GUARDAR TRABAJADOR
  Future<void> _handleSave() async {
    if (_isSaving) return;

    final mode = widget.worker != null ? 'EDIT' : 'CREATE';

    debugPrint('[WorkerDialog][$mode] Save pressed');

    if (!_formKey.currentState!.validate()) {
      debugPrint('[WorkerDialog][$mode] Validation failed');
      return;
    }

    setState(() => _isSaving = true);

    debugPrint('[WorkerDialog][$mode] Validation passed');

    try {
      debugPrint(
        '[WorkerDialog][$mode] Selected departmentId=$_selectedDepartmentId localId=$_selectedLocalId',
      );

      // Obtener objetos completos si existen.
      final Department? department = _selectedDepartmentId != null
          ? await widget.departmentProvider.getDepartmentById(
              _selectedDepartmentId!,
            )
          : null;

      final Local? local = _selectedLocalId != null
          ? await widget.localProvider.getLocalById(_selectedLocalId!)
          : null;

      if (!mounted) return;

      // Crear el Worker con los objetos completos.
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

      final success = await widget.onSave(worker);

      debugPrint('[WorkerDialog][$mode] onSave returned success=$success');

      if (!mounted) return;

      if (success) {
        final messenger = ScaffoldMessenger.of(context);

        Navigator.of(context).pop();

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              widget.worker != null
                  ? 'Trabajador actualizado exitosamente'
                  : 'Trabajador creado exitosamente',
            ),
            backgroundColor: _success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        debugPrint('[WorkerDialog][$mode] Save failed, dialog remains open');
      }
    } catch (e) {
      debugPrint('[WorkerDialog][$mode] Exception: $e');

      if (mounted) {
        final errorTitle =
            'Error al ${widget.worker != null ? 'actualizar' : 'crear'} trabajador';

        DialogErrorHandler.showErrorDialog(
          context: context,
          title: errorTitle,
          technicalError: e.toString(),
          showRetryButton: true,
          onRetry: _handleSave,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

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
