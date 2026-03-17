import 'dart:async';
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

class _CustomerPageContentState extends State<_CustomerPageContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep state when navigating back

  List<CustomerModel> allCustomers = [];
  List<CustomerModel> displayedCustomers = [];
  Map<String, Map<String, dynamic>> customerOutstandingData = {};
  bool isLoading = true;
  bool isLoadingSessionData = true;
  bool isLoadingOutstanding = false;
  bool isLoadingMore = false; // For pagination loading
  String errorMessage = '';
  int totalCustomers = 0;
  int currentPage = 1;
  int totalPages = 1;
  bool hasMorePages = false;
  String searchQuery = '';

  String unid = '';
  String veh = '';

  late CustomerApiService customerApiService;
  final TextEditingController _searchController = TextEditingController();

  // Track current filter state
  String? currentFilter; // 'active', 'inactive', 'outstanding', or null for all

  // Debounce timer for search
  Timer? _debounceTimer;

  // Scroll controller for pagination
  final ScrollController _scrollController = ScrollController();

  @override
  @override
  void initState() {
    super.initState();
    print('🚀 DEBUG: CustomerPage initState called');
    _loadSessionData();

    // Add scroll listener for pagination with post frame callback
    _scrollController.addListener(() {
      // Use post frame callback to avoid layout issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _onScroll();
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll listener for pagination
  // Update the _onScroll method
  void _onScroll() {
    // Use WidgetsBinding to schedule the scroll check after the current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        // User scrolled near the bottom, load more data
        if (!isLoadingMore && hasMorePages && !isLoading) {
          _loadMoreCustomers();
        }
      }
    });
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
      _fetchCustomers(resetPagination: true);
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

    if (mounted) {
      setState(() {
        isLoadingOutstanding = true;
      });
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/customers.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "unid": unid,
          "veh": veh,
          "srch": "",
          "page": ""
        }),
      );

      print('💰 DEBUG: Outstanding API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

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
            }
          }

          if (mounted) {
            setState(() {
              customerOutstandingData = outstandingMap;
              print('💰 DEBUG: Loaded outstanding amounts for ${customerOutstandingData.length} customers');
            });
          }
        }
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

  // =================== FETCH CUSTOMERS WITH SEARCH AND PAGINATION ===================
  Future<void> _fetchCustomers({bool resetPagination = true}) async {
    print('🎯 DEBUG: Starting _fetchCustomers');
    print('🎯 DEBUG: Search query = "$searchQuery"');
    print('🎯 DEBUG: Reset pagination = $resetPagination');
    print('🎯 DEBUG: Current page before = $currentPage');

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

    if (resetPagination) {
      if (mounted) {
        setState(() {
          isLoading = true;
          errorMessage = '';
          currentPage = 1;
          allCustomers = [];
          hasMorePages = false;
        });
      }
    }

    print('📡 DEBUG: Calling API with search: "$searchQuery", page: $currentPage');

    try {
      final result = await customerApiService.fetchCustomers(
        search: searchQuery,
        page: currentPage.toString(),
      );

      print('📡 DEBUG: API Response received');
      print('📡 DEBUG: Response success: ${result['success']}');

      if (!mounted) {
        print('⚠️ DEBUG: Widget not mounted, returning');
        return;
      }

      if (result['success'] == true) {
        List<CustomerModel> customers = [];
        if (result['customers'] is List) {
          final List<dynamic> rawList = result['customers'] as List<dynamic>;
          customers = rawList.map((item) {
            if (item is CustomerModel) {
              return item;
            } else if (item is Map<String, dynamic>) {
              return CustomerModel.fromJson(item);
            } else {
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

        print('📊 DEBUG: Main API returned ${customers.length} customers for page $currentPage');

        // Update customers with outstanding amounts
        final List<CustomerModel> updatedCustomers = customers.map((customer) {
          final outstandingData = customerOutstandingData[customer.custid];
          final outstanding = outstandingData?['outstandingAmount'] ?? '0.00';
          return customer.copyWith(outstandingAmount: outstanding);
        }).toList();

        // Calculate pagination
        int totalCustomersFromApi = int.tryParse(result['totalCustomers']?.toString() ?? '0') ?? 0;
        int itemsPerPage = customers.length > 0 ? customers.length : 1;
        int totalPagesFromApi = (totalCustomersFromApi / itemsPerPage).ceil();
        bool hasMoreFromApi = currentPage < totalPagesFromApi;

        print('📊 DEBUG: Calculated pagination:');
        print('📊 DEBUG: - totalCustomers: $totalCustomersFromApi');
        print('📊 DEBUG: - itemsPerPage: $itemsPerPage');
        print('📊 DEBUG: - totalPages: $totalPagesFromApi');
        print('📊 DEBUG: - currentPage: $currentPage');
        print('📊 DEBUG: - hasMore: $hasMoreFromApi');

        setState(() {
          if (resetPagination) {
            allCustomers = updatedCustomers;
          } else {
            allCustomers.addAll(updatedCustomers);
          }

          totalCustomers = totalCustomersFromApi;
          totalPages = totalPagesFromApi;
          hasMorePages = hasMoreFromApi;

          _applyCurrentFilter();

          isLoading = false;
          isLoadingMore = false;

          print('✅ DEBUG: After setState:');
          print('✅ DEBUG: - allCustomers length: ${allCustomers.length}');
          print('✅ DEBUG: - displayedCustomers length: ${displayedCustomers.length}');
          print('✅ DEBUG: - currentPage: $currentPage');
          print('✅ DEBUG: - totalPages: $totalPages');
          print('✅ DEBUG: - hasMorePages: $hasMorePages');
        });

        // Fetch outstanding amounts in background
        _fetchCustomerOutstanding();

      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load customers';
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      print('❌ DEBUG: Exception in _fetchCustomers: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
          errorMessage = 'Failed to load customers: $e';
        });
      }
    }
  }

  // Load more customers for pagination
  Future<void> _loadMoreCustomers() async {
    if (isLoadingMore || !hasMorePages) {
      print('📄 DEBUG: Cannot load more - isLoadingMore: $isLoadingMore, hasMorePages: $hasMorePages');
      return;
    }

    print('📄 DEBUG: Loading more customers - Page ${currentPage + 1} of $totalPages');

    setState(() {
      isLoadingMore = true;
    });

    currentPage++;
    await _fetchCustomers(resetPagination: false);
  }

  // =================== SEARCH FUNCTIONALITY ===================
  void _searchCustomers(String query) {
    print('🔍 DEBUG: Searching for: $query');

    setState(() {
      searchQuery = query;
    });

    _debounceSearch();
  }

  void _debounceSearch() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchCustomers(resetPagination: true);
    });
  }

  void _clearSearch() {
    print('🔍 DEBUG: Clearing search');

    _debounceTimer?.cancel();

    setState(() {
      searchQuery = '';
      _searchController.clear();
    });

    _fetchCustomers(resetPagination: true);
    FocusScope.of(context).unfocus();
  }

  // Apply current filter
  void _applyCurrentFilter() {
    if (currentFilter == 'active') {
      displayedCustomers = allCustomers.where((c) => c.isActive).toList();
    } else if (currentFilter == 'inactive') {
      displayedCustomers = allCustomers.where((c) => !c.isActive).toList();
    } else if (currentFilter == 'outstanding') {
      displayedCustomers = allCustomers.where((c) => c.hasOutstanding).toList();
    } else {
      displayedCustomers = List.from(allCustomers);
    }
    print('🔍 DEBUG: Applied filter "$currentFilter" - showing ${displayedCustomers.length} customers');
  }

  // Toggle customer status
  void _toggleCustomerStatus(int index) async {
    final customer = displayedCustomers[index];
    final newStatus = !customer.isActive;
    final statusText = newStatus ? 'active' : 'inactive';

    print('🔄 DEBUG: Toggling customer ${customer.custname} status to $statusText');

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? checkingSnackbar;
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? loadingSnackbar;

    if (!newStatus) {
      checkingSnackbar = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              const SizedBox(width: 15),
              const Text('Checking customer status...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 5),
        ),
      );

      try {
        Map<String, dynamic> statusResult;
        try {
          statusResult = await customerApiService.checkCustomerStatus(customer.custid);
        } catch (e) {
          statusResult = await _checkCustomerStatusDirect(customer.custid);
        }

        try {
          if (checkingSnackbar != null && mounted) {
            checkingSnackbar.close();
          }
        } catch (e) {}

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
        }

        if (!statusResult['success'] || !statusResult['canDelete']) {
          String errorMessage = statusResult['message']?.toString() ?? '';
          errorMessage = errorMessage.replaceAll(RegExp(r'<[^>]*>'), '');
          errorMessage = errorMessage
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&amp;', '&')
              .replaceAll('&quot;', '"')
              .replaceAll('&#39;', "'");

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage.isNotEmpty ? errorMessage : 'Cannot deactivate customer. Has pending outstanding amount.'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      } catch (e) {
        try {
          if (checkingSnackbar != null && mounted) {
            checkingSnackbar.close();
          }
        } catch (e) {}

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to verify customer status. Proceeding with caution.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }

    loadingSnackbar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 15),
            Text('Updating customer status to ${newStatus ? 'Active' : 'Inactive'}...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      final result = await customerApiService.updateCustomerStatus(
        custId: customer.custid,
        isActive: newStatus,
      );

      try {
        if (loadingSnackbar != null && mounted) {
          loadingSnackbar.close();
        }
      } catch (e) {}

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (result['success'] == true) {
        if (mounted) {
          setState(() {
            final updatedCustomer = customer.copyWith(status: statusText);

            displayedCustomers[index] = updatedCustomer;

            final allIndex = allCustomers.indexWhere((c) => c.custid == customer.custid);
            if (allIndex != -1) {
              allCustomers[allIndex] = updatedCustomer;
            }

            if (currentFilter == 'active' && !newStatus) {
              displayedCustomers.removeAt(index);
            } else if (currentFilter == 'inactive' && newStatus) {
              displayedCustomers.removeAt(index);
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${customer.custname} is now ${newStatus ? 'Active' : 'Inactive'}'),
              backgroundColor: newStatus ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        String errorMessage = result['message']?.toString() ?? 'Failed to update status';
        errorMessage = errorMessage.replaceAll(RegExp(r'<[^>]*>'), '');
        errorMessage = errorMessage
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&amp;', '&')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      try {
        if (loadingSnackbar != null && mounted) {
          loadingSnackbar.close();
        }
      } catch (e) {}

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Direct customer status check
  Future<Map<String, dynamic>> _checkCustomerStatusDirect(String custId) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/action/customers.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'unid': unid,
          'veh': veh,
          'action': 'customerstatus',
          'custid': custId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': data['result'] == '1',
          'message': data['message'] ?? '',
          'canDelete': data['result'] == '1',
        };
      } else {
        return {'success': false, 'message': 'Server error: ${response.statusCode}', 'canDelete': false};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e', 'canDelete': false};
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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

  // Access denied screen
  Scaffold _buildAccessDeniedScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: const Text('Customers', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 20),
                const Text('Limited Access', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 15),
                const Text('You do not have permission to view customers.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // App bar
  AppBar _buildAppBar(BuildContext context, PermissionProvider permissionProvider) {
    return AppBar(
      backgroundColor: Colors.blue.shade800,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.people_outline, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text('Customers', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 20)),
          const Spacer(),
          if (isLoadingOutstanding)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ),
          if (totalCustomers > 0 && !isLoadingOutstanding)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Text('$totalCustomers', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
        ],
      ),
      centerTitle: false,
      elevation: 1,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => _fetchCustomers(resetPagination: true),
        ),
        if (permissionProvider.canAddCustomer())
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Addcustomer())),
              child: const Row(
                children: [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 6),
                  Text("Add", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
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
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
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
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.blue, size: 20),
                  onPressed: () => _showFilterOptions(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Filter options
  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Filter Customers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade100, foregroundColor: Colors.grey.shade800),
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
    if (!mounted) return;
    setState(() {
      currentFilter = status;
      _applyCurrentFilter();
      searchQuery = '';
      _searchController.clear();
    });
  }

  void _filterByOutstanding() {
    if (!mounted) return;
    setState(() {
      currentFilter = 'outstanding';
      _applyCurrentFilter();
      searchQuery = '';
      _searchController.clear();
    });
  }

  void _clearFilters() {
    _debounceTimer?.cancel();
    setState(() {
      currentFilter = null;
      searchQuery = '';
      _searchController.clear();
    });
    _fetchCustomers(resetPagination: true);
  }

  // Customer list
  Widget _buildCustomerList(PermissionProvider permissionProvider) {
    if (isLoading) {
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchCustomers(resetPagination: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
              child: const Text('Retry', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (displayedCustomers.isEmpty) {
      String emptyMessage = 'No Customers Found';
      if (searchQuery.isNotEmpty) {
        emptyMessage = 'No customers found for "$searchQuery"';
      } else if (currentFilter == 'active') {
        emptyMessage = 'No active customers found';
      } else if (currentFilter == 'inactive') {
        emptyMessage = 'No inactive customers found';
      } else if (currentFilter == 'outstanding') {
        emptyMessage = 'No customers with outstanding amounts found';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty || currentFilter != null ? Icons.search_off : Icons.people_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(emptyMessage, style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty || currentFilter != null ? 'Try a different search term or clear filters' : 'Add your first customer to get started',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (searchQuery.isNotEmpty || currentFilter != null)
                  ElevatedButton(
                    onPressed: _clearFilters,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                    child: const Text('Clear Filters', style: TextStyle(color: Colors.white)),
                  ),
                if (searchQuery.isNotEmpty || currentFilter != null) const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _fetchCustomers(resetPagination: true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
                  child: const Text('Refresh', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchCustomers(resetPagination: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: displayedCustomers.length + (hasMorePages ? 1 : 0),
        // Add a key to help with rebuilding
        key: PageStorageKey('customer_list'),
        itemBuilder: (context, index) {
          if (index == displayedCustomers.length) {
            return _buildLoadMoreButton();
          }

          final customer = displayedCustomers[index];
          final isActive = customer.isActive;
          final outstanding = customer.outstandingAmount ?? '0.00';
          final isPositive = outstanding.contains('Cr');
          final amountColor = isPositive ? Colors.red : Colors.green;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.blue.shade50 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.person, size: 30, color: isActive ? Colors.blue.shade700 : Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  customer.custname,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.grey.shade600),
                                ),
                              ),
                              if (permissionProvider.canEditCustomer())
                                GestureDetector(
                                  onTap: () => _toggleCustomerStatus(index),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: isActive ? Colors.green : Colors.red, width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(isActive ? Icons.check_circle : Icons.cancel, size: 14, color: isActive ? Colors.green : Colors.red),
                                        const SizedBox(width: 6),
                                        Text(
                                          isActive ? "ACTIVE" : "INACTIVE",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isActive ? "ACTIVE" : "INACTIVE",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.red),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (customer.phone.isNotEmpty) _buildDetailItem(Icons.phone, "Phone", customer.phone),
                          if (customer.address.isNotEmpty) _buildDetailItem(Icons.location_on, "Address", customer.address),
                          if (customer.custTypeName.isNotEmpty) _buildDetailItem(Icons.category, "Type", customer.custTypeName),
                          if (customer.gst.isNotEmpty) _buildDetailItem(Icons.numbers, "GST", customer.gst),
                          _buildDetailItem(Icons.account_balance_wallet, "Balance", customer.formattedBalance),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Icon(Icons.money_off, size: 16, color: amountColor),
                                const SizedBox(width: 8),
                                Text("Outstanding: ", style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                Text(outstanding, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: amountColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        _buildActionButton(
                          icon: Icons.visibility,
                          color: Colors.blue,
                          onTap: () => _showCustomerDetails(customer, permissionProvider, outstanding),
                          tooltip: 'View Details',
                        ),
                        const SizedBox(height: 8),
                        _buildActionButton(
                          icon: Icons.edit,
                          color: isActive && permissionProvider.canEditCustomer() ? Colors.orange : Colors.grey,
                          onTap: isActive && permissionProvider.canEditCustomer()
                              ? () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => Updatecustomer(customer: customer))).then((value) {
                              if (value == true) {
                                _fetchCustomers(resetPagination: true);
                              }
                            });
                          }
                              : () {
                            final message = !isActive ? "Inactive customer cannot be edited" : "You do not have permission to edit customers";
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(message), duration: const Duration(seconds: 2)));
                          },
                          tooltip: isActive ? 'Edit Customer' : 'Cannot edit inactive customer',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );  }

  // Load More Button
  Widget _buildLoadMoreButton() {
    if (!hasMorePages) {
      return const SizedBox.shrink();
    }

    if (isLoadingMore) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 16),
              Text('Loading more customers...'),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ElevatedButton(
          onPressed: _loadMoreCustomers,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade800,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_downward, size: 18),
              const SizedBox(width: 8),
              Text('Load More (Page $currentPage of $totalPages)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // Detail item builder
  Widget _buildDetailItem(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text("$label: ${value ?? 'N/A'}", style: const TextStyle(fontSize: 14, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // Action button builder
  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap, required String tooltip}) {
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

  // Show customer details dialog
  void _showCustomerDetails(CustomerModel customer, PermissionProvider permissionProvider, String outstanding) {
    final isPositive = outstanding.contains('Cr');
    final amountColor = isPositive ? Colors.red : Colors.green;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(child: Text(customer.custname, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (customer.phone.isNotEmpty) _buildDetailRow(Icons.phone, "Phone", customer.phone),
              if (customer.email.isNotEmpty) _buildDetailRow(Icons.email, "Email", customer.email),
              if (customer.landPhone.isNotEmpty) _buildDetailRow(Icons.phone, "Land Phone", customer.landPhone),
              if (customer.address.isNotEmpty) _buildDetailRow(Icons.location_on, "Address", customer.address),
              if (customer.custTypeName.isNotEmpty) _buildDetailRow(Icons.category, "Customer Type", customer.custTypeName),
              if (customer.gst.isNotEmpty) _buildDetailRow(Icons.numbers, "GST Number", customer.gst),
              _buildDetailRow(Icons.account_balance_wallet, "Balance", customer.formattedBalance),
              _buildDetailRow(Icons.calendar_today, "Credit Days", "${customer.creditDays} days"),
              _buildDetailRow(Icons.location_city, "State", "${customer.state} (${customer.stateCode})"),
              _buildDetailRow(Icons.account_balance, "Opening Balance", "₹${customer.opBln.toStringAsFixed(2)}"),
              _buildDetailRow(Icons.compare_arrows, "Balance Type", customer.balanceType),
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
                          const Text("Outstanding Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(outstanding, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: amountColor)),
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
                  color: customer.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: customer.isActive ? Colors.green : Colors.red, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(customer.isActive ? Icons.check_circle : Icons.cancel, color: customer.isActive ? Colors.green : Colors.red),
                    const SizedBox(width: 8),
                    Text(customer.isActive ? "Active" : "Inactive", style: TextStyle(fontWeight: FontWeight.bold, color: customer.isActive ? Colors.green : Colors.red)),
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => Updatecustomer(customer: customer))).then((value) {
                  if (value == true) {
                    _fetchCustomers(resetPagination: true);
                  }
                });
              },
              child: const Text('Edit'),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  // Detail row for dialog
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
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value ?? 'N/A', style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}