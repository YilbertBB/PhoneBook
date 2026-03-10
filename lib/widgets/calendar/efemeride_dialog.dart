// import 'package:flutter/material.dart';
// import '../../models/efemeride.dart';

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

//   final List<int> _days = List.generate(31, (index) => index + 1);

//   @override
//   void initState() {
//     super.initState();

//     if (widget.efemeride != null) {
//       // Modo edición: cargar datos existentes
//       _datoController.text = widget.efemeride!.dato;
//       _detalleController.text = widget.efemeride!.detalle;
//       _selectedDay = widget.efemeride!.fecha.day;
//       _selectedMonth = widget.efemeride!.fecha.month;
//       _yearController.text = widget.efemeride!.fecha.year.toString();
//     } else {
//       // Modo agregar: valores por defecto
//       _yearController.text = DateTime.now().year.toString();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isEditMode = widget.efemeride != null;
//     final title = isEditMode ? 'Editar Efeméride' : 'Agregar Efeméride';
//     final buttonText = isEditMode ? 'Guardar Cambios' : 'Guardar';

//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         constraints: BoxConstraints(
//           maxWidth: MediaQuery.of(context).size.width * 0.9,
//           maxHeight: MediaQuery.of(context).size.height * 0.8,
//         ),
//         padding: EdgeInsets.all(20),
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
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue[700],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               SizedBox(height: 16),

//               Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     // Selector de fecha
//                     Container(
//                       padding: EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.blue[50],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Fecha de la efeméride',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blue[700],
//                               fontSize: 14,
//                             ),
//                           ),
//                           SizedBox(height: 8),

//                           // Día
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Día',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               SizedBox(height: 4),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: DropdownButtonFormField<int>(
//                                   initialValue: _selectedDay,
//                                   isExpanded: true,
//                                   decoration: InputDecoration(
//                                     contentPadding: EdgeInsets.symmetric(
//                                       horizontal: 12,
//                                       vertical: 8,
//                                     ),
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     filled: true,
//                                     fillColor: Colors.white,
//                                   ),
//                                   items: _days.map((int day) {
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
//                                 ),
//                               ),
//                             ],
//                           ),

//                           SizedBox(height: 12),

//                           // Mes
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Mes',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               SizedBox(height: 4),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: DropdownButtonFormField<int>(
//                                   initialValue: _selectedMonth,
//                                   isExpanded: true,
//                                   decoration: InputDecoration(
//                                     contentPadding: EdgeInsets.symmetric(
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
//                                 ),
//                               ),
//                             ],
//                           ),

//                           SizedBox(height: 12),

//                           // Año
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Año',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               SizedBox(height: 4),
//                               TextFormField(
//                                 controller: _yearController,
//                                 keyboardType: TextInputType.number,
//                                 decoration: InputDecoration(
//                                   hintText: 'Ej: 2024',
//                                   contentPadding: EdgeInsets.symmetric(
//                                     horizontal: 12,
//                                     vertical: 12,
//                                   ),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   filled: true,
//                                   fillColor: Colors.white,
//                                 ),
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
//                                   return null;
//                                 },
//                               ),
//                             ],
//                           ),

//                           SizedBox(height: 12),

//                           // Información
//                           Container(
//                             padding: EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: Colors.amber[50],
//                               borderRadius: BorderRadius.circular(6),
//                               border: Border.all(color: Colors.amber[200]!),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(
//                                   Icons.info,
//                                   size: 16,
//                                   color: Colors.amber[700],
//                                 ),
//                                 SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     isEditMode
//                                         ? 'Nota: El año original se guarda, pero la efeméride se muestra anualmente'
//                                         : 'Las efemérides se mostrarán anualmente en el calendario',
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.amber[800],
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     SizedBox(height: 16),

//                     TextFormField(
//                       controller: _datoController,
//                       decoration: InputDecoration(
//                         labelText: 'Nombre de la efeméride *',
//                         border: OutlineInputBorder(),
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 12,
//                         ),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Por favor ingresa el nombre';
//                         }
//                         return null;
//                       },
//                     ),

//                     SizedBox(height: 16),

//                     TextFormField(
//                       controller: _detalleController,
//                       maxLines: 3,
//                       decoration: InputDecoration(
//                         labelText: 'Descripción',
//                         border: OutlineInputBorder(),
//                         alignLabelWithHint: true,
//                         contentPadding: EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 12,
//                         ),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Por favor ingresa una descripción';
//                         }
//                         return null;
//                       },
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: 20),

//               // Botones
//               LayoutBuilder(
//                 builder: (context, constraints) {
//                   final isSmall = constraints.maxWidth < 300;

//                   if (isSmall) {
//                     return Column(
//                       children: [
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: _handleSave,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blue[700],
//                               padding: EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text(
//                               buttonText,
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         SizedBox(
//                           width: double.infinity,
//                           child: TextButton(
//                             onPressed: () => Navigator.of(context).pop(),
//                             style: TextButton.styleFrom(
//                               padding: EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text(
//                               'Cancelar',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   } else {
//                     return Row(
//                       children: [
//                         Expanded(
//                           child: TextButton(
//                             onPressed: () => Navigator.of(context).pop(),
//                             style: TextButton.styleFrom(
//                               padding: EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text(
//                               'Cancelar',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: 12),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: _handleSave,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.blue[700],
//                               padding: EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                             child: Text(
//                               buttonText,
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _handleSave() {
//     if (_formKey.currentState!.validate()) {
//       final year = int.tryParse(_yearController.text);
//       if (year == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Año inválido'), backgroundColor: Colors.red),
//         );
//         return;
//       }

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

//       widget.onSave(efemeride);
//       Navigator.of(context).pop();

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             widget.efemeride != null
//                 ? 'Efeméride actualizada exitosamente'
//                 : 'Efeméride agregada exitosamente',
//           ),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
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
  final _formKey = GlobalKey<FormState>();
  final _datoController = TextEditingController();
  final _detalleController = TextEditingController();
  final _yearController = TextEditingController();

  int _selectedDay = 1;
  int _selectedMonth = 1;
  // bool _isSaving = false;

  final List<String> _months = [
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

  // Validar día según mes seleccionado
  List<int> get _availableDays {
    final year = int.tryParse(_yearController.text) ?? DateTime.now().year;
    final daysInMonth = DateTime(year, _selectedMonth + 1, 0).day;
    return List.generate(daysInMonth, (index) => index + 1);
  }

  @override
  void initState() {
    super.initState();

    if (widget.efemeride != null) {
      _datoController.text = widget.efemeride!.dato;
      _detalleController.text = widget.efemeride!.detalle;
      _selectedDay = widget.efemeride!.fecha.day;
      _selectedMonth = widget.efemeride!.fecha.month;
      _yearController.text = widget.efemeride!.fecha.year.toString();
    } else {
      final now = DateTime.now();
      _selectedDay = now.day;
      _selectedMonth = now.month;
      _yearController.text = now.year.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.efemeride != null;
    final availableDays = _availableDays;

    // Asegurarse de que el día seleccionado sea válido para el mes
    if (!availableDays.contains(_selectedDay)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedDay = availableDays.first;
        });
      });
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isEditMode ? Icons.edit : Icons.history,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEditMode ? 'Editar Efeméride' : 'Agregar Efeméride',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Selector de fecha
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha de la efeméride *',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Día
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Día *',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: double.infinity,
                                child: DropdownButtonFormField<int>(
                                  initialValue: _selectedDay,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  items: availableDays.map((int day) {
                                    return DropdownMenuItem<int>(
                                      value: day,
                                      child: Text(
                                        '$day',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (int? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedDay = newValue;
                                      });
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Seleccione un día';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Mes
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mes *',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: double.infinity,
                                child: DropdownButtonFormField<int>(
                                  initialValue: _selectedMonth,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  items: _months.asMap().entries.map((entry) {
                                    return DropdownMenuItem<int>(
                                      value: entry.key + 1,
                                      child: Text(
                                        entry.value,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (int? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedMonth = newValue;
                                      });
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Seleccione un mes';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Año
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Año *',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _yearController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Ej: 2024',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                onChanged: (value) {
                                  // Actualizar días disponibles cuando cambie el año
                                  if (value.length == 4) {
                                    setState(() {});
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingresa el año';
                                  }
                                  final year = int.tryParse(value);
                                  if (year == null) {
                                    return 'Año inválido';
                                  }
                                  if (year < 1000 || year > 9999) {
                                    return 'Año debe ser entre 1000 y 9999';
                                  }

                                  // Verificar que la fecha sea válida
                                  try {
                                    final date = DateTime(
                                      year,
                                      _selectedMonth,
                                      _selectedDay,
                                    );
                                    if (date.year != year ||
                                        date.month != _selectedMonth ||
                                        date.day != _selectedDay) {
                                      return 'Fecha inválida para este año';
                                    }
                                  } catch (e) {
                                    return 'Fecha inválida';
                                  }

                                  return null;
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Nombre de la efeméride
                    TextFormField(
                      controller: _datoController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la efeméride *',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Día de la Independencia',
                      ),
                      validator: (value) => Validators.validateRequired(
                        value,
                        'El nombre de la efeméride',
                        minLength: 3,
                        maxLength: 100,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _detalleController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        hintText: 'Descripción detallada del evento...',
                      ),
                      validator: (value) => Validators.validateRequired(
                        value,
                        'La descripción',
                        minLength: 10,
                        maxLength: 500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isEditMode ? 'Guardar Cambios' : 'Agregar',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // void _handleSave() {
  //   if (_formKey.currentState!.validate()) {
  //     final year = int.tryParse(_yearController.text);
  //     if (year == null) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Año inválido'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //       return;
  //     }

  //     final fecha = DateTime(year, _selectedMonth, _selectedDay);

  //     final efemeride = widget.efemeride != null
  //         ? widget.efemeride!.copyWith(
  //             fecha: fecha,
  //             dato: _datoController.text.trim(),
  //             detalle: _detalleController.text.trim(),
  //           )
  //         : Efemeride(
  //             id: 0,
  //             fecha: fecha,
  //             dato: _datoController.text.trim(),
  //             detalle: _detalleController.text.trim(),
  //           );

  //     widget.onSave(efemeride);
  //     Navigator.of(context).pop();
  //   }
  // }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final year = int.tryParse(_yearController.text);
    if (year == null) {
      _showErrorSnackbar('Año inválido');
      return;
    }

    try {
      // setState(() => _isSaving = true);

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

      // Intentar guardar
      await widget.onSave(efemeride);

      // Si llega aquí, fue exitoso
      if (mounted) {
        Navigator.of(context).pop();
      }

      _showSuccessSnackbar(
        widget.efemeride != null
            ? '✅ Efeméride actualizada exitosamente'
            : '✅ Efeméride creada exitosamente',
      );
    } catch (e) {
      // Manejar el error
      _showErrorDialog(
        'No se pudo ${widget.efemeride != null ? 'actualizar' : 'crear'} la efeméride',
        e.toString(),
      );
    } finally {
      if (mounted) {
        // setState(() => _isSaving = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
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
            if (_isNetworkError(message)) const SizedBox(height: 12),
            if (_isNetworkError(message))
              const Text(
                '📡 Sugerencia: Verifique su conexión a internet e intente nuevamente.',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  String _getFriendlyErrorMessage(String technicalError) {
    final error = technicalError.toLowerCase();

    if (error.contains('conexión') ||
        error.contains('socket') ||
        error.contains('network')) {
      return '❌ Error de conexión. No se pudo conectar con el servidor.';
    }

    if (error.contains('timeout')) {
      return '⏰ El servidor está tardando demasiado en responder.';
    }

    if (error.contains('duplicad') || error.contains('ya existe')) {
      return '⚠️ Ya existe una efeméride con esta fecha y nombre.';
    }

    if (error.contains('fecha') || error.contains('date')) {
      return '📅 La fecha ingresada no es válida.';
    }

    if (error.contains('required') || error.contains('requerido')) {
      return '📝 Por favor, complete todos los campos requeridos.';
    }

    if (error.contains('500') || error.contains('server')) {
      return '🔧 Error en el servidor. Por favor, intente más tarde.';
    }

    return '❌ Ocurrió un error. Por favor, intente nuevamente.';
  }

  bool _isNetworkError(String error) {
    final e = error.toLowerCase();
    return e.contains('conexión') ||
        e.contains('socket') ||
        e.contains('network') ||
        e.contains('timeout');
  }

  // Modificar el botón de guardar en el build para mostrar loading
  // Widget _buildSaveButton(bool isEditMode) {
  //   return Expanded(
  //     child: ElevatedButton(
  //       onPressed: _isSaving ? null : _handleSave,
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: Colors.blue[700],
  //         padding: const EdgeInsets.symmetric(vertical: 12),
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //       ),
  //       child: _isSaving
  //           ? const SizedBox(
  //               height: 20,
  //               width: 20,
  //               child: CircularProgressIndicator(
  //                 strokeWidth: 2,
  //                 color: Colors.white,
  //               ),
  //             )
  //           : Text(
  //               isEditMode ? 'Guardar Cambios' : 'Agregar',
  //               style: const TextStyle(
  //                 fontSize: 16,
  //                 color: Colors.white,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //     ),
  //   );
  // }

  @override
  void dispose() {
    _datoController.dispose();
    _detalleController.dispose();
    _yearController.dispose();
    super.dispose();
  }
}
