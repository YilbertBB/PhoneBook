import 'dart:io';

import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class ExcelImportService {
  static Future<List<List<dynamic>>> readRowsFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('El archivo no existe.');
    }

    final bytes = await file.readAsBytes();
    final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: false);

    if (decoder.tables.isEmpty) {
      throw Exception('No se encontró una hoja válida en el archivo.');
    }

    final table = decoder.tables.values.first;
    final rows = <List<dynamic>>[];

    for (final row in table.rows) {
      rows.add(row.map((value) => value ?? '').toList());
    }

    return rows;
  }

  static List<Map<String, dynamic>> parseSimpleRows({
    required List<List<dynamic>> rows,
    required List<String> requiredColumns,
  }) {
    if (rows.isEmpty) {
      return [];
    }

    final headerRow = rows.first;
    final normalizedHeaders = <String, int>{};

    for (var i = 0; i < headerRow.length; i++) {
      final rawHeader = headerRow[i]?.toString().trim() ?? '';
      final normalizedHeader = _normalizeHeader(rawHeader);
      if (normalizedHeader.isNotEmpty) {
        normalizedHeaders[normalizedHeader] = i;
      }
    }

    final parsedRows = <Map<String, dynamic>>[];

    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final isEmpty = row.every((value) => value.toString().trim().isEmpty);
      if (isEmpty) {
        continue;
      }

      final mappedRow = <String, dynamic>{};
      for (final requiredColumn in requiredColumns) {
        final columnIndex = _findColumnIndex(
          normalizedHeaders: normalizedHeaders,
          requiredColumn: requiredColumn,
        );
        if (columnIndex == null) {
          continue;
        }
        final value = row.length > columnIndex ? row[columnIndex] : '';
        mappedRow[requiredColumn] = value?.toString().trim() ?? '';
      }

      if (mappedRow.values.any((value) => value.toString().trim().isNotEmpty)) {
        parsedRows.add(mappedRow);
      }
    }

    return parsedRows;
  }

  static int? _findColumnIndex({
    required Map<String, int> normalizedHeaders,
    required String requiredColumn,
  }) {
    final normalizedRequiredColumn = _normalizeHeader(requiredColumn);
    if (normalizedRequiredColumn.isEmpty) {
      return null;
    }

    if (normalizedHeaders.containsKey(normalizedRequiredColumn)) {
      return normalizedHeaders[normalizedRequiredColumn];
    }

    for (final alias in _columnAliases(requiredColumn)) {
      if (normalizedHeaders.containsKey(alias)) {
        return normalizedHeaders[alias];
      }
    }

    return null;
  }

  static List<String> _columnAliases(String requiredColumn) {
    final normalized = _normalizeHeader(requiredColumn);
    switch (normalized) {
      case 'nombre':
        return ['nombrecompleto', 'nombreyapellido', 'nombres', 'fullname'];
      case 'apellido':
        return ['apellidos', 'lastname'];
      case 'carnet':
        return ['carnetidentidad', 'carnetdeidentidad', 'carnetid', 'ci'];
      case 'telefono':
        return ['telefonocelular', 'numerocelular', 'celular', 'phone', 'mobile'];
      case 'direccion':
        return ['domicilio', 'direccionpersonal', 'address'];
      case 'departamento':
        return ['departamentos', 'area'];
      case 'local':
        return ['sucursal', 'ubicacion', 'branch'];
      case 'fechacumpleannos':
        return ['fechadenacimiento', 'cumpleannos', 'birthday'];
      default:
        return [];
    }
  }

  static String _normalizeHeader(String value) {
    final normalized = value
        .toLowerCase()
        .trim()
        .split('')
        .map((char) {
          switch (char) {
            case 'á':
            case 'à':
            case 'ä':
            case 'â':
              return 'a';
            case 'é':
            case 'è':
            case 'ë':
            case 'ê':
              return 'e';
            case 'í':
            case 'ì':
            case 'ï':
            case 'î':
              return 'i';
            case 'ó':
            case 'ò':
            case 'ö':
            case 'ô':
              return 'o';
            case 'ú':
            case 'ù':
            case 'ü':
            case 'û':
              return 'u';
            case 'ñ':
              return 'n';
            case 'ç':
              return 'c';
            default:
              return char;
          }
        })
        .join('')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');

    return normalized;
  }
}
