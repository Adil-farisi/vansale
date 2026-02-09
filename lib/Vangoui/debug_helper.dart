import 'package:shared_preferences/shared_preferences.dart';

class DebugHelper {

  static Future<void> printStoredData() async {
    final prefs = await SharedPreferences.getInstance();

    print("========== SHARED PREFERENCES DATA ==========");

    for (String key in prefs.getKeys()) {
      print("$key : ${prefs.get(key)}");
    }

    print("=============================================");
  }
}
