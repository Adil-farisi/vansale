import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  List<Map<String, dynamic>> receipts = [];
  Map<String, String> walletMap = {}; // Map wallet IDs to names
  bool isLoading = true;
  bool isLoadingWallets = false;
  bool hasError = false;
  bool isDeleting = false; // Fixed: Added at class level
  String errorMessage = '';
  final TextEditingController searchController = TextEditingController();

  // API URLs
  final String receiptsApiUrl =
      "http://192.168.20.103/gst-3-3-production/mobile-service/vansales/receipts.php";
  final String walletsApiUrl =
      "http://192.168.20.103/gst-3-3-production/mobile-service/vansales/get_wallets.php";
  final String receiptActionApiUrl =
      "http://192.168.20.103/gst-3-3-production/mobile-service/vansales/action/receipt.php";

  // Session variables
  String unid = '';
  String veh = '';

  @override
  void initState() {
    super.initState();
    print("🚀 ReceiptsMainPage initialized");
    _loadSessionData();
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

    // Start loading
    setState(() {
      isLoadingWallets = true;
    });

    // Fetch wallets first
    await _fetchWallets();

    // Then fetch receipts
    await _fetchReceipts();
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
          // Don't set error - continue with receipts even if wallets fail
        }
      } else {
        print('❌ Wallet API HTTP error: ${response.statusCode}');
        // Don't set error - continue with receipts
      }
    } catch (e) {
      print('❌ Exception in _fetchWallets: $e');
      // Don't set error - continue with receipts
    } finally {
      setState(() {
        isLoadingWallets = false;
      });
    }
  }

  Future<void> _fetchReceipts() async {
    print("🔄 Starting API call to: $receiptsApiUrl");

    // Request body with session data
    final Map<String, dynamic> requestBody = {
      "unid": unid,
      "veh": veh,
      "srch": "",
      "page": "",
    };

    print("📦 Request body: $requestBody");

    setState(() {
      isLoading = true;
      hasError = false;
    });

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
        print("✅ HTTP 200 OK");
        final responseData = json.decode(response.body);
        print("📋 Parsed Response Data: ${responseData['result']}");
        print("📋 Total Receipts from API: ${responseData['ttlreceipts']}");

        if (responseData['result'] == "1") {
          // Transform API data to match our existing structure
          final List<dynamic> receiptList = responseData['receiptdet'];
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
              print(
                "💳 Using wallet name from map: $walletName (ID: $walletId)",
              );
            }

            // FIX: If walletName is "1", convert it to "Cash"
            if (walletName == "1") {
              walletName = "Cash";
              print(
                "🔄 Converted wallet '1' to 'Cash' for receipt ${receipt['rcp_no']}",
              );
            }

            transformedReceipts.add({
              "slNo": i + 1,
              "date": receipt['rcp_date']?.toString() ?? '',
              "receiptNo": receipt['rcp_no']?.toString() ?? '',
              "customerName": receipt['custname']?.toString() ?? '',
              "wallet": walletName,
              "wltid": walletId, // Store wallet ID for reference
              "notes": receipt['notes']?.toString() ?? "",
              "receivedAmount": receipt['rcp_amt']?.toString() ?? '0',
              "rcpid": receipt['rcpid']?.toString() ?? '',
              "whatsappNo": receipt['whatsapp_no']?.toString() ?? '',
              "confirm": receipt['confirm']?.toString() ?? '',
            });

            // Print first few receipts for debugging
            if (i < 3) {
              print(
                "📝 Receipt ${i + 1}: ${receipt['custname']} - ${receipt['rcp_amt']} - $walletName",
              );
            }
          }

          setState(() {
            receipts = transformedReceipts;
            isLoading = false;
          });

          print("✅ Successfully loaded ${receipts.length} receipts");
          print("✅ Total amount: ₹${_calculateTotalAmount()}");
        } else {
          print("❌ API returned result: ${responseData['result']}");
          print("❌ Error message: ${responseData['message']}");
          setState(() {
            hasError = true;
            errorMessage =
                responseData['message']?.toString() ??
                    'Failed to load receipts';
            isLoading = false;
          });
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        setState(() {
          hasError = true;
          errorMessage = 'HTTP Error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌❌❌ EXCEPTION CAUGHT!");
      print("❌ Error type: ${e.runtimeType}");
      print("❌ Error message: $e");
      setState(() {
        hasError = true;
        errorMessage = 'Network Error: $e';
        isLoading = false;
      });
    }

    print(
      "🏁 _fetchReceipts() completed. Loading: $isLoading, Error: $hasError",
    );
  }

  // Calculate overall total amount
  String _calculateTotalAmount() {
    double total = 0;
    for (var receipt in receipts) {
      final amountStr = receipt["receivedAmount"].toString().replaceAll(
        ",",
        "",
      );
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
        // Refresh receipts after saving
        _fetchReceipts();
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
    await _fetchWalletsAndReceipts();
  }

  @override
  Widget build(BuildContext context) {
    print("🎨 Building ReceiptsMainPage UI...");
    print("   isLoading: $isLoading");
    print("   isLoadingWallets: $isLoadingWallets");
    print("   hasError: $hasError");
    print("   receipts count: ${receipts.length}");
    print("   wallets count: ${walletMap.length}");

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

    if (receipts.isEmpty) {
      print("📭 Showing empty state");
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No Receipts Found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add your first receipt',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    print("✅ Showing receipts list with ${receipts.length} items");
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      print("🔍 Search text changed: $value");
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    print("🗑️ Clear search button pressed");
                    searchController.clear();
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: const Text("Clear"),
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
                        "Total: ${receipts.length}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Customers: ${Set.from(receipts.map((r) => r["customerName"])).length}",
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

        // Compact List of All Receipts
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: receipts.length,
            itemBuilder: (context, index) {
              final receipt = receipts[index];

              // Apply search filter
              if (searchController.text.isNotEmpty) {
                final search = searchController.text.toLowerCase();
                final customerName =
                    receipt["customerName"]?.toString().toLowerCase() ?? "";
                final receiptNo =
                    receipt["receiptNo"]?.toString().toLowerCase() ?? "";
                final wallet =
                    receipt["wallet"]?.toString().toLowerCase() ?? "";
                final notes = receipt["notes"]?.toString().toLowerCase() ?? "";

                if (!customerName.contains(search) &&
                    !receiptNo.contains(search) &&
                    !wallet.contains(search) &&
                    !notes.contains(search)) {
                  return const SizedBox();
                }
              }

              return _receiptCard(receipt);
            },
          ),
        ),
      ],
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
                    color:
                    walletDisplayName.toLowerCase() == "cash"
                        ? Colors.green.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color:
                      walletDisplayName.toLowerCase() == "cash"
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
                        color:
                        walletDisplayName.toLowerCase() == "cash"
                            ? Colors.green.shade800
                            : Colors.blue.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        walletDisplayName,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                          walletDisplayName.toLowerCase() == "cash"
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
      itemBuilder:
          (context) => [
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
                // Update the receipt in your list
                final index = receipts.indexWhere(
                      (r) =>
                  r["rcpid"] == receipt["rcpid"] ||
                      r["slNo"] == receipt["slNo"],
                );
                if (index != -1) {
                  setState(() {
                    receipts[index] = updatedReceipt;
                  });
                }

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
                  onPressed:
                  isDeleting
                      ? null
                      : () {
                    print("   ❌ Delete cancelled");
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed:
                  isDeleting
                      ? null
                      : () async {
                    print("   ✅ Delete confirmed");
                    // Update both class state and dialog state
                    setState(() {
                      isDeleting = true;
                    });
                    setDialogState(() {
                      isDeleting = true;
                    });

                    await _deleteReceipt(rcpid, reason, setDialogState);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child:
                  isDeleting
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
      // Prepare API request data
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

      // Make API call
      final response = await http.post(
        Uri.parse(receiptActionApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      print("📥 API response status: ${response.statusCode}");
      print("📥 API raw response: ${response.body}");

      // Reset loading state and close dialog
      setState(() {
        isDeleting = false;
      });

      // Always close the dialog
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print("📥 API parsed response: $responseData");

        if (responseData['result'] == "1") {
          // Success - remove from local list
          setState(() {
            receipts.removeWhere((receipt) => receipt["rcpid"] == rcpid);
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Receipt deleted successfully"),
              backgroundColor: Colors.green,
            ),
          );

          print("✅ Receipt deleted successfully from server");
        } else {
          // API returned error
          String errorMessage =
              responseData['message']?.toString() ?? 'Failed to delete receipt';
          // Extract plain text from HTML message
          errorMessage = errorMessage.replaceAll(RegExp(r'<[^>]*>'), '');
          errorMessage = errorMessage
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&amp;', '&')
              .replaceAll('&quot;', '"')
              .replaceAll('&#39;', "'");

          // Show error message
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
        // HTTP error
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

      // Close dialog on error
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