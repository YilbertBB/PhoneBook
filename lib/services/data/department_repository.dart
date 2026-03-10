import 'package:flutter/material.dart';

import '../../db/app_database.dart';
import '../../db/daos/department_dao.dart';
import '../../db/entities/department_entity.dart';
import '../../models/department_lite.dart';
import '../../utils/connectivity_manager.dart';
import '../api/api_response.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../../models/department.dart';

class DepartmentRepository {
  final ApiClient _apiClient;
  final ConnectivityManager _connectivityManager;
  late DepartmentDao _departmentDao;

  DepartmentRepository({
    required ApiClient apiClient,
    required AppDatabase appDatabase,
    required ConnectivityManager connectivityManager,
  }) : _apiClient = apiClient,
       _connectivityManager = connectivityManager {
    _departmentDao = appDatabase.departmentDao;
  }

  // Obtener todos los departamentos (OFFLINE-FIRST)
  Future<ApiResponse<List<Department>>> getDepartments({
    bool forceRefresh = false,
  }) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        try {
          final apiResponse = await _getDepartmentsFromApi();

          if (!apiResponse.hasError && apiResponse.data != null) {
            await _saveDepartmentsToLocal(apiResponse.data!);
            return apiResponse;
          }
        } catch (e) {
          debugPrint('⚠️ API falló: $e');
        }
      }

      return await _getDepartmentsFromLocal();
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Obtener departamento por ID
  Future<ApiResponse<Department>> getDepartmentById(int id) async {
    try {
      final localDepartment = await _departmentDao.getDepartmentById(id);

      if (localDepartment != null) {
        final department = _departmentDao.toDepartmentModel(localDepartment);
        return ApiResponse.success(department);
      }

      final hasNetwork = await _connectivityManager.hasNetworkConnection();
      if (hasNetwork) {
        final apiResponse = await _getDepartmentByIdFromApi(id);

        if (!apiResponse.hasError && apiResponse.data != null) {
          await _saveDepartmentToLocal(apiResponse.data!);
        }

        return apiResponse;
      }

      return ApiResponse.error(
        'Departamento no encontrado localmente y sin conexión',
      );
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Crear departamento
  Future<ApiResponse<Department>> createDepartment(
    Department department,
  ) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (!hasNetwork) {
        return ApiResponse.error('No hay conexión para crear departamento');
      }

      final apiResponse = await _createDepartmentInApi(department);

      if (!apiResponse.hasError && apiResponse.data != null) {
        await _saveDepartmentToLocal(apiResponse.data!);
      }

      return apiResponse;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Actualizar departamento
  Future<ApiResponse<Department>> updateDepartment(
    Department department,
  ) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (!hasNetwork) {
        return ApiResponse.error('No hay conexión para actualizar');
      }

      final apiResponse = await _updateDepartmentInApi(department);

      if (!apiResponse.hasError && apiResponse.data != null) {
        await _saveDepartmentToLocal(apiResponse.data!);
      }

      return apiResponse;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Eliminar departamento
  Future<ApiResponse<bool>> deleteDepartment(int id) async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (!hasNetwork) {
        return ApiResponse.error('No hay conexión para eliminar');
      }

      final apiResponse = await _deleteDepartmentFromApi(id);

      if (!apiResponse.hasError && apiResponse.data == true) {
        await _departmentDao.deleteDepartment(id);
      }

      return apiResponse;
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Buscar departamentos
  Future<ApiResponse<List<Department>>> searchDepartments(String query) async {
    try {
      final localResults = await _departmentDao.searchDepartments(query);
      final localDepartments = _departmentDao.toDepartmentModelList(
        localResults,
      );

      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        final apiResponse = await _searchDepartmentsInApi(query);

        if (!apiResponse.hasError && apiResponse.data != null) {
          await _saveDepartmentsToLocal(apiResponse.data!);

          // Combinar resultados
          final combinedDepartments = _mergeDepartmentLists(
            localDepartments,
            apiResponse.data!,
          );
          return ApiResponse.success(combinedDepartments);
        }
      }

      return ApiResponse.success(localDepartments);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Sincronizar departamentos
  // En el método syncDepartments, agrega prints:
  Future<bool> syncDepartments() async {
    try {
      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (!hasNetwork) {
        return false;
      }

      final apiResponse = await _getDepartmentsFromApi();

      if (apiResponse.hasError || apiResponse.data == null) {
        return false;
      }

      await _saveDepartmentsToLocal(apiResponse.data!);

      // Verificar que se guardaron
      // final countAfter = await _departmentDao.countDepartments();

      return true;
    } catch (e) {
      return false;
    }
  }

  // También agrega logs en _getDepartmentsFromApi:
  Future<ApiResponse<List<Department>>> _getDepartmentsFromApi() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        ApiEndpoints.departments,
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al obtener departamentos',
        );
      }

      if (response.data == null) {
        return ApiResponse.success([]);
      }

      try {
        final departments = response.data!
            .map((json) => Department.fromJson(json))
            .toList();
        return ApiResponse.success(departments);
      } catch (e) {
        return ApiResponse.error('Error al procesar departamentos');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Department>> _getDepartmentByIdFromApi(int id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiEndpoints.departments}/$id',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al obtener departamento',
        );
      }

      if (response.data == null) {
        return ApiResponse.error('Departamento no encontrado');
      }

      try {
        final department = Department.fromJson(response.data!);
        return ApiResponse.success(department);
      } catch (e) {
        return ApiResponse.error('Error al procesar departamento');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Department>> _createDepartmentInApi(
    Department department,
  ) async {
    try {
      final dto = department.toCreateDto();

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.departments,
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al crear departamento',
        );
      }

      if (response.data == null) {
        return ApiResponse.error('Error al procesar respuesta');
      }

      try {
        final newDepartment = Department.fromJson(response.data!);
        return ApiResponse.success(newDepartment);
      } catch (e) {
        return ApiResponse.error('Error al procesar departamento creado');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<Department>> _updateDepartmentInApi(
    Department department,
  ) async {
    try {
      final dto = department.toUpdateDto();

      final response = await _apiClient.put<Map<String, dynamic>>(
        '${ApiEndpoints.departments}/${department.id}',
        body: dto,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al actualizar departamento',
        );
      }

      if (response.data == null) {
        return ApiResponse.error('Error al procesar respuesta');
      }

      try {
        final updatedDepartment = Department.fromJson(response.data!);
        return ApiResponse.success(updatedDepartment);
      } catch (e) {
        return ApiResponse.error('Error al procesar departamento actualizado');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<bool>> _deleteDepartmentFromApi(int id) async {
    try {
      final response = await _apiClient.delete<bool>(
        '${ApiEndpoints.departments}/$id',
        fromJson: (json) => true,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al eliminar departamento',
        );
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  Future<ApiResponse<List<Department>>> _searchDepartmentsInApi(
    String query,
  ) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '${ApiEndpoints.departments}/search/$query',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.hasError) {
        return ApiResponse.error(
          response.error ?? 'Error al buscar departamentos',
        );
      }

      if (response.data == null || response.data!.isEmpty) {
        return ApiResponse.success([]);
      }

      try {
        final departments = response.data!
            .map((json) => Department.fromJson(json))
            .toList();
        return ApiResponse.success(departments);
      } catch (e) {
        return ApiResponse.error('Error al procesar búsqueda');
      }
    } catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  // Métodos para base de datos local
  Future<ApiResponse<List<Department>>> _getDepartmentsFromLocal() async {
    try {
      final departments = await _departmentDao.getAllDepartmentsAsModels();
      return ApiResponse.success(departments);
    } catch (e) {
      return ApiResponse.error('Error al obtener departamentos locales');
    }
  }

  Future<void> _saveDepartmentsToLocal(List<Department> departments) async {
    try {
      final entities = departments
          .map((department) => DepartmentEntity.fromDepartmentModel(department))
          .toList();
      await _departmentDao.insertOrUpdateAll(entities);
    } catch (e) {
      debugPrint('Error al guardar departamentos en local: $e');
    }
  }

  Future<void> _saveDepartmentToLocal(Department department) async {
    try {
      final entity = DepartmentEntity.fromDepartmentModel(department);
      await _departmentDao.insertOrUpdate(entity);
    } catch (e) {
      debugPrint('Error al guardar departamento en local: $e');
    }
  }

  // Helper para combinar listas
  List<Department> _mergeDepartmentLists(
    List<Department> list1,
    List<Department> list2,
  ) {
    final Map<int, Department> mergedMap = {};

    for (final department in list1) {
      mergedMap[department.id] = department;
    }

    for (final department in list2) {
      mergedMap[department.id] = department;
    }

    return mergedMap.values.toList();
  }

  // Obtener estadísticas
  Future<Map<String, dynamic>> getLocalStats() async {
    final totalDepartments = await _departmentDao.countDepartments();
    final lastSyncDate = await _departmentDao.getLastSyncDate();

    return {
      'totalDepartments': totalDepartments,
      'lastSyncDate': lastSyncDate,
      'lastSyncFormatted': lastSyncDate?.toIso8601String() ?? 'Nunca',
    };
  }

  // Agregar al final de la clase DepartmentRepository, antes del último }

  // NUEVO: Obtener departamentos locales paginados
  Future<List<Department>> getLocalDepartmentsPaginated({
    int page = 0,
    int pageSize = 20,
    String? searchQuery,
  }) async {
    try {
      final offset = page * pageSize;
      final entities = await _departmentDao.getDepartmentsPaginated(
        limit: pageSize,
        offset: offset,
        searchQuery: searchQuery,
      );

      return _departmentDao.toDepartmentModelList(entities);
    } catch (e) {
      return [];
    }
  }

  // NUEVO: Obtener DepartmentLite paginados
  Future<List<DepartmentLite>> getLocalDepartmentsLitePaginated({
    int page = 0,
    int pageSize = 20,
    String? searchQuery,
  }) async {
    try {
      return await _departmentDao.getDepartmentsLitePaginated(
        limit: pageSize,
        offset: page * pageSize,
        searchQuery: searchQuery,
      );
    } catch (e) {
      return [];
    }
  }

  // NUEVO: Buscar departamentos paginados
  Future<List<Department>> searchDepartmentsPaginated({
    required String query,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      if (query.isEmpty) {
        return await getLocalDepartmentsPaginated(
          page: page,
          pageSize: pageSize,
        );
      }

      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        // Intentar búsqueda en API
        try {
          final apiResponse = await _searchDepartmentsInApi(query);
          if (!apiResponse.hasError && apiResponse.data != null) {
            await _saveDepartmentsToLocal(apiResponse.data!);

            // Filtrar y paginar localmente después de guardar
            return await getLocalDepartmentsPaginated(
              page: page,
              pageSize: pageSize,
              searchQuery: query,
            );
          }
        } catch (e) {
          debugPrint('Búsqueda API falló, usando local: $e');
        }
      }

      // Usar búsqueda local
      return await getLocalDepartmentsPaginated(
        page: page,
        pageSize: pageSize,
        searchQuery: query,
      );
    } catch (e) {
      return [];
    }
  }

  // NUEVO: Buscar DepartmentLite paginados
  Future<List<DepartmentLite>> searchDepartmentsLitePaginated({
    required String query,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      if (query.isEmpty) {
        return await getLocalDepartmentsLitePaginated(
          page: page,
          pageSize: pageSize,
        );
      }

      final hasNetwork = await _connectivityManager.hasNetworkConnection();

      if (hasNetwork) {
        try {
          final apiResponse = await _searchDepartmentsInApi(query);
          if (!apiResponse.hasError && apiResponse.data != null) {
            await _saveDepartmentsToLocal(apiResponse.data!);
          }
        } catch (e) {
          debugPrint('Búsqueda API falló, usando local: $e');
        }
      }

      // Siempre usar búsqueda local para paginación
      return await _departmentDao.getDepartmentsLitePaginated(
        limit: pageSize,
        offset: page * pageSize,
        searchQuery: query,
      );
    } catch (e) {
      return [];
    }
  }

  // NUEVO: Obtener count con filtro
  Future<int> countDepartmentsWithFilter(String? searchQuery) async {
    try {
      return await _departmentDao.countDepartmentsWithFilter(searchQuery);
    } catch (e) {
      return 0;
    }
  }
}
