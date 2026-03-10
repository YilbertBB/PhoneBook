// import 'package:flutter/material.dart';
// import '../models/local.dart';

// class LocalDialog extends StatefulWidget {
//   final Local? local;
//   final Function(Local) onSave;

//   const LocalDialog({super.key, this.local, required this.onSave});

//   @override
//   LocalDialogState createState() => LocalDialogState();
// }

// class LocalDialogState extends State<LocalDialog> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _phoneController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     if (widget.local != null) {
//       _nameController.text = widget.local!.name;
//       _phoneController.text = widget.local!.phone;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text(widget.local == null ? 'Agregar Local' : 'Editar Local'),
//       content: SingleChildScrollView(
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextFormField(
//                 controller: _nameController,
//                 decoration: InputDecoration(
//                   labelText: 'Nombre del local',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Por favor ingresa el nombre';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 16),
//               TextFormField(
//                 controller: _phoneController,
//                 decoration: InputDecoration(
//                   labelText: 'Teléfono',
//                   border: OutlineInputBorder(),
//                 ),
//                 keyboardType: TextInputType.phone,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Por favor ingresa el teléfono';
//                   }
//                   return null;
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             if (_formKey.currentState!.validate()) {
//               final local = Local(
//                 id: widget.local?.id ?? 0,
//                 name: _nameController.text,
//                 phone: _phoneController.text,
//               );
//               widget.onSave(local);
//               Navigator.of(context).pop();
//             }
//           },
//           style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
//           child: Text('Guardar'),
//         ),
//       ],
//     );
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import '../models/local.dart';
import '../utils/dialog_error_handler.dart';
import '../utils/validators.dart';

// class LocalDialog extends StatefulWidget {
//   final Local? local;
//   final Function(Local) onSave;

//   const LocalDialog({super.key, this.local, required this.onSave});

//   @override
//   LocalDialogState createState() => LocalDialogState();
// }

// class LocalDialogState extends State<LocalDialog> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _phoneController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     if (widget.local != null) {
//       _nameController.text = widget.local!.name;
//       _phoneController.text = widget.local!.phone;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Row(
//         children: [
//           Icon(
//             widget.local == null ? Icons.business : Icons.edit,
//             color: Colors.green[700],
//           ),
//           const SizedBox(width: 8),
//           Text(widget.local == null ? 'Agregar Local' : 'Editar Local'),
//         ],
//       ),
//       content: SingleChildScrollView(
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Nombre del local
//               TextFormField(
//                 controller: _nameController,
//                 decoration: const InputDecoration(
//                   labelText: 'Nombre del local *',
//                   prefixIcon: Icon(Icons.store),
//                   border: OutlineInputBorder(),
//                   hintText: 'Ej: Sucursal Central',
//                 ),
//                 validator: (value) => Validators.validateRequired(
//                   value,
//                   'El nombre del local',
//                   minLength: 2,
//                   maxLength: 100,
//                 ),
//               ),

//               const SizedBox(height: 16),

//               // Teléfono
//               TextFormField(
//                 controller: _phoneController,
//                 decoration: const InputDecoration(
//                   labelText: 'Teléfono *',
//                   prefixIcon: Icon(Icons.phone),
//                   border: OutlineInputBorder(),
//                   hintText: 'Ej: +53 55512345',
//                 ),
//                 keyboardType: TextInputType.phone,
//                 validator: (value) =>
//                     Validators.validatePhone(value, required: true),
//               ),
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             if (_formKey.currentState!.validate()) {
//               final local = Local(
//                 id: widget.local?.id ?? 0,
//                 name: _nameController.text.trim(),
//                 phone: _phoneController.text.trim(),
//               );
//               widget.onSave(local);
//               Navigator.of(context).pop();
//             }
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.green[700],
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//           ),
//           child: Text(
//             widget.local == null ? 'Agregar' : 'Guardar',
//             style: TextStyle(color: Colors.white),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }
// }

class LocalDialog extends StatefulWidget {
  final Local? local;
  final Function(Local) onSave;

  const LocalDialog({super.key, this.local, required this.onSave});

  @override
  LocalDialogState createState() => LocalDialogState();
}

class LocalDialogState extends State<LocalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false; // <-- AGREGAR ESTADO DE GUARDADO

  @override
  void initState() {
    super.initState();
    if (widget.local != null) {
      _nameController.text = widget.local!.name;
      _phoneController.text = widget.local!.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.local != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditMode ? Icons.edit : Icons.business,
            color: Colors.green[700],
          ),
          const SizedBox(width: 8),
          Text(isEditMode ? 'Editar Local' : 'Agregar Local'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nombre del local
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del local *',
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Sucursal Central',
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  'El nombre del local',
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
                  hintText: 'Ej: +53 55512345',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    Validators.validatePhone(value, required: true),
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
            backgroundColor: Colors.green[700],
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
                  isEditMode ? 'Guardar' : 'Agregar',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);

      final local = Local(
        id: widget.local?.id ?? 0,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      // Intentar guardar
      await widget.onSave(local);
      if (mounted) {
        // Si llega aquí, fue exitoso
        Navigator.of(context).pop();

        DialogErrorHandler.showSuccessSnackbar(
          context: context,
          message: widget.local != null
              ? '✅ Local actualizado exitosamente'
              : '✅ Local creado exitosamente',
        );
      }
    } catch (e) {
      if (mounted) {
        // Manejar el error
        DialogErrorHandler.showErrorDialog(
          context: context,
          title:
              'Error al ${widget.local != null ? 'actualizar' : 'crear'} local',
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
