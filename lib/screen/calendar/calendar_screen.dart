import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../models/efemeride.dart';
import '../../providers/auth_provider.dart';
import '../../providers/worker_provider.dart';
import '../../providers/efemeride_provider.dart';
import '../../widgets/calendar/efemeride_dialog.dart';
import '../../widgets/calendar/event_details_dialog.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Map<DateTime, List<Event>> events;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedFilter = 'todos';
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    events = {};

    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  // void _loadInitialData() {
  //   final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
  //   final efemerideProvider = Provider.of<EfemerideProvider>(
  //     context,
  //     listen: false,
  //   );

  //   // USAR loadInitialData en lugar de loadWorkers
  //   if (!workerProvider.hasLoaded) {
  //     workerProvider.loadInitialData().then((_) {
  //       if (mounted) {
  //         _loadBirthdays();
  //       }
  //     });
  //   } else {
  //     _loadBirthdays();
  //   }

  //   // USAR loadInitialData en lugar de loadEfemerides
  //   if (!efemerideProvider.hasLoaded) {
  //     efemerideProvider.loadInitialData().then((_) {
  //       _loadEfemerides();
  //     });
  //   } else {
  //     _loadEfemerides();
  //   }
  // }
  void _loadInitialData() {
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    final efemerideProvider = Provider.of<EfemerideProvider>(
      context,
      listen: false,
    );

    // Cargar trabajadores primero
    if (!workerProvider.hasLoaded) {
      workerProvider.loadWorkers().then((_) {
        if (mounted) {
          _loadBirthdays();
        }
      });
    } else {
      _loadBirthdays();
    }

    // Cargar efemérides
    if (!efemerideProvider.hasLoaded) {
      efemerideProvider.loadEfemerides().then((_) {
        if (mounted) {
          _loadEfemerides();
        }
      });
    } else {
      _loadEfemerides();
    }
  }

  void _loadBirthdays() {
    final workerProvider = Provider.of<WorkerProvider>(context, listen: false);

    // Limpiar solo cumpleaños
    final keysToRemove = <DateTime>[];
    events.forEach((key, value) {
      final newValue = value
          .where((event) => event.type != EventType.birthday)
          .toList();
      if (newValue.isEmpty) {
        keysToRemove.add(key);
      } else {
        events[key] = newValue;
      }
    });

    for (var key in keysToRemove) {
      events.remove(key);
    }

    for (var worker in workerProvider.workers) {
      final birthdayDate = worker.birthdayDate;
      if (birthdayDate != null) {
        // Cumpleaños para el año actual del calendario
        final eventDate = DateTime(
          _focusedDay.year,
          birthdayDate.month,
          birthdayDate.day,
        );

        events[eventDate] = [
          ...(events[eventDate] ?? []),
          Event(
            title: 'Cumpleaños de ${worker.fullName}',
            type: EventType.birthday,
            date: eventDate,
            worker: worker,
          ),
        ];
      }
    }

    if (mounted) setState(() {});
  }

  void _loadEfemerides() {
    final efemerideProvider = Provider.of<EfemerideProvider>(
      context,
      listen: false,
    );

    // Limpiar solo efemérides
    final keysToRemove = <DateTime>[];
    events.forEach((key, value) {
      final newValue = value
          .where((event) => event.type != EventType.efemeride)
          .toList();
      if (newValue.isEmpty) {
        keysToRemove.add(key);
      } else {
        events[key] = newValue;
      }
    });

    for (var key in keysToRemove) {
      events.remove(key);
    }

    // Cargar efemérides para el año actual del calendario
    for (var efemeride in efemerideProvider.efemerides) {
      final eventDate = DateTime(
        _focusedDay.year,
        efemeride.fecha.month,
        efemeride.fecha.day,
      );

      events[eventDate] = [
        ...(events[eventDate] ?? []),
        Event(
          title: efemeride.dato,
          type: EventType.efemeride,
          date: eventDate,
          efemeride: efemeride,
        ),
      ];
    }

    if (mounted) setState(() {});
  }

  void _refreshEvents() {
    setState(() {
      events = {};
    });
    _loadBirthdays();
    _loadEfemerides();
  }

  void _refreshEventsForCurrentYear() {
    _loadBirthdays();
    _loadEfemerides();
  }

  List<Event> _getEventsForDay(DateTime day) {
    final allEvents = events[DateTime(day.year, day.month, day.day)] ?? [];

    if (_selectedFilter == 'todos') {
      return allEvents;
    } else if (_selectedFilter == 'cumpleaños') {
      return allEvents
          .where((event) => event.type == EventType.birthday)
          .toList();
    } else if (_selectedFilter == 'efemerides') {
      return allEvents
          .where((event) => event.type == EventType.efemeride)
          .toList();
    }

    return allEvents;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final dayEvents = _getEventsForDay(selectedDay);
    if (dayEvents.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) =>
            EventDetailsDialog(date: selectedDay, events: dayEvents),
      );
    }
  }

  int _getEventCountByType(EventType type) {
    return events.entries
        .where(
          (entry) =>
              entry.key.month == _focusedDay.month &&
              entry.key.year == _focusedDay.year,
        )
        .fold(
          0,
          (count, entry) =>
              count + entry.value.where((event) => event.type == type).length,
        );
  }

  int _getTotalEventCountForMonth() {
    return _getEventCountByType(EventType.birthday) +
        _getEventCountByType(EventType.efemeride);
  }

  // NUEVO: Función para sincronizar efemérides
  Future<void> _syncEfemerides(EfemerideProvider provider) async {
    final success = await provider.syncEfemerides();

    if (success) {
      _showSnackBar('✅ Efemérides sincronizadas');
      _refreshEvents();
    } else {
      _showSnackBar(
        '❌ Error en sincronización: ${provider.error}',
        isError: true,
      );
    }
  }

  void _showAddEfemerideDialog() {
    final provider = Provider.of<EfemerideProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar(
        'No tienes permisos para agregar efemérides',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EfemerideDialog(
        onSave: (nuevaEfemeride) async {
          final success = await provider.createEfemeride(
            nuevaEfemeride.fecha,
            nuevaEfemeride.dato,
            nuevaEfemeride.detalle,
          );
          if (success) {
            _showSnackBar('✅ Efeméride creada exitosamente');
            _refreshEvents();
          } else {
            _showSnackBar('❌ Error: ${provider.error}', isError: true);
          }
        },
      ),
    );
  }

  void _editEfemeride(Efemeride efemeride) {
    final provider = Provider.of<EfemerideProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar('No tienes permisos para editar efemérides', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EfemerideDialog(
        efemeride: efemeride,
        onSave: (updatedEfemeride) async {
          final efemerideToUpdate = updatedEfemeride.copyWith(id: efemeride.id);
          final success = await provider.updateEfemeride(efemerideToUpdate);
          if (success) {
            _showSnackBar('✅ Efeméride actualizada exitosamente');
            _refreshEvents();
          } else {
            _showSnackBar('❌ Error: ${provider.error}', isError: true);
          }
        },
      ),
    );
  }

  void _deleteEfemeride(Efemeride efemeride) {
    final provider = Provider.of<EfemerideProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar(
        'No tienes permisos para eliminar efemérides',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Flexible(
              child: Text('Eliminar Efeméride', softWrap: true, maxLines: 2),
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
                color: Colors.purple[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history, size: 40, color: Colors.purple[700]),
            ),
            SizedBox(height: 16),
            Text(
              '¿Estás seguro de que deseas eliminar:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              efemeride.dato,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              '📅 ${efemeride.displayDate}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: TextStyle(color: Colors.red[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);

              final success = await provider.deleteEfemeride(efemeride.id);

              if (success) {
                _showSnackBar('🗑️ Efeméride eliminada exitosamente');
                _refreshEvents();
              } else {
                _showSnackBar('❌ Error: ${provider.error}', isError: true);
              }
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEfemeridesList() {
    // final provider = Provider.of<EfemerideProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.user?.isAdmin ?? false;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.list, color: Colors.purple[700], size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lista de Efemérides',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                  ),

                  // NUEVO: Indicador de estado offline
                  Consumer<EfemerideProvider>(
                    builder: (context, efProvider, child) {
                      if (efProvider.isOffline) {
                        return Container(
                          margin: EdgeInsets.only(right: 8),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cloud_off,
                                size: 12,
                                color: Colors.orange[700],
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Offline',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),

                  IconButton(
                    icon: Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Estadísticas
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Consumer<EfemerideProvider>(
                          builder: (context, efProvider, child) {
                            return Column(
                              children: [
                                Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${efProvider.efemerides.length}${efProvider.isOffline ? ' (offline)' : ''}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: efProvider.isOffline
                                        ? Colors.orange[700]
                                        : Colors.purple[700],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),

                    if (isAdmin)
                      Row(
                        children: [
                          // NUEVO: Botón de sincronización si está offline
                          Consumer<EfemerideProvider>(
                            builder: (context, efProvider, child) {
                              if (efProvider.isOffline) {
                                return IconButton(
                                  icon: Icon(
                                    Icons.cloud_upload,
                                    size: 20,
                                    color: Colors.purple[700],
                                  ),
                                  onPressed: efProvider.syncing
                                      ? null
                                      : () => _syncEfemerides(efProvider),
                                  tooltip: 'Sincronizar efemérides',
                                );
                              }
                              return SizedBox.shrink();
                            },
                          ),

                          ElevatedButton.icon(
                            icon: Icon(
                              Icons.add,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Agregar',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddEfemerideDialog();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple[700],
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Lista
              Expanded(
                child: Consumer<EfemerideProvider>(
                  builder: (context, efProvider, child) {
                    if (efProvider.loading && !efProvider.hasLoaded) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Colors.purple[700],
                        ),
                      );
                    }

                    if (efProvider.hasError && !efProvider.hasLoaded) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              efProvider.isOffline
                                  ? Icons.cloud_off
                                  : Icons.error_outline,
                              size: 60,
                              color: efProvider.isOffline
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                            SizedBox(height: 16),
                            Text(
                              efProvider.isOffline
                                  ? 'Modo offline'
                                  : 'Error al cargar efemérides',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Text(
                                efProvider.isOffline && efProvider.hasLocalData
                                    ? 'Mostrando ${efProvider.localDataCount} efemérides almacenadas localmente.'
                                    : efProvider.error,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return efProvider.efemerides.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  efProvider.isOffline
                                      ? Icons.cloud_off
                                      : Icons.event_note,
                                  size: 60,
                                  color: efProvider.isOffline
                                      ? Colors.orange[300]
                                      : Colors.grey[300],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  efProvider.isOffline &&
                                          efProvider.hasLocalData
                                      ? 'No hay efemérides locales'
                                      : 'No hay efemérides registradas',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  efProvider.isOffline
                                      ? 'Conéctate a internet para cargar las efemérides.'
                                      : 'Agrega la primera efeméride',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: efProvider.efemerides.length,
                            separatorBuilder: (context, index) =>
                                Divider(height: 1),
                            itemBuilder: (context, index) {
                              final efemeride = efProvider.efemerides[index];
                              return ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.purple[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${efemeride.fecha.day}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple[700],
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  efemeride.dato,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${efemeride.fecha.day}/${efemeride.fecha.month}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                trailing: isAdmin
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _editEfemeride(efemeride);
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _deleteEfemeride(efemeride),
                                          ),
                                        ],
                                      )
                                    : null,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(efemeride.dato),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '📅 Fecha: ${efemeride.displayDate}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            SizedBox(height: 12),
                                            if (efemeride.detalle.isNotEmpty)
                                              Container(
                                                padding: EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  efemeride.detalle,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        if (isAdmin)
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _editEfemeride(efemeride);
                                            },
                                            child: Text('Editar'),
                                          ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('Cerrar'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue[700]),
            SizedBox(width: 8),
            Flexible(
              child: Text('Estadísticas del Mes', softWrap: true, maxLines: 2),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Estadísticas por tipo
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildStatItem(
                    'Total de Eventos',
                    Icons.event,
                    Colors.blue[700]!,
                    _getTotalEventCountForMonth().toString(),
                  ),
                  SizedBox(height: 12),
                  _buildStatItem(
                    'Cumpleaños',
                    Icons.cake,
                    Colors.pink[700]!,
                    _getEventCountByType(EventType.birthday).toString(),
                  ),
                  SizedBox(height: 12),
                  _buildStatItem(
                    'Efemérides',
                    Icons.history,
                    Colors.purple[700]!,
                    _getEventCountByType(EventType.efemeride).toString(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Información del mes
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text(
                    'Mes: ${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    final months = [
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
    return months[month - 1];
  }

  Widget _buildStatItem(
    String label,
    IconData icon,
    Color color,
    String value,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
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
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.isAdmin ?? false;
    final workerProvider = Provider.of<WorkerProvider>(context);
    final efemerideProvider = Provider.of<EfemerideProvider>(context);

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Calendario',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          backgroundColor: Colors.blue[700],
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // NUEVO: Botón de sincronización offline para efemérides
            Consumer<EfemerideProvider>(
              builder: (context, efProvider, child) {
                if (efProvider.syncing) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  );
                }

                if (efProvider.isOffline) {
                  return IconButton(
                    icon: Icon(
                      Icons.cloud_off,
                      color: Colors.orange[100],
                      size: 24,
                    ),
                    onPressed: () => _syncEfemerides(efProvider),
                    tooltip: 'Efemérides offline - Toque para sincronizar',
                  );
                }

                return SizedBox.shrink();
              },
            ),

            IconButton(
              icon: Icon(
                Icons.analytics_outlined,
                color: Colors.white,
                size: 24,
              ),
              onPressed: _showStatistics,
              tooltip: 'Estadísticas',
            ),
            IconButton(
              icon: Icon(Icons.list, color: Colors.white, size: 24),
              onPressed: _showEfemeridesList,
              tooltip: 'Lista de efemérides',
            ),
            if (isAdmin)
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: _showAddEfemerideDialog,
                tooltip: 'Agregar efeméride',
              ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white, size: 24),
              onPressed: () {
                _refreshEvents();
                _showSnackBar('🔄 Calendario actualizado');
              },
              tooltip: 'Actualizar',
            ),
          ],
        ),
        backgroundColor: Colors.white,
        body: workerProvider.loading || efemerideProvider.loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.blue[700]),
                    SizedBox(height: 16),
                    Text(
                      'Cargando calendario...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final screenHeight = constraints.maxHeight;
                  final isVerySmallScreen = screenHeight < 500;

                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                      child: Column(
                        children: [
                          // Filtros
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              padding: EdgeInsets.all(
                                isVerySmallScreen ? 8 : 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildFilterButton(
                                    'todos',
                                    'Todos',
                                    Icons.event,
                                  ),
                                  _buildFilterButton(
                                    'cumpleaños',
                                    'Cumpleaños',
                                    Icons.cake,
                                  ),
                                  _buildFilterButton(
                                    'efemerides',
                                    'Efemérides',
                                    Icons.history,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: isVerySmallScreen ? 12 : 16),

                          // Header informativo
                          Container(
                            padding: EdgeInsets.all(
                              isVerySmallScreen ? 12 : 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.calendar_today,
                                    color: Colors.blue[700],
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: isVerySmallScreen ? 8 : 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Calendario Corporativo',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                          fontSize: isVerySmallScreen ? 14 : 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Cumpleaños del personal y efemérides importantes',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: isVerySmallScreen ? 12 : 14,
                                        ),
                                      ),

                                      // NUEVO: Indicador de estado offline
                                      Consumer<EfemerideProvider>(
                                        builder: (context, efProvider, child) {
                                          if (efProvider.isOffline) {
                                            return Column(
                                              children: [
                                                SizedBox(height: 4),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          Colors.orange[200]!,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.cloud_off,
                                                        size: 12,
                                                        color:
                                                            Colors.orange[700],
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Modo offline - Efemérides cargadas localmente',
                                                        style: TextStyle(
                                                          fontSize:
                                                              isVerySmallScreen
                                                              ? 9
                                                              : 11,
                                                          color: Colors
                                                              .orange[700],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          }
                                          return SizedBox.shrink();
                                        },
                                      ),

                                      if (isAdmin) ...[
                                        SizedBox(height: 4),
                                        Text(
                                          'Modo Administrador - Puedes gestionar efemérides',
                                          style: TextStyle(
                                            color: Colors.green[600],
                                            fontSize: isVerySmallScreen
                                                ? 10
                                                : 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: isVerySmallScreen ? 12 : 16),

                          // Leyenda de eventos
                          Container(
                            padding: EdgeInsets.all(isVerySmallScreen ? 8 : 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildLegendItem(
                                  Icons.cake,
                                  'Cumpleaños',
                                  Colors.pink[700]!,
                                  isVerySmallScreen,
                                ),
                                _buildLegendItem(
                                  Icons.history,
                                  'Efemérides',
                                  Colors.purple[700]!,
                                  isVerySmallScreen,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: isVerySmallScreen ? 12 : 16),

                          // Calendario
                          Container(
                            height: _getCalendarHeight(screenHeight),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                isVerySmallScreen ? 8 : 12,
                              ),
                              child: TableCalendar(
                                locale: 'es_ES',
                                headerStyle: HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                  titleTextStyle: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: isVerySmallScreen ? 14 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  leftChevronIcon: Icon(
                                    Icons.chevron_left,
                                    color: Colors.blue[700],
                                    size: isVerySmallScreen ? 20 : 28,
                                  ),
                                  rightChevronIcon: Icon(
                                    Icons.chevron_right,
                                    color: Colors.blue[700],
                                    size: isVerySmallScreen ? 20 : 28,
                                  ),
                                  headerPadding: EdgeInsets.symmetric(
                                    vertical: isVerySmallScreen ? 8 : 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                daysOfWeekStyle: DaysOfWeekStyle(
                                  weekdayStyle: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: isVerySmallScreen ? 12 : 14,
                                  ),
                                  weekendStyle: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: isVerySmallScreen ? 12 : 14,
                                  ),
                                ),
                                calendarStyle: CalendarStyle(
                                  todayDecoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    shape: BoxShape.circle,
                                  ),
                                  selectedDecoration: BoxDecoration(
                                    color: Colors.blue[700],
                                    shape: BoxShape.circle,
                                  ),
                                  selectedTextStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: isVerySmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  todayTextStyle: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: isVerySmallScreen ? 12 : 14,
                                  ),
                                  weekendTextStyle: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: isVerySmallScreen ? 12 : 14,
                                  ),
                                  defaultTextStyle: TextStyle(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                    fontSize: isVerySmallScreen ? 12 : 14,
                                  ),
                                  outsideTextStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: isVerySmallScreen ? 10 : 12,
                                  ),
                                  markerMargin: EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                ),
                                firstDay: DateTime.utc(2020, 1, 1),
                                lastDay: DateTime.utc(2030, 12, 31),
                                focusedDay: _focusedDay,
                                selectedDayPredicate: (day) =>
                                    isSameDay(_selectedDay, day),
                                eventLoader: _getEventsForDay,
                                onDaySelected: _onDaySelected,
                                onPageChanged: (focusedDay) {
                                  setState(() {
                                    _focusedDay = focusedDay;
                                  });
                                  _refreshEventsForCurrentYear();
                                },
                                calendarBuilders: CalendarBuilders(
                                  markerBuilder: (context, date, events) {
                                    if (events.isEmpty) return null;

                                    final eventList = events
                                        .cast<Event>()
                                        .toList();
                                    final hasBirthday = eventList.any(
                                      (e) => e.type == EventType.birthday,
                                    );
                                    final hasEfemeride = eventList.any(
                                      (e) => e.type == EventType.efemeride,
                                    );

                                    Color markerColor;
                                    IconData markerIcon;

                                    if (hasBirthday && hasEfemeride) {
                                      markerColor = Colors.blue[700]!;
                                      markerIcon = Icons.event;
                                    } else if (hasBirthday) {
                                      markerColor = Colors.pink[700]!;
                                      markerIcon = Icons.cake;
                                    } else {
                                      markerColor = Colors.purple[700]!;
                                      markerIcon = Icons.history;
                                    }

                                    return Positioned(
                                      bottom: 1,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: markerColor.withValues(
                                            alpha: 0.9,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: markerColor.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 2,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          markerIcon,
                                          size: isVerySmallScreen ? 10 : 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isVerySmallScreen ? 12 : 16),

                          // Resumen del mes
                          Container(
                            padding: EdgeInsets.all(
                              isVerySmallScreen ? 12 : 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Resumen del Mes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                    fontSize: isVerySmallScreen ? 14 : 16,
                                  ),
                                ),
                                SizedBox(height: isVerySmallScreen ? 8 : 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildMonthSummary(
                                      'Cumpleaños',
                                      Icons.cake,
                                      Colors.pink[700]!,
                                      _getEventCountByType(EventType.birthday),
                                      isVerySmallScreen,
                                    ),
                                    _buildMonthSummary(
                                      'Efemérides',
                                      Icons.history,
                                      Colors.purple[700]!,
                                      _getEventCountByType(EventType.efemeride),
                                      isVerySmallScreen,
                                    ),
                                    _buildMonthSummary(
                                      'Total',
                                      Icons.event,
                                      Colors.blue[700]!,
                                      _getTotalEventCountForMonth(),
                                      isVerySmallScreen,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: isVerySmallScreen ? 8 : 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildFilterButton(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getCalendarHeight(double screenHeight) {
    if (screenHeight < 500) {
      return 370;
    } else if (screenHeight < 600) {
      return 410;
    } else if (screenHeight < 700) {
      return 450;
    } else if (screenHeight < 800) {
      return 490;
    } else {
      return 530;
    }
  }

  Widget _buildLegendItem(
    IconData icon,
    String text,
    Color color,
    bool isSmall,
  ) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, size: 10, color: Colors.white),
        ),
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: isSmall ? 10 : 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSummary(
    String title,
    IconData icon,
    Color color,
    int count,
    bool isSmall,
  ) {
    return Column(
      children: [
        Container(
          width: isSmall ? 36 : 48,
          height: isSmall ? 36 : 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: isSmall ? 18 : 24, color: color),
        ),
        SizedBox(height: isSmall ? 4 : 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: isSmall ? 16 : 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: isSmall ? 10 : 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
