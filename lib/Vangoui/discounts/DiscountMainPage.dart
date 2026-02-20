import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> discounts = [];
  List<Map<String, dynamic>> allDiscounts =
      []; // Store all discounts for local filtering
  bool isLoading = false;
  bool isDeleting = false; // Add delete loading state
  String totalDiscounts = "0";
  final TextEditingController searchController = TextEditingController();

  // Add a flag to track if we're using local filtering
  bool isSearching = false;

  // API endpoints
  final String apiUrl =
      "http://192.168.1.108:80/gst-3-3-production/mobile-service/vansales/discounts.php";
  final String deleteApiUrl =
      "http://192.168.1.108:80/gst-3-3-production/mobile-service/vansales/action/discounts.php";

  @override
  void initState() {
    super.initState();
    print("🚀 DiscountMainPage initialized");

    // Add listener to search controller for real-time filtering
    searchController.addListener(_onSearchChanged);

    _fetchDiscountsFromApi();
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  // Listen to search text changes
  void _onSearchChanged() {
    // If search text is empty, show all discounts
    if (searchController.text.isEmpty) {
      setState(() {
        discounts = List.from(allDiscounts);
        isSearching = false;
      });
    } else {
      // If search text is not empty, filter locally
      _filterDiscountsLocally();
    }
  }

  // Filter discounts locally based on search text
  void _filterDiscountsLocally() {
    final query = searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        discounts = List.from(allDiscounts);
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
      discounts =
          allDiscounts.where((discount) {
            final customerName = (discount['customerName'] ?? '').toLowerCase();
            final notes = (discount['notes'] ?? '').toLowerCase();

            return customerName.contains(query) || notes.contains(query);
          }).toList();
    });

    print("🔍 Local search: '$query' found ${discounts.length} results");
  }

  // Fetch discounts from API
  Future<void> _fetchDiscountsFromApi() async {
    print("📋 Fetching discounts from API...");
    setState(() {
      isLoading = true;
    });

    try {
      // Prepare request body as per API specification
      Map<String, dynamic> requestBody = {
        "unid": "20260117130317",
        "veh": "MQ--",
        "srch": "", // Always send empty search to API to get all discounts
        "page": "1",
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
          setState(() {
            totalDiscounts = responseData['ttldiscounts'] ?? "0";

            // Parse discountdet array with correct field names from API
            if (responseData['discountdet'] != null &&
                responseData['discountdet'] is List) {
              allDiscounts = List<Map<String, dynamic>>.from(
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

              // If there's existing search text, apply local filter
              if (searchController.text.isNotEmpty) {
                _filterDiscountsLocally();
              } else {
                discounts = List.from(allDiscounts);
              }
            } else {
              allDiscounts = [];
              discounts = [];
            }

            isLoading = false;
          });

          print("✅ Loaded ${allDiscounts.length} discounts from API");
          print("📊 Total discounts from API: $totalDiscounts");
          print("📊 Displaying ${discounts.length} discounts (filtered)");
        } else {
          // API returned error
          setState(() {
            allDiscounts = [];
            discounts = [];
            totalDiscounts = "0";
            isLoading = false;
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
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to server: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Filter discounts based on search - This getter is no longer needed but kept for compatibility
  List<Map<String, dynamic>> get filteredDiscounts {
    return discounts; // Return the already filtered list
  }

  // Calculate total discount amount
  String _calculateTotalDiscount() {
    double total = 0;
    for (var discount in discounts) {
      // Use originalAmount for calculation (without ₹ symbol)
      String amountStr = discount['originalAmount']?.toString() ?? '0';

      // Handle if it's already with ₹ symbol
      if (amountStr.contains('₹')) {
        amountStr = amountStr.replaceAll('₹', '');
      }
      amountStr = amountStr.replaceAll(',', '');

      final amount = double.tryParse(amountStr) ?? 0;
      total += amount;
    }
    return '₹ ${total.toStringAsFixed(2)}';
  }

  // Search with API - Modified to use local filtering
  void _performSearch() {
    // Instead of calling API again, just filter locally
    _filterDiscountsLocally();
  }

  // Edit discount - Navigate to EditDiscountPage
  void _editDiscount(Map<String, dynamic> discount) {
    print("✏️ Editing discount for: ${discount['customerName']}");

    // DEBUG: Print all fields in the discount object
    print("📦 Full discount data being passed to EditDiscountPage:");
    discount.forEach((key, value) {
      print("   - $key: $value (${value.runtimeType})");
    });

    // Specifically check if custid exists
    if (discount.containsKey('custid')) {
      print("✅ custid found: ${discount['custid']}");
    } else {
      print("❌ custid NOT found in discount object!");
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDiscountPage(discount: discount),
      ),
    ).then((updatedDiscount) {
      // Handle the updated discount data returned from EditDiscountPage
      if (updatedDiscount != null && updatedDiscount is Map<String, dynamic>) {
        // Update in allDiscounts as well
        final indexInAll = allDiscounts.indexWhere(
          (c) => c['id'] == discount['id'],
        );
        if (indexInAll != -1) {
          allDiscounts[indexInAll] = updatedDiscount;
        }

        // Refresh the displayed list based on current search
        if (searchController.text.isNotEmpty) {
          _filterDiscountsLocally();
        } else {
          setState(() {
            discounts = List.from(allDiscounts);
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discount updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh data from API after update
        _fetchDiscountsFromApi();
      }
    });
  }

  // Delete discount - Updated with API integration
  Future<void> _deleteDiscount(String discountId, String customerName) async {
    print("🗑️ Deleting discount: $discountId for customer: $customerName");

    final TextEditingController reasonController = TextEditingController();

    // Show confirmation dialog with reason
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

    // If user confirmed deletion
    if (confirmDelete == true) {
      final deleteReason = reasonController.text.trim();

      setState(() {
        isDeleting = true;
      });

      try {
        // Prepare delete request body
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

            // Remove from local lists
            setState(() {
              allDiscounts.removeWhere((c) => c['id'] == discountId);
              discounts.removeWhere((c) => c['id'] == discountId);
              isDeleting = false;
            });

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Discount for '$customerName' deleted successfully",
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );

            // Refresh data from API to ensure sync
            _fetchDiscountsFromApi();
          } else {
            // API returned error
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
        // Refresh data from API after adding
        _fetchDiscountsFromApi();

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
    // Clear search when refreshing
    searchController.clear();
    await _fetchDiscountsFromApi();
  }

  // Clear search
  void _clearSearch() {
    searchController.clear();
    // The listener will handle resetting the list
  }

  @override
  Widget build(BuildContext context) {
    print("🎨 Building DiscountMainPage UI...");
    print("   All discounts count: ${allDiscounts.length}");
    print("   Displayed discounts: ${discounts.length}");
    print("   Search text: '${searchController.text}'");
    print("   Is searching: $isSearching");

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

          // Global loading overlay for delete operation
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
    if (isLoading) {
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

    if (allDiscounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.discount, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No Discounts Found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add your first discount',
              style: TextStyle(fontSize: 14, color: Colors.grey),
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
                    onChanged: (value) {
                      // The listener will handle filtering
                    },
                    onSubmitted: (value) {
                      _performSearch();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Clear"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Search result info
        if (isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  'Found ${discounts.length} result${discounts.length != 1 ? 's' : ''}',
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
                          allDiscounts.length.toString(),
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

        // Discounts List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: discounts.length,
            itemBuilder: (context, index) {
              final discount = discounts[index];
              return _discountCard(discount);
            },
          ),
        ),
      ],
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
