import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BillStorage {
  static const String key = "saved_bills";

  static Future<void> saveBill(Map<String, dynamic> bill) async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> existing =
        prefs.getStringList(key) ?? [];

    existing.add(jsonEncode(bill));

    await prefs.setStringList(key, existing);
  }

  static Future<List<Map<String, dynamic>>> loadBills() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> stored =
        prefs.getStringList(key) ?? [];

    return stored
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
