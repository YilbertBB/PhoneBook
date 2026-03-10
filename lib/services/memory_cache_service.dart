import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

/// Tipos de caché disponibles
enum CacheType {
  volatile, // Datos que cambian frecuentemente (10 min)
  stable, // Datos estables (2 horas)
  critical, // Datos críticos que rara vez cambian (24 horas)
  permanent, // Sin expiración (hasta limpieza manual)
}

/// Servicio de caché en memoria con expiración automática y políticas avanzadas
class MemoryCacheService {
  static final MemoryCacheService _instance = MemoryCacheService._internal();

  factory MemoryCacheService() => _instance;

  MemoryCacheService._internal() {
    // Iniciar limpieza periódica automática
    _startCleanupTimer();
  }

  // ========== CONFIGURACIÓN ==========
  static const Duration _defaultCleanupInterval = Duration(minutes: 1);
  static const int _maxCacheSize = 100; // Máximo de items en caché
  static const Duration _defaultVolatileTTL = Duration(minutes: 10);
  static const Duration _defaultStableTTL = Duration(hours: 2);
  static const Duration _defaultCriticalTTL = Duration(hours: 24);

  // ========== ESTRUCTURAS DE DATOS ==========
  final Map<String, CacheEntry> _cache = HashMap(); // HashMap para acceso O(1)
  final Map<String, List<String>> _categoryKeys = {};
  final LinkedHashMap<String, DateTime> _accessLog =
      LinkedHashMap(); // Para LRU

  Timer? _cleanupTimer;

  // ========== MÉTODOS PÚBLICOS ==========

  /// Obtiene un item del caché, actualizando su posición en LRU
  Future<T?> get<T>(String key) async {
    final entry = _cache[key];

    if (entry == null) return null;

    // Verificar expiración
    if (entry.expiresAt != null && entry.expiresAt!.isBefore(DateTime.now())) {
      await _removeEntry(key);
      return null;
    }

    // Actualizar tiempo de acceso (LRU)
    _accessLog[key] = DateTime.now();

    // Incrementar contador de accesos para estadísticas
    entry.accessCount++;
    entry.lastAccessed = DateTime.now();

    return entry.data as T;
  }

  /// Almacena un item en caché con política configurable
  Future<void> set<T>(
    String key,
    T data, {
    CacheType type = CacheType.stable,
    String? category,
    Duration? customTTL,
    bool forceUpdate = false,
  }) async {
    // Si el caché está lleno, eliminar el menos usado recientemente (LRU)
    if (_cache.length >= _maxCacheSize && !_cache.containsKey(key)) {
      await _evictLRUItem();
    }

    // Configurar TTL según tipo
    Duration ttl;
    switch (type) {
      case CacheType.volatile:
        ttl = _defaultVolatileTTL;
        break;
      case CacheType.stable:
        ttl = _defaultStableTTL;
        break;
      case CacheType.critical:
        ttl = _defaultCriticalTTL;
        break;
      case CacheType.permanent:
        ttl = Duration(days: 365 * 100); // ~100 años
        break;
    }

    final expiresAt = customTTL != null
        ? DateTime.now().add(customTTL)
        : DateTime.now().add(ttl);

    // Actualizar o crear entrada
    _cache[key] = CacheEntry(
      data: data,
      expiresAt: expiresAt,
      category: category,
      type: type,
      created: DateTime.now(),
    );

    _accessLog[key] = DateTime.now();

    // Registrar en categoría si se especificó
    if (category != null) {
      _categoryKeys.putIfAbsent(category, () => []);
      if (!_categoryKeys[category]!.contains(key)) {
        _categoryKeys[category]!.add(key);
      }
    }
  }

  /// Obtiene o calcula y cachea si no existe (patrón cache-aside)
  Future<T> getOrSet<T>(
    String key,
    Future<T> Function() fetchData, {
    CacheType type = CacheType.stable,
    String? category,
    Duration? ttl,
  }) async {
    // Intentar obtener del caché
    final cached = await get<T>(key);
    if (cached != null) {
      return cached;
    }

    // Obtener datos frescos
    final freshData = await fetchData();

    // Almacenar en caché
    await set<T>(
      key,
      freshData,
      type: type,
      category: category,
      customTTL: ttl,
    );

    return freshData;
  }

  /// Invalida una entrada específica
  Future<void> invalidate(String key) async {
    await _removeEntry(key);
  }

  /// Invalida todas las entradas de una categoría
  Future<void> invalidateCategory(String category) async {
    final keys = _categoryKeys[category]?.toList() ?? [];

    for (final key in keys) {
      await _removeEntry(key);
    }

    _categoryKeys.remove(category);
  }

  /// Invalida entradas por patrón (usando wildcards)
  Future<void> invalidatePattern(String pattern) async {
    final keysToRemove = <String>[];

    for (final key in _cache.keys) {
      if (_matchesPattern(key, pattern)) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      await _removeEntry(key);
    }
  }

  /// Limpia todo el caché
  Future<void> clear() async {
    _cache.clear();
    _categoryKeys.clear();
    _accessLog.clear();
  }

  /// Obtiene estadísticas del caché
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    int expiredCount = 0;
    int volatileCount = 0;
    int stableCount = 0;
    int criticalCount = 0;
    int permanentCount = 0;

    int totalAccessCount = 0;
    DateTime? oldestEntry;
    DateTime? newestEntry;

    for (final entry in _cache.values) {
      // Contar por tipo
      switch (entry.type) {
        case CacheType.volatile:
          volatileCount++;
          break;
        case CacheType.stable:
          stableCount++;
          break;
        case CacheType.critical:
          criticalCount++;
          break;
        case CacheType.permanent:
          permanentCount++;
          break;
      }

      // Contar expirados
      if (entry.expiresAt != null && entry.expiresAt!.isBefore(now)) {
        expiredCount++;
      }

      // Estadísticas de acceso
      totalAccessCount += entry.accessCount;

      // Encontrar entrada más antigua y más nueva
      if (oldestEntry == null || entry.created.isBefore(oldestEntry)) {
        oldestEntry = entry.created;
      }
      if (newestEntry == null || entry.created.isAfter(newestEntry)) {
        newestEntry = entry.created;
      }
    }

    return {
      'totalEntries': _cache.length,
      'expiredEntries': expiredCount,
      'byType': {
        'volatile': volatileCount,
        'stable': stableCount,
        'critical': criticalCount,
        'permanent': permanentCount,
      },
      'categories': _categoryKeys.length,
      'accessStats': {
        'totalAccesses': totalAccessCount,
        'avgAccessPerEntry': _cache.isEmpty
            ? 0
            : totalAccessCount / _cache.length,
      },
      'age': {
        'oldest': oldestEntry?.toIso8601String(),
        'newest': newestEntry?.toIso8601String(),
      },
      'memoryUsage': _estimateMemoryUsage(),
    };
  }

  /// Precalienta el caché con datos comunes
  Future<void> prewarm(Map<String, dynamic> data) async {
    for (final entry in data.entries) {
      await set(entry.key, entry.value, type: CacheType.stable);
    }
  }

  // ========== MÉTODOS PRIVADOS ==========

  /// Inicia el timer de limpieza automática
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(_defaultCleanupInterval, (_) {
      _cleanExpiredEntries();
    });
  }

  /// Limpia entradas expiradas
  Future<void> _cleanExpiredEntries() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (entry.value.expiresAt != null &&
          entry.value.expiresAt!.isBefore(now)) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      await _removeEntry(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint(
        '[MemoryCache] Limpiadas ${expiredKeys.length} entradas expiradas',
      );
    }
  }

  /// Elimina el item menos usado recientemente (LRU)
  Future<void> _evictLRUItem() async {
    if (_accessLog.isEmpty) return;

    // Encontrar la clave con el acceso más antiguo
    String? lruKey;
    DateTime? oldestAccess;

    for (final entry in _accessLog.entries) {
      if (oldestAccess == null || entry.value.isBefore(oldestAccess)) {
        oldestAccess = entry.value;
        lruKey = entry.key;
      }
    }

    if (lruKey != null) {
      await _removeEntry(lruKey);
    }
  }

  /// Elimina una entrada de todas las estructuras
  Future<void> _removeEntry(String key) async {
    final entry = _cache[key];

    if (entry != null && entry.category != null) {
      // Remover de la categoría
      final categoryList = _categoryKeys[entry.category!];
      categoryList?.remove(key);

      if (categoryList?.isEmpty ?? false) {
        _categoryKeys.remove(entry.category!);
      }
    }

    _cache.remove(key);
    _accessLog.remove(key);
  }

  /// Verifica si una clave coincide con un patrón (soporta * como wildcard)
  bool _matchesPattern(String key, String pattern) {
    if (pattern == '*') return true;

    final regexPattern = pattern
        .replaceAll('.', r'\.')
        .replaceAll('*', '.*')
        .replaceAll('?', '.');

    final regex = RegExp('^$regexPattern\$');
    return regex.hasMatch(key);
  }

  /// Estimación del uso de memoria (aproximada)
  int _estimateMemoryUsage() {
    // Estimación simple: ~100 bytes por entrada + tamaño de datos
    int estimatedBytes = _cache.length * 100;

    for (final entry in _cache.values) {
      if (entry.data is String) {
        estimatedBytes += (entry.data as String).length * 2; // UTF-16
      } else if (entry.data is List) {
        estimatedBytes += (entry.data as List).length * 8; // Aproximación
      } else if (entry.data is Map) {
        estimatedBytes += (entry.data as Map).length * 16;
      }
    }

    return estimatedBytes;
  }

  /// Dispose: detiene el timer de limpieza
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }
}

/// Entrada individual del caché
class CacheEntry {
  final dynamic data;
  final DateTime? expiresAt;
  final String? category;
  final CacheType type;
  final DateTime created;

  DateTime lastAccessed;
  int accessCount;

  CacheEntry({
    required this.data,
    required this.expiresAt,
    required this.category,
    required this.type,
    required this.created,
  }) : lastAccessed = created,
       accessCount = 0;
}
