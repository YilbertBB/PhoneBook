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

  bool _isSaving = false;

  static const Color _primary = Color(0xFF1769AA);
  static const Color _primaryDark = Color(0xFF104C80);
  static const Color _background = Color(0xFFF4F7FB);
  static const Color _textDark = Color(0xFF243447);
  static const Color _textMuted = Color(0xFF718096);
  static const Color _border = Color(0xFFE4EAF2);
  static const Color _success = Color(0xFF159B72);

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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 600),
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
                        _buildSectionTitle(),
                        const SizedBox(height: 18),

                        _buildFieldLabel('Nombre del departamento'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: _buildInputDecoration(
                            hint: 'Ej: Recursos Humanos',
                            icon: Icons.business_center_rounded,
                          ),
                          validator: (value) => Validators.validateRequired(
                            value,
                            'El nombre del departamento',
                            minLength: 2,
                            maxLength: 100,
                          ),
                        ),

                        const SizedBox(height: 22),

                        _buildFieldLabel('Teléfono'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          decoration: _buildInputDecoration(
                            hint: 'Ej: +53 55567890',
                            icon: Icons.phone_rounded,
                          ),
                          validator: (value) =>
                              Validators.validatePhone(value, required: true),
                        ),

                        const SizedBox(height: 20),
                        _buildInformationNote(),
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
              isEditMode ? Icons.edit : Icons.add_business_rounded,
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
                  isEditMode ? 'Editar departamento' : 'Nuevo departamento',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditMode
                      ? 'Modifica la información del departamento'
                      : 'Registra un nuevo departamento',
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
              Icons.apartment_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  // TÍTULO DE SECCIÓN
  Widget _buildSectionTitle() {
    return const Row(
      children: [
        Icon(Icons.account_balance_rounded, color: _primary, size: 20),
        SizedBox(width: 9),
        Text(
          'Información del departamento',
          style: TextStyle(
            color: _textDark,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ETIQUETAS
  Widget _buildFieldLabel(String label) {
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
        const SizedBox(width: 4),
        const Text(
          '*',
          style: TextStyle(
            color: Color(0xFFD94B4B),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
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
        borderSide: const BorderSide(color: Color(0xFFD94B4B)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFD94B4B), width: 1.5),
      ),
    );
  }

  // NOTA INFORMATIVA
  Widget _buildInformationNote() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withValues(alpha: 0.12)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _primary, size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Introduce el nombre y el teléfono de contacto para registrar correctamente el departamento.',
              style: TextStyle(color: _textMuted, fontSize: 12, height: 1.5),
            ),
          ),
        ],
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
                      height: 19,
                      width: 19,
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

  // GUARDAR DEPARTAMENTO
  Future<void> _handleSave() async {
    if (_isSaving) return;

    final mode = widget.department != null ? 'EDIT' : 'CREATE';

    debugPrint('[DepartmentDialog][$mode] Save pressed');

    if (!_formKey.currentState!.validate()) {
      debugPrint('[DepartmentDialog][$mode] Validation failed');
      return;
    }

    setState(() => _isSaving = true);

    debugPrint('[DepartmentDialog][$mode] Validation passed');

    try {
      final department = Department(
        id: widget.department?.id ?? 0,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      debugPrint(
        '[DepartmentDialog][$mode] Department built: ${department.toJson()}',
      );

      debugPrint(
        '[DepartmentDialog][$mode] DTO: '
        '${widget.department != null ? department.toUpdateDto() : department.toCreateDto()}',
      );

      final success = await widget.onSave(department);

      debugPrint('[DepartmentDialog][$mode] onSave returned success=$success');

      if (!mounted) return;

      if (success) {
        final messenger = ScaffoldMessenger.of(context);

        Navigator.of(context).pop();

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              widget.department != null
                  ? 'Departamento actualizado exitosamente'
                  : 'Departamento creado exitosamente',
            ),
            backgroundColor: _success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        debugPrint(
          '[DepartmentDialog][$mode] Save failed, dialog remains open',
        );
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
    _phoneController.dispose();
    super.dispose();
  }
}
