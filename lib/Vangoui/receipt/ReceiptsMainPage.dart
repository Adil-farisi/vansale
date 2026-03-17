import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ReceiptUpdatePage.dart';
import 'SingleReceiptViewPage.dart';
import 'ReceiptSavePage.dart';

class ReceiptsMainPage extends StatefulWidget {
  const ReceiptsMainPage({super.key});

  @override
  State<ReceiptsMainPage> createState() => _ReceiptsMainPageState();
}

class _ReceiptsMainPageState extends State<ReceiptsMainPage> {
  List<Map<String, dynamic>> allReceipts = [];
  List<Map<String, dynamic>> displayedReceipts = [];
  Map<String, String> walletMap = {}; // Map wallet IDs to names
  bool isLoading = true;
  bool isLoadingWallets = false;
  bool isLoadingMore = false;
  bool hasError = false;
  bool isDeleting = false;
  String errorMessage = '';
  final TextEditingController searchController = TextEditingController();

  // Pagination variables
  int currentPage = 1;
  int totalPages = 1;
  int totalReceipts = 0;
  bool hasMorePages = false;
  String searchQuery = '';

  // Debounce timer for search
  Timer? _debounceTimer;

  // Scroll controller for pagination
  final ScrollController _scrollController = ScrollController();

  // API URLs
  final String receiptsApiUrl =
      "http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/receipts.php";
  final String walletsApiUrl =
      "http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/get_wallets.php";
  final String receiptActionApiUrl =
      "http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/action/receipt.php";

  // Session variables
  String unid = '';
  String veh = '';

  @override
  void initState() {
    super.initState();
    print("🚀 ReceiptsMainPage initialized");
    _loadSessionData();

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll listener for pagination
  void _onScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        // User scrolled near the bottom, load more data
        if (!isLoadingMore && hasMorePages && !isLoading) {
          _loadMoreReceipts();
        }
      }
    });
  }

  Future<void> _loadSessionData() async {
    try {
      print('🔍 Loading session data...');
      final prefs = await SharedPreferences.getInstance();
      unid = prefs.getString('unid') ?? '';
      veh = prefs.getString('veh') ?? '';

      print('🔍 Loaded from SharedPreferences - unid: $unid, veh: $veh');

      if (unid.isEmpty || veh.isEmpty) {
        print('❌ Session data missing');
        setState(() {
          hasError = true;
          errorMessage = 'Session data missing. Please login again.';
          isLoading = false;
        });
        return;
      }

      print('✅ Session data loaded successfully');
      await _fetchWalletsAndReceipts();
    } catch (e) {
      print('❌ Error loading session data: $e');
      setState(() {
        hasError = true;
        errorMessage = 'Failed to load session data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchWalletsAndReceipts() async {
    print("🔄 Starting to fetch wallets and receipts...");

    setState(() {
      isLoadingWallets = true;
    });

    await _fetchWallets();
    await _fetchReceipts(resetPagination: true);
  }

  Future<void> _fetchWallets() async {
    print('💰 Starting _fetchWallets');
    print('💰 API URL: $walletsApiUrl');
    print('💰 Request body: {"unid": "$unid", "veh": "$veh"}');

    try {
      final response = await http.post(
        Uri.parse(walletsApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"unid": unid, "veh": veh}),
      );

      print('💰 Wallet API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('💰 Wallet API parsed response result: ${data['result']}');

        if (data['result'] == "1") {
          final List<dynamic> walletList = data['walletdet'] ?? [];
          final Map<String, String> wallets = {};

          for (var wallet in walletList) {
            final wltid = wallet['wltid']?.toString() ?? '';
            final wltName = wallet['wlt_name']?.toString() ?? '';

            if (wltid.isNotEmpty && wltName.isNotEmpty) {
              wallets[wltid] = wltName;
              print('💰 Wallet $wltid - Name: $wltName');
            }
          }

          setState(() {
            walletMap = wallets;
            print('✅ Loaded ${wallets.length} wallets from API');
          });
        } else {
          print('❌ Wallet API returned result: ${data['result']}');
          print('❌ Wallet API message: ${data['message']}');
        }
      } else {
        print('❌ Wallet API HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in _fetchWallets: $e');
    } finally {
      setState(() {
        isLoadingWallets = false;
      });
    }
  }

  // =================== FETCH RECEIPTS WITH SEARCH AND PAGINATION ===================
  Future<void> _fetchReceipts({bool resetPagination = true}) async {
    print("🔄 Starting API call to: $receiptsApiUrl");
    print("📝 Search query: '$searchQuery'");
    print("📄 Page: $currentPage");

    if (resetPagination) {
      setState(() {
        isLoading = true;
        hasError = false;
        currentPage = 1;
        allReceipts = [];
      });
    }

    // Request body with session data, search and page
    final Map<String, dynamic> requestBody = {
      "unid": unid,
      "veh": veh,
      "srch": searchQuery,
      "page": currentPage.toString(),
    };

    print("📦 Request body: $requestBody");

    try {
      print("🌐 Making HTTP POST request...");
      final response = await http.post(
        Uri.parse(receiptsApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print("✅ HTTP Response received");
      print("📊 Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("📋 Parsed Response Data: ${responseData['result']}");
        print("📋 Total Receipts from API: ${responseData['ttlreceipts']}");

        if (responseData['result'] == "1") {
          final List<dynamic> receiptList = responseData['receiptdet'] ?? [];
          print("✅ Success! Found ${receiptList.length} receipts");

          List<Map<String, dynamic>> transformedReceipts = [];

          for (int i = 0; i < receiptList.length; i++) {
            final receipt = receiptList[i];

            // Get wallet name from walletMap if available, otherwise use API value
            String walletName = receipt['wlt_name']?.toString() ?? 'Cash';
            final walletId = receipt['wltid']?.toString();

            // Try to get wallet name from our wallet map
            if (walletId != null && walletMap.containsKey(walletId)) {
              walletName = walletMap[walletId]!;
            }

            // If walletName is "1", convert it to "Cash"
            if (walletName == "1") {
              walletName = "Cash";
            }

            transformedReceipts.add({
              "slNo": i + 1,
              "date": receipt['rcp_date']?.toString() ?? '',
              "receiptNo": receipt['rcp_no']?.toString() ?? '',
              "customerName": receipt['custname']?.toString() ?? '',
              "wallet": walletName,
              "wltid": walletId,
              "notes": receipt['notes']?.toString() ?? "",
              "receivedAmount": receipt['rcp_amt']?.toString() ?? '0',
              "rcpid": receipt['rcpid']?.toString() ?? '',
              "whatsappNo": receipt['whatsapp_no']?.toString() ?? '',
              "confirm": receipt['confirm']?.toString() ?? '',
            });
          }

          // Calculate pagination
          int totalReceiptsFromApi = int.tryParse(responseData['ttlreceipts']?.toString() ?? '0') ?? 0;
          int itemsPerPage = receiptList.length > 0 ? receiptList.length : 1;
          int totalPagesFromApi = itemsPerPage > 0 ? (totalReceiptsFromApi / itemsPerPage).ceil() : 1;
          bool hasMoreFromApi = currentPage < totalPagesFromApi;

          print("📊 Pagination calculated:");
          print("   - totalReceipts: $totalReceiptsFromApi");
          print("   - itemsPerPage: $itemsPerPage");
          print("   - totalPages: $totalPagesFromApi");
          print("   - currentPage: $currentPage");
          print("   - hasMore: $hasMoreFromApi");

          setState(() {
            if (resetPagination) {
              allReceipts = transformedReceipts;
            } else {
              allReceipts.addAll(transformedReceipts);
            }

            // Apply current filter (if any) - for now just show all
            displayedReceipts = List.from(allReceipts);

            totalReceipts = totalReceiptsFromApi;
            totalPages = totalPagesFromApi;
            hasMorePages = hasMoreFromApi;
            isLoading = false;
            isLoadingMore = false;
          });

          print("✅ Successfully loaded ${allReceipts.length} receipts");
          print("✅ Displaying ${displayedReceipts.length} receipts");
          print("✅ Total amount: ₹${_calculateTotalAmount()}");
        } else {
          print("❌ API returned result: ${responseData['result']}");
          print("❌ Error message: ${responseData['message']}");
          setState(() {
            hasError = true;
            errorMessage = responseData['message']?.toString() ?? 'Failed to load receipts';
            isLoading = false;
            isLoadingMore = false;
          });
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        setState(() {
          hasError = true;
          errorMessage = 'HTTP Error: ${response.statusCode}';
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      print("❌❌❌ EXCEPTION CAUGHT!");
      print("❌ Error message: $e");
      setState(() {
        hasError = true;
        errorMessage = 'Network Error: $e';
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  // Load more receipts for pagination
  Future<void> _loadMoreReceipts() async {
    if (isLoadingMore || !hasMorePages) {
      print('📄 Cannot load more - isLoadingMore: $isLoadingMore, hasMorePages: $hasMorePages');
      return;
    }

    print('📄 Loading more receipts - Page ${currentPage + 1} of $totalPages');

    setState(() {
      isLoadingMore = true;
    });

    currentPage++;
    await _fetchReceipts(resetPagination: false);
  }

  // =================== SEARCH FUNCTIONALITY ===================
  void _searchReceipts(String query) {
    print('🔍 Searching for: $query');

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
      _fetchReceipts(resetPagination: true);
    });
  }

  void _clearSearch() {
    print('🔍 Clearing search');

    _debounceTimer?.cancel();

    setState(() {
      searchQuery = '';
      searchController.clear();
    });

    _fetchReceipts(resetPagination: true);
    FocusScope.of(context).unfocus();
  }

  // Calculate overall total amount
  String _calculateTotalAmount() {
    double total = 0;
    for (var receipt in displayedReceipts) {
      final amountStr = receipt["receivedAmount"].toString().replaceAll(",", "");
      final amount = double.tryParse(amountStr) ?? 0;
      total += amount;
    }
    return total.toStringAsFixed(2);
  }

  // Navigate to ReceiptSavePage
  void _navigateToSaveReceipt() {
    print("➕ Navigating to ReceiptSavePage...");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReceiptSavePage()),
    ).then((savedReceipt) {
      if (savedReceipt != null) {
        print("✅ New receipt saved, refreshing list...");
        _fetchReceipts(resetPagination: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print("↩️ Returned from ReceiptSavePage without saving");
      }
    });
  }

  // Refresh both wallets and receipts
  Future<void> _refreshData() async {
    print("🔄 Refreshing all data...");
    setState(() {
      currentPage = 1;
    });
    await _fetchWallets();
    await _fetchReceipts(resetPagination: true);
  }

  @override
  Widget build(BuildContext context) {
    print("🎨 Building ReceiptsMainPage UI...");
    print("   isLoading: $isLoading");
    print("   isLoadingMore: $isLoadingMore");
    print("   hasError: $hasError");
    print("   allReceipts count: ${allReceipts.length}");
    print("   displayedReceipts count: ${displayedReceipts.length}");
    print("   currentPage: $currentPage, totalPages: $totalPages, hasMore: $hasMorePages");

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Receipts",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 3,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              print("🔄 Refresh button pressed");
              _refreshData();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              print("➕ Add Receipt button pressed");
              _navigateToSaveReceipt();
            },
            tooltip: 'Add New Receipt',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    print("🔨 Building body based on state...");

    if (isLoading) {
      print("⏳ Showing loading indicator");
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading receipts...'),
          ],
        ),
      );
    }

    if (hasError) {
      print("❌ Showing error state");
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading receipts',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print("🔄 Retry button pressed");
                _refreshData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (displayedReceipts.isEmpty) {
      print("📭 Showing empty state");
      String emptyMessage = 'No Receipts Found';
      if (searchQuery.isNotEmpty) {
        emptyMessage = 'No receipts found for "$searchQuery"';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
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
                  : 'Tap the + button to add your first receipt',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            if (searchQuery.isNotEmpty)
              ElevatedButton(
                onPressed: _clearSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text('Clear Search', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      );
    }

    print("✅ Showing receipts list with ${displayedReceipts.length} items");
    return Column(
      children: [
        // Search Section
        Card(
          margin: const EdgeInsets.all(8),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search by customer, receipt or wallet...",
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _clearSearch,
                        padding: EdgeInsets.zero,
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    onChanged: _searchReceipts,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Summary Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total: ${displayedReceipts.length} of $totalReceipts",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Customers: ${Set.from(displayedReceipts.map((r) => r["customerName"])).length}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹${_calculateTotalAmount()}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      const Text(
                        "Total Received",
                        style: TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Compact List of All Receipts with Pagination
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: displayedReceipts.length + (hasMorePages ? 1 : 0),
            itemBuilder: (context, index) {
              // Check if this is the load more button item
              if (index == displayedReceipts.length) {
                return _buildLoadMoreButton();
              }

              final receipt = displayedReceipts[index];
              return _receiptCard(receipt);
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
              SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 16),
              Text('Loading more receipts...'),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ElevatedButton(
          onPressed: _loadMoreReceipts,
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
              Text('Load More (Page $currentPage of $totalPages)'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptCard(Map<String, dynamic> receipt) {
    // Get the proper wallet display name
    String walletDisplayName = receipt["wallet"]?.toString() ?? "Cash";
    if (walletDisplayName == "1") {
      walletDisplayName = "Cash";
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Customer, Receipt, Date and Three-dot Menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Name
                      Text(
                        receipt["customerName"]?.toString() ?? "Unknown",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Receipt Number with "Receipt" text
                      Row(
                        children: [
                          Text(
                            "Receipt: ",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              "#${receipt["receiptNo"]}",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Date and Three-dot Menu
                Row(
                  children: [
                    // Date
                    Text(
                      receipt["date"]?.toString() ?? "",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    // Three-dot Menu
                    _actionMenu(receipt),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Middle Row: Wallet and Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Wallet Type
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: walletDisplayName.toLowerCase() == "cash"
                        ? Colors.green.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: walletDisplayName.toLowerCase() == "cash"
                          ? Colors.green.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        walletDisplayName.toLowerCase() == "cash"
                            ? Icons.attach_money
                            : Icons.account_balance_wallet,
                        size: 12,
                        color: walletDisplayName.toLowerCase() == "cash"
                            ? Colors.green.shade800
                            : Colors.blue.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        walletDisplayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: walletDisplayName.toLowerCase() == "cash"
                              ? Colors.green.shade800
                              : Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${receipt["receivedAmount"]}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    const Text(
                      "Received",
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionMenu(Map<String, dynamic> receipt) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20, color: Colors.black),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text('View'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16, color: Colors.orange),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 16, color: Colors.green),
              SizedBox(width: 8),
              Text('Share'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        print("🎯 Action menu selected: $value");

        switch (value) {
          case 'view':
            print("   ➡️ Navigating to SingleReceiptViewPage");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SingleReceiptViewPage(receipt: receipt),
              ),
            );
            break;
          case 'edit':
            print("✏️ Edit receipt");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReceiptUpdatePage(receiptData: receipt),
              ),
            ).then((updatedReceipt) {
              if (updatedReceipt != null) {
                print("✅ Receipt updated, refreshing list...");
                _fetchReceipts(resetPagination: true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Receipt updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            });
            break;
          case 'share':
            print("   📤 Share receipt");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Share functionality will be added later'),
                backgroundColor: Colors.green,
              ),
            );
            break;
          case 'delete':
            print("   🗑️ Delete receipt");
            _showDeleteDialog(
              receipt["rcpid"] ?? receipt["slNo"],
              receipt["customerName"] ?? "Unknown",
            );
            break;
        }
      },
    );
  }

  void _showDeleteDialog(String rcpid, String customerName) {
    print("🗑️ Showing delete dialog for receipt ID: $rcpid");

    String reason = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Delete Receipt"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Are you sure you want to delete receipt for $customerName?",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Reason for deletion (optional):",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: "Enter reason...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      reason = value;
                    },
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () {
                    print("   ❌ Delete cancelled");
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isDeleting ? null : () async {
                    print("   ✅ Delete confirmed");
                    setState(() {
                      isDeleting = true;
                    });
                    setDialogState(() {
                      isDeleting = true;
                    });

                    await _deleteReceipt(rcpid, reason, setDialogState);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: isDeleting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "Delete",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteReceipt(
      String rcpid,
      String reason,
      StateSetter setDialogState,
      ) async {
    print("🗑️ Starting API delete request for receipt ID: $rcpid");

    try {
      final Map<String, dynamic> requestData = {
        "unid": unid,
        "veh": veh,
        "action": "delete",
        "rcpid": rcpid,
        "reason": reason,
      };

      print("📤 Sending delete request to API:");
      print("📤 API URL: $receiptActionApiUrl");
      print("📤 Request body: ${json.encode(requestData)}");

      final response = await http.post(
        Uri.parse(receiptActionApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      print("📥 API response status: ${response.statusCode}");

      setState(() {
        isDeleting = false;
      });

      Navigator.pop(context);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['result'] == "1") {
          // Success - remove from local list
          setState(() {
            allReceipts.removeWhere((receipt) => receipt["rcpid"] == rcpid);
            displayedReceipts = List.from(allReceipts);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Receipt deleted successfully"),
              backgroundColor: Colors.green,
            ),
          );

          print("✅ Receipt deleted successfully from server");
        } else {
          String errorMessage = responseData['message']?.toString() ?? 'Failed to delete receipt';
          errorMessage = errorMessage.replaceAll(RegExp(r'<[^>]*>'), '');
          errorMessage = errorMessage
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&amp;', '&')
              .replaceAll('&quot;', '"')
              .replaceAll('&#39;', "'");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Delete failed: $errorMessage"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );

          print("❌ Failed to delete receipt: $errorMessage");
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("HTTP Error: ${response.statusCode}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );

        print("❌ HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print('❌ Exception in _deleteReceipt: $e');
      setState(() {
        isDeleting = false;
      });

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Network Error: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}