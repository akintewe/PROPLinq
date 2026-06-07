/// Utility functions for formatting
class FormatUtils {
  FormatUtils._();

  /// Returns a summary string for hotel/shortlet room info on property cards.
  /// e.g. "5 room types • From ₦50,000/night"
  /// Returns null for non-hotel/shortlet or when no rooms data is present.
  static String? roomsUnitsSummary(Map<String, dynamic>? rawJson, String type) {
    final t = type.toLowerCase();
    if (t != 'hotel' && t != 'shortlet') return null;
    final rooms = rawJson?['rooms'];
    if (rooms is! List || rooms.isEmpty) return null;
    final count = rooms.length;
    // For shortlets: only show unit summary when has_units is true (multi-unit)
    // Fall back to count > 1 if has_units not present
    if (t == 'shortlet') {
      final hasUnits = rawJson?['has_units'];
      final isMultiUnit = hasUnits == true || hasUnits == 1 || hasUnits == '1';
      if (!isMultiUnit && count < 2) return null;
    }
    final label = t == 'shortlet'
        ? (count == 1 ? 'unit type' : 'unit types')
        : (count == 1 ? 'room type' : 'room types');
    double? minPrice;
    for (final r in rooms) {
      if (r is Map) {
        final p = double.tryParse(r['price']?.toString() ?? '');
        if (p != null && (minPrice == null || p < minPrice)) minPrice = p;
      }
    }
    final fromStr = minPrice != null ? ' • From ${formatPrice(minPrice.toStringAsFixed(0))}/night' : '';
    return '$count $label$fromStr';
  }

  /// Capitalises the first letter of each word
  /// Example: "individual_agent" -> "Individual_agent", "standard room" -> "Standard Room"
  static String toTitleCase(String s) => s
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  /// Format price string with commas for thousands separators
  /// Example: "1000000" -> "₦1,000,000"
  static String formatPrice(String price) {
    try {
      // Remove any existing currency symbols, commas, and non-numeric characters
      String cleanPrice = price.replaceAll(RegExp(r'[^\d.]'), '');
      
      // Parse as double
      double priceValue = double.parse(cleanPrice);
      
      // Convert to int if it's a whole number, otherwise keep as double
      String priceString = priceValue % 1 == 0 
          ? priceValue.toInt().toString() 
          : priceValue.toStringAsFixed(2);
      
      // Add comma separators for thousands
      String formatted = priceString.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      
      return '₦$formatted';
    } catch (e) {
      // Fallback to original price if parsing fails
      return '₦$price';
    }
  }
}

