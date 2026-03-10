class ErrorMessages {
  // Errores de conexión/red
  static const String noInternet =
      'No hay conexión a internet. Por favor, verifica tu conexión y vuelve a intentar.';
  static const String connectionTimeout =
      'El servidor está tardando demasiado en responder. Por favor, intenta de nuevo más tarde.';
  static const String serverUnreachable =
      'No se puede conectar con el servidor. Verifica que estés conectado a la red correcta.';
  static const String networkError =
      'Error de red. Por favor, verifica tu conexión.';

  // Errores HTTP
  static const String badRequest =
      'La solicitud no es válida. Por favor, verifica los datos ingresados.';
  static const String unauthorized =
      'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
  static const String forbidden =
      'No tienes permiso para realizar esta acción.';
  static const String notFound =
      'El recurso solicitado no existe o ha sido eliminado.';
  static const String serverError =
      'Error en el servidor. Nuestro equipo ha sido notificado. Por favor, intenta más tarde.';
  static const String serviceUnavailable =
      'El servicio no está disponible temporalmente. Estamos trabajando para resolverlo.';

  // Errores específicos de la aplicación
  static const String invalidCredentials =
      'Correo o contraseña incorrectos. Por favor, verifica tus credenciales.';
  static const String emailAlreadyExists =
      'Este correo electrónico ya está registrado.';
  static const String weakPassword =
      'La contraseña es demasiado débil. Debe tener al menos 6 caracteres.';
  static const String invalidEmail = 'El correo electrónico no es válido.';
  static const String userNotFound = 'Usuario no encontrado.';
  static const String validationError =
      'Por favor, completa todos los campos requeridos correctamente.';
  static const String dataNotFound = 'No se encontraron datos.';

  // Errores generales
  static const String unexpectedError =
      'Ocurrió un error inesperado. Por favor, intenta de nuevo.';
  static const String dataProcessingError =
      'Error al procesar los datos. Por favor, verifica la información.';
  static const String operationFailed =
      'La operación no pudo completarse. Por favor, intenta de nuevo.';

  // Mensajes específicos para trabajadores
  static const String workerNotFound =
      'El trabajador no existe o ha sido eliminado.';
  static const String duplicateCarnet =
      'El número de carnet ya existe. Por favor, use uno diferente.';
  static const String duplicatePhone =
      'El número de teléfono ya está registrado.';
  static const String duplicateEmail =
      'El correo electrónico ya está registrado.';
  static const String workersLoadFailed =
      'No se pudieron cargar los trabajadores.';
  static const String workerCreateFailed = 'No se pudo crear el trabajador.';
  static const String workerUpdateFailed =
      'No se pudo actualizar el trabajador.';
  static const String workerDeleteFailed = 'No se pudo eliminar el trabajador.';

  // Mensajes específicos para departamentos
  static const String departmentNotFound =
      'El departamento no existe o ha sido eliminado.';
  static const String duplicateDepartmentName =
      'Ya existe un departamento con ese nombre.';
  static const String duplicateDepartmentPhone =
      'Ya existe un departamento con ese teléfono.';
  static const String departmentHasWorkers =
      'No se puede eliminar el departamento porque tiene trabajadores asignados. Reasigna los trabajadores primero.';
  static const String departmentsLoadFailed =
      'No se pudieron cargar los departamentos.';
  static const String departmentCreateFailed =
      'No se pudo crear el departamento.';
  static const String departmentUpdateFailed =
      'No se pudo actualizar el departamento.';
  static const String departmentDeleteFailed =
      'No se pudo eliminar el departamento.';

  // Agregar esto a tu archivo error_messages.dart existente

  // Mensajes específicos para locales
  static const String localNotFound = 'El local no existe o ha sido eliminado.';
  static const String duplicateLocalName = 'Ya existe un local con ese nombre.';
  static const String duplicateLocalPhone =
      'Ya existe un local con ese teléfono.';
  static const String localHasWorkers =
      'No se puede eliminar el local porque tiene trabajadores asignados. Reasigna los trabajadores primero.';
  static const String localsLoadFailed = 'No se pudieron cargar los locales.';
  static const String localCreateFailed = 'No se pudo crear el local.';
  static const String localUpdateFailed = 'No se pudo actualizar el local.';
  static const String localDeleteFailed = 'No se pudo eliminar el local.';

  // Mensajes específicos para usuarios
  static const String duplicateUsername = 'El nombre de usuario ya existe.';
  static const String duplicateUserEmail =
      'El correo electrónico ya está registrado.';
  static const String weakUserPassword =
      'La contraseña debe tener al menos 6 caracteres.';
  static const String currentPasswordIncorrect =
      'La contraseña actual es incorrecta.';
  static const String newPasswordInvalid =
      'La nueva contraseña no cumple los requisitos de seguridad.';
  static const String lastAdminCannotDelete =
      'No se puede eliminar el último administrador del sistema.';
  static const String usersLoadFailed = 'No se pudieron cargar los usuarios.';
  static const String userCreateFailed = 'No se pudo crear el usuario.';
  static const String userUpdateFailed = 'No se pudo actualizar el usuario.';
  static const String userDeleteFailed = 'No se pudo eliminar el usuario.';
  static const String userRoleUpdateFailed =
      'No se pudieron actualizar los roles del usuario.';

  // Agregar esto a tu archivo error_messages.dart existente

  // Mensajes específicos para efemérides
  static const String efemerideNotFound =
      'La efeméride no existe o ha sido eliminada.';
  static const String efemerideInvalidDate =
      'La fecha de la efeméride no es válida.';
  static const String efemerideDataRequired =
      'El dato de la efeméride es requerido.';
  static const String efemeridesLoadFailed =
      'No se pudieron cargar las efemérides.';
  static const String efemerideCreateFailed = 'No se pudo crear la efeméride.';
  static const String efemerideUpdateFailed =
      'No se pudo actualizar la efeméride.';
  static const String efemerideDeleteFailed =
      'No se pudo eliminar la efeméride.';
  static const String efemerideDuplicate =
      'Ya existe una efeméride para esta fecha con el mismo dato.';
  // Mensajes para diálogos
  static const String saveFailed = 'No se pudo guardar los cambios.';
  static const String deleteFailed = 'No se pudo eliminar el registro.';
  static const String loadFailed = 'No se pudieron cargar los datos.';
  static const String validationFailed =
      'Error de validación. Verifique los datos.';

  // Mensajes de éxito
  static const String saveSuccess = 'Guardado exitosamente';
  static const String deleteSuccess = 'Eliminado exitosamente';
  static const String createSuccess = 'Creado exitosamente';
  static const String updateSuccess = 'Actualizado exitosamente';

  // Sugerencias
  static const String networkSuggestion =
      'Verifique su conexión a internet e intente nuevamente.';
  static const String validationSuggestion =
      'Revise los campos marcados con error.';
  static const String serverSuggestion =
      'El problema puede ser temporal. Intente más tarde.';

  // Método para obtener sugerencia según error
  static String getSuggestion(String error) {
    final e = error.toLowerCase();

    if (e.contains('conexión') ||
        e.contains('network') ||
        e.contains('socket')) {
      return networkSuggestion;
    }

    if (e.contains('validation') ||
        e.contains('validación') ||
        e.contains('invalid')) {
      return validationSuggestion;
    }

    if (e.contains('500') || e.contains('server') || e.contains('timeout')) {
      return serverSuggestion;
    }

    return 'Por favor, intente nuevamente.';
  }

  // Mensajes específicos para trabajadores
  static const String duplicateWorkerPhone =
      'El número de teléfono ya está registrado.';
  static const String invalidBirthday = 'La fecha de cumpleaños no es válida.';
  static const String invalidCarnetFormat =
      'El carnet debe tener 11 dígitos numéricos.';
  static const String carnetProvinceInvalid =
      'Los primeros dígitos no corresponden a una provincia válida.';
  static const String birthdayFutureDate =
      'La fecha de cumpleaños no puede ser futura.';

  // Mensajes específicos para efemérides
  static const String duplicateEfemerideDate =
      'Ya existe una efeméride para esta fecha con el mismo dato.';
  static const String duplicateEfemerideName =
      'Ya existe una efeméride con este nombre.';

  // Sugerencias específicas
  static const String carnetSuggestion =
      'El carnet debe tener 11 dígitos. Los primeros 2 dígitos representan la provincia.';
  static const String phoneSuggestion =
      'Formato: +53 XXX XXXXXX. Use solo números y el código de país.';
  static const String dateSuggestion =
      'Use el formato YYYY-MM-DD (Ej: 1990-05-15).';
  static const String birthdaySuggestion =
      'La fecha no puede ser futura y debe ser real.';
  // Método para obtener mensaje según código HTTP
  static String fromStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return badRequest;
      case 401:
        return unauthorized;
      case 403:
        return forbidden;
      case 404:
        return notFound;
      case 500:
        return serverError;
      case 503:
        return serviceUnavailable;
      default:
        if (statusCode >= 500) {
          return serverError;
        } else if (statusCode >= 400) {
          return badRequest;
        }
        return unexpectedError;
    }
  }

  // Método para obtener mensaje según tipo de excepción
  static String fromException(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('host lookup')) {
      return noInternet;
    }

    if (errorString.contains('timeout')) {
      return connectionTimeout;
    }

    if (errorString.contains('format') || errorString.contains('json')) {
      return dataProcessingError;
    }

    if (errorString.contains('credentials') || errorString.contains('auth')) {
      return invalidCredentials;
    }

    if (errorString.contains('email already')) {
      return emailAlreadyExists;
    }

    return unexpectedError;
  }
}
