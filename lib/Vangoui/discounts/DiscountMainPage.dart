import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'EditDiscountPage.dart';
import 'NewDiscountPage.dart';

class DiscountMainPage extends StatefulWidget {
  const DiscountMainPage({super.key});

  @override
  State<DiscountMainPage> createState() => _DiscountMainPageState();
}

class _DiscountMainPageState extends State<DiscountMainPage> {
  List<Map<String, dynamic>> allDiscounts = [];
  List<Map<String, dynamic>> displayedDiscounts = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isDeleting = false;
  String totalDiscounts = "0";
  final TextEditingController searchController = TextEditingController();

  // Pagination variables
  int currentPage = 1;
  int totalPages = 1;
  int totalDiscountsCount = 0;
  bool hasMorePages = false;
  String searchQuery = '';

  // Debounce timer for search
  Timer? _debounceTimer;

  // Scroll controller for pagination
  final ScrollController _scrollController = ScrollController();

  // API endpoints
  final String apiUrl =
      "http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/discounts.php";
  final String deleteApiUrl =
      "http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/action/discounts.php";

  @override
  void initState() {
    super.initState();
    print("🚀 DiscountMainPage initialized");

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);

    _fetchDiscountsFromApi(resetPagination: true);
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
          _loadMoreDiscounts();
        }
      }
    });
  }

  // =================== FETCH DISCOUNTS WITH SEARCH AND PAGINATION ===================
  Future<void> _fetchDiscountsFromApi({bool resetPagination = true}) async {
    print("📋 Fetching discounts from API...");
    print("📝 Search query: '$searchQuery'");
    print("📄 Page: $currentPage");
    print("🔄 Reset pagination: $resetPagination");

    if (resetPagination) {
      setState(() {
        isLoading = true;
        currentPage = 1;
        allDiscounts = [];
      });
    }

    try {
      // Prepare request body with search and page
      Map<String, dynamic> requestBody = {
        "unid": "20260117130317",
        "veh": "MQ--",
        "srch": searchQuery,
        "page": currentPage.toString(),
      };

      print("📤 Request body: $requestBody");

      // Make API call
      final response = await http
          .post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      )
          .timeout(const Duration(seconds: 10));

      print("📥 Response status: ${response.statusCode}");
      print("📥 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['result'] == "1") {
          // Parse discountdet array
          List<Map<String, dynamic>> newDiscounts = [];
          if (responseData['discountdet'] != null &&
              responseData['discountdet'] is List) {
            newDiscounts = List<Map<String, dynamic>>.from(
              (responseData['discountdet'] as List).map((item) {
                return {
                  "id": item['dscid']?.toString() ?? '',
                  "dscid": item['dscid']?.toString() ?? '',
                  "custid": item['custid']?.toString() ?? '',
                  "customerName": item['custname'] ?? 'Unknown',
                  "date": item['dsc_date'] ?? '',
                  "notes": item['notes'] ?? '',
                  "discountAmount": "₹${item['dsc_amt'] ?? '0'}",
                  "originalAmount": item['dsc_amt'] ?? '0',
                };
              }).toList(),
            );
          }

          // Calculate pagination
          int totalDiscountsFromApi = int.tryParse(responseData['ttldiscounts']?.toString() ?? '0') ?? 0;
          int itemsPerPage = newDiscounts.length > 0 ? newDiscounts.length : 1;
          int totalPagesFromApi = itemsPerPage > 0 ? (totalDiscountsFromApi / itemsPerPage).ceil() : 1;
          bool hasMoreFromApi = currentPage < totalPagesFromApi;

          print("📊 Pagination calculated:");
          print("   - totalDiscounts: $totalDiscountsFromApi");
          print("   - itemsPerPage: $itemsPerPage");
          print("   - totalPages: $totalPagesFromApi");
          print("   - currentPage: $currentPage");
          print("   - hasMore: $hasMoreFromApi");

          setState(() {
            if (resetPagination) {
              allDiscounts = newDiscounts;
            } else {
              allDiscounts.addAll(newDiscounts);
            }

            displayedDiscounts = List.from(allDiscounts);

            totalDiscountsCount = totalDiscountsFromApi;
            totalDiscounts = totalDiscountsCount.toString();
            totalPages = totalPagesFromApi;
            hasMorePages = hasMoreFromApi;

            isLoading = false;
            isLoadingMore = false;
          });

          print("✅ Loaded ${allDiscounts.length} discounts from API");
          print("📊 Total discounts from API: $totalDiscountsCount");
          print("📊 Displaying ${displayedDiscounts.length} discounts");
        } else {
          // API returned error
          setState(() {
            allDiscounts = [];
            displayedDiscounts = [];
            totalDiscounts = "0";
            isLoading = false;
            isLoadingMore = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData['message'] ?? 'Failed to load discounts',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error fetching discounts: $e");

      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to server: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Load more discounts for pagination
  Future<void> _loadMoreDiscounts() async {
    if (isLoadingMore || !hasMorePages) {
      print('📄 Cannot load more - isLoadingMore: $isLoadingMore, hasMorePages: $hasMorePages');
      return;
    }

    print('📄 Loading more discounts - Page ${currentPage + 1} of $totalPages');

    setState(() {
      isLoadingMore = true;
    });

    currentPage++;
    await _fetchDiscountsFromApi(resetPagination: false);
  }

  // =================== SEARCH FUNCTIONALITY ===================
  void _searchDiscounts(String query) {
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
      _fetchDiscountsFromApi(resetPagination: true);
    });
  }

  void _clearSearch() {
    print("🧹 Clearing search");
    _debounceTimer?.cancel();

    setState(() {
      searchQuery = '';
      searchController.clear();
    });

    _fetchDiscountsFromApi(resetPagination: true);
    FocusScope.of(context).unfocus();
  }

  // Calculate total discount amount
  String _calculateTotalDiscount() {
    double total = 0;
    for (var discount in displayedDiscounts) {
      String amountStr = discount['originalAmount']?.toString() ?? '0';

      if (amountStr.contains('₹')) {
        amountStr = amountStr.replaceAll('₹', '');
      }
      amountStr = amountStr.replaceAll(',', '');

      final amount = double.tryParse(amountStr) ?? 0;
      total += amount;
    }
    return '₹ ${total.toStringAsFixed(2)}';
  }

  // Edit discount - Navigate to EditDiscountPage
  void _editDiscount(Map<String, dynamic> discount) {
    print("✏️ Editing discount for: ${discount['customerName']}");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDiscountPage(discount: discount),
      ),
    ).then((updatedDiscount) {
      if (updatedDiscount != null && updatedDiscount is Map<String, dynamic>) {
        final indexInAll = allDiscounts.indexWhere(
              (c) => c['id'] == discount['id'],
        );
        if (indexInAll != -1) {
          allDiscounts[indexInAll] = updatedDiscount;
        }

        setState(() {
          displayedDiscounts = List.from(allDiscounts);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discount updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _fetchDiscountsFromApi(resetPagination: true);
      }
    });
  }

  // Delete discount - Updated with API integration
  Future<void> _deleteDiscount(String discountId, String customerName) async {
    print("🗑️ Deleting discount: $discountId for customer: $customerName");

    final TextEditingController reasonController = TextEditingController();

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
        title: const Text("Delete Discount"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to delete discount for '$customerName'?",
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for deletion *',
                hintText: 'Enter reason for deleting this discount...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please enter a reason for deletion"),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      final deleteReason = reasonController.text.trim();

      setState(() {
        isDeleting = true;
      });

      try {
        Map<String, dynamic> deleteRequestBody = {
          "unid": "20260117130317",
          "veh": "MQ--",
          "action": "delete",
          "dscid": discountId,
          "reason": deleteReason,
        };

        print("📤 Sending delete request to API: $deleteApiUrl");
        print("📤 Delete request body: $deleteRequestBody");

        final response = await http
            .post(
          Uri.parse(deleteApiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(deleteRequestBody),
        )
            .timeout(const Duration(seconds: 10));

        print("📥 Delete response status: ${response.statusCode}");
        print("📥 Delete response body: ${response.body}");

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData['result'] == "1") {
            print("✅ Discount deleted successfully from API");

            setState(() {
              allDiscounts.removeWhere((c) => c['id'] == discountId);
              displayedDiscounts.removeWhere((c) => c['id'] == discountId);
              isDeleting = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Discount for '$customerName' deleted successfully",
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );

            _fetchDiscountsFromApi(resetPagination: true);
          } else {
            setState(() {
              isDeleting = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  responseData['message'] ?? 'Failed to delete discount',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          setState(() {
            isDeleting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server error: ${response.statusCode}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print("❌ Error deleting discount: $e");

        setState(() {
          isDeleting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting to server: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Navigate to NewDiscountPage
  void _addNewDiscount() {
    print("➕ Navigating to NewDiscountPage");

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewDiscountPage()),
    ).then((newDiscount) {
      if (newDiscount != null && newDiscount is Map<String, dynamic>) {
        _fetchDiscountsFromApi(resetPagination: true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discount added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  // Refresh data
  Future<void> _refreshData() async {
    print("🔄 Refreshing discounts data from API");
    setState(() {
      currentPage = 1;
      searchQuery = '';
      searchController.clear();
    });
    await _fetchDiscountsFromApi(resetPagination: true);
  }

  @override
  Widget build(BuildContext context) {
    print("🎨 Building DiscountMainPage UI...");
    print("   All discounts count: ${allDiscounts.length}");
    print("   Displayed discounts: ${displayedDiscounts.length}");
    print("   Search query: '$searchQuery'");
    print("   Current page: $currentPage, Total pages: $totalPages, Has more: $hasMorePages");

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Discounts",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 3,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _addNewDiscount,
            tooltip: 'Add New Discount',
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),

          if (isDeleting)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Deleting discount...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && allDiscounts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading discounts...'),
          ],
        ),
      );
    }

    if (allDiscounts.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.discount, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty
                  ? 'No discounts found for "$searchQuery"'
                  : 'No Discounts Found',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty
                  ? 'Try a different search term or clear search'
                  : 'Tap the + button to add your first discount',
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

    return Column(
      children: [
        // Search Section
        Card(
          margin: const EdgeInsets.all(12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search by customer or notes...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                      searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                    onChanged: _searchDiscounts,
                    onSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Search result info
        if (searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  'Found ${displayedDiscounts.length} result${displayedDiscounts.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

        // Summary Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // Total Discounts
              Expanded(
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Discounts",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalDiscounts,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Total Discount Amount
              Expanded(
                child: Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Discount Amount",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _calculateTotalDiscount(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Discounts List with Pagination
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: displayedDiscounts.length + (hasMorePages ? 1 : 0),
            itemBuilder: (context, index) {
              // Check if this is the load more button item
              if (index == displayedDiscounts.length) {
                return _buildLoadMoreButton();
              }

              final discount = displayedDiscounts[index];
              return _discountCard(discount);
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
              Text('Loading more discounts...'),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ElevatedButton(
          onPressed: _loadMoreDiscounts,
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

  Widget _discountCard(Map<String, dynamic> discount) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Customer Name and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    discount['customerName'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        discount['date'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 2: Notes and Discount Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Notes",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        discount['notes']?.isNotEmpty == true
                            ? discount['notes']
                            : 'No notes',
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Discount Amount",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        discount['discountAmount'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Row 3: Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: isDeleting ? null : () => _editDiscount(discount),
                  icon: const Icon(Icons.edit, size: 18),
                  color: Colors.blue,
                  tooltip: 'Edit',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed:
                  isDeleting
                      ? null
                      : () => _deleteDiscount(
                    discount['id'],
                    discount['customerName'],
                  ),
                  icon: const Icon(Icons.delete, size: 18),
                  color: Colors.red,
                  tooltip: 'Delete',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}