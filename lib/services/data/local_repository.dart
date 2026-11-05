// lib/services/data/local_repository.dart
export 'local_repository_web.dart'
    if (dart.library.io) 'local_repository_io.dart';
