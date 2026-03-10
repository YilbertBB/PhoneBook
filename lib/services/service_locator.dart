import '../db/app_database.dart';
import '../utils/connectivity_manager.dart';
import 'api/api_client.dart';
import 'api/api_endpoints.dart';
import 'auth/auth_repository.dart';
import 'auth/auth_service.dart';
import 'auth/token_expiry_manager.dart';
import 'auth/token_manager.dart';
import 'auth_security_service.dart';
import 'data/department_repository.dart';
import 'data/efemeride_repository.dart';
import 'data/local_repository.dart';
import 'data/user_repository.dart';
import 'data/worker_repository.dart';
import 'data/worker_service.dart';
import 'data/department_service.dart';
import 'data/local_service.dart';
import 'data/user_service.dart';
import 'data/efemeride_service.dart';
import 'secure_token_manager.dart';

// Importar los providers
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import 'sync_service.dart';

// AGREGAR IMPORT DEL NUEVO SERVICIO DE ACTUALIZACIONES
import 'update/update_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late ApiClient _apiClient;
  late TokenManager _tokenManager;
  late SecureTokenManager _secureTokenManager;
  late AuthSecurityService _authSecurityService;
  late AuthService _authService;
  late WorkerService _workerService;
  late DepartmentService _departmentService;
  late LocalService _localService;
  late UserService _userService;
  late EfemerideService _efemerideService;

  // SERVICIOS EXISTENTES
  late AppDatabase _appDatabase;
  late ConnectivityManager _connectivityManager;
  late SyncService _syncService;

  late TokenExpiryManager _tokenExpiryManager;

  // AGREGAR NUEVO SERVICIO DE ACTUALIZACIONES
  late UpdateService _updateService;

  // Providers
  late AuthProvider _authProvider;
  late UserProvider _userProvider;

  // Repositorios
  late WorkerRepository _workerRepository;
  late DepartmentRepository _departmentRepository;
  late LocalRepository _localRepository;
  late EfemerideRepository _efemerideRepository;
  late AuthRepository _authRepository;
  late UserRepository _userRepository;

  Future<void> initialize() async {
    // ========== FASE 1: SERVICIOS BÁSICOS Y SEGURIDAD ==========
    _secureTokenManager = SecureTokenManager();
    _authSecurityService = AuthSecurityService();
    _tokenManager = _secureTokenManager;
    final token = await _secureTokenManager.getToken();
    _apiClient = ApiClient(baseUrl: ApiEndpoints.baseUrl, token: token);

    // ========== FASE 1.5: INICIALIZAR UPDATE SERVICE (necesita package_info) ==========
    // El UpdateService necesita inicializarse temprano para verificar al inicio
    _updateService = UpdateService();

    // ========== FASE 2: SERVICIOS DE NEGOCIO ==========
    _authService = AuthService(
      client: _apiClient,
      tokenManager: _secureTokenManager,
    );
    _workerService = WorkerService(_apiClient);
    _departmentService = DepartmentService(_apiClient);
    _localService = LocalService(_apiClient);
    _userService = UserService(_apiClient);
    _efemerideService = EfemerideService(_apiClient);

    // ========== FASE 3: SERVICIOS OFFLINE ==========
    _appDatabase = await AppDatabase.instance();
    await _appDatabase.initializeDaos();
    _connectivityManager = ConnectivityManager();

    _workerRepository = WorkerRepository(
      apiClient: _apiClient,
      appDatabase: _appDatabase,
      connectivityManager: _connectivityManager,
    );

    _departmentRepository = DepartmentRepository(
      apiClient: _apiClient,
      appDatabase: _appDatabase,
      connectivityManager: _connectivityManager,
    );

    _localRepository = LocalRepository(
      apiClient: _apiClient,
      appDatabase: _appDatabase,
      connectivityManager: _connectivityManager,
    );

    _efemerideRepository = EfemerideRepository(
      apiClient: _apiClient,
      appDatabase: _appDatabase,
      connectivityManager: _connectivityManager,
    );

    _authRepository = AuthRepository(
      apiClient: _apiClient,
      appDatabase: _appDatabase,
      connectivityManager: _connectivityManager,
      tokenManager: _secureTokenManager,
      authService: _authService,
    );

    _userRepository = UserRepository(
      appDatabase: _appDatabase,
      connectivityManager: _connectivityManager,
      userService: _userService,
    );

    _syncService = SyncService(appDatabase: _appDatabase);

    _syncService.setServices(
      workerService: _workerService,
      departmentService: _departmentService,
      localService: _localService,
      userService: _userService,
      efemerideService: _efemerideService,
    );

    _syncService.setWorkerRepository(_workerRepository);
    _syncService.setDepartmentRepository(_departmentRepository);
    _syncService.setLocalRepository(_localRepository);
    _syncService.setEfemerideRepository(_efemerideRepository);
    _syncService.setAuthRepository(_authRepository);
    _syncService.setUserRepository(_userRepository);

    // ========== FASE 4: SERVICIOS ADICIONALES ==========
    _tokenExpiryManager = TokenExpiryManager();

    // ========== FASE 5: PROVIDERS ==========
    _authProvider = AuthProvider();
    _userProvider = UserProvider();
  }

  // Getters para servicios
  ApiClient get apiClient => _apiClient;
  TokenManager get tokenManager => _tokenManager;
  SecureTokenManager get secureTokenManager => _secureTokenManager;
  AuthSecurityService get authSecurityService => _authSecurityService;
  AuthService get authService => _authService;
  WorkerService get workerService => _workerService;
  DepartmentService get departmentService => _departmentService;
  LocalService get localService => _localService;
  UserService get userService => _userService;
  EfemerideService get efemerideService => _efemerideService;

  // GETTERS PARA SERVICIOS EXISTENTES
  AppDatabase get appDatabase => _appDatabase;
  ConnectivityManager get connectivityManager => _connectivityManager;
  SyncService get syncService => _syncService;
  WorkerRepository get workerRepository => _workerRepository;
  DepartmentRepository get departmentRepository => _departmentRepository;
  LocalRepository get localRepository => _localRepository;
  EfemerideRepository get efemerideRepository => _efemerideRepository;
  AuthRepository get authRepository => _authRepository;
  UserRepository get userRepository => _userRepository;
  TokenExpiryManager get tokenExpiryManager => _tokenExpiryManager;

  // NUEVO GETTER PARA UPDATE SERVICE
  UpdateService get updateService => _updateService;

  // Getters para providers
  AuthProvider get authProvider => _authProvider;
  UserProvider get userProvider => _userProvider;

  void dispose() {
    _apiClient.dispose();
    _appDatabase.close();
    // Agregar dispose del updateService
    _updateService.dispose();
  }
}
