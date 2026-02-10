import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CsvUtils {
  /// Parse CSV file and return list of rows
  static Future<List<List<String>>> parseCsvFile(String filePath) async {
    try {
      final file = File(filePath);
      final contents = await file.readAsString();

      final converter = const CsvToListConverter();
      final rows = converter.convert(contents);

      // Convert to List<List<String>>
      return rows.map((row) => row.map((cell) => cell.toString()).toList()).toList();
    } catch (e) {
      print('❌ [CsvUtils] Error parsing CSV: $e');
      rethrow;
    }
  }

  /// Download CSV sample template for rooms
  static Future<void> downloadRoomsSampleCsv() async {
    try {
      final csvData = const ListToCsvConverter().convert([
        ['name', 'type', 'price', 'capacity', 'count', 'features'],
        ['Deluxe Room', 'Suite', '150.00', '2', '5', 'wifi|ac|balcony'],
        ['Standard Room', 'Single', '80.00', '1', '10', 'wifi|tv'],
        ['Family Suite', 'Suite', '250.00', '4', '2', 'wifi|ac|kitchen|pool_view'],
      ]);

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/rooms_sample.csv';

      // Write CSV file
      final file = File(filePath);
      await file.writeAsString(csvData);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Hotel Rooms Sample CSV',
        text: 'Use this template to upload hotel rooms',
      );

      print('✅ [CsvUtils] Sample CSV downloaded and shared');
    } catch (e) {
      print('❌ [CsvUtils] Error downloading sample CSV: $e');
      rethrow;
    }
  }

  /// Create CSV from rooms data
  static String roomsToCSV(List<Map<String, dynamic>> rooms) {
    final rows = [
      ['name', 'type', 'price', 'capacity', 'count', 'features'],
      ...rooms.map((room) => [
            room['name'],
            room['type'],
            room['price'].toString(),
            room['capacity'].toString(),
            room['count'].toString(),
            (room['features'] as List).join('|'),
          ]),
    ];

    return const ListToCsvConverter().convert(rows);
  }
}
