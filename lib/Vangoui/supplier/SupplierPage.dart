import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'AddSupplierPage.dart';
import 'UpdateSupplierPage.dart';
import 'ViewSupplierPage.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  // API variables
  String unid = '';
  String veh = '';
  final String apiUrl =
      "http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/get_suppliers.php";
  final String actionApiUrl =
      "http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/action/suppliers.php";

  // Data lists
  List<Map<String, dynamic>> allSuppliers = [];
  List<Map<String, dynamic>> displayedSuppliers = [];

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Loading states
  bool isLoading = true;
  bool isLoadingMore = false;
  bool isToggling = false;
  String? errorMessage;

  // Pagination variables (client-side pagination)
  int currentPage = 1;
  int totalPages = 1;
  int totalSuppliers = 0;
  bool hasMorePages = false;
  String searchQuery = '';
  final int itemsPerPage = 10;

  // Debounce timer for search
  Timer? _debounceTimer;

  // Scroll controller for pagination
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    print("🚀 SupplierPage initialized");
    _loadSessionData();

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // Load session data from SharedPreferences
  Future<void> _loadSessionData() async {
    try {
      print('🔍 Loading session data...');
      final prefs = await SharedPreferences.getInstance();
      unid = prefs.getString('unid') ?? '';
      veh = prefs.getString('veh') ?? '';

      print('🔍 Loaded from SharedPreferences - unid: $unid, veh: $veh');

      if (unid.isEmpty || veh.isEmpty) {
        setState(() {
          errorMessage = 'Session data missing. Please login again.';
          isLoading = false;
        });
        return;
      }

      print('✅ Session data loaded successfully');
      await _fetchSuppliersFromApi();
    } catch (e) {
      print('❌ Error loading session data: $e');
      setState(() {
        errorMessage = 'Failed to load session data: $e';
        isLoading = false;
      });
    }
  }

  // Scroll listener for pagination
  void _onScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200) {
        // User scrolled near the bottom, load more data
        if (!isLoadingMore && hasMorePages && !isLoading && !isToggling) {
          _loadMoreSuppliers();
        }
      }
    });
  }

  // =================== FETCH SUPPLIERS FROM API ===================
  Future<void> _fetchSuppliersFromApi() async {
    print("📋 Fetching suppliers from API...");

    setState(() {
      isLoading = true;
      errorMessage = null;
      currentPage = 1;
      allSuppliers = [];
    });

    try {
      // Prepare request body
      Map<String, dynamic> requestBody = {
        "unid": unid,
        "veh": veh,
      };

      print("📤 Request Body: ${json.encode(requestBody)}");

      // Make API call
      final response = await http
          .post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      )
          .timeout(const Duration(seconds: 10));

      print("📥 Response Status Code: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      // Check if widget is still mounted
      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        print("📊 API Response Parsed:");
        print("   Result: ${responseData['result']}");
        print("   Message: ${responseData['message']}");

        if (responseData['result'] == "1") {
          // Parse suppliers data
          List<Map<String, dynamic>> newSuppliers = [];

          if (responseData['supplierdet'] != null &&
              responseData['supplierdet'] is List) {
            final supplierList = responseData['supplierdet'] as List;
            print("📋 Found ${supplierList.length} suppliers");

            newSuppliers =
                supplierList.map<Map<String, dynamic>>((item) {
                  String id = item['suppid']?.toString() ?? '';
                  String name = item['supp_name']?.toString() ?? 'Unknown';

                  // Parse outstanding amount
                  double balance = 0.0;
                  String balanceType = 'Dr';

                  if (item['outstand_amt'] != null) {
                    String balanceStr = item['outstand_amt'].toString();

                    // Extract balance type (Dr/Cr)
                    if (balanceStr.contains('Dr')) {
                      balanceType = 'Dr';
                    } else if (balanceStr.contains('Cr')) {
                      balanceType = 'Cr';
                    }

                    // Extract numeric value
                    RegExp regExp = RegExp(r'([\d,]+\.?\d*)');
                    Match? match = regExp.firstMatch(balanceStr);
                    if (match != null) {
                      String numStr = match.group(1)!.replaceAll(',', '');
                      balance = double.tryParse(numStr) ?? 0.0;
                    }
                  }

                  // Default values for fields not provided by this API
                  bool isActive = true; // Default to active

                  return {
                    'id': id,
                    'name': name,
                    'gst': '', // Not provided in this API
                    'phone': '', // Not provided in this API
                    'email': '',
                    'address': '',
                    'landPhone': '',
                    'state': '',
                    'stateCode': '',
                    'balance': balance,
                    'balanceType': balanceType,
                    'isActive': isActive,
                  };
                }).toList();

            print("✅ Parsed ${newSuppliers.length} suppliers:");
            for (var i = 0; i < newSuppliers.length; i++) {
              print(
                "   ${i + 1}. ID: ${newSuppliers[i]['id']} - ${newSuppliers[i]['name']} - Balance: ${newSuppliers[i]['balance']} ${newSuppliers[i]['balanceType']}",
              );
            }
          }

          // Calculate pagination (client-side)
          int totalSuppliersFromApi = newSuppliers.length;
          int totalPagesFromApi = (totalSuppliersFromApi / itemsPerPage).ceil();

          // Get first page of data
          int startIndex = 0;
          int endIndex = itemsPerPage < totalSuppliersFromApi ? itemsPerPage : totalSuppliersFromApi;
          List<Map<String, dynamic>> pageData = newSuppliers.sublist(startIndex, endIndex);

          setState(() {
            allSuppliers = newSuppliers; // Store all suppliers
            displayedSuppliers = pageData; // Show first page
            totalSuppliers = totalSuppliersFromApi;
            totalPages = totalPagesFromApi;
            hasMorePages = totalPagesFromApi > 1;
            currentPage = 1;
            isLoading = false;
            isLoadingMore = false;
          });

          print("✅ Successfully loaded ${allSuppliers.length} total suppliers");
          print("✅ Displaying ${displayedSuppliers.length} suppliers on page 1");
          print("📊 Total pages: $totalPages, Has more: $hasMorePages");
        } else {
          // API returned error
          String message =
              responseData['message'] ?? 'Failed to load suppliers';
          message = message.replaceAll(RegExp(r'<[^>]*>'), '');

          setState(() {
            allSuppliers = [];
            displayedSuppliers = [];
            errorMessage = message;
            isLoading = false;
            isLoadingMore = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Server error: ${response.statusCode}";
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      print("❌ Exception occurred: $e");
      if (mounted) {
        setState(() {
          errorMessage = "Network error: $e";
          isLoading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  // Load more suppliers for pagination (client-side)
  Future<void> _loadMoreSuppliers() async {
    if (isLoadingMore || !hasMorePages) {
      return;
    }

    setState(() {
      isLoadingMore = true;
    });

    // Simulate network delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));

    int nextPage = currentPage + 1;
    int startIndex = (nextPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;

    if (startIndex < allSuppliers.length) {
      if (endIndex > allSuppliers.length) {
        endIndex = allSuppliers.length;
      }

      List<Map<String, dynamic>> nextPageData = allSuppliers.sublist(startIndex, endIndex);

      setState(() {
        displayedSuppliers.addAll(nextPageData);
        currentPage = nextPage;
        hasMorePages = currentPage < totalPages;
        isLoadingMore = false;
      });

      print("📄 Loaded page $currentPage with ${nextPageData.length} suppliers");
    } else {
      setState(() {
        hasMorePages = false;
        isLoadingMore = false;
      });
    }
  }

  // =================== SEARCH FUNCTIONALITY ===================
  void _searchSuppliers(String query) {
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
      if (mounted) {
        _performLocalSearch();
      }
    });
  }

  void _performLocalSearch() {
    if (searchQuery.isEmpty) {
      // Reset to first page of all suppliers
      setState(() {
        currentPage = 1;
        int endIndex = itemsPerPage < allSuppliers.length ? itemsPerPage : allSuppliers.length;
        displayedSuppliers = allSuppliers.sublist(0, endIndex);
        hasMorePages = allSuppliers.length > itemsPerPage;
      });
    } else {
      // Filter suppliers locally
      final query = searchQuery.toLowerCase();
      final filtered = allSuppliers.where((supplier) {
        return supplier['name'].toLowerCase().contains(query) ||
            supplier['id'].toLowerCase().contains(query);
      }).toList();

      setState(() {
        displayedSuppliers = filtered;
        hasMorePages = false; // Disable pagination during search
      });

      print("🔍 Search found ${filtered.length} suppliers for '$searchQuery'");
    }
  }

  void _clearSearch() {
    _debounceTimer?.cancel();

    setState(() {
      searchQuery = '';
      _searchController.clear();
    });

    // Reset to first page
    if (mounted) {
      setState(() {
        currentPage = 1;
        int endIndex = itemsPerPage < allSuppliers.length ? itemsPerPage : allSuppliers.length;
        displayedSuppliers = allSuppliers.sublist(0, endIndex);
        hasMorePages = allSuppliers.length > itemsPerPage;
      });
    }
    FocusScope.of(context).unfocus();
  }

  // =================== TOGGLE ACTIVE STATUS ===================
  void _toggleActiveStatus(String id) async {
    if (isToggling) return;

    // Find the supplier
    final supplier = allSuppliers.firstWhere((s) => s['id'] == id);
    final newStatus = !supplier['isActive'];
    final statusText = newStatus ? 'active' : 'inactive';

    print('🔄 Toggling supplier ${supplier['name']} status to $statusText');

    setState(() {
      isToggling = true;
    });

    try {
      // Prepare request body for status update
      Map<String, dynamic> requestBody = {
        "unid": unid,
        "veh": veh,
        "action": "supplierstatus",
        "supp": id,
      };

      print("📤 Status Update Request: ${json.encode(requestBody)}");

      // Make API call to update status
      final response = await http
          .post(
        Uri.parse(actionApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      )
          .timeout(const Duration(seconds: 10));

      print("📥 Status Update Response: ${response.statusCode}");
      print("📥 Status Update Body: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['result'] == "1") {
          // Success - update local list
          setState(() {
            // Update in allSuppliers
            final allIndex = allSuppliers.indexWhere((s) => s['id'] == id);
            if (allIndex != -1) {
              allSuppliers[allIndex]['isActive'] = newStatus;
            }

            // Update in displayedSuppliers
            final displayIndex = displayedSuppliers.indexWhere(
                  (s) => s['id'] == id,
            );
            if (displayIndex != -1) {
              displayedSuppliers[displayIndex]['isActive'] = newStatus;
            }
          });

          // Show success message
          String message = responseData['message'] ??
              '${supplier['name']} is now ${newStatus ? 'Active' : 'Inactive'}';
          message = message.replaceAll(RegExp(r'<[^>]*>'), '');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: newStatus ? Colors.green : Colors.orange,
            ),
          );
        } else {
          // API returned error
          String errorMessage = responseData['message'] ?? 'Failed to update status';
          errorMessage = errorMessage.replaceAll(RegExp(r'<[^>]*>'), '');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error toggling status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isToggling = false;
        });
      }
    }
  }

  void _viewSupplier(String id) {
    final supplier = allSuppliers.firstWhere((s) => s['id'] == id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewSupplierPage(supplier: supplier),
      ),
    ).then((result) {
      if (result == 'edit') {
        _editSupplier(id);
      }
    });
  }

  void _editSupplier(String id) {
    final supplier = allSuppliers.firstWhere((s) => s['id'] == id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateSupplierPage(supplier: supplier),
      ),
    ).then((result) {
      if (result == true) {
        _fetchSuppliersFromApi();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supplier updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _addSupplier() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddSupplierPage()),
    ).then((result) {
      if (result == true) {
        _fetchSuppliersFromApi();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supplier added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  String _formatBalance(double balance, String balanceType) {
    String formatted = balance.toStringAsFixed(2);
    if (balanceType == 'Cr') {
      return '₹ $formatted Cr';
    } else {
      return '₹ $formatted Dr';
    }
  }

  // Refresh data
  Future<void> _refreshData() async {
    setState(() {
      currentPage = 1;
      searchQuery = '';
      _searchController.clear();
    });
    await _fetchSuppliersFromApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        title: const Text(
          'Suppliers',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addSupplier,
            tooltip: 'Add Supplier',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading && allSuppliers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading suppliers...'),
          ],
        ),
      );
    }

    if (errorMessage != null && allSuppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error Loading Suppliers',
              style: TextStyle(
                fontSize: 18,
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (allSuppliers.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty
                  ? 'No suppliers found for "$searchQuery"'
                  : 'No Suppliers Found',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Click + to add a new supplier',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: _clearSearch,
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: _searchSuppliers,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Supplier Count and Stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          child: Row(
            children: [
              Text(
                'Total Suppliers: $totalSuppliers',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Active: ${allSuppliers.where((s) => s['isActive']).length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Inactive: ${allSuppliers.where((s) => !s['isActive']).length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Suppliers List
        Expanded(
          child: ListView.builder(
            key: const PageStorageKey<String>('supplier_list'),
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: displayedSuppliers.length + (hasMorePages && searchQuery.isEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == displayedSuppliers.length && hasMorePages && searchQuery.isEmpty) {
                return _buildLoadMoreButton();
              }

              final supplier = displayedSuppliers[index];
              return _buildSupplierCard(supplier, index + 1);
            },
          ),
        ),
      ],
    );
  }

  // Load More Button for Pagination
  Widget _buildLoadMoreButton() {
    if (!hasMorePages) {
      return const SizedBox.shrink();
    }

    if (isLoadingMore) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Loading more suppliers...'),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ElevatedButton(
          onPressed: _loadMoreSuppliers,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade800,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_downward, size: 18),
              const SizedBox(width: 8),
              Text('Load More (Page $currentPage of $totalPages)'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierCard(Map<String, dynamic> supplier, int serialNo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border:
          !supplier['isActive']
              ? Border.all(color: Colors.red.shade100, width: 1)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // First Row: S.No, Name, Status
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '#$serialNo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                            supplier['isActive']
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                supplier['isActive']
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 14,
                                color:
                                supplier['isActive']
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                supplier['isActive'] ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color:
                                  supplier['isActive']
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Second Row: ID and Balance
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Supplier ID',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                supplier['id']?.isNotEmpty == true
                                    ? supplier['id']
                                    : 'N/A',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Balance',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _formatBalance(
                                  supplier['balance'],
                                  supplier['balanceType'],
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Third Row: Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // View Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.visibility_outlined,
                        size: 20,
                        color: Colors.blue.shade800,
                      ),
                      onPressed:
                      isToggling
                          ? null
                          : () => _viewSupplier(supplier['id']),
                      tooltip: 'View',
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Edit Button
                  Container(
                    decoration: BoxDecoration(
                      color:
                      supplier['isActive']
                          ? Colors.orange.shade50
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color:
                        supplier['isActive']
                            ? Colors.orange.shade800
                            : Colors.grey,
                      ),
                      onPressed:
                      supplier['isActive'] && !isToggling
                          ? () => _editSupplier(supplier['id'])
                          : null,
                      tooltip:
                      supplier['isActive']
                          ? 'Edit'
                          : 'Cannot edit inactive supplier',
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Active/Inactive Toggle Button
                  Container(
                    decoration: BoxDecoration(
                      color:
                      supplier['isActive']
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        supplier['isActive']
                            ? Icons.toggle_on
                            : Icons.toggle_off,
                        size: 24,
                        color:
                        supplier['isActive']
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                      onPressed:
                      isToggling
                          ? null
                          : () => _toggleActiveStatus(supplier['id']),
                      tooltip:
                      supplier['isActive'] ? 'Deactivate' : 'Activate',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}