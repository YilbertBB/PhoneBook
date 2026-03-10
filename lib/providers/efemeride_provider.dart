import 'package:flutter/material.dart';
import '../services/data/efemeride_repository.dart';
import '../services/service_locator.dart';
import '../models/efemeride.dart';
import '../utils/error_messages.dart';

class EfemerideProvider with ChangeNotifier {
  final EfemerideRepository _efemerideRepository =
      ServiceLocator().efemerideRepository;

  List<Efemeride> _efemerides = [];
  List<Efemeride> _todayEfemerides = [];
  List<Efemeride> _upcomingEfemerides = [];
  final Map<int, List<Efemeride>> _efemeridesByMonth = {};

  bool _loading = false;
  bool _hasLoaded = false;
  String _error = '';

  // NUEVAS PROPIEDADES PARA OFFLINE
  bool _isOffline = false;
  bool _syncing = false;
  DateTime? _lastSyncDate;
  int _localDataCount = 0;

  // Getters
  List<Efemeride> get efemerides => _efemerides;
  List<Efemeride> get todayEfemerides => _todayEfemerides;
  List<Efemeride> get upcomingEfemerides => _upcomingEfemerides;
  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  bool get hasError => _error.isNotEmpty;
  String get error => _error;
  int get totalEfemerides => _efemerides.length;

  // NUEVOS GETTERS PARA OFFLINE
  bool get isOffline => _isOffline;
  bool get syncing => _syncing;
  DateTime? get lastSyncDate => _lastSyncDate;
  int get localDataCount => _localDataCount;
  bool get hasLocalData => _localDataCount > 0;

  // ============ MÉTODOS PRINCIPALES (OFFLINE-FIRST) ============

  // Cargar todas las efemérides
  Future<void> loadEfemerides({bool forceRefresh = false}) async {
    if (_loading && !forceRefresh) return;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      // Para la primera carga, siempre forzar refresh
      final isFirstLoad = !_hasLoaded;
      final actualForceRefresh = forceRefresh || isFirstLoad;

      final response = await _efemerideRepository.getEfemerides(
        forceRefresh: actualForceRefresh,
      );

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.dataNotFound;

        // Si hay error pero tenemos datos locales, no es crítico
        if (_efemerides.isNotEmpty) {
          _error = 'Usando datos locales. $_error';
          _isOffline = true;
        }
      } else {
        _efemerides = response.data ?? [];
        _hasLoaded = true;
        _isOffline = false;

        // Actualizar listas derivadas
        _updateDerivedLists();

        // Actualizar estadísticas locales
        _updateLocalStats();
      }
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);

      // Si tenemos datos locales, marcar como offline
      if (_efemerides.isNotEmpty) {
        _isOffline = true;
      }

      notifyListeners();
    }
  }

  // NUEVO: Actualizar listas derivadas
  void _updateDerivedLists() {
    final now = DateTime.now();

    // Efemérides de hoy
    _todayEfemerides = _efemerides.where((efemeride) {
      return efemeride.isToday;
    }).toList();

    // Efemérides próximas (próximos 7 días)
    _upcomingEfemerides = _efemerides.where((efemeride) {
      final difference = efemeride.fecha.difference(now).inDays;
      return difference >= 0 && difference <= 7;
    }).toList();

    // Organizar por mes
    _efemeridesByMonth.clear();
    for (final efemeride in _efemerides) {
      final monthKey = efemeride.fecha.month;
      if (!_efemeridesByMonth.containsKey(monthKey)) {
        _efemeridesByMonth[monthKey] = [];
      }
      _efemeridesByMonth[monthKey]!.add(efemeride);
    }
  }

  // NUEVO: Actualizar estadísticas locales
  // Corregir en el método _updateLocalStats() del provider:
  void _updateLocalStats() async {
    try {
      final stats = await _efemerideRepository.getLocalStats();
      _localDataCount = stats['totalEfemerides'] as int;

      final lastSyncString = stats['lastSyncFormatted'] as String?;
      if (lastSyncString != null && lastSyncString != 'Nunca') {
        try {
          _lastSyncDate = DateTime.parse(lastSyncString);
        } catch (e) {
          _lastSyncDate = null;
        }
      } else {
        _lastSyncDate = null;
      }
    } catch (e) {
      '';
    }
  }

  // NUEVO: Sincronizar manualmente
  Future<bool> syncEfemerides() async {
    if (_syncing) return false;

    _syncing = true;
    _error = '';
    notifyListeners();

    try {
      final success = await _efemerideRepository.syncEfemerides();
      _syncing = false;

      if (success) {
        // Recargar datos después de sincronizar
        await loadEfemerides(forceRefresh: true);
        _isOffline = false;
      } else {
        _error = 'Error al sincronizar efemérides';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _syncing = false;
      _error = 'Error de sincronización: $e';
      notifyListeners();
      return false;
    }
  }

  // ============ MÉTODOS DE CONSULTA ============

  // Obtener efemérides por mes
  List<Efemeride> getEfemeridesByMonth(int month) {
    // Primero buscar en cache local
    if (_efemeridesByMonth.containsKey(month)) {
      return _efemeridesByMonth[month]!;
    }

    // Si no está en cache, calcular
    final monthEfemerides = _efemerides
        .where((efemeride) => efemeride.fecha.month == month)
        .toList();

    _efemeridesByMonth[month] = monthEfemerides;
    return monthEfemerides;
  }

  // Obtener efemérides por mes (con carga remota si es necesario)
  Future<List<Efemeride>> loadEfemeridesByMonth(int month) async {
    try {
      final response = await _efemerideRepository.getEfemeridesByMonth(month);

      if (!response.hasError && response.data != null) {
        // Actualizar lista principal con nuevos datos
        _updateEfemerideList(response.data!);
        return response.data!;
      }

      // Fallback a datos locales
      return getEfemeridesByMonth(month);
    } catch (e) {
      return getEfemeridesByMonth(month);
    }
  }

  // Obtener efemérides por fecha
  Future<List<Efemeride>> getEfemeridesByDate(DateTime date) async {
    try {
      final response = await _efemerideRepository.getEfemeridesByDate(date);

      if (!response.hasError && response.data != null) {
        // Actualizar lista principal con nuevos datos
        _updateEfemerideList(response.data!);
        return response.data!;
      }

      // Fallback a datos locales
      return _efemerides.where((efemeride) {
        return efemeride.isSameDate(date);
      }).toList();
    } catch (e) {
      return _efemerides.where((efemeride) {
        return efemeride.isSameDate(date);
      }).toList();
    }
  }

  // Cargar efemérides de hoy (con soporte offline)
  Future<void> loadTodayEfemerides() async {
    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _efemerideRepository.getTodayEfemerides();

      _loading = false;

      if (response.hasError) {
        // Usar datos locales si hay error
        if (_efemerides.isNotEmpty) {
          _todayEfemerides = _efemerides.where((e) => e.isToday).toList();
          _isOffline = true;
        } else {
          _todayEfemerides = [];
        }
      } else {
        _todayEfemerides = response.data ?? [];
        _isOffline = false;

        // Actualizar lista principal
        _updateEfemerideList(_todayEfemerides);
      }
      notifyListeners();
    } catch (e) {
      _loading = false;

      // Fallback a datos locales
      _todayEfemerides = _efemerides.where((e) => e.isToday).toList();
      if (_todayEfemerides.isNotEmpty) {
        _isOffline = true;
      }

      notifyListeners();
    }
  }

  // NUEVO: Cargar efemérides próximas
  Future<void> loadUpcomingEfemerides(int days) async {
    try {
      final response = await _efemerideRepository.getUpcomingEfemerides(days);

      if (!response.hasError && response.data != null) {
        _upcomingEfemerides = response.data!;
        _updateEfemerideList(_upcomingEfemerides);
      }
    } catch (e) {
      // Fallback a cálculo local
      final now = DateTime.now();
      _upcomingEfemerides = _efemerides.where((efemeride) {
        final difference = efemeride.fecha.difference(now).inDays;
        return difference >= 0 && difference <= days;
      }).toList();
    }
  }

  // ============ OPERACIONES CRUD ============

  // Crear efeméride
  Future<bool> createEfemeride(
    DateTime fecha,
    String dato,
    String detalle,
  ) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final efemeride = Efemeride(
        id: 0,
        fecha: fecha,
        dato: dato,
        detalle: detalle,
      );

      final response = await _efemerideRepository.createEfemeride(efemeride);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Recargar la lista para incluir la nueva efeméride
        await loadEfemerides(forceRefresh: true);
        _isOffline = false;
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // Actualizar efeméride
  Future<bool> updateEfemeride(Efemeride efemeride) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _efemerideRepository.updateEfemeride(efemeride);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Actualizar en la lista local
        final index = _efemerides.indexWhere((e) => e.id == efemeride.id);
        if (index != -1) {
          _efemerides[index] = response.data!;
          _updateDerivedLists();
        }
        _isOffline = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // Eliminar efeméride
  Future<bool> deleteEfemeride(int id) async {
    if (_loading) return false;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _efemerideRepository.deleteEfemeride(id);

      _loading = false;

      if (response.hasError) {
        _error = response.error ?? ErrorMessages.operationFailed;
        notifyListeners();
        return false;
      } else {
        // Remover de la lista local
        _efemerides.removeWhere((e) => e.id == id);
        _updateDerivedLists();
        _isOffline = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _loading = false;
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // ============ MÉTODOS ADICIONALES ============

  // Buscar efemérides
  Future<List<Efemeride>> searchEfemerides(String query) async {
    try {
      final response = await _efemerideRepository.searchEfemerides(query);

      if (!response.hasError && response.data != null) {
        return response.data!;
      }

      // Fallback: buscar en lista local
      return _efemerides.where((efemeride) {
        return efemeride.dato.toLowerCase().contains(query.toLowerCase()) ||
            efemeride.detalle.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      return _efemerides.where((efemeride) {
        return efemeride.dato.toLowerCase().contains(query.toLowerCase()) ||
            efemeride.detalle.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }

  // Obtener estadísticas
  // En EfemerideProvider, simplifica el método:
  Future<Map<String, dynamic>> getEfemerideStats() async {
    try {
      // Usar el repositorio que ahora tiene el método implementado
      return await _efemerideRepository.getEfemerideStats();
    } catch (e) {
      return {
        'total': 0,
        'por_mes': {},
        'por_tipo': {},
        'ultimo_mes': 0,
        'hoy': 0,
        'last_sync': 'Error',
        'is_offline': true,
      };
    }
  }

  // ============ MÉTODOS DE UTILIDAD ============

  // NUEVO: Actualizar lista principal manteniendo unicidad
  void _updateEfemerideList(List<Efemeride> newEfemerides) {
    final Map<int, Efemeride> efemerideMap = {};

    // Primero agregar existentes
    for (final efemeride in _efemerides) {
      efemerideMap[efemeride.id] = efemeride;
    }

    // Luego actualizar/agregar nuevas
    for (final efemeride in newEfemerides) {
      efemerideMap[efemeride.id] = efemeride;
    }

    // Convertir de nuevo a lista y ordenar por fecha
    _efemerides = efemerideMap.values.toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    _updateDerivedLists();
  }

  // Limpiar error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Refrescar datos
  Future<void> refreshEfemerides() async {
    await loadEfemerides(forceRefresh: true);
  }

  // NUEVO: Cargar datos iniciales
  Future<void> loadInitialData() async {
    if (!_hasLoaded) {
      await loadEfemerides();
    }

    // Cargar efemérides de hoy
    await loadTodayEfemerides();

    // Cargar efemérides próximas
    await loadUpcomingEfemerides(7);

    // Actualizar estadísticas
    _updateLocalStats();
  }

  // NUEVO: Obtener estadísticas del provider
  Map<String, dynamic> getStatistics() {
    return {
      'total': _efemerides.length,
      'today': _todayEfemerides.length,
      'upcoming': _upcomingEfemerides.length,
      'isOffline': _isOffline,
      'localDataCount': _localDataCount,
      'lastSync': _lastSyncDate?.toIso8601String() ?? 'Nunca',
      'byMonth': _efemeridesByMonth.keys.length,
    };
  }

  // NUEVO: Obtener efeméride por ID
  Future<Efemeride?> getEfemerideById(int id) async {
    // Primero buscar localmente
    try {
      return _efemerides.firstWhere((efemeride) => efemeride.id == id);
    } catch (e) {
      // Si no está local, cargar individualmente
      final response = await _efemerideRepository.getEfemerideById(id);

      if (!response.hasError && response.data != null) {
        // Agregar a lista local
        _efemerides.add(response.data!);
        _efemerides.sort((a, b) => a.fecha.compareTo(b.fecha));
        _updateDerivedLists();
        notifyListeners();
        return response.data;
      }

      return null;
    }
  }
}
