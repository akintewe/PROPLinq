/// Utility functions for formatting
class FormatUtils {
  FormatUtils._();

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

