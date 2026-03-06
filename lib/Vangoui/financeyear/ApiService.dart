import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../financeyear/financial_year.dart';

class ApiService {
  static const String baseUrl = "http://192.168.1.108:80";
  static const String financialYearEndpoint = "/gst-3-3-production/mobile-service/vansales/get_financial_year.php";

  // Fetch financial years from API
  static Future<List<FinancialYear>> fetchFinancialYears(String unid, String veh) async {
    print('\n🔵 ===== FETCHING FINANCIAL YEARS FROM API =====');
    print('📤 Request URL: $baseUrl$financialYearEndpoint');

    try {
      final url = Uri.parse('$baseUrl$financialYearEndpoint');

      // Prepare request body
      final Map<String, String> requestBody = {
        'unid': unid,
        'veh': veh,
      };

      print('📦 Request Body:');
      print(json.encode(requestBody));

      // Make POST request
      print('⏳ Sending request...');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ Request timeout after 30 seconds');
          throw Exception('Connection timeout. Please check your network.');
        },
      );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Headers: ${response.headers}');
      print('📥 Response Body:');
      print('┌──────────────────────────────────────────');
      print('│ ${response.body.replaceAll('\n', '\n│ ')}');
      print('└──────────────────────────────────────────');

      if (response.statusCode == 200) {
        // Parse JSON response
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        print('\n🔍 Parsed Response Data:');
        print('├─ result: "${responseData['result']}"');
        print('├─ message: "${responseData['message']}"');
        print('├─ runn_financial_year count: ${responseData['runn_financial_year']?.length ?? 0}');

        // Check if result is success (1 means success)
        if (responseData['result'] == "1") {
          final List<dynamic> yearsData = responseData['runn_financial_year'] ?? [];

          print('\n📊 Financial Years Received:');
          for (var i = 0; i < yearsData.length; i++) {
            var year = yearsData[i];
            print('├─ Year ${i + 1}:');
            print('│  ├─ finid: ${year['finid']}');
            print('│  ├─ financial_year: ${year['financial_year']}');
            if (i < yearsData.length - 1) print('│  └─');
          }

          // Convert API response to FinancialYear objects
          List<FinancialYear> financialYears = yearsData.map((yearData) {
            return FinancialYear.fromApiResponse(
              finid: yearData['finid'],
              financialYear: yearData['financial_year'],
            );
          }).toList();

          print('\n✅ Successfully converted ${financialYears.length} financial years');
          print('🔵 ===== FINANCIAL YEARS FETCH COMPLETED =====\n');

          return financialYears;
        } else {
          print('❌ API returned error result: ${responseData['result']}');
          print('❌ Error message: ${responseData['message']}');
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception('Failed to load financial years. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception caught: $e');
      print('🔴 ===== FINANCIAL YEARS FETCH FAILED =====\n');
      throw Exception('Failed to connect to server: $e');
    }
  }

  // Get user credentials from SharedPreferences
  static Future<Map<String, String>> getUserCredentials() async {
    print('\n🔵 ===== GETTING USER CREDENTIALS =====');
    try {
      final prefs = await SharedPreferences.getInstance();
      final unid = prefs.getString('unid') ?? '';
      final veh = prefs.getString('veh') ?? '';

      print('📦 Retrieved from SharedPreferences:');
      print('├─ unid: ${unid.isNotEmpty ? unid : 'NOT FOUND'}');
      print('└─ veh: ${veh.isNotEmpty ? veh : 'NOT FOUND'}');

      if (unid.isEmpty || veh.isEmpty) {
        print('⚠️ Warning: Credentials are empty or not found');
      }

      print('🔵 ===== CREDENTIALS RETRIEVED =====\n');
      return {'unid': unid, 'veh': veh};
    } catch (e) {
      print('❌ Error getting credentials: $e');
      print('🔴 ===== CREDENTIALS RETRIEVAL FAILED =====\n');
      return {'unid': '', 'veh': ''};
    }
  }

  // Test API connection (for debugging)
  static Future<void> testApiConnection() async {
    print('\n🧪 ===== TESTING API CONNECTION =====');
    try {
      final credentials = await getUserCredentials();

      if (credentials['unid']!.isEmpty || credentials['veh']!.isEmpty) {
        print('⚠️ Cannot test API: Missing credentials');
        print('🧪 ===== TEST ABORTED =====\n');
        return;
      }

      await fetchFinancialYears(credentials['unid']!, credentials['veh']!);
      print('✅ API connection test successful');
    } catch (e) {
      print('❌ API connection test failed: $e');
    }
    print('🧪 ===== TEST COMPLETED =====\n');
  }
}