import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'customer_model.dart';

class CustomerApiService {
  static const String baseUrl =
      'http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales';

  // Don't store unid and vehicle in constructor - fetch from SharedPreferences when needed
  CustomerApiService();

  // Helper method to get session data
  Future<Map<String, String>> _getSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unid = prefs.getString('unid') ?? '';
      final veh = prefs.getString('veh') ?? '';

      print('🔑 API DEBUG: Loaded session - unid: $unid, veh: $veh');

      if (unid.isEmpty || veh.isEmpty) {
        throw Exception('Session data missing. Please login again.');
      }

      return {'unid': unid, 'veh': veh};
    } catch (e) {
      print('❌ API DEBUG: Error loading session: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchCustomers({
    String search = '',
    String page = '1', // Default to page 1
  }) async {
    try {
      // Get session data first
      final sessionData = await _getSessionData();
      final unid = sessionData['unid']!;
      final veh = sessionData['veh']!;

      print('🔍 API DEBUG: Making request to $baseUrl/customers.php');
      print(
        '🔍 API DEBUG: Request body: {"unid": "$unid", "veh": "$veh", "srch": "$search", "page": "$page"}',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/customers.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'unid': unid,
          'veh': veh,
          'srch': search,
          'page': page, // Pass the page parameter
        }),
      );

      print('🔍 API DEBUG: Response status code: ${response.statusCode}');
      print('🔍 API DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('🔍 API DEBUG: Parsed data: $data');

        if (data['result'] == '1') {
          List<CustomerModel> customers = [];
          if (data['customerdet'] is List) {
            print(
              '🔍 API DEBUG: customerdet is List with length: ${(data['customerdet'] as List).length}',
            );
            customers =
                (data['customerdet'] as List)
                    .map((item) => CustomerModel.fromJson(item))
                    .toList();
          }

          // Get total customers count
          int totalCustomers = 0;
          if (data['ttlcustomers'] != null) {
            totalCustomers = int.tryParse(data['ttlcustomers'].toString()) ?? 0;
          }

          // Calculate pagination info
          int currentPage = int.tryParse(page) ?? 1;
          int itemsPerPage = customers.length; // This will be 2 in your case
          int totalPages = itemsPerPage > 0
              ? (totalCustomers / itemsPerPage).ceil()
              : 1;
          bool hasMore = currentPage < totalPages;

          print('📊 API DEBUG: Pagination calculated:');
          print('📊 API DEBUG: - totalCustomers: $totalCustomers');
          print('📊 API DEBUG: - itemsPerPage: $itemsPerPage');
          print('📊 API DEBUG: - currentPage: $currentPage');
          print('📊 API DEBUG: - totalPages: $totalPages');
          print('📊 API DEBUG: - hasMore: $hasMore');

          return {
            'success': true,
            'message': data['message'] ?? '',
            'totalCustomers': totalCustomers,
            'customers': customers,
            'currentPage': currentPage,
            'totalPages': totalPages,
            'hasMore': hasMore,
            'itemsPerPage': itemsPerPage,
          };
        } else {
          print('❌ API DEBUG: API returned result != 1');
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to fetch customers',
            'totalCustomers': 0,
            'customers': [],
            'currentPage': 1,
            'totalPages': 1,
            'hasMore': false,
            'itemsPerPage': 0,
          };
        }
      } else {
        print('❌ API DEBUG: HTTP Error ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'totalCustomers': 0,
          'customers': [],
          'currentPage': 1,
          'totalPages': 1,
          'hasMore': false,
          'itemsPerPage': 0,
        };
      }
    } catch (e) {
      print('❌ API DEBUG: Exception: $e');
      return {
        'success': false,
        'message': e.toString(),
        'totalCustomers': 0,
        'customers': [],
        'currentPage': 1,
        'totalPages': 1,
        'hasMore': false,
        'itemsPerPage': 0,
      };
    }
  }

  // =================== UPDATE CUSTOMER METHOD ===================
  Future<Map<String, dynamic>> updateCustomer({
    required String cust,
    required String custType,
    required String custName,
    required String slex,
    required String email,
    required String phone,
    required String address,
    required String gstNumber,
    required String landPhone,
    required String opBln,
    required String opAcc,
    required String state,
    required String stateCode,
    required String creditDays,
    required String route,
  }) async {
    try {
      // Get session data first
      final sessionData = await _getSessionData();
      final unid = sessionData['unid']!;
      final veh = sessionData['veh']!;

      print(
        '📤 API DEBUG: Making update request to $baseUrl/action/customers.php',
      );

      final requestBody = {
        'unid': unid,
        'veh': veh,
        'action': 'update',
        'cust': cust,
        'cust_type': custType,
        'cust_name': custName,
        'slex': slex,
        'email': email,
        'phone': phone,
        'address': address,
        'gst_number': gstNumber,
        'land_phone': landPhone,
        'op_bln': opBln,
        'op_acc': opAcc,
        'state': state,
        'state_code': stateCode,
        'credit_days': creditDays,
        'route': route,
      };

      print('📤 API DEBUG: Update request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/action/customers.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print(
        '📤 API DEBUG: Update response status code: ${response.statusCode}',
      );
      print('📤 API DEBUG: Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('📤 API DEBUG: Parsed update response: $data');

        return {
          'success': data['result'] == '1',
          'message':
          data['message'] ??
              (data['result'] == '1'
                  ? 'Customer updated successfully'
                  : 'Update failed'),
        };
      } else {
        print('❌ API DEBUG: HTTP Error ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ API DEBUG: Exception: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // =================== ADD CUSTOMER METHOD ===================
  Future<Map<String, dynamic>> addCustomer({
    required String custType,
    required String custName,
    required String slex,
    required String email,
    required String phone,
    required String address,
    required String gstNumber,
    required String landPhone,
    required String opBln,
    required String opAcc,
    required String state,
    required String stateCode,
    required String creditDays,
    required String route,
  }) async {
    try {
      // Get session data first
      final sessionData = await _getSessionData();
      final unid = sessionData['unid']!;
      final veh = sessionData['veh']!;

      print(
        '➕ API DEBUG: Making add customer request to $baseUrl/action/customers.php',
      );

      final requestBody = {
        'unid': unid,
        'veh': veh,
        'action': 'add', // Changed to 'add' for adding customer
        'cust': '', // Empty for new customer
        'cust_type': custType,
        'cust_name': custName,
        'slex': slex,
        'email': email,
        'phone': phone,
        'address': address,
        'gst_number': gstNumber,
        'land_phone': landPhone,
        'op_bln': opBln,
        'op_acc': opAcc,
        'state': state,
        'state_code': stateCode,
        'credit_days': creditDays,
        'route': route,
      };

      print(
        '➕ API DEBUG: Add customer request body: ${json.encode(requestBody)}',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/action/customers.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print(
        '➕ API DEBUG: Add customer response status code: ${response.statusCode}',
      );
      print('➕ API DEBUG: Add customer response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('➕ API DEBUG: Parsed add customer response: $data');

        return {
          'success': data['result'] == '1',
          'message':
          data['message'] ??
              (data['result'] == '1'
                  ? 'Customer added successfully'
                  : 'Add failed'),
          'custid': data['custid'] ?? '', // API might return new customer ID
        };
      } else {
        print('❌ API DEBUG: HTTP Error ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ API DEBUG: Exception: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Add this method to CustomerApiService class
  Future<List<Map<String, dynamic>>> getCustomerTypes() async {
    try {
      // Get session data first
      final sessionData = await _getSessionData();
      final unid = sessionData['unid']!;
      final veh = sessionData['veh']!;

      print('📥 API DEBUG: Fetching customer types');
      print('📥 API DEBUG: Request to get_customer_types.php');
      print('📥 API DEBUG: Request body: {"unid": "$unid", "veh": "$veh"}');

      final response = await http.post(
        Uri.parse('$baseUrl/get_customer_types.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'unid': unid, 'veh': veh}),
      );

      print('📥 API DEBUG: Response status code: ${response.statusCode}');
      print('📥 API DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['result'] == '1' && data['customertypesdet'] is List) {
          final List<Map<String, dynamic>> types =
          (data['customertypesdet'] as List)
              .map(
                (item) => {
              'id': item['custtypeid'].toString(),
              'name': item['custtype_name'].toString(),
            },
          )
              .toList();

          print('✅ API DEBUG: Found ${types.length} customer types');
          return types;
        } else {
          print('❌ API DEBUG: API returned result != 1 or invalid data');
          return [];
        }
      } else {
        print('❌ API DEBUG: HTTP Error ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ API DEBUG: Exception fetching customer types: $e');
      return [];
    }
  }

  // Add this method to CustomerApiService class
  Future<List<Map<String, dynamic>>> getSalesExecutives() async {
    try {
      // Get session data first
      final sessionData = await _getSessionData();
      final unid = sessionData['unid']!;
      final veh = sessionData['veh']!;

      print('📥 API DEBUG: Fetching sales executives');
      print('📥 API DEBUG: Request to get_sales_executives.php');
      print('📥 API DEBUG: Request body: {"unid": "$unid", "veh": "$veh"}');

      final response = await http.post(
        Uri.parse('$baseUrl/get_sales_executives.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'unid': unid, 'veh': veh}),
      );

      print('📥 API DEBUG: Response status code: ${response.statusCode}');
      print('📥 API DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['result'] == '1' && data['salesexedet'] is List) {
          final List<Map<String, dynamic>> executives =
          (data['salesexedet'] as List)
              .map(
                (item) => {
              'id': item['slex'].toString(),
              'name': item['executive_name'].toString(),
              'phone': item['phone'].toString(),
            },
          )
              .toList();

          print('✅ API DEBUG: Found ${executives.length} sales executives');
          return executives;
        } else {
          print('❌ API DEBUG: API returned result != 1 or invalid data');
          return [];
        }
      } else {
        print('❌ API DEBUG: HTTP Error ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ API DEBUG: Exception fetching sales executives: $e');
      return [];
    }
  }

  // Add this method to CustomerApiService class
  Future<Map<String, dynamic>> checkCustomerStatus(String custId) async {
    try {
      // Get session data first
      final sessionData = await _getSessionData();
      final unid = sessionData['unid']!;
      final veh = sessionData['veh']!;

      print('🔍 API DEBUG: Checking customer status for ID: $custId');
      print('🔍 API DEBUG: Request to customers.php with action: customerstatus');

      final requestBody = {
        'unid': unid,
        'veh': veh,
        'action': 'customerstatus',
        'custid': custId,
      };

      print('🔍 API DEBUG: Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/action/customers.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('🔍 API DEBUG: Response status code: ${response.statusCode}');
      print('🔍 API DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('🔍 API DEBUG: Parsed response: $data');

        return {
          'success': data['result'] == '1',
          'message': data['message'] ?? '',
          'canDelete': data['result'] == '1', // If result is 1, can delete (no pending amount)
        };
      } else {
        print('❌ API DEBUG: HTTP Error ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'canDelete': false,
        };
      }
    } catch (e) {
      print('❌ API DEBUG: Exception: $e');
      return {
        'success': false,
        'message': e.toString(),
        'canDelete': false,
      };
    }
  }

  // Add this method to CustomerApiService class
  Future<List<Map<String, dynamic>>> getRoutes() async {
    try {
      // Get session data first
      final sessionData = await _getSessionData();
      final unid = sessionData['unid']!;
      final veh = sessionData['veh']!;

      print('📥 API DEBUG: Fetching routes');
      print('📥 API DEBUG: Request to get_routes.php');
      print('📥 API DEBUG: Request body: {"unid": "$unid", "veh": "$veh"}');

      final response = await http.post(
        Uri.parse('$baseUrl/get_routes.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'unid': unid, 'veh': veh}),
      );

      print('📥 API DEBUG: Response status code: ${response.statusCode}');
      print('📥 API DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['result'] == '1' && data['routedet'] is List) {
          final List<Map<String, dynamic>> routes =
          (data['routedet'] as List)
              .map(
                (item) => {
              'id': item['rtid'].toString(),
              'name': item['route_name'].toString(),
            },
          )
              .toList();

          print('✅ API DEBUG: Found ${routes.length} routes');
          return routes;
        } else {
          print('❌ API DEBUG: API returned result != 1 or invalid data');
          return [];
        }
      } else {
        print('❌ API DEBUG: HTTP Error ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ API DEBUG: Exception fetching routes: $e');
      return [];
    }
  }

  // =================== UPDATE CUSTOMER STATUS METHOD ===================
  Future<Map<String, dynamic>> updateCustomerStatus({
    required String custId,
    required bool isActive,
  }) async {
    try {
      // Get session data first
      final sessionData = await _getSessionData();
      final unid = sessionData['unid']!;
      final veh = sessionData['veh']!;

      print('🔄 API DEBUG: Making status update request for customer: $custId to ${isActive ? 'active' : 'inactive'}');

      // Try with 'updatestatus' action
      final requestBody = {
        'unid': unid,
        'veh': veh,
        'action': 'updatestatus',
        'custid': custId,
        'status': isActive ? 'active' : 'inactive',
      };

      print('🔄 API DEBUG: Status update request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/action/customers.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('🔄 API DEBUG: Status update response status code: ${response.statusCode}');
      print('🔄 API DEBUG: Status update response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('🔄 API DEBUG: Parsed status update response: $data');

        return {
          'success': data['result'] == '1',
          'message': data['message'] ?? (data['result'] == '1'
              ? 'Status updated successfully'
              : 'Status update failed'),
        };
      } else {
        print('❌ API DEBUG: HTTP Error ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ API DEBUG: Exception: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}