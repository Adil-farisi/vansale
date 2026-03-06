import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'ApiService.dart';
import 'financial_year.dart';

class FinancialYearService {
  static const String _selectedYearKey = 'selected_financial_year';
  static const String _allYearsKey = 'all_financial_years';
  static const String _isFirstTimeKey = 'is_first_time_user';
  static const String _unidKey = 'unid';
  static const String _vehKey = 'veh';
  static const String _lastSyncKey = 'last_financial_year_sync';

  // Save user credentials after login
  static Future<void> saveUserCredentials(String unid, String veh) async {
    print('\n🔵 ===== SAVING USER CREDENTIALS =====');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_unidKey, unid);
      await prefs.setString(_vehKey, veh);

      print('✅ Credentials saved successfully:');
      print('├─ unid: $unid');
      print('└─ veh: $veh');
    } catch (e) {
      print('❌ Error saving credentials: $e');
    }
    print('🔵 ===== CREDENTIALS SAVED =====\n');
  }

  // Get user credentials
  static Future<Map<String, String>> getUserCredentials() async {
    return await ApiService.getUserCredentials();
  }

  // Fetch and save financial years from API
  static Future<List<FinancialYear>> fetchAndSaveFinancialYears() async {
    print('\n🟢 ===== FETCHING FINANCIAL YEARS FROM API =====');
    try {
      // Get user credentials
      final credentials = await getUserCredentials();

      final unid = credentials['unid']!;
      final veh = credentials['veh']!;

      if (unid.isEmpty || veh.isEmpty) {
        print('⚠️ Credentials missing, cannot fetch from API');
        print('🟢 ===== FETCH SKIPPED =====\n');
        return [];
      }

      print('📋 Using credentials:');
      print('├─ unid: $unid');
      print('└─ veh: $veh');

      // Fetch from API
      final years = await ApiService.fetchFinancialYears(unid, veh);

      if (years.isNotEmpty) {
        // Save to SharedPreferences
        await saveAllYears(years);

        // Save last sync time
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

        print('✅ Fetched and saved ${years.length} financial years from API');
      } else {
        print('⚠️ API returned empty list');
      }

      print('🟢 ===== FETCH COMPLETED =====\n');
      return years;
    } catch (e) {
      print('❌ Error fetching from API: $e');
      print('🟢 ===== FETCH FAILED =====\n');
      return [];
    }
  }

  // Check if user is first time
  static Future<bool> isFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool(_isFirstTimeKey) ?? true;
    print('🔍 First time user check: $isFirstTime');
    return isFirstTime;
  }

  // Set first time user flag
  static Future<void> setFirstTimeUser(bool isFirstTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstTimeKey, isFirstTime);
    print('📝 First time user flag set to: $isFirstTime');
  }

  // Save selected financial year
  static Future<void> saveSelectedYear(FinancialYear year) async {
    print('\n🔵 ===== SAVING SELECTED YEAR =====');
    try {
      final prefs = await SharedPreferences.getInstance();
      String yearJson = jsonEncode(year.toJson());
      await prefs.setString(_selectedYearKey, yearJson);

      print('✅ Selected year saved:');
      print('├─ id: ${year.id}');
      print('├─ displayName: ${year.displayName}');
      print('└─ isDefault: ${year.isDefault}');
    } catch (e) {
      print('❌ Error saving selected year: $e');
    }
    print('🔵 ===== YEAR SAVED =====\n');
  }

  // Load selected financial year
  static Future<FinancialYear?> loadSelectedYear() async {
    print('\n🔵 ===== LOADING SELECTED YEAR =====');
    try {
      final prefs = await SharedPreferences.getInstance();
      String? yearJson = prefs.getString(_selectedYearKey);

      if (yearJson != null) {
        Map<String, dynamic> jsonMap = jsonDecode(yearJson);
        final year = FinancialYear.fromJson(jsonMap);

        print('✅ Loaded selected year:');
        print('├─ id: ${year.id}');
        print('├─ displayName: ${year.displayName}');
        print('└─ isDefault: ${year.isDefault}');

        return year;
      } else {
        print('ℹ️ No selected year found in storage');
      }
    } catch (e) {
      print('❌ Error loading selected year: $e');
    }
    print('🔵 ===== LOAD COMPLETED =====\n');
    return null;
  }

  // Save all financial years
  static Future<void> saveAllYears(List<FinancialYear> years) async {
    print('\n🔵 ===== SAVING ALL FINANCIAL YEARS =====');
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> yearsJson = years.map((year) => jsonEncode(year.toJson())).toList();
      await prefs.setStringList(_allYearsKey, yearsJson);

      print('✅ Saved ${years.length} financial years:');
      for (var i = 0; i < years.length; i++) {
        print('├─ [${i + 1}] ${years[i].displayName} (${years[i].id})');
      }
    } catch (e) {
      print('❌ Error saving all years: $e');
    }
    print('🔵 ===== ALL YEARS SAVED =====\n');
  }

  // Load all financial years
  static Future<List<FinancialYear>> loadAllYears() async {
    print('\n🔵 ===== LOADING ALL FINANCIAL YEARS =====');
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? yearsJson = prefs.getStringList(_allYearsKey);

      if (yearsJson != null && yearsJson.isNotEmpty) {
        final years = yearsJson.map((jsonString) {
          return FinancialYear.fromJson(jsonDecode(jsonString));
        }).toList();

        print('✅ Loaded ${years.length} financial years from storage:');
        for (var i = 0; i < years.length; i++) {
          print('├─ [${i + 1}] ${years[i].displayName} (${years[i].id})');
        }

        return years;
      } else {
        print('ℹ️ No financial years found in storage');
      }
    } catch (e) {
      print('❌ Error loading all years: $e');
    }
    print('🔵 ===== LOAD COMPLETED =====\n');
    return [];
  }

  // Check if user has selected a year
  static Future<bool> hasSelectedYear() async {
    final prefs = await SharedPreferences.getInstance();
    final hasYear = prefs.containsKey(_selectedYearKey);
    print('🔍 Has selected year check: $hasYear');
    return hasYear;
  }

  // Refresh financial years from API
  static Future<List<FinancialYear>> refreshFinancialYears() async {
    print('\n🔄 ===== REFRESHING FINANCIAL YEARS =====');
    final years = await fetchAndSaveFinancialYears();
    print('🔄 ===== REFRESH COMPLETED =====\n');
    return years;
  }

  // Get last sync time
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final syncTimeStr = prefs.getString(_lastSyncKey);
    if (syncTimeStr != null) {
      return DateTime.parse(syncTimeStr);
    }
    return null;
  }

  // Clear all data (for logout)
  static Future<void> clearAllData() async {
    print('\n🔴 ===== CLEARING ALL FINANCIAL YEAR DATA =====');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedYearKey);
      await prefs.remove(_allYearsKey);
      await prefs.remove(_isFirstTimeKey);
      await prefs.remove(_lastSyncKey);
      // Don't remove credentials on logout
      print('✅ All financial year data cleared');
    } catch (e) {
      print('❌ Error clearing data: $e');
    }
    print('🔴 ===== CLEAR COMPLETED =====\n');
  }
}