import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:van_go/Vangoui/permissions/permission_model.dart';

class PermissionService {
  static const String _permissionsKey = 'permissions_data';
  static const String _permissionsTimestamp = 'permissions_timestamp';

  // Get permissions for the current user
  static Future<PermissionResponse> getPermissions() async {
    try {
      // Get stored user data
      final prefs = await SharedPreferences.getInstance();
      final unid = prefs.getString('unid') ?? '';
      final veh = prefs.getString('veh') ?? '';
      final baseUrl = prefs.getString('server_url') ?? '';

      if (unid.isEmpty || veh.isEmpty) {
        throw Exception('User credentials not found. Please login again.');
      }

      // Prepare request body
      final Map<String, dynamic> body = {
        'unid': unid,
        'veh': veh,
      };

      // Construct URL
      String apiUrl = baseUrl.isNotEmpty
          ? "$baseUrl/vansales-permission.php"
          : "http://192.168.1.108/gst-3-3-production/mobile-service/vansales/vansales-permission.php";

      print("===== PERMISSION API REQUEST =====");
      print("URL: $apiUrl");
      print("Body: ${json.encode(body)}");
      print("==================================");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode(body),
      );

      print("===== PERMISSION API RESPONSE =====");
      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");
      print("===================================");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Debug: Print received data structure
        print("Response Data Type: ${responseData.runtimeType}");
        print("Has permissiondet: ${responseData.containsKey('permissiondet')}");
        if (responseData.containsKey('permissiondet')) {
          print("permissiondet type: ${responseData['permissiondet'].runtimeType}");
          print("permissiondet length: ${(responseData['permissiondet'] as List).length}");
        }

        final permissionResponse = PermissionResponse.fromJson(responseData);

        if (!permissionResponse.isSuccess) {
          throw Exception('Failed to get permissions: ${permissionResponse.message}');
        }

        if (permissionResponse.permissiondet.isEmpty) {
          throw Exception('No permission data received');
        }

        // Cache the full permissions object
        await _cacheFullPermissions(permissionResponse.permissiondet.first);

        return permissionResponse;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print("PermissionService Error: $e");
      print("Stack Trace: ${e.toString()}");
      rethrow;
    }
  }

  // Cache the FULL permissions object
  static Future<void> _cacheFullPermissions(PermissionData permissions) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert permission data to map
    final Map<String, dynamic> permissionsMap = {
      'invoice_view': permissions.invoiceView,
      'new_bill': permissions.newBill,
      'invoice_sale_credit': permissions.invoiceSaleCredit,
      'invoice_unit_rate': permissions.invoiceUnitRate,
      'invoice_gst_edit': permissions.invoiceGstEdit,
      'invoice_discount_allow': permissions.invoiceDiscountAllow,
      'creditnote_view': permissions.creditnoteView,
      'receipt_add': permissions.receiptAdd,
      'receipt_due_amount': permissions.receiptDueAmount,
      'receipt_date_change': permissions.receiptDateChange,
      'receipt_edit': permissions.receiptEdit,
      'receipt_view': permissions.receiptView,
      'receipt_delete': permissions.receiptDelete,
      'receipt_delete_reason': permissions.receiptDeleteReason,
      'receipt_whatsapp': permissions.receiptWhatsapp,
      'cheque_add': permissions.chequeAdd,
      'cheque_view': permissions.chequeView,
      'cheque_edit': permissions.chequeEdit,
      'cheque_clear': permissions.chequeClear,
      'cheque_bounce': permissions.chequeBounce,
      'cheque_delete': permissions.chequeDelete,
      'cheque_delete_reason': permissions.chequeDeleteReason,
      'discount_add': permissions.discountAdd,
      'discount_due_amount': permissions.discountDueAmount,
      'discount_date_change': permissions.discountDateChange,
      'discount_allowed': permissions.discountAllowed,
      'discount_edit': permissions.discountEdit,
      'discount_view': permissions.discountView,
      'discount_delete': permissions.discountDelete,
      'discount_delete_reason': permissions.discountDeleteReason,
      'stock_view': permissions.stockView,
      'customer_add': permissions.customerAdd,
      'customer_view': permissions.customerView,
      'customer_edit': permissions.customerEdit,
      'customer_status': permissions.customerStatus,
      'aged_receivable': permissions.agedReceivable,
      'sales_report': permissions.salesReport,
      'sales_detail': permissions.salesDetail,
      'sales_other': permissions.salesOther,
      'receipt_report': permissions.receiptReport,
      'sales_return_report': permissions.salesReturnReport,
      'sales_return_detail': permissions.salesReturnDetail,
      'discount_report': permissions.discountReport,
      'all_report_excel': permissions.allReportExcel,
      'debitors': permissions.debitors,
      'debitors_whatsapp': permissions.debitorsWhatsapp,
      'debitors_excel': permissions.debitorsExcel,
      'day_book': permissions.dayBook,
      'customer_ledger': permissions.customerLedger,
      'ledger_excel': permissions.ledgerExcel,
      'account_sales': permissions.accountSales,
      'account_receipt': permissions.accountReceipt,
      'account_sales_return': permissions.accountSalesReturn,
      'account_discount': permissions.accountDiscount,
    };

    // Store as JSON string
    final permissionsJson = json.encode(permissionsMap);

    await prefs.setString(_permissionsKey, permissionsJson);
    await prefs.setInt(_permissionsTimestamp, DateTime.now().millisecondsSinceEpoch);

    print('Full permissions cached successfully');
    print('Permissions cached: ${permissionsMap.length} fields');
  }

  // Get cached permissions
  static Future<PermissionData?> getCachedPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_permissionsKey);
      final timestamp = prefs.getInt(_permissionsTimestamp) ?? 0;

      if (jsonString != null && timestamp > 0) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;

        // Use cached if less than 1 hour old (3600000 ms)
        if (age < 3600000) {
          final Map<String, dynamic> data = json.decode(jsonString);
          print('Loading cached permissions (age: ${age ~/ 1000}s)');
          return PermissionData.fromJson(data);
        } else {
          print('Cached permissions expired (age: ${age ~/ 1000}s)');
          await clearCachedPermissions();
        }
      }

      return null;
    } catch (e) {
      print('Error loading cached permissions: $e');
      return null;
    }
  }

  // Clear cached permissions
  static Future<void> clearCachedPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionsKey);
    await prefs.remove(_permissionsTimestamp);
    print('Cached permissions cleared');
  }
}