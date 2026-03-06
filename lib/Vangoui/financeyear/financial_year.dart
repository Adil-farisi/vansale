class FinancialYear {
  final String id; // This stores finid (e.g., "Mw--", "Mg--", "MQ--")
  final String displayName; // This stores financial_year (e.g., "2027 - 2028")
  final DateTime startDate;
  final DateTime endDate;
  final bool isDefault;

  FinancialYear({
    required this.id,
    required this.displayName,
    required this.startDate,
    required this.endDate,
    this.isDefault = false,
  });

  // Factory method to create from API response
  factory FinancialYear.fromApiResponse({
    required String finid,
    required String financialYear,
  }) {
    print('🔧 Creating FinancialYear from API response:');
    print('├─ finid: $finid');
    print('└─ financial_year: $financialYear');

    // Parse financial year string like "2027 - 2028"
    final years = financialYear.split(' - ');
    DateTime startDate;
    DateTime endDate;

    if (years.length == 2) {
      final startYear = int.tryParse(years[0].trim()) ?? 0;
      final endYear = int.tryParse(years[1].trim()) ?? 0;

      // Financial year starts from April 1st
      startDate = DateTime(startYear, 4, 1);
      endDate = DateTime(endYear, 3, 31);

      print('├─ Parsed years: $startYear - $endYear');
      print('├─ Start date: ${startDate.day}/${startDate.month}/${startDate.year}');
      print('└─ End date: ${endDate.day}/${endDate.month}/${endDate.year}');
    } else {
      // Fallback if parsing fails
      print('⚠️ Failed to parse financial year string, using fallback');
      startDate = DateTime.now();
      endDate = DateTime.now().add(const Duration(days: 365));
    }

    // Check if this is current year (simple logic - can be enhanced)
    final now = DateTime.now();
    final isDefault = financialYear.contains(now.year.toString());

    return FinancialYear(
      id: finid,
      displayName: financialYear,
      startDate: startDate,
      endDate: endDate,
      isDefault: isDefault,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  // Create from JSON
  factory FinancialYear.fromJson(Map<String, dynamic> json) {
    return FinancialYear(
      id: json['id'],
      displayName: json['displayName'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isDefault: json['isDefault'] ?? false,
    );
  }

  // Generate next years as fallback
  static List<FinancialYear> generateNextYears() {
    print('🔧 Generating fallback financial years');
    final now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;

    int startYear = currentMonth >= 4 ? currentYear : currentYear - 1;

    return [
      FinancialYear(
        id: '${startYear - 1}-${(startYear).toString().substring(2)}',
        displayName: '${startYear - 1} - ${startYear}',
        startDate: DateTime(startYear - 1, 4, 1),
        endDate: DateTime(startYear, 3, 31),
      ),
      FinancialYear(
        id: '${startYear}-${(startYear + 1).toString().substring(2)}',
        displayName: '$startYear - ${startYear + 1}',
        startDate: DateTime(startYear, 4, 1),
        endDate: DateTime(startYear + 1, 3, 31),
        isDefault: true,
      ),
      FinancialYear(
        id: '${startYear + 1}-${(startYear + 2).toString().substring(2)}',
        displayName: '${startYear + 1} - ${startYear + 2}',
        startDate: DateTime(startYear + 1, 4, 1),
        endDate: DateTime(startYear + 2, 3, 31),
      ),
    ];
  }
}