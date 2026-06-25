import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ExcelTemplateService {
  static Future<String?> generateWorkersTemplate() async {
    return _generateTemplate(
      fileName: 'plantilla_trabajadores.xlsx',
      sheetName: 'Trabajadores',
      title: 'Plantilla para importar trabajadores',
      instructions: [
        '1. Completa las columnas obligatorias.',
        '2. El campo nombre y carnet son obligatorios.',
        '3. Los campos departamento y local deben coincidir con los nombres existentes.',
        '4. Usa fechas como 15 de mayo o 2024-05-15.',
      ],
      headers: [
        'nombre',
        'apellido',
        'carnet',
        'telefono',
        'direccion',
        'departamento',
        'local',
        'fechaCumpleannos',
      ],
      sampleRows: [
        [
          'Juan',
          'Pérez',
          'JP001',
          '555-1234',
          'Calle 123',
          'Ventas',
          'Sucursal Centro',
          '15 de mayo',
        ],
      ],
    );
  }

  static Future<String?> generateLocalsTemplate() async {
    return _generateTemplate(
      fileName: 'plantilla_locales.xlsx',
      sheetName: 'Locales',
      title: 'Plantilla para importar locales',
      instructions: [
        '1. Completa el nombre del local.',
        '2. El teléfono es opcional.',
        '3. Cada fila representa un local nuevo.',
      ],
      headers: ['nombre', 'telefono'],
      sampleRows: [
        ['Sucursal Centro', '555-1111'],
      ],
    );
  }

  static Future<String?> generateDepartmentsTemplate() async {
    return _generateTemplate(
      fileName: 'plantilla_departamentos.xlsx',
      sheetName: 'Departamentos',
      title: 'Plantilla para importar departamentos',
      instructions: [
        '1. Completa el nombre del departamento.',
        '2. El teléfono es opcional.',
        '3. Cada fila representa un departamento nuevo.',
      ],
      headers: ['nombre', 'telefono'],
      sampleRows: [
        ['Ventas', '555-2222'],
      ],
    );
  }

  static Future<String?> _generateTemplate({
    required String fileName,
    required String sheetName,
    required String title,
    required List<String> instructions,
    required List<String> headers,
    required List<List<dynamic>> sampleRows,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('La generación de plantillas no está disponible en web.');
    }

    try {
      final excel = Excel.createExcel();
      final instructionsSheet = excel['Instrucciones'];
      _writeRow(instructionsSheet, 0, ['Plantilla de importación']);
      _writeRow(instructionsSheet, 1, [title]);
      _writeRow(instructionsSheet, 3, ['Instrucciones']);

      for (var i = 0; i < instructions.length; i++) {
        _writeRow(instructionsSheet, 4 + i, [instructions[i]]);
      }

      _writeRow(instructionsSheet, 8, ['Columnas esperadas']);
      for (var i = 0; i < headers.length; i++) {
        _writeRow(instructionsSheet, 9 + i, [headers[i]]);
      }

      final dataSheet = excel[sheetName];
      _writeRow(dataSheet, 0, headers);

      for (var i = 0; i < sampleRows.length; i++) {
        _writeRow(dataSheet, i + 1, sampleRows[i]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('No se pudo generar el archivo Excel.');
      }

      final directory = await _getOutputDirectory();
      if (directory == null) {
        throw Exception('No se pudo obtener un directorio para guardar la plantilla.');
      }

      final file = File(p.join(directory.path, fileName));
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      throw Exception('Error al generar la plantilla: $e');
    }
  }

  static void _writeRow(Sheet sheet, int rowIndex, List<dynamic> values) {
    for (var columnIndex = 0; columnIndex < values.length; columnIndex++) {
      final value = values[columnIndex].toString();
      sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: columnIndex,
          rowIndex: rowIndex,
        ),
      ).value = TextCellValue(value);
    }
  }

  static Future<Directory?> _getOutputDirectory() async {
    const appFolderName = 'PhoneBook';

    try {
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.request();
        final manageStatus = await Permission.manageExternalStorage.request();

        final granted = storageStatus.isGranted || manageStatus.isGranted;
        if (!granted) {
          throw Exception('Se requieren permisos de almacenamiento para guardar archivos.');
        }

        final rootDir = Directory('/storage/emulated/0');
        if (await rootDir.exists()) {
          final appDir = Directory(p.join(rootDir.path, appFolderName));
          await appDir.create(recursive: true);
          return appDir;
        }
      }

      if (Platform.isIOS) {
        final baseDir = await getApplicationDocumentsDirectory();
        final appDir = Directory(p.join(baseDir.path, appFolderName));
        await appDir.create(recursive: true);
        return appDir;
      }

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          final appDir = Directory(p.join(downloadsDir.path, appFolderName));
          await appDir.create(recursive: true);
          return appDir;
        }
      }

      final fallbackDir = await getApplicationDocumentsDirectory();
      final appDir = Directory(p.join(fallbackDir.path, appFolderName));
      await appDir.create(recursive: true);
      return appDir;
    } catch (_) {
      return null;
    }
  }
}
