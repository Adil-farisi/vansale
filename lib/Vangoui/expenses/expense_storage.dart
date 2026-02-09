import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ExpenseStorage {
  static const String key = "saved_expenses";

  static Future<void> saveExpense(Map<String, dynamic> expense) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> existing = prefs.getStringList(key) ?? [];

    existing.add(jsonEncode(expense));

    await prefs.setStringList(key, existing);
  }

  static Future<List<Map<String, dynamic>>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> stored = prefs.getStringList(key) ?? [];

    return stored
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> deleteExpense(int index) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> existing = prefs.getStringList(key) ?? [];

    if (index < existing.length) {
      existing.removeAt(index);
      await prefs.setStringList(key, existing);
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
