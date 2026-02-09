import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:van_go/Vangoui/addcustomer.dart';
import 'package:van_go/Vangoui/updatecustomer.dart';
import 'package:van_go/Vangoui/permissions/permission_provider.dart';

import 'customer_api_service.dart';
import 'customer_model.dart';

class CustomerPage extends StatelessWidget {
  const CustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _CustomerPageContent();
  }
}

class _CustomerPageContent extends StatefulWidget {
  @override
  State<_CustomerPageContent> createState() => _CustomerPageContentState();
}

class _CustomerPageContentState extends State<_CustomerPageContent> {
  List<CustomerModel> allCustomers = [];
  List<CustomerModel> displayedCustomers = [];
  Map<String, Map<String, dynamic>> customerOutstandingData = {};
  bool isLoading = true;
  bool isLoadingSessionData = true;
  bool isLoadingOutstanding = false;
  String errorMessage = '';
  int totalCustomers = 0;
  String searchQuery = '';

  String unid = '';
  String veh = '';

  late CustomerApiService customerApiService;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('🚀 DEBUG: CustomerPage initState called');
    _loadSessionData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionData() async {
    try {
      print('🔍 DEBUG: Starting _loadSessionData');
      final prefs = await SharedPreferences.getInstance();
      final loadedUnid = prefs.getString('unid') ?? '';
      final loadedVeh = prefs.getString('veh') ?? '';

      print('🔍 DEBUG: Loaded from SharedPreferences - unid: $loadedUnid, veh: $loadedVeh');

      if (!mounted) return;

      setState(() {
        unid = loadedUnid;
        veh = loadedVeh;
        isLoadingSessionData = false;
      });

      if (unid.isEmpty || veh.isEmpty) {
        print('❌ DEBUG: Session data missing - unid: $unid, veh: $veh');
        if (mounted) {
          setState(() {
            isLoading = false;
            errorMessage = 'Session data missing. Please login again.';
          });
        }
        return;
      }

      print('✅ DEBUG: Session data loaded successfully');
      print('✅ DEBUG: Creating CustomerApiService');
      customerApiService = CustomerApiService();
      print('🚀 DEBUG: Calling _fetchCustomers');
      _fetchCustomers();
    } catch (e) {
      print('❌ DEBUG: Error loading session data: $e');
      if (mounted) {
        setState(() {
          isLoadingSessionData = false;
          isLoading = false;
          errorMessage = 'Failed to load session data: $e';
        });
      }
    }
  }

  // =================== FETCH OUTSTANDING AMOUNTS API ===================
  Future<void> _fetchCustomerOutstanding() async {
    if (unid.isEmpty || veh.isEmpty) {
      print('❌ DEBUG: Missing session data for outstanding API');
      return;
    }

    print('💰 DEBUG: Starting _fetchCustomerOutstanding');
    print('💰 DEBUG: API URL: http://192.168.20.103/gst-3-3-production/mobile-service/vansales/get_customers.php');
    print('💰 DEBUG: Request body: {"unid": "$unid", "veh": "$veh"}');

    if (mounted) {
      setState(() {
        isLoadingOutstanding = true;
      });
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.20.103/gst-3-3-production/mobile-service/vansales/get_customers.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "unid": unid,
          "veh": veh,
        }),
      );

      print('💰 DEBUG: Outstanding API response status: ${response.statusCode}');
      print('💰 DEBUG: Outstanding API response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('💰 DEBUG: Outstanding API parsed response: $data');

        if (data['result'] == "1") {
          final List<dynamic> customerList = data['customerdet'] ?? [];
          final Map<String, Map<String, dynamic>> outstandingMap = {};

          for (var customer in customerList) {
            final custid = customer['custid']?.toString() ?? '';
            final custName = customer['cust_name']?.toString() ?? '';
            final outstandingAmt = customer['outstand_amt']?.toString() ?? '0.00';

            if (custid.isNotEmpty) {
              outstandingMap[custid] = {
                'name': custName,
                'outstandingAmount': outstandingAmt,
              };
              print('💰 DEBUG: Customer $custid - Name: $custName - Outstanding: $outstandingAmt');
            }
          }

          if (mounted) {
            setState(() {
              customerOutstandingData = outstandingMap;
              print('💰 DEBUG: Loaded outstanding amounts for ${customerOutstandingData.length} customers');
            });
          }
        } else {
          print('❌ DEBUG: Outstanding API returned result: ${data['result']}');
          print('❌ DEBUG: Outstanding API message: ${data['message']}');
        }
      } else {
        print('❌ DEBUG: Outstanding API HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ DEBUG: Exception in _fetchCustomerOutstanding: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingOutstanding = false;
        });
      }
    }
  }

  // =================== FETCH CUSTOMERS WITH OUTSTANDING ===================
  Future<void> _fetchCustomers() async {
    print('🎯 DEBUG: Starting _fetchCustomers');
    print('🎯 DEBUG: unid = $unid, veh = $veh');

    if (unid.isEmpty || veh.isEmpty) {
      print('❌ DEBUG: Missing session data in _fetchCustomers');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'User session data missing. Please login again.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = '';
        searchQuery = '';
        _searchController.clear();
        allCustomers = [];
        displayedCustomers = [];
        customerOutstandingData = {};
      });
    }

    print('📡 DEBUG: Calling API with search: "${_searchController.text}"');

    try {
      // Fetch customers AND outstanding amounts in parallel
      print('📡 DEBUG: Starting parallel API calls');
      final mainApiCall = customerApiService.fetchCustomers(
        search: _searchController.text,
        page: '',
      );
      final outstandingApiCall = _fetchCustomerOutstanding();

      // Wait for both to complete
      final List<dynamic> results = await Future.wait([mainApiCall, outstandingApiCall]);
      final result = results[0] as Map<String, dynamic>;

      print('📡 DEBUG: API Response received');
      print('📡 DEBUG: Response success: ${result['success']}');
      print('📡 DEBUG: Response message: ${result['message']}');
      print('📡 DEBUG: Total customers from API: ${result['totalCustomers']}');

      if (!mounted) {
        print('⚠️ DEBUG: Widget not mounted, returning');
        return;
      }

      if (result['success'] == true) {
        // Get the customers list and ensure it's List<CustomerModel>
        List<CustomerModel> customers = [];
        if (result['customers'] is List<CustomerModel>) {
          customers = result['customers'] as List<CustomerModel>;
        } else if (result['customers'] is List) {
          // Convert list to CustomerModel if needed
          final List<dynamic> rawList = result['customers'] as List<dynamic>;
          customers = rawList.map((item) {
            if (item is CustomerModel) {
              return item;
            } else if (item is Map<String, dynamic>) {
              return CustomerModel.fromJson(item);
            } else {
              // Return a default customer model
              return CustomerModel(
                custid: '',
                custname: '',
                custType: '0',
                custTypeName: '',
                address: '',
                gst: '',
                phone: '',
                email: '',
                landPhone: '',
                opBln: 0.0,
                state: '',
                stateCode: '',
                creditDays: 0,
                opAcc: 'dr',
                status: 'inactive',
                balance: '0.00',
                slex: '',
              );
            }
          }).toList();
        }

        // DEBUG: Print all customer IDs from main API
        print('📊 DEBUG: Main API returned ${customers.length} customers:');
        for (var customer in customers) {
          print('📊 DEBUG: - ${customer.custid}: ${customer.custname}');
        }

        // DEBUG: Print all customer IDs from outstanding API
        print('💰 DEBUG: Outstanding API has ${customerOutstandingData.length} customers:');
        customerOutstandingData.forEach((custid, data) {
          print('💰 DEBUG: - $custid: ${data['name']} - ${data['outstandingAmount']}');
        });

        // Update customers with outstanding amounts
        final List<CustomerModel> updatedCustomers = customers.map((customer) {
          final outstandingData = customerOutstandingData[customer.custid];
          final outstanding = outstandingData?['outstandingAmount'] ?? '0.00';
          print('💰 DEBUG: Customer ${customer.custid} - Outstanding: $outstanding');
          return customer.copyWith(outstandingAmount: outstanding);
        }).toList();

        // ALSO ADD CUSTOMERS FROM OUTSTANDING API THAT ARE NOT IN MAIN API
        final Set<String> mainCustomerIds = Set.from(customers.map((c) => c.custid));
        final Set<String> outstandingCustomerIds = Set.from(customerOutstandingData.keys);

        // Find customers that are in outstanding API but not in main API
        final missingCustomerIds = outstandingCustomerIds.difference(mainCustomerIds);

        if (missingCustomerIds.isNotEmpty) {
          print('🔍 DEBUG: Found ${missingCustomerIds.length} customers in outstanding API but not in main API: $missingCustomerIds');

          // Create placeholder CustomerModel objects for these customers
          final List<CustomerModel> missingCustomers = missingCustomerIds.map((custid) {
            final data = customerOutstandingData[custid]!;
            return CustomerModel(
              custid: custid,
              custname: data['name'] ?? 'Customer $custid',
              custType: '0',
              custTypeName: '',
              address: '',
              gst: '',
              phone: '',
              email: '',
              landPhone: '',
              opBln: 0.0,
              state: '',
              stateCode: '',
              creditDays: 0,
              opAcc: 'dr',
              status: 'active',
              balance: '0.00',
              slex: '',
              outstandingAmount: data['outstandingAmount'] ?? '0.00',
            );
          }).toList();

          // Add to the list
          updatedCustomers.addAll(missingCustomers);
        }

        setState(() {
          allCustomers = updatedCustomers;
          displayedCustomers = List.from(allCustomers);
          totalCustomers = allCustomers.length;
          print('✅ DEBUG: Total loaded customers: ${allCustomers.length}');
          print('✅ DEBUG: Displaying ${displayedCustomers.length} customers');
          print('✅ DEBUG: Loaded outstanding amounts for ${customerOutstandingData.length} customers');

          if (allCustomers.isNotEmpty) {
            for (var i = 0; i < min(5, allCustomers.length); i++) {
              print('✅ DEBUG: Customer $i: ${allCustomers[i].custid} - ${allCustomers[i].custname} - ${allCustomers[i].outstandingAmount}');
            }
          }
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load customers';
          print('❌ DEBUG: API Error: $errorMessage');
        });
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('❌ DEBUG: Exception in _fetchCustomers: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load customers: $e';
          print('❌ DEBUG: Error message set: $errorMessage');
        });
      }
    }
  }

  // =================== SEARCH FUNCTIONALITY ===================
  void _searchCustomers(String query) {
    print('🔍 DEBUG: Searching for: $query');
    if (!mounted) return;

    setState(() {
      searchQuery = query.trim().toLowerCase();

      if (searchQuery.isEmpty) {
        displayedCustomers = List.from(allCustomers);
        print('🔍 DEBUG: Search cleared, showing ${displayedCustomers.length} customers');
      } else {
        displayedCustomers = allCustomers.where((customer) {
          return customer.custname.toLowerCase().contains(searchQuery) ||
              customer.custid.toLowerCase().contains(searchQuery) ||
              (customer.phone?.toLowerCase() ?? '').contains(searchQuery) ||
              (customer.email?.toLowerCase() ?? '').contains(searchQuery) ||
              (customer.address?.toLowerCase() ?? '').contains(searchQuery) ||
              (customer.gst?.toLowerCase() ?? '').contains(searchQuery);
        }).toList();
        print('🔍 DEBUG: Found ${displayedCustomers.length} customers matching "$searchQuery"');
      }
    });
  }

  void _clearSearch() {
    print('🔍 DEBUG: Clearing search');
    if (!mounted) return;

    setState(() {
      searchQuery = '';
      _searchController.clear();
      displayedCustomers = List.from(allCustomers);
      FocusScope.of(context).unfocus();
    });
  }

  void _toggleCustomerStatus(int index) async {
    final customer = displayedCustomers[index];
    final newStatus = !customer.isActive;
    final statusText = newStatus ? 'active' : 'inactive';

    print('🔄 DEBUG: Toggling customer ${customer.custname} status to $statusText');

    // First check if we can deactivate (if going to inactive)
    if (!newStatus) {
      // Show loading while checking status
      final checkingSnackbar = ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 15),
              Text('Checking customer status...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 5),
        ),
      );

      try {
        // Check customer status using the API
        print('🔍 DEBUG: Checking customer status before deactivation');

        Map<String, dynamic> statusResult;
        try {
          // Try to use the checkCustomerStatus method if available
          statusResult = await customerApiService.checkCustomerStatus(customer.custid);
        } catch (e) {
          print('⚠️ DEBUG: checkCustomerStatus method not available: $e');
          // If method doesn't exist, create a direct request
          statusResult = await _checkCustomerStatusDirect(customer.custid);
        }

        checkingSnackbar.close();

        print('🔍 DEBUG: Status check result: $statusResult');

        if (!statusResult['success'] || !statusResult['canDelete']) {
          // Extract plain text from HTML message
          String errorMessage = statusResult['message']?.toString() ?? '';
          // Remove HTML tags
          errorMessage = errorMessage.replaceAll(RegExp(r'<[^>]*>'), '');
          // Decode HTML entities
          errorMessage = errorMessage
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&amp;', '&')
              .replaceAll('&quot;', '"')
              .replaceAll('&#39;', "'");

          // Show error message from API
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage.isNotEmpty
                    ? errorMessage
                    : 'Cannot deactivate customer. Has pending outstanding amount.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
      } catch (e) {
        checkingSnackbar.close();
        print('❌ DEBUG: Error checking customer status: $e');
        // If status check fails, still allow the status change but show warning
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to verify customer status. Proceeding with caution.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    // Show loading for status update
    final loadingSnackbar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 15),
            Text('Updating customer status to ${newStatus ? 'Active' : 'Inactive'}...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      // Call API to update status
      print('📤 DEBUG: Calling updateCustomerStatus API');
      final result = await customerApiService.updateCustomerStatus(
        custId: customer.custid,
        isActive: newStatus,
      );

      loadingSnackbar.close();

      print('📥 DEBUG: Update status result: $result');

      if (result['success'] == true) {
        // Update in displayed list
        setState(() {
          displayedCustomers[index] = customer.copyWith(
            status: statusText,
          );

          // Also update in allCustomers list
          final allIndex = allCustomers.indexWhere((c) => c.custid == customer.custid);
          if (allIndex != -1) {
            allCustomers[allIndex] = displayedCustomers[index];
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${customer.custname} is now ${newStatus ? 'Active' : 'Inactive'}'),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Extract plain text from HTML message
        String errorMessage = result['message']?.toString() ?? 'Failed to update status';
        errorMessage = errorMessage.replaceAll(RegExp(r'<[^>]*>'), '');
        errorMessage = errorMessage
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&amp;', '&')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      loadingSnackbar.close();
      print('❌ DEBUG: Error updating customer status: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

// =================== DIRECT CUSTOMER STATUS CHECK ===================
  Future<Map<String, dynamic>> _checkCustomerStatusDirect(String custId) async {
    try {
      print('🔍 DEBUG: Direct check customer status for ID: $custId');

      // Make direct HTTP request
      final response = await http.post(
        Uri.parse('http://192.168.20.103/gst-3-3-production/mobile-service/vansales/action/customers.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'unid': unid,
          'veh': veh,
          'action': 'customerstatus',
          'custid': custId,
        }),
      );

      print('🔍 DEBUG: Direct status check response status: ${response.statusCode}');
      print('🔍 DEBUG: Direct status check response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('🔍 DEBUG: Parsed direct response: $data');

        return {
          'success': data['result'] == '1',
          'message': data['message'] ?? '',
          'canDelete': data['result'] == '1',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'canDelete': false,
        };
      }
    } catch (e) {
      print('❌ DEBUG: Error in direct status check: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
        'canDelete': false,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 DEBUG: Building CustomerPage');
    print('🎨 DEBUG: isLoadingSessionData: $isLoadingSessionData');
    print('🎨 DEBUG: isLoading: $isLoading');
    print('🎨 DEBUG: isLoadingOutstanding: $isLoadingOutstanding');
    print('🎨 DEBUG: allCustomers length: ${allCustomers.length}');
    print('🎨 DEBUG: displayedCustomers length: ${displayedCustomers.length}');
    print('🎨 DEBUG: customerOutstandingData length: ${customerOutstandingData.length}');
    print('🎨 DEBUG: errorMessage: $errorMessage');

    final permissionProvider = Provider.of<PermissionProvider>(context);

    if (!permissionProvider.canViewCustomer()) {
      return _buildAccessDeniedScreen(context);
    }

    if (isLoadingSessionData) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading session data...'),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context, permissionProvider),
      body: _buildCustomerList(permissionProvider),
    );
  }

  // =================== ACCESS DENIED SCREEN ===================
  Scaffold _buildAccessDeniedScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          'Customers',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Limited Access',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'You do not have permission to view customers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =================== APP BAR WITH WORKING SEARCH ===================
  AppBar _buildAppBar(BuildContext context, PermissionProvider permissionProvider) {
    return AppBar(
      backgroundColor: Colors.blue.shade800,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.people_outline, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'Customers',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (isLoadingOutstanding)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          if (totalCustomers > 0 && !isLoadingOutstanding)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalCustomers',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      centerTitle: false,
      elevation: 1,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            print('🔄 DEBUG: Refresh button pressed');
            _fetchCustomers();
          },
        ),
        if (permissionProvider.canAddCustomer())
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Addcustomer()),
                );
              },
              child: const Row(
                children: [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 6),
                  Text(
                    "Add",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name, phone...',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey.shade500, size: 18),
                              onPressed: _clearSearch,
                              padding: EdgeInsets.zero,
                            )
                                : null,
                          ),
                          onChanged: _searchCustomers,
                          onSubmitted: (_) {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.blue, size: 20),
                  onPressed: () {
                    _showFilterOptions(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =================== FILTER OPTIONS ===================
  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter Customers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 20),
              _buildFilterOption('Active Customers Only', Icons.check_circle, () {
                Navigator.pop(context);
                _filterByStatus('active');
              }),
              _buildFilterOption('Inactive Customers Only', Icons.cancel, () {
                Navigator.pop(context);
                _filterByStatus('inactive');
              }),
              _buildFilterOption('Customers with Outstanding', Icons.money_off, () {
                Navigator.pop(context);
                _filterByOutstanding();
              }),
              _buildFilterOption('Show All Customers', Icons.list, () {
                Navigator.pop(context);
                _clearFilters();
              }),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.grey.shade800,
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade600),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _filterByStatus(String status) {
    print('🔍 DEBUG: Filtering by status: $status');
    if (!mounted) return;

    setState(() {
      displayedCustomers = allCustomers
          .where((customer) => customer.status.toLowerCase() == status.toLowerCase())
          .toList();
      searchQuery = '';
      _searchController.clear();
      print('🔍 DEBUG: Filtered to ${displayedCustomers.length} customers');
    });
  }

  void _filterByOutstanding() {
    print('💰 DEBUG: Filtering customers with outstanding amounts');
    if (!mounted) return;

    setState(() {
      displayedCustomers = allCustomers
          .where((customer) {
        final outstanding = customer.outstandingAmount ?? '0.00';
        // Check if amount is not zero (remove commas for parsing)
        final amountStr = outstanding.replaceAll(RegExp(r'[^0-9.-]'), '');
        final amount = double.tryParse(amountStr) ?? 0;
        return amount != 0;
      })
          .toList();
      searchQuery = '';
      _searchController.clear();
      print('💰 DEBUG: Filtered to ${displayedCustomers.length} customers with outstanding amounts');
    });
  }

  void _clearFilters() {
    print('🔍 DEBUG: Clearing all filters');
    if (!mounted) return;

    setState(() {
      displayedCustomers = List.from(allCustomers);
      searchQuery = '';
      _searchController.clear();
      print('🔍 DEBUG: Showing all ${displayedCustomers.length} customers');
    });
  }

  // =================== CUSTOMER LIST ===================
  Widget _buildCustomerList(PermissionProvider permissionProvider) {
    print('📱 DEBUG: Building customer list');
    print('📱 DEBUG: isLoading: $isLoading');
    print('📱 DEBUG: isLoadingOutstanding: $isLoadingOutstanding');
    print('📱 DEBUG: errorMessage: $errorMessage');
    print('📱 DEBUG: displayedCustomers length: ${displayedCustomers.length}');

    if (isLoading) {
      print('📱 DEBUG: Showing loading spinner');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading customers...'),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      print('📱 DEBUG: Showing error: $errorMessage');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchCustomers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text('Retry', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (displayedCustomers.isEmpty) {
      print('📱 DEBUG: Showing empty state');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              searchQuery.isNotEmpty
                  ? 'No customers found for "$searchQuery"'
                  : 'No Customers Found',
              style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Add your first customer to get started',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: searchQuery.isNotEmpty ? _clearSearch : _fetchCustomers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: Text(
                searchQuery.isNotEmpty ? 'Clear Search' : 'Refresh',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    print('📱 DEBUG: Showing list with ${displayedCustomers.length} customers');
    return RefreshIndicator(
      onRefresh: _fetchCustomers,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: displayedCustomers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final customer = displayedCustomers[index];
          final isActive = customer.isActive;
          final outstanding = customer.outstandingAmount ?? '0.00';

          // Determine if outstanding amount is positive (Cr) or negative (Dr)
          final isPositive = outstanding.contains('Cr');
          final amountColor = isPositive ? Colors.red : Colors.green;

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.blue.shade50 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: isActive ? Colors.blue.shade700 : Colors.grey,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Customer Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Status Row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customer.custname,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Colors.black : Colors.grey.shade600,
                                ),
                              ),
                            ),

                            // ACTIVE/INACTIVE BUTTON
                            if (permissionProvider.canEditCustomer())
                              GestureDetector(
                                onTap: () => _toggleCustomerStatus(index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green.withOpacity(0.15)
                                        : Colors.red.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isActive ? Colors.green : Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isActive ? Icons.check_circle : Icons.cancel,
                                        size: 14,
                                        color: isActive ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isActive ? "ACTIVE" : "INACTIVE",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isActive ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green.withOpacity(0.15)
                                      : Colors.red.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isActive ? "ACTIVE" : "INACTIVE",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Customer Details from API
                        if (customer.phone.isNotEmpty)
                          _buildDetailItem(Icons.phone, "Phone", customer.phone),
                        if (customer.address.isNotEmpty)
                          _buildDetailItem(Icons.location_on, "Address", customer.address),
                        if (customer.custTypeName.isNotEmpty)
                          _buildDetailItem(Icons.category, "Type", customer.custTypeName),
                        if (customer.gst.isNotEmpty)
                          _buildDetailItem(Icons.numbers, "GST", customer.gst),
                        _buildDetailItem(Icons.account_balance_wallet, "Balance", customer.formattedBalance),

                        // Show Outstanding Amount
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.money_off,
                                size: 16,
                                color: amountColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Outstanding: ",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                outstanding,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: amountColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Show customer ID
                        _buildDetailItem(Icons.credit_card, "Customer ID", customer.custid),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Action Buttons (Only View and Edit)
                  Column(
                    children: [
                      // View Button
                      _buildActionButton(
                        icon: Icons.visibility,
                        color: Colors.blue,
                        onTap: () => _showCustomerDetails(customer, permissionProvider, outstanding),
                        tooltip: 'View Details',
                      ),

                      const SizedBox(height: 8),

                      // Edit Button
                      _buildActionButton(
                        icon: Icons.edit,
                        color: isActive && permissionProvider.canEditCustomer()
                            ? Colors.orange
                            : Colors.grey,
                        onTap: isActive && permissionProvider.canEditCustomer()
                            ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Updatecustomer(customer: customer),
                            ),
                          ).then((value) {
                            if (value == true) {
                              _fetchCustomers();
                            }
                          });
                        }
                            : () {
                          final message = !isActive
                              ? "Inactive customer cannot be edited"
                              : "You do not have permission to edit customers";

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(message),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        tooltip: 'Edit Customer',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =================== DETAIL ITEM BUILDER ===================
  Widget _buildDetailItem(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label: ${value ?? 'N/A'}",
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // =================== ACTION BUTTON BUILDER ===================
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  // =================== SHOW CUSTOMER DETAILS DIALOG ===================
  void _showCustomerDetails(CustomerModel customer, PermissionProvider permissionProvider, String outstanding) {
    // Determine if outstanding amount is positive (Cr) or negative (Dr)
    final isPositive = outstanding.contains('Cr');
    final amountColor = isPositive ? Colors.red : Colors.green;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                customer.custname,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(Icons.credit_card, "Customer ID", customer.custid),
              if (customer.phone.isNotEmpty)
                _buildDetailRow(Icons.phone, "Phone", customer.phone),
              if (customer.email.isNotEmpty)
                _buildDetailRow(Icons.email, "Email", customer.email),
              if (customer.landPhone.isNotEmpty)
                _buildDetailRow(Icons.phone, "Land Phone", customer.landPhone),
              if (customer.address.isNotEmpty)
                _buildDetailRow(Icons.location_on, "Address", customer.address),
              if (customer.custTypeName.isNotEmpty)
                _buildDetailRow(Icons.category, "Customer Type", customer.custTypeName),
              if (customer.gst.isNotEmpty)
                _buildDetailRow(Icons.numbers, "GST Number", customer.gst),
              _buildDetailRow(Icons.account_balance_wallet, "Balance", customer.formattedBalance),
              _buildDetailRow(Icons.calendar_today, "Credit Days", "${customer.creditDays} days"),
              _buildDetailRow(Icons.location_city, "State", "${customer.state} (${customer.stateCode})"),
              _buildDetailRow(Icons.account_balance, "Opening Balance", "₹${customer.opBln.toStringAsFixed(2)}"),
              _buildDetailRow(Icons.compare_arrows, "Balance Type", customer.balanceType),

              // Outstanding Amount
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.money_off, color: amountColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Outstanding Amount",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            outstanding,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: amountColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: customer.isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: customer.isActive ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      customer.isActive ? Icons.check_circle : Icons.cancel,
                      color: customer.isActive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      customer.isActive ? "Active" : "Inactive",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: customer.isActive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (permissionProvider.canEditCustomer() && customer.isActive)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Updatecustomer(customer: customer),
                  ),
                ).then((value) {
                  if (value == true) {
                    _fetchCustomers();
                  }
                });
              },
              child: const Text('Edit'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // =================== DETAIL ROW FOR DIALOG ===================
  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? 'N/A',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}