import 'dart:io';

void main() async {
  try {
    print('[TEST] Reading CSV file...');
    final file = File('/home/qasim/Desktop/GeoGuard/assets/data/cleaned-data.csv');
    final csvString = await file.readAsString();
    print('[TEST] File size: ${csvString.length} bytes');
    
    print('[TEST] Parsing CSV manually...');
    final lines = csvString.split('\n');
    print('[TEST] Total lines: ${lines.length}');
    
    // Parse header
    final headerLine = lines[0];
    final headers = headerLine.split(',');
    print('[TEST] Headers count: ${headers.length}');
    print('[TEST] First 10 headers: ${headers.sublist(0, 10.clamp(0, headers.length))}');
    
    // Find Country column
    int? countryIndex;
    for (int i = 0; i < headers.length; i++) {
      if (headers[i].trim() == 'Country') {
        countryIndex = i;
        break;
      }
    }
    
    print('[TEST] Country column index: $countryIndex');
    
    if (countryIndex != null && countryIndex < headers.length) {
      // Get first few countries
      print('[TEST] First 5 countries:');
      for (int i = 1; i < 6 && i < lines.length; i++) {
        final parts = lines[i].split(',');
        if (countryIndex < parts.length) {
          print('  Line $i: ${parts[countryIndex]}');
        }
      }
      
      // Test search
      print('[TEST] Searching for "united"...');
      final matching = <String>{};
      for (int i = 1; i < lines.length && i < 100; i++) {
        final parts = lines[i].split(',');
        if (countryIndex < parts.length) {
          final country = parts[countryIndex].trim();
          if (country.toLowerCase().contains('united')) {
            matching.add(country);
          }
        }
      }
      print('[TEST] Found: $matching');
    }
  } catch (e) {
    print('[TEST] Error: $e');
  }
}
