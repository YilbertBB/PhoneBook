import 'package:flutter/material.dart';
import '../models/department.dart';
import '../providers/department_provider.dart';
import '../utils/dialog_error_handler.dart';
import '../utils/validators.dart';

class DepartmentDialog extends StatefulWidget {
  final Department? department;
  final Future<bool> Function(Department) onSave;
  final DepartmentProvider departmentProvider;

  const DepartmentDialog({
    super.key,
    this.department,
    required this.onSave,
    required this.departmentProvider,
  });

  @override
  DepartmentDialogState createState() => DepartmentDialogState();
}

class DepartmentDialogState extends State<DepartmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false; // <-- AGREGAR

  @override
  void initState() {
    super.initState();
    if (widget.department != null) {
      _nameController.text = widget.department!.name;
      _phoneController.text = widget.department!.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.department != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditMode ? Icons.mode_edit_rounded : Icons.work,
            color: Colors.orange[700],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isEditMode ? 'Editar Departamento' : 'Agregar Departamento',
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
              // Nombre del departamento
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del departamento *',
                  prefixIcon: Icon(Icons.business_center),
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Recursos Humanos',
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  'El nombre del departamento',
                  minLength: 2,
                  maxLength: 100,
                ),
              ),

              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono *',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  hintText: 'Ej: +53 55567890',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    Validators.validatePhone(value, required: true),
              ),

              const SizedBox(height: 16),
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
            backgroundColor: Colors.orange[700],
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
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  void _handleSave() async {
    final mode = widget.department != null ? 'EDIT' : 'CREATE';
    debugPrint('[DepartmentDialog][$mode] Save pressed');

    if (!_formKey.currentState!.validate()) {
      debugPrint('[DepartmentDialog][$mode] Validation failed');
      return;
    }

    try {
      setState(() => _isSaving = true);
      debugPrint('[DepartmentDialog][$mode] Validation passed');

      final department = Department(
        id: widget.department?.id ?? 0,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      debugPrint(
        '[DepartmentDialog][$mode] Department built: ${department.toJson()}',
      );
      debugPrint(
        '[DepartmentDialog][$mode] DTO: ${widget.department != null ? department.toUpdateDto() : department.toCreateDto()}',
      );

      // Intentar guardar
      final success = await widget.onSave(department);
      debugPrint('[DepartmentDialog][$mode] onSave returned success=$success');

      // Si llega aquí, fue exitoso
      if (success && mounted) {
        Navigator.of(context).pop();

        DialogErrorHandler.showSuccessSnackbar(
          context: context,
          message: widget.department != null
              ? '✅ Departamento actualizado exitosamente'
              : '✅ Departamento creado exitosamente',
        );
      }
      if (!success) {
        debugPrint('[DepartmentDialog][$mode] Save failed, dialog remains open');
      }
    } catch (e) {
      debugPrint('[DepartmentDialog][$mode] Exception: $e');
      if (mounted) {
        DialogErrorHandler.showErrorDialog(
          context: context,
          title:
              'Error al ${widget.department != null ? 'actualizar' : 'crear'} departamento',
          technicalError: e.toString(),
          showRetryButton: true,
          onRetry: () => _handleSave(),
        );
      }
      // Manejar el error
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
