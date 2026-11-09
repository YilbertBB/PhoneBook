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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.user?.isAdmin ?? false;

    const primary = Color(0xFF1769AA);
    const primaryDark = Color(0xFF104C80);
    const background = Color(0xFFF4F7FB);
    const textDark = Color(0xFF243447);
    const textMuted = Color(0xFF718096);
    const border = Color(0xFFE4EAF2);
    const warning = Color(0xFFE49A27);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Encabezado
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 20, 16, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.event_note_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Efemérides',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Listado de fechas y acontecimientos',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Consumer<EfemerideProvider>(
                        builder: (context, efProvider, child) {
                          if (!efProvider.isOffline) {
                            return const SizedBox.shrink();
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: warning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cloud_off_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Offline',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                ),

                // Estadísticas y acciones
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Consumer<EfemerideProvider>(
                    builder: (context, efProvider, child) {
                      return Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                color: primary,
                                size: 25,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total registradas',
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${efProvider.efemerides.length}',
                                    style: TextStyle(
                                      color: efProvider.isOffline
                                          ? warning
                                          : textDark,
                                      fontSize: 23,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isAdmin) ...[
                              if (efProvider.isOffline)
                                IconButton(
                                  onPressed: efProvider.syncing
                                      ? null
                                      : () => _syncEfemerides(efProvider),
                                  tooltip: 'Sincronizar efemérides',
                                  icon: efProvider.syncing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: primary,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.cloud_upload_rounded,
                                          color: primary,
                                        ),
                                ),
                              const SizedBox(width: 5),
                              FilledButton.icon(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  _showAddEfemerideDialog();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text(
                                  'Agregar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Separador
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 1, color: border),
                ),

                // Lista
                Expanded(
                  child: Consumer<EfemerideProvider>(
                    builder: (context, efProvider, child) {
                      if (efProvider.loading && !efProvider.hasLoaded) {
                        return const Center(
                          child: CircularProgressIndicator(color: primary),
                        );
                      }

                      if (efProvider.hasError && !efProvider.hasLoaded) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  efProvider.isOffline
                                      ? Icons.cloud_off_rounded
                                      : Icons.error_outline_rounded,
                                  size: 55,
                                  color: efProvider.isOffline
                                      ? warning
                                      : Colors.redAccent,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  efProvider.isOffline
                                      ? 'Modo sin conexión'
                                      : 'Error al cargar efemérides',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  efProvider.isOffline &&
                                          efProvider.hasLocalData
                                      ? 'Mostrando ${efProvider.localDataCount} efemérides almacenadas localmente.'
                                      : efProvider.error,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: textMuted,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (efProvider.efemerides.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: background,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Icon(
                                    efProvider.isOffline
                                        ? Icons.cloud_off_rounded
                                        : Icons.event_note_rounded,
                                    size: 38,
                                    color: textMuted.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  efProvider.isOffline &&
                                          efProvider.hasLocalData
                                      ? 'No hay efemérides locales'
                                      : 'No hay efemérides registradas',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: textDark,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  efProvider.isOffline
                                      ? 'Conéctate a internet para cargar las efemérides.'
                                      : 'Agrega la primera efeméride para comenzar.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                        itemCount: efProvider.efemerides.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 9),
                        itemBuilder: (context, index) {
                          final efemeride = efProvider.efemerides[index];

                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (detailContext) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    insetPadding: const EdgeInsets.all(20),
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        maxWidth: 420,
                                      ),
                                      padding: const EdgeInsets.all(22),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 42,
                                                  height: 42,
                                                  decoration: BoxDecoration(
                                                    color: primary.withValues(
                                                      alpha: 0.1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.event_note_rounded,
                                                    color: primary,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Expanded(
                                                  child: Text(
                                                    'Detalle de efeméride',
                                                    style: TextStyle(
                                                      color: textDark,
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        detailContext,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.close_rounded,
                                                    color: textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 18),
                                            Text(
                                              efemeride.dato,
                                              style: const TextStyle(
                                                color: textDark,
                                                fontSize: 19,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: background,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .calendar_today_rounded,
                                                    color: primary,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 9),
                                                  Expanded(
                                                    child: Text(
                                                      efemeride.displayDate,
                                                      style: const TextStyle(
                                                        color: textDark,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (efemeride
                                                .detalle
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 14),
                                              const Text(
                                                'Descripción',
                                                style: TextStyle(
                                                  color: textMuted,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 7),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  14,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: background,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: border,
                                                  ),
                                                ),
                                                child: Text(
                                                  efemeride.detalle,
                                                  style: const TextStyle(
                                                    color: textDark,
                                                    fontSize: 13,
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 20),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                if (isAdmin)
                                                  TextButton.icon(
                                                    onPressed: () {
                                                      Navigator.pop(
                                                        detailContext,
                                                      );
                                                      Navigator.pop(
                                                        dialogContext,
                                                      );
                                                      _editEfemeride(efemeride);
                                                    },
                                                    icon: const Icon(
                                                      Icons.edit_rounded,
                                                      size: 17,
                                                    ),
                                                    label: const Text('Editar'),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: primary,
                                                    ),
                                                  ),
                                                const SizedBox(width: 8),
                                                FilledButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        detailContext,
                                                      ),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: primary,
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text('Cerrar'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: primary.withValues(alpha: 0.09),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${efemeride.fecha.day}',
                                            style: const TextStyle(
                                              color: primary,
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${efemeride.fecha.month}',
                                            style: const TextStyle(
                                              color: textMuted,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 13),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            efemeride.dato,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: textDark,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today_outlined,
                                                size: 12,
                                                color: textMuted,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                '${efemeride.fecha.day}/${efemeride.fecha.month}',
                                                style: const TextStyle(
                                                  color: textMuted,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isAdmin) ...[
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        tooltip: 'Editar',
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                          _editEfemeride(efemeride);
                                        },
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: primary,
                                          size: 19,
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        tooltip: 'Eliminar',
                                        onPressed: () =>
                                            _deleteEfemeride(efemeride),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Color(0xFFD94B4B),
                                          size: 19,
                                        ),
                                      ),
                                    ] else
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: textMuted,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Pie
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: background,
                    border: Border(top: BorderSide(color: border)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: textMuted,
                      ),
                      const SizedBox(width: 7),
                      const Expanded(
                        child: Text(
                          'Selecciona una efeméride para ver sus detalles.',
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text(
                          'Cerrar',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStatistics() {
    const primary = Color(0xFF1769AA);
    const primaryDark = Color(0xFF104C80);
    const background = Color(0xFFF4F7FB);
    const textDark = Color(0xFF243447);
    const textMuted = Color(0xFF718096);
    const border = Color(0xFFE4EAF2);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Encabezado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.analytics_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estadísticas del mes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Resumen de eventos registrados',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Total de eventos
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.event_available_rounded,
                              color: primary,
                              size: 27,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getTotalEventCountForMonth().toString(),
                              style: const TextStyle(
                                color: primaryDark,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Total de eventos',
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Estadísticas por tipo
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              'Cumpleaños',
                              Icons.cake_rounded,
                              const Color(0xFFD95B83),
                              _getEventCountByType(
                                EventType.birthday,
                              ).toString(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatItem(
                              'Efemérides',
                              Icons.history_rounded,
                              primary,
                              _getEventCountByType(
                                EventType.efemeride,
                              ).toString(),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Mes seleccionado
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                color: primary,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Período seleccionado',
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
                                    style: const TextStyle(
                                      color: textDark,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text(
                            'Cerrar',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
  // ============================================================
  // INTERFAZ RESPONSIVE
  // ============================================================

  static const Color _primary = Color(0xFF1769AA);
  static const Color _primaryDark = Color(0xFF104D80);
  static const Color _background = Color(0xFFF4F7FB);
  static const Color _birthdayColor = Color(0xFFE45B87);
  static const Color _efemerideColor = Color(0xFF8661C5);
  static const Color _textDark = Color(0xFF243247);
  static const Color _textMuted = Color(0xFF78869A);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.isAdmin ?? false;
    final workerProvider = Provider.of<WorkerProvider>(context);
    final efemerideProvider = Provider.of<EfemerideProvider>(context);

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: _background,
        appBar: _buildAppBar(efemerideProvider, isAdmin),
        body: workerProvider.loading || efemerideProvider.loading
            ? _buildLoadingView()
            : LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isDesktop = width >= 1100;
                  final isTablet = width >= 650 && width < 1100;

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: width < 600
                          ? 14
                          : width < 1100
                          ? 24
                          : 32,
                      vertical: 22,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1500),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPageHeader(
                              isAdmin: isAdmin,
                              isOffline: efemerideProvider.isOffline,
                            ),
                            const SizedBox(height: 22),

                            if (isDesktop)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: _buildCalendarColumn(
                                      isTablet: false,
                                      isAdmin: isAdmin,
                                      isOffline: efemerideProvider.isOffline,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 3,
                                    child: _buildInformationColumn(
                                      isAdmin: isAdmin,
                                      isOffline: efemerideProvider.isOffline,
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _buildCalendarColumn(
                                isTablet: isTablet,
                                isAdmin: isAdmin,
                                isOffline: efemerideProvider.isOffline,
                              ),
                              const SizedBox(height: 20),
                              _buildInformationColumn(
                                isAdmin: isAdmin,
                                isOffline: efemerideProvider.isOffline,
                              ),
                            ],

                            const SizedBox(height: 24),
                            _buildFooter(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: isAdmin
            ? FloatingActionButton.extended(
                onPressed: _showAddEfemerideDialog,
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Nueva efeméride',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              )
            : null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    EfemerideProvider efemerideProvider,
    bool isAdmin,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: _textDark,
      elevation: 0,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Volver',
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 4,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: _primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            // 👈 CLAVE
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Calendario',
                  maxLines: 1, // 👈
                  overflow: TextOverflow.ellipsis, // 👈
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Directorio Telefónico Desoft',
                  maxLines: 1, // 👈
                  overflow: TextOverflow.ellipsis, // 👈
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (efemerideProvider.syncing)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: _primary,
                ),
              ),
            ),
          )
        else if (efemerideProvider.isOffline)
          IconButton(
            tooltip: 'Sincronizar efemérides',
            onPressed: () => _syncEfemerides(efemerideProvider),
            icon: const Icon(Icons.cloud_sync_rounded, color: Colors.orange),
          ),
        IconButton(
          tooltip: 'Estadísticas',
          onPressed: _showStatistics,
          icon: const Icon(Icons.analytics_outlined),
        ),
        IconButton(
          tooltip: 'Lista de efemérides',
          onPressed: _showEfemeridesList,
          icon: const Icon(Icons.format_list_bulleted_rounded),
        ),
        if (isAdmin)
          IconButton(
            tooltip: 'Agregar efeméride',
            onPressed: _showAddEfemerideDialog,
            icon: const Icon(Icons.add_circle_outline_rounded, color: _primary),
          ),
        IconButton(
          tooltip: 'Actualizar calendario',
          onPressed: () {
            _refreshEvents();
            _showSnackBar('Calendario actualizado');
          },
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(strokeWidth: 3, color: _primary),
          ),
          SizedBox(height: 18),
          Text(
            'Preparando tu calendario...',
            style: TextStyle(
              color: _textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader({required bool isAdmin, required bool isOffline}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -35,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 65,
            bottom: -65,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Text(
                      'Calendario corporativo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                'Cumpleaños del personal y fechas importantes de nuestra organización.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 9,
                runSpacing: 8,
                children: [
                  _buildHeaderChip(
                    Icons.calendar_today_rounded,
                    '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
                  ),
                  if (isAdmin)
                    _buildHeaderChip(
                      Icons.admin_panel_settings_outlined,
                      'Administrador',
                    ),
                  if (isOffline)
                    _buildHeaderChip(Icons.cloud_off_rounded, 'Modo offline'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarColumn({
    required bool isTablet,
    required bool isAdmin,
    required bool isOffline,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFiltersCard(),
        const SizedBox(height: 16),
        _buildCalendarCard(isTablet: isTablet),
      ],
    );
  }

  Widget _buildFiltersCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt_rounded, size: 16, color: _primary),
              const SizedBox(width: 8),
              const Expanded(
                // 👈 CLAVE
                child: Text(
                  'Filtrar eventos',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // 👈
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8), // 👈 separación fija
              // contador opcional
              Flexible(
                // 👈 opcional
                child: Text(
                  '${_getTotalEventCountForMonth()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterButton(
                  'todos',
                  _filterLabel('Todos', 'Todos'),
                  Icons.event_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterButton(
                  'cumpleaños',
                  _filterLabel('Cumpleaños', 'Cumpl.'),
                  Icons.cake_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterButton(
                  'efemerides',
                  _filterLabel('Efemérides', 'Efem.'),
                  Icons.history_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard({required bool isTablet}) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: _primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vista mensual',
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Selecciona un día para ver sus eventos',
                      style: TextStyle(color: _textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ir al mes actual',
                onPressed: () {
                  final today = DateTime.now();
                  setState(() {
                    _focusedDay = today;
                    _selectedDay = today;
                  });
                  _refreshEventsForCurrentYear();
                },
                icon: const Icon(Icons.today_rounded, color: _primary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TableCalendar<Event>(
              locale: 'es_ES',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              onDaySelected: _onDaySelected,
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
                _refreshEventsForCurrentYear();
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (date, locale) =>
                    '${_getMonthName(date.month)} ${date.year}',
                titleTextStyle: const TextStyle(
                  color: _textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left_rounded,
                  color: _primary,
                  size: 27,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right_rounded,
                  color: _primary,
                  size: 27,
                ),
                headerPadding: const EdgeInsets.only(top: 4, bottom: 13),
                decoration: const BoxDecoration(),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: _textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                weekendStyle: TextStyle(
                  color: _textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                cellMargin: const EdgeInsets.all(3),
                cellPadding: EdgeInsets.zero,
                todayDecoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w800,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
                defaultTextStyle: const TextStyle(
                  color: _textDark,
                  fontWeight: FontWeight.w500,
                ),
                weekendTextStyle: const TextStyle(
                  color: _textDark,
                  fontWeight: FontWeight.w500,
                ),
                outsideTextStyle: const TextStyle(color: Color(0xFFCAD1DB)),
                markerDecoration: const BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
              ),
              calendarBuilders: CalendarBuilders<Event>(
                markerBuilder: (context, date, dayEvents) {
                  if (dayEvents.isEmpty) return null;

                  final hasBirthday = dayEvents.any(
                    (event) => event.type == EventType.birthday,
                  );
                  final hasEfemeride = dayEvents.any(
                    (event) => event.type == EventType.efemeride,
                  );

                  final markerColor = hasBirthday && hasEfemeride
                      ? _primary
                      : hasBirthday
                      ? _birthdayColor
                      : _efemerideColor;

                  final markerIcon = hasBirthday && hasEfemeride
                      ? Icons.event_rounded
                      : hasBirthday
                      ? Icons.cake_rounded
                      : Icons.history_rounded;

                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: markerColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: markerColor.withValues(alpha: 0.22),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(markerIcon, size: 10, color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 15),
          _buildCalendarLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Wrap(
      spacing: 18,
      runSpacing: 10,
      children: [
        _buildLegendItem(
          Icons.cake_rounded,
          'Cumpleaños',
          _birthdayColor,
          false,
        ),
        _buildLegendItem(
          Icons.history_rounded,
          'Efemérides',
          _efemerideColor,
          false,
        ),
        _buildLegendItem(Icons.event_rounded, 'Ambos eventos', _primary, false),
      ],
    );
  }

  Widget _buildInformationColumn({
    required bool isAdmin,
    required bool isOffline,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMonthlySummaryCard(),
        const SizedBox(height: 16),
        _buildSelectedDayCard(),
        const SizedBox(height: 16),
        _buildStatusCard(isAdmin: isAdmin, isOffline: isOffline),
      ],
    );
  }

  Widget _buildMonthlySummaryCard() {
    final birthdays = _getEventCountByType(EventType.birthday);
    final efemerides = _getEventCountByType(EventType.efemeride);
    final total = _getTotalEventCountForMonth();

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Resumen del mes',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getMonthName(_focusedDay.month),
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          _buildTotalSummary(total),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildCompactSummary(
                  'Cumpleaños',
                  birthdays,
                  Icons.cake_rounded,
                  _birthdayColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCompactSummary(
                  'Efemérides',
                  efemerides,
                  Icons.history_rounded,
                  _efemerideColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSummary(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primary.withValues(alpha: 0.10),
            _primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _primary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_note_rounded,
              color: _primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Text(
              'Eventos registrados',
              style: TextStyle(
                color: _textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$total',
            style: const TextStyle(
              color: _primary,
              fontSize: 29,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSummary(
    String label,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 9),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayCard() {
    final selected = _selectedDay ?? _focusedDay;
    final dayEvents = _getEventsForDay(selected);

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Día seleccionado',
            style: TextStyle(
              color: _textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${selected.day}',
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _getMonthName(selected.month).substring(0, 3),
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${selected.day} de ${_getMonthName(selected.month)} de ${selected.year}',
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (dayEvents.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    color: Color(0xFFADB8C6),
                    size: 27,
                  ),
                  SizedBox(height: 7),
                  Text(
                    'No hay eventos para este día',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _textMuted, fontSize: 12),
                  ),
                ],
              ),
            )
          else ...[
            ...dayEvents
                .take(3)
                .map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _buildEventPreview(event),
                  ),
                ),
            if (dayEvents.length > 3)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          EventDetailsDialog(date: selected, events: dayEvents),
                    );
                  },
                  child: Text(
                    'Ver los ${dayEvents.length} eventos',
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventPreview(Event event) {
    final isBirthday = event.type == EventType.birthday;
    final color = isBirthday ? _birthdayColor : _efemerideColor;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(
            isBirthday ? Icons.cake_rounded : Icons.history_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({required bool isAdmin, required bool isOffline}) {
    final color = isOffline ? Colors.orange : const Color(0xFF27966D);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estado del calendario',
            style: TextStyle(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isOffline ? 'Funcionando sin conexión' : 'Estado disponible',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (isOffline) ...[
            const SizedBox(height: 9),
            const Text(
              'Se están utilizando los datos locales disponibles.',
              style: TextStyle(color: _textMuted, fontSize: 11, height: 1.4),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final provider = Provider.of<EfemerideProvider>(
                    context,
                    listen: false,
                  );
                  if (!provider.syncing) {
                    _syncEfemerides(provider);
                  }
                },
                icon: const Icon(Icons.cloud_sync_rounded, size: 17),
                label: const Text('Sincronizar ahora'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _primary),
                ),
              ),
            ),
          ],
          if (isAdmin) ...[
            const SizedBox(height: 13),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  color: _primary,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tienes permisos para gestionar efemérides.',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_rounded,
            size: 14,
            color: Colors.blueGrey.shade300,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              'Directorio Telefónico Desoft  •  Calendario corporativo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey.shade400,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE9EEF5)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF263B53).withValues(alpha: 0.045),
          blurRadius: 18,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  String _filterLabel(String full, String short) {
    return MediaQuery.of(context).size.width < 420 ? short : full;
  }

  Widget _buildFilterButton(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    final color = value == 'cumpleaños'
        ? _birthdayColor
        : value == 'efemerides'
        ? _efemerideColor
        : _primary;

    return Material(
      color: isSelected ? color : const Color(0xFFF5F7FA),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 10,
          ), // 👈 menos padding
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE8EDF3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // 👈 no fuerza ancho extra
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : color,
              ), // 👈 14 en vez de 15
              const SizedBox(width: 4), // 👈 4 en vez de 5
              Flexible(
                // 👈 el texto puede encoger
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _textDark,
                    fontSize: 11, // 👈 11 en vez de 11.5
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    IconData icon,
    String text,
    Color color,
    bool isSmall,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 23,
          height: 23,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            color: _textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
