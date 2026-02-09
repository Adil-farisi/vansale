import 'package:flutter/material.dart';
import 'package:van_go/Vangoui/permissions/permission_model.dart';
import 'package:van_go/Vangoui/permissions/permission_service.dart';

class PermissionProvider extends ChangeNotifier {
  PermissionData? _permissions;
  bool _isLoading = false;
  String? _error;
  bool _initialLoadComplete = false;

  PermissionData? get permissions => _permissions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoaded => _permissions != null;
  bool get hasError => _error != null && _error!.isNotEmpty;
  bool get initialLoadComplete => _initialLoadComplete;

  PermissionProvider() {
    _initializePermissions();
  }

  Future<void> _initializePermissions() async {
    await _loadCachedPermissions();
    _initialLoadComplete = true;
    notifyListeners();
  }

  Future<void> _loadCachedPermissions() async {
    try {
      final cached = await PermissionService.getCachedPermissions();
      if (cached != null) {
        _permissions = cached;
        print('Loaded permissions from cache');
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cached permissions: $e');
    }
  }

  // Fetch permissions from API
  Future<bool> fetchPermissions({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await PermissionService.getPermissions();

      if (response.isSuccess && response.permissiondet.isNotEmpty) {
        _permissions = response.permissiondet.first;
        print('Permissions loaded from API successfully');

        // Print some key permissions for debugging
        if (_permissions != null) {
          print('Key Permissions:');
          print('- Add Customer: ${_permissions!.customerAdd}');
          print('- New Bill: ${_permissions!.newBill}');
          print('- View Stock: ${_permissions!.stockView}');
          print('- Add Receipt: ${_permissions!.receiptAdd}');
        }

        return true;
      } else {
        _error = response.message.isNotEmpty
            ? response.message
            : 'Failed to load permissions';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('PermissionProvider Error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Permission check methods with better error handling
  bool canAddCustomer() => _permissions?.customerAdd == 'yes';
  bool canViewCustomer() => _permissions?.customerView == 'yes';
  bool canEditCustomer() => _permissions?.customerEdit == 'yes';
  bool canViewStock() => _permissions?.stockView == 'yes';
  bool canCreateNewBill() => _permissions?.newBill == 'yes';
  bool canViewInvoice() => _permissions?.invoiceView == 'yes';
  bool canAddReceipt() => _permissions?.receiptAdd == 'yes';
  bool canAddDiscount() => _permissions?.discountAdd == 'yes';
  bool canAddCheque() => _permissions?.chequeAdd == 'yes';
  bool canViewSalesReport() => _permissions?.salesReport == 'yes';
  bool canViewDebitors() => _permissions?.debitors == 'yes';
  bool canViewDayBook() => _permissions?.dayBook == 'yes';

  // Additional permission checks you might need
  bool canDeleteReceipt() => _permissions?.receiptDelete == 'yes';
  bool canEditReceipt() => _permissions?.receiptEdit == 'yes';
  bool canSendReceiptWhatsapp() => _permissions?.receiptWhatsapp == 'yes';
  bool canEditGST() => _permissions?.invoiceGstEdit == 'yes';
  bool canAllowDiscount() => _permissions?.invoiceDiscountAllow == 'yes';
  bool canChangeReceiptDate() => _permissions?.receiptDateChange == 'yes';

  // Check if user has any sales permissions
  bool hasSalesPermissions() =>
      canCreateNewBill() || canViewInvoice() || canViewSalesReport();

  // Check if user has any customer permissions
  bool hasCustomerPermissions() =>
      canAddCustomer() || canViewCustomer() || canEditCustomer();

  // Clear permissions (on logout)
  Future<void> clearPermissions() async {
    _permissions = null;
    _error = null;
    _initialLoadComplete = false;
    await PermissionService.clearCachedPermissions();
    notifyListeners();
  }

  // Refresh permissions
  Future<void> refreshPermissions() async {
    await fetchPermissions(forceRefresh: true);
  }

  // Check if a specific permission is granted
  bool hasPermission(String permissionKey) {
    if (_permissions == null) return false;

    switch (permissionKey) {
      case 'add_customer': return canAddCustomer();
      case 'view_customer': return canViewCustomer();
      case 'edit_customer': return canEditCustomer();
      case 'view_stock': return canViewStock();
      case 'create_bill': return canCreateNewBill();
      case 'view_invoice': return canViewInvoice();
      case 'add_receipt': return canAddReceipt();
      case 'add_discount': return canAddDiscount();
      case 'add_cheque': return canAddCheque();
      case 'view_sales_report': return canViewSalesReport();
      case 'view_debitors': return canViewDebitors();
      case 'view_day_book': return canViewDayBook();
      default: return false;
    }
  }
}