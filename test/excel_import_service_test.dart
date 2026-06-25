import 'package:flutter_test/flutter_test.dart';
import 'package:phonebook/utils/excel_import_service.dart';

void main() {
  group('ExcelImportService', () {
    test('parseSimpleRows maps common headers and trims values', () {
      final rows = [
        ['Nombre', 'Teléfono'],
        ['Sucursal Centro', '555-1111'],
        ['Sucursal Norte', '555-2222'],
      ];

      final parsed = ExcelImportService.parseSimpleRows(
        rows: rows,
        requiredColumns: ['nombre', 'telefono'],
      );

      expect(parsed, hasLength(2));
      expect(parsed[0]['nombre'], 'Sucursal Centro');
      expect(parsed[0]['telefono'], '555-1111');
      expect(parsed[1]['nombre'], 'Sucursal Norte');
      expect(parsed[1]['telefono'], '555-2222');
    });

    test('parseSimpleRows ignores empty rows and missing values', () {
      final rows = [
        ['Nombre', 'Teléfono'],
        ['', ''],
        ['Departamento Uno', '555-9999'],
      ];

      final parsed = ExcelImportService.parseSimpleRows(
        rows: rows,
        requiredColumns: ['nombre', 'telefono'],
      );

      expect(parsed, hasLength(1));
      expect(parsed.first['nombre'], 'Departamento Uno');
    });

    test('parseSimpleRows recognizes common worker aliases', () {
      final rows = [
        ['Nombre Completo', 'Carnet de Identidad', 'Número Celular', 'Dirección', 'Departamento', 'Local'],
        ['Juan Pérez', 'JP001', '555-1234', 'Calle 123', 'Ventas', 'Sucursal Centro'],
      ];

      final parsed = ExcelImportService.parseSimpleRows(
        rows: rows,
        requiredColumns: ['nombre', 'carnet', 'telefono', 'direccion', 'departamento', 'local'],
      );

      expect(parsed, hasLength(1));
      expect(parsed.first['nombre'], 'Juan Pérez');
      expect(parsed.first['carnet'], 'JP001');
      expect(parsed.first['telefono'], '555-1234');
      expect(parsed.first['direccion'], 'Calle 123');
      expect(parsed.first['departamento'], 'Ventas');
      expect(parsed.first['local'], 'Sucursal Centro');
    });
  });
}
