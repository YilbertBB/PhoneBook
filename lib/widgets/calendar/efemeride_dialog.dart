// import 'package:flutter/material.dart';
// import '../../models/efemeride.dart';
// import '../../utils/validators.dart';

// class EfemerideDialog extends StatefulWidget {
//   final Efemeride? efemeride;
//   final Function(Efemeride) onSave;

//   const EfemerideDialog({super.key, this.efemeride, required this.onSave});

//   @override
//   State<EfemerideDialog> createState() => _EfemerideDialogState();
// }

// class _EfemerideDialogState extends State<EfemerideDialog> {
//   final _formKey = GlobalKey<FormState>();
//   final _datoController = TextEditingController();
//   final _detalleController = TextEditingController();
//   final _yearController = TextEditingController();

//   int _selectedDay = 1;
//   int _selectedMonth = 1;
//   // bool _isSaving = false;

//   final List<String> _months = [
//     'Enero',
//     'Febrero',
//     'Marzo',
//     'Abril',
//     'Mayo',
//     'Junio',
//     'Julio',
//     'Agosto',
//     'Septiembre',
//     'Octubre',
//     'Noviembre',
//     'Diciembre',
//   ];

//   // Validar día según mes seleccionado
//   List<int> get _availableDays {
//     final year = int.tryParse(_yearController.text) ?? DateTime.now().year;
//     final daysInMonth = DateTime(year, _selectedMonth + 1, 0).day;
//     return List.generate(daysInMonth, (index) => index + 1);
//   }

//   @override
//   void initState() {
//     super.initState();

//     if (widget.efemeride != null) {
//       _datoController.text = widget.efemeride!.dato;
//       _detalleController.text = widget.efemeride!.detalle;
//       _selectedDay = widget.efemeride!.fecha.day;
//       _selectedMonth = widget.efemeride!.fecha.month;
//       _yearController.text = widget.efemeride!.fecha.year.toString();
//     } else {
//       final now = DateTime.now();
//       _selectedDay = now.day;
//       _selectedMonth = now.month;
//       _yearController.text = now.year.toString();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isEditMode = widget.efemeride != null;
//     final availableDays = _availableDays;

//     // Asegurarse de que el día seleccionado sea válido para el mes
//     if (!availableDays.contains(_selectedDay)) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         setState(() {
//           _selectedDay = availableDays.first;
//         });
//       });
//     }

//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         constraints: BoxConstraints(
//           maxWidth: MediaQuery.of(context).size.width * 0.9,
//           maxHeight: MediaQuery.of(context).size.height * 0.8,
//         ),
//         padding: const EdgeInsets.all(20),
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(
//                     isEditMode ? Icons.edit : Icons.history,
//                     color: Colors.blue[700],
//                     size: 24,
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       isEditMode ? 'Editar Efeméride' : 'Agregar Efeméride',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue[700],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 16),

//               Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     // Selector de fecha
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.blue[50],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Fecha de la efeméride *',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blue[700],
//                               fontSize: 14,
//                             ),
//                           ),
//                           const SizedBox(height: 8),

//                           // Día
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Día *',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: DropdownButtonFormField<int>(
//                                   initialValue: _selectedDay,
//                                   isExpanded: true,
//                                   decoration: InputDecoration(
//                                     contentPadding: const EdgeInsets.symmetric(
//                                       horizontal: 12,
//                                       vertical: 8,
//                                     ),
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     filled: true,
//                                     fillColor: Colors.white,
//                                   ),
//                                   items: availableDays.map((int day) {
//                                     return DropdownMenuItem<int>(
//                                       value: day,
//                                       child: Text(
//                                         '$day',
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     );
//                                   }).toList(),
//                                   onChanged: (int? newValue) {
//                                     if (newValue != null) {
//                                       setState(() {
//                                         _selectedDay = newValue;
//                                       });
//                                     }
//                                   },
//                                   validator: (value) {
//                                     if (value == null) {
//                                       return 'Seleccione un día';
//                                     }
//                                     return null;
//                                   },
//                                 ),
//                               ),
//                             ],
//                           ),

//                           const SizedBox(height: 12),

//                           // Mes
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Mes *',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: DropdownButtonFormField<int>(
//                                   initialValue: _selectedMonth,
//                                   isExpanded: true,
//                                   decoration: InputDecoration(
//                                     contentPadding: const EdgeInsets.symmetric(
//                                       horizontal: 12,
//                                       vertical: 8,
//                                     ),
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     filled: true,
//                                     fillColor: Colors.white,
//                                   ),
//                                   items: _months.asMap().entries.map((entry) {
//                                     return DropdownMenuItem<int>(
//                                       value: entry.key + 1,
//                                       child: Text(
//                                         entry.value,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     );
//                                   }).toList(),
//                                   onChanged: (int? newValue) {
//                                     if (newValue != null) {
//                                       setState(() {
//                                         _selectedMonth = newValue;
//                                       });
//                                     }
//                                   },
//                                   validator: (value) {
//                                     if (value == null) {
//                                       return 'Seleccione un mes';
//                                     }
//                                     return null;
//                                   },
//                                 ),
//                               ),
//                             ],
//                           ),

//                           const SizedBox(height: 12),

//                           // Año
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Año *',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               TextFormField(
//                                 controller: _yearController,
//                                 keyboardType: TextInputType.number,
//                                 decoration: InputDecoration(
//                                   hintText: 'Ej: 2024',
//                                   prefixIcon: const Icon(Icons.calendar_today),
//                                   contentPadding: const EdgeInsets.symmetric(
//                                     horizontal: 12,
//                                     vertical: 12,
//                                   ),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   filled: true,
//                                   fillColor: Colors.white,
//                                 ),
//                                 onChanged: (value) {
//                                   // Actualizar días disponibles cuando cambie el año
//                                   if (value.length == 4) {
//                                     setState(() {});
//                                   }
//                                 },
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Ingresa el año';
//                                   }
//                                   final year = int.tryParse(value);
//                                   if (year == null) {
//                                     return 'Año inválido';
//                                   }
//                                   if (year < 1000 || year > 9999) {
//                                     return 'Año debe ser entre 1000 y 9999';
//                                   }

//                                   // Verificar que la fecha sea válida
//                                   try {
//                                     final date = DateTime(
//                                       year,
//                                       _selectedMonth,
//                                       _selectedDay,
//                                     );
//                                     if (date.year != year ||
//                                         date.month != _selectedMonth ||
//                                         date.day != _selectedDay) {
//                                       return 'Fecha inválida para este año';
//                                     }
//                                   } catch (e) {
//                                     return 'Fecha inválida';
//                                   }

//                                   return null;
//                                 },
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 16),

//                     // Nombre de la efeméride
//                     TextFormField(
//                       controller: _datoController,
//                       decoration: const InputDecoration(
//                         labelText: 'Nombre de la efeméride *',
//                         prefixIcon: Icon(Icons.title),
//                         border: OutlineInputBorder(),
//                         hintText: 'Ej: Día de la Independencia',
//                       ),
//                       validator: (value) => Validators.validateRequired(
//                         value,
//                         'El nombre de la efeméride',
//                         minLength: 3,
//                         maxLength: 100,
//                       ),
//                     ),

//                     const SizedBox(height: 16),

//                     // Descripción
//                     TextFormField(
//                       controller: _detalleController,
//                       maxLines: 3,
//                       decoration: const InputDecoration(
//                         labelText: 'Descripción *',
//                         prefixIcon: Icon(Icons.description),
//                         border: OutlineInputBorder(),
//                         alignLabelWithHint: true,
//                         hintText: 'Descripción detallada del evento...',
//                       ),
//                       validator: (value) => Validators.validateRequired(
//                         value,
//                         'La descripción',
//                         minLength: 10,
//                         maxLength: 500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // Botones
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextButton(
//                       onPressed: () => Navigator.of(context).pop(),
//                       style: TextButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: const Text(
//                         'Cancelar',
//                         style: TextStyle(fontSize: 16, color: Colors.grey),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: _handleSave,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue[700],
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: Text(
//                         isEditMode ? 'Guardar Cambios' : 'Agregar',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // void _handleSave() {
//   //   if (_formKey.currentState!.validate()) {
//   //     final year = int.tryParse(_yearController.text);
//   //     if (year == null) {
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         const SnackBar(
//   //           content: Text('Año inválido'),
//   //           backgroundColor: Colors.red,
//   //         ),
//   //       );
//   //       return;
//   //     }

//   //     final fecha = DateTime(year, _selectedMonth, _selectedDay);

//   //     final efemeride = widget.efemeride != null
//   //         ? widget.efemeride!.copyWith(
//   //             fecha: fecha,
//   //             dato: _datoController.text.trim(),
//   //             detalle: _detalleController.text.trim(),
//   //           )
//   //         : Efemeride(
//   //             id: 0,
//   //             fecha: fecha,
//   //             dato: _datoController.text.trim(),
//   //             detalle: _detalleController.text.trim(),
//   //           );

//   //     widget.onSave(efemeride);
//   //     Navigator.of(context).pop();
//   //   }
//   // }

//   void _handleSave() async {
//     if (!_formKey.currentState!.validate()) return;

//     final year = int.tryParse(_yearController.text);
//     if (year == null) {
//       _showErrorSnackbar('Año inválido');
//       return;
//     }

//     try {
//       // setState(() => _isSaving = true);

//       final fecha = DateTime(year, _selectedMonth, _selectedDay);
//       final efemeride = widget.efemeride != null
//           ? widget.efemeride!.copyWith(
//               fecha: fecha,
//               dato: _datoController.text.trim(),
//               detalle: _detalleController.text.trim(),
//             )
//           : Efemeride(
//               id: 0,
//               fecha: fecha,
//               dato: _datoController.text.trim(),
//               detalle: _detalleController.text.trim(),
//             );

//       // Intentar guardar
//       await widget.onSave(efemeride);

//       // Si llega aquí, fue exitoso
//       if (mounted) {
//         Navigator.of(context).pop();
//       }

//       _showSuccessSnackbar(
//         widget.efemeride != null
//             ? '✅ Efeméride actualizada exitosamente'
//             : '✅ Efeméride creada exitosamente',
//       );
//     } catch (e) {
//       // Manejar el error
//       _showErrorDialog(
//         'No se pudo ${widget.efemeride != null ? 'actualizar' : 'crear'} la efeméride',
//         e.toString(),
//       );
//     } finally {
//       if (mounted) {
//         // setState(() => _isSaving = false);
//       }
//     }
//   }

//   void _showErrorSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showSuccessSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   void _showErrorDialog(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             const Icon(Icons.error_outline, color: Colors.red),
//             const SizedBox(width: 8),
//             Text(title),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               _getFriendlyErrorMessage(message),
//               style: const TextStyle(fontSize: 14),
//             ),
//             if (_isNetworkError(message)) const SizedBox(height: 12),
//             if (_isNetworkError(message))
//               const Text(
//                 '📡 Sugerencia: Verifique su conexión a internet e intente nuevamente.',
//                 style: TextStyle(fontSize: 12, color: Colors.blueGrey),
//               ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Aceptar'),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getFriendlyErrorMessage(String technicalError) {
//     final error = technicalError.toLowerCase();

//     if (error.contains('conexión') ||
//         error.contains('socket') ||
//         error.contains('network')) {
//       return '❌ Error de conexión. No se pudo conectar con el servidor.';
//     }

//     if (error.contains('timeout')) {
//       return '⏰ El servidor está tardando demasiado en responder.';
//     }

//     if (error.contains('duplicad') || error.contains('ya existe')) {
//       return '⚠️ Ya existe una efeméride con esta fecha y nombre.';
//     }

//     if (error.contains('fecha') || error.contains('date')) {
//       return '📅 La fecha ingresada no es válida.';
//     }

//     if (error.contains('required') || error.contains('requerido')) {
//       return '📝 Por favor, complete todos los campos requeridos.';
//     }

//     if (error.contains('500') || error.contains('server')) {
//       return '🔧 Error en el servidor. Por favor, intente más tarde.';
//     }

//     return '❌ Ocurrió un error. Por favor, intente nuevamente.';
//   }

//   bool _isNetworkError(String error) {
//     final e = error.toLowerCase();
//     return e.contains('conexión') ||
//         e.contains('socket') ||
//         e.contains('network') ||
//         e.contains('timeout');
//   }

//   @override
//   void dispose() {
//     _datoController.dispose();
//     _detalleController.dispose();
//     _yearController.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';

import '../../models/efemeride.dart';
import '../../utils/validators.dart';

class EfemerideDialog extends StatefulWidget {
  final Efemeride? efemeride;
  final Function(Efemeride) onSave;

  const EfemerideDialog({super.key, this.efemeride, required this.onSave});

  @override
  State<EfemerideDialog> createState() => _EfemerideDialogState();
}

class _EfemerideDialogState extends State<EfemerideDialog> {
  static const Color _primary = Color(0xFF1769AA);
  static const Color _primaryDark = Color(0xFF104C80);
  static const Color _background = Color(0xFFF4F7FB);
  static const Color _textDark = Color(0xFF243447);
  static const Color _textMuted = Color(0xFF718096);
  static const Color _border = Color(0xFFE4EAF2);
  static const Color _danger = Color(0xFFD94B4B);
  static const Color _success = Color(0xFF159B72);

  final _formKey = GlobalKey<FormState>();

  final _datoController = TextEditingController();
  final _detalleController = TextEditingController();
  final _yearController = TextEditingController();

  int _selectedDay = 1;
  int _selectedMonth = 1;

  bool _isSaving = false;

  bool get _isEditMode => widget.efemeride != null;

  final List<String> _months = const [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  // ---------------------------------------------------------
  // FECHAS
  // ---------------------------------------------------------

  int get _selectedYear =>
      int.tryParse(_yearController.text) ?? DateTime.now().year;

  int get _daysInSelectedMonth {
    return DateTime(_selectedYear, _selectedMonth + 1, 0).day;
  }

  List<int> get _availableDays {
    return List.generate(_daysInSelectedMonth, (index) => index + 1);
  }

  @override
  void initState() {
    super.initState();

    if (widget.efemeride != null) {
      final efemeride = widget.efemeride!;

      _datoController.text = efemeride.dato;
      _detalleController.text = efemeride.detalle;
      _selectedDay = efemeride.fecha.day;
      _selectedMonth = efemeride.fecha.month;
      _yearController.text = efemeride.fecha.year.toString();
    } else {
      final now = DateTime.now();

      _selectedDay = now.day;
      _selectedMonth = now.month;
      _yearController.text = now.year.toString();
    }
  }

  void _updateDate() {
    final days = _availableDays;

    if (!days.contains(_selectedDay)) {
      _selectedDay = days.last;
    }
  }

  // ---------------------------------------------------------
  // VALIDACIONES
  // ---------------------------------------------------------

  String? _validateYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa el año';
    }

    final year = int.tryParse(value.trim());

    if (year == null) {
      return 'Año inválido';
    }

    if (year < 1000 || year > 9999) {
      return 'El año debe estar entre 1000 y 9999';
    }

    final date = DateTime(year, _selectedMonth, _selectedDay);

    if (date.year != year ||
        date.month != _selectedMonth ||
        date.day != _selectedDay) {
      return 'Fecha inválida para este año';
    }

    return null;
  }

  String? _validateDate() {
    final year = int.tryParse(_yearController.text);

    if (year == null) {
      return 'Ingresa un año válido';
    }

    if (year < 1000 || year > 9999) {
      return 'El año debe estar entre 1000 y 9999';
    }

    final date = DateTime(year, _selectedMonth, _selectedDay);

    if (date.year != year ||
        date.month != _selectedMonth ||
        date.day != _selectedDay) {
      return 'La fecha seleccionada no es válida';
    }

    return null;
  }

  // ---------------------------------------------------------
  // DECORACIÓN
  // ---------------------------------------------------------

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _textMuted, size: 20),
      filled: true,
      fillColor: Colors.white,
      alignLabelWithHint: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _danger, width: 1.5),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: _textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textDark,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  Widget _buildDateSelector() {
    final availableDays = _availableDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Fecha de la efeméride',
            subtitle: 'Selecciona el día, mes y año del acontecimiento',
            icon: Icons.calendar_month_rounded,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 420;

              final dayField = _buildDateField(
                label: 'Día *',
                child: DropdownButtonFormField<int>(
                  key: ValueKey('day_${_selectedYear}_$_selectedDay'),
                  initialValue: _selectedDay,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    label: 'Día',
                    icon: Icons.today_rounded,
                  ),
                  items: availableDays.map((day) {
                    return DropdownMenuItem<int>(
                      value: day,
                      child: Text('$day'),
                    );
                  }).toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _selectedDay = value;
                            });
                          }
                        },
                ),
              );

              final monthField = _buildDateField(
                label: 'Mes *',
                child: DropdownButtonFormField<int>(
                  key: ValueKey('month_$_selectedMonth'),
                  initialValue: _selectedMonth,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    label: 'Mes',
                    icon: Icons.date_range_rounded,
                  ),
                  items: _months.asMap().entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key + 1,
                      child: Text(entry.value, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _selectedMonth = value;
                              _updateDate();
                            });
                          }
                        },
                ),
              );

              final yearField = _buildDateField(
                label: 'Año *',
                child: TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  enabled: !_isSaving,
                  decoration: _inputDecoration(
                    label: 'Año',
                    icon: Icons.event_available_rounded,
                    hint: 'Ej: 2026',
                  ),
                  onChanged: (_) {
                    setState(_updateDate);
                  },
                  validator: _validateYear,
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: dayField),
                    const SizedBox(width: 12),
                    Expanded(child: monthField),
                    const SizedBox(width: 12),
                    Expanded(child: yearField),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: dayField),
                      const SizedBox(width: 12),
                      Expanded(child: monthField),
                    ],
                  ),
                  const SizedBox(height: 14),
                  yearField,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Información del acontecimiento',
          subtitle: 'Describe la efeméride que deseas registrar',
          icon: Icons.history_edu_rounded,
        ),
        TextFormField(
          controller: _datoController,
          enabled: !_isSaving,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration(
            label: 'Nombre de la efeméride *',
            icon: Icons.title_rounded,
            hint: 'Ej: Día de la Independencia',
          ),
          validator: (value) => Validators.validateRequired(
            value,
            'El nombre de la efeméride',
            minLength: 3,
            maxLength: 100,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _detalleController,
          enabled: !_isSaving,
          maxLines: 4,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration(
            label: 'Descripción *',
            icon: Icons.description_outlined,
            hint: 'Descripción detallada del acontecimiento...',
          ),
          validator: (value) => Validators.validateRequired(
            value,
            'La descripción',
            minLength: 10,
            maxLength: 500,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _background,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateSelector(),
                      const SizedBox(height: 26),
                      _buildTextFields(),
                      const SizedBox(height: 16),
                      _buildInformationNote(),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // CABECERA
  // ---------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
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
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _isEditMode
                  ? Icons.edit_calendar_rounded
                  : Icons.event_note_rounded,
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
                  _isEditMode ? 'Editar efeméride' : 'Nueva efeméride',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEditMode
                      ? 'Actualiza los datos del acontecimiento'
                      : 'Registra una fecha importante en el calendario',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // INFORMACIÓN
  // ---------------------------------------------------------

  Widget _buildInformationNote() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _primary, size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Los campos marcados con * son obligatorios. '
              'Verifica que la fecha seleccionada sea correcta '
              'antes de guardar.',
              style: TextStyle(color: _textMuted, fontSize: 11, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // BOTONES
  // ---------------------------------------------------------

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;

          final cancelButton = OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: _textMuted,
              side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: const Text('Cancelar'),
          );

          final saveButton = ElevatedButton.icon(
            onPressed: _isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primary.withValues(alpha: 0.5),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    _isEditMode ? Icons.save_outlined : Icons.add_rounded,
                    size: 19,
                  ),
            label: Text(
              _isSaving
                  ? 'Guardando...'
                  : _isEditMode
                  ? 'Guardar cambios'
                  : 'Agregar efeméride',
            ),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: double.infinity, child: saveButton),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: cancelButton),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: cancelButton),
              const SizedBox(width: 12),
              Expanded(child: saveButton),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------
  // GUARDAR
  // ---------------------------------------------------------

  Future<void> _handleSave() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dateError = _validateDate();

    if (dateError != null) {
      _showErrorSnackbar(dateError);
      return;
    }

    final year = int.tryParse(_yearController.text);

    if (year == null) {
      _showErrorSnackbar('Año inválido');
      return;
    }

    setState(() => _isSaving = true);

    final messenger = ScaffoldMessenger.of(context);
    final isEditing = _isEditMode;

    try {
      final fecha = DateTime(year, _selectedMonth, _selectedDay);

      final efemeride = widget.efemeride != null
          ? widget.efemeride!.copyWith(
              fecha: fecha,
              dato: _datoController.text.trim(),
              detalle: _detalleController.text.trim(),
            )
          : Efemeride(
              id: 0,
              fecha: fecha,
              dato: _datoController.text.trim(),
              detalle: _detalleController.text.trim(),
            );

      await widget.onSave(efemeride);

      if (!mounted) return;

      Navigator.of(context).pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Efeméride actualizada exitosamente'
                : 'Efeméride creada exitosamente',
          ),
          backgroundColor: _success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showErrorDialog(
        'No se pudo ${isEditing ? 'actualizar' : 'crear'} la efeméride',
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ---------------------------------------------------------
  // MENSAJES
  // ---------------------------------------------------------

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _danger,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: _danger),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getFriendlyErrorMessage(message),
                style: const TextStyle(fontSize: 14),
              ),
              if (_isNetworkError(message)) ...[
                const SizedBox(height: 12),
                const Text(
                  'Verifica tu conexión a internet e intenta nuevamente.',
                  style: TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  String _getFriendlyErrorMessage(String technicalError) {
    final error = technicalError.toLowerCase();

    if (error.contains('conexión') ||
        error.contains('socket') ||
        error.contains('network')) {
      return 'Error de conexión. No se pudo conectar con el servidor.';
    }

    if (error.contains('timeout')) {
      return 'El servidor está tardando demasiado en responder.';
    }

    if (error.contains('duplicad') || error.contains('ya existe')) {
      return 'Ya existe una efeméride con esta fecha y nombre.';
    }

    if (error.contains('fecha') || error.contains('date')) {
      return 'La fecha ingresada no es válida.';
    }

    if (error.contains('required') || error.contains('requerido')) {
      return 'Por favor, complete todos los campos requeridos.';
    }

    if (error.contains('500') || error.contains('server')) {
      return 'Error en el servidor. Por favor, intente más tarde.';
    }

    return 'Ocurrió un error. Por favor, intente nuevamente.';
  }

  bool _isNetworkError(String error) {
    final e = error.toLowerCase();

    return e.contains('conexión') ||
        e.contains('socket') ||
        e.contains('network') ||
        e.contains('timeout');
  }

  // ---------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------

  @override
  void dispose() {
    _datoController.dispose();
    _detalleController.dispose();
    _yearController.dispose();
    super.dispose();
  }
}
