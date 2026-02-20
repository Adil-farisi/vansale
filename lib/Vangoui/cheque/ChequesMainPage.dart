import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Add this import for navigation
import 'ChequeEditPage.dart';
import 'NewChequePage.dart';

class ChequesMainPage extends StatefulWidget {
  const ChequesMainPage({super.key});

  @override
  State<ChequesMainPage> createState() => _ChequesMainPageState();
}

class _ChequesMainPageState extends State<ChequesMainPage> {
  List<Map<String, dynamic>> cheques = [];
  List<Map<String, dynamic>> filteredCheques = [];
  bool isLoading = false;
  String? errorMessage;
  final TextEditingController searchController = TextEditingController();

  // Filter state
  String? selectedFilter; // Can be 'pending', 'cleared', 'bounced', or null for all

  // API Configuration
  final String apiUrl = "http://192.168.1.108:80/gst-3-3-production/mobile-service/vansales/cheques.php";
  final String deleteApiUrl = "http://192.168.1.108:80/gst-3-3-production/mobile-service/vansales/action/cheques.php";
  final String bounceApiUrl = "http://192.168.1.108:80/gst-3-3-production/mobile-service/vansales/action/cheques.php";
  final String walletApiUrl = "http://192.168.1.108:80/gst-3-3-production/mobile-service/vansales/get_wallets.php";
  final String unid = "20260117130317"; // You can modify this as needed
  final String veh = "MQ--"; // You can modify this as needed

  @override
  void initState() {
    super.initState();
    print("🚀 ChequesMainPage initialized");
    print("📡 API URL: $apiUrl");
    print("📡 Delete API URL: $deleteApiUrl");
    print("📡 Bounce API URL: $bounceApiUrl");
    print("📡 Wallet API URL: $walletApiUrl");
    print("📡 UNID: $unid");
    print("📡 VEH: $veh");
    _fetchChequesFromApi();
  }

  Future<void> _fetchChequesFromApi() async {
    print("📋 Fetching cheques from API...");
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Prepare request body
      Map<String, dynamic> requestBody = {
        "unid": unid,
        "veh": veh,
        "srch": searchController.text.isEmpty ? "" : searchController.text,
        "page": "" // You can add pagination if needed
      };

      print("📤 Request Body: ${json.encode(requestBody)}");

      // Make API call
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print("📥 Response Status Code: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        print("📊 API Response Parsed:");
        print("   Result: ${responseData['result']}");
        print("   Message: ${responseData['message']}");
        print("   Total Cheques: ${responseData['ttlcheques']}");

        if (responseData['result'] == "1") {
          // Parse cheques data
          List<dynamic> chequeList = responseData['chequedet'] ?? [];
          print("   Cheques Count from API: ${chequeList.length}");

          setState(() {
            cheques = chequeList.map((item) {
              print("📝 Processing cheque: ${item['chq_no']}");
              return {
                "id": item['chqid'] ?? '',
                "customerName": item['custname'] ?? 'Unknown',
                "chequeNo": item['chq_no'] ?? '',
                "date": item['chq_date'] ?? '',
                "wallet": "Bank", // Default value since API doesn't provide this
                "walletId": "2", // Default wallet ID
                "bankName": item['bank'] ?? '',
                "amount": _formatAmount(item['chq_amt']),
                "status": item['chq_status']?.toLowerCase() ?? 'pending',
              };
            }).toList();

            // Apply current filter to the new data
            _applyFilter();

            errorMessage = null;
            print("✅ Successfully loaded ${cheques.length} cheques from API");
          });
        } else {
          // API returned error
          String message = responseData['message'] ?? 'Unknown error';
          print("❌ API Error: $message");
          setState(() {
            cheques = [];
            filteredCheques = [];
            errorMessage = message;
          });
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        setState(() {
          cheques = [];
          filteredCheques = [];
          errorMessage = "Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      print("❌ Exception occurred: $e");
      setState(() {
        cheques = [];
        filteredCheques = [];
        errorMessage = "Network error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatAmount(String? amount) {
    if (amount == null || amount.isEmpty) return '₹0.00';
    try {
      double value = double.parse(amount);
      return '₹${value.toStringAsFixed(2)}';
    } catch (e) {
      return '₹$amount';
    }
  }

  // Apply both search and filter to the cheques list
  void _applyFilter() {
    print("🔍 Applying filter: ${selectedFilter ?? 'All'}");
    print("🔍 Search query: ${searchController.text}");

    // First filter by status if a filter is selected
    List<Map<String, dynamic>> statusFiltered = [];

    if (selectedFilter == null) {
      statusFiltered = List.from(cheques);
    } else {
      statusFiltered = cheques.where((cheque) {
        return cheque['status'] == selectedFilter;
      }).toList();
    }

    // Then apply search filter
    if (searchController.text.isEmpty) {
      filteredCheques = statusFiltered;
    } else {
      final query = searchController.text.toLowerCase();
      filteredCheques = statusFiltered.where((cheque) {
        return cheque['customerName'].toLowerCase().contains(query) ||
            cheque['chequeNo'].toLowerCase().contains(query) ||
            (cheque['bankName'] != null &&
                cheque['bankName'].toLowerCase().contains(query));
      }).toList();
    }

    print("🔍 Filtered cheques count: ${filteredCheques.length}");
    setState(() {});
  }

  // Clear search and filter
  void _clearSearch() {
    print("🧹 Clearing search and filter");
    searchController.clear();
    selectedFilter = null;
    _applyFilter();
    FocusScope.of(context).unfocus();
  }

  // Show filter options
  void _showFilterOptions() {
    print("📊 Showing filter options");

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
                'Filter Cheques',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 20),

              // All Cheques Option
              _buildFilterOption(
                title: 'All Cheques',
                icon: Icons.list,
                color: Colors.grey,
                filterValue: null,
                count: cheques.length,
              ),

              const Divider(),

              // Pending Cheques Option
              _buildFilterOption(
                title: 'Pending Cheques',
                icon: Icons.pending_actions,
                color: Colors.blue,
                filterValue: 'pending',
                count: cheques.where((c) => c['status'] == 'pending').length,
              ),

              // Cleared Cheques Option
              _buildFilterOption(
                title: 'Cleared Cheques',
                icon: Icons.check_circle,
                color: Colors.green,
                filterValue: 'cleared',
                count: cheques.where((c) => c['status'] == 'cleared').length,
              ),

              // Bounced Cheques Option
              _buildFilterOption(
                title: 'Bounced Cheques',
                icon: Icons.cancel,
                color: Colors.red,
                filterValue: 'bounced',
                count: cheques.where((c) => c['status'] == 'bounced').length,
              ),

              const SizedBox(height: 20),

              // Close button
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

  // Build filter option for bottom sheet
  Widget _buildFilterOption({
    required String title,
    required IconData icon,
    required Color color,
    required String? filterValue,
    required int count,
  }) {
    final isSelected = selectedFilter == filterValue;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Row(
        children: [
          Text(title),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Colors.green)
          : null,
      onTap: () {
        setState(() {
          selectedFilter = filterValue;
        });
        _applyFilter();
        Navigator.pop(context);
      },
    );
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'cleared':
        return Colors.green;
      case 'bounced':
        return Colors.red;
      case 'pending':
      default:
        return Colors.blue;
    }
  }

  // Get status text
  String _getStatusText(String status) {
    switch (status) {
      case 'cleared':
        return 'Cleared';
      case 'bounced':
        return 'Bounced';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  // Calculate total amount
  String _calculateTotalAmount() {
    double total = 0;
    for (var cheque in filteredCheques) {
      final amountStr = cheque['amount']
          .toString()
          .replaceAll('₹', '')
          .replaceAll(',', '');
      final amount = double.tryParse(amountStr) ?? 0;
      total += amount;
    }
    return '₹${total.toStringAsFixed(2)}';
  }

  // Calculate pending amount
  String _calculatePendingAmount() {
    double total = 0;
    for (var cheque in cheques) {
      if (cheque['status'] == 'pending') {
        final amountStr = cheque['amount']
            .toString()
            .replaceAll('₹', '')
            .replaceAll(',', '');
        final amount = double.tryParse(amountStr) ?? 0;
        total += amount;
      }
    }
    return '₹${total.toStringAsFixed(2)}';
  }

  // Mark cheque as cleared with popup dialog - UPDATED WITH WALLET API
// Mark cheque as cleared with popup dialog - UPDATED WITH WALLET API AND CLEAR API
// Mark cheque as cleared with popup dialog - UPDATED WITH WALLET API AND CLEAR API
// Mark cheque as cleared with popup dialog - FIXED VERSION
  Future<void> _markAsClearedWithPopup(Map<String, dynamic> cheque) async {
    print("📝 Opening clear popup for cheque: ${cheque['chequeNo']}");

    // Fetch wallets first
    List<Map<String, dynamic>> wallets = [];
    String? walletError;

    try {
      print("💰 Fetching wallets from API...");

      final response = await http.post(
        Uri.parse(walletApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "unid": unid,
          "veh": veh,
        }),
      );

      print("💰 Wallet API Response: ${response.statusCode}");
      print("💰 Wallet API Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['result'] == "1") {
          final List<dynamic> walletList = data['walletdet'] ?? [];
          wallets = walletList.map((wallet) {
            return {
              'id': wallet['wltid'].toString(),
              'name': wallet['wlt_name'].toString(),
            };
          }).toList();
          print("✅ Loaded ${wallets.length} wallets");
        } else {
          walletError = data['message'] ?? 'Failed to load wallets';
          print("❌ Wallet API Error: $walletError");
        }
      } else {
        walletError = 'Server error: ${response.statusCode}';
        print("❌ Wallet HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      walletError = 'Network error: $e';
      print("❌ Wallet Exception: $e");
    }

    // If no wallets, show fallback options
    if (wallets.isEmpty) {
      wallets = [
        {'id': '1', 'name': 'Cash'},
        {'id': '2', 'name': 'Bank'},
      ];
      print("⚠️ Using fallback wallet options");
    }

    // Controllers for the popup
    TextEditingController dateController = TextEditingController(
      text: cheque['date'],
    );
    TextEditingController receivedAmountController = TextEditingController(
      text: cheque['amount'].toString().replaceAll('₹', '').replaceAll(',', ''),
    );

    // Auto-generated notes text with cheque number
    final String autoNotesText = "Cleared cheque no ${cheque['chequeNo']}";
    TextEditingController notesController = TextEditingController(
      text: autoNotesText,
    );

    // Dropdown value for Amount to (Cash/Bank)
    String selectedWalletId = wallets.isNotEmpty ? wallets[0]['id'] as String : '1';
    String selectedWalletName = wallets.isNotEmpty ? wallets[0]['name'] as String : 'Cash';

    // Show the dialog
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Center(
                child: const Text(
                  "Clear Cheque",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cheque No (Non-editable)
                    _buildPopupField(
                      label: "Cheque No",
                      value: cheque['chequeNo'],
                      isEditable: false,
                    ),
                    const SizedBox(height: 12),

                    // Date with format hint
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Date",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "(DD-MM-YYYY)",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: dateController,
                          decoration: InputDecoration(
                            hintText: "DD-MM-YYYY",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Received Amount
                    _buildPopupEditableField(
                      label: "Received Amount",
                      controller: receivedAmountController,
                      hintText: "Enter amount",
                      isAmount: true,
                    ),
                    const SizedBox(height: 12),

                    // Wallet Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Amount to",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            if (walletError != null) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.warning, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  walletError!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedWalletId,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey,
                              ),
                              items: wallets.map<DropdownMenuItem<String>>((wallet) {
                                return DropdownMenuItem<String>(
                                  value: wallet['id'] as String,
                                  child: Row(
                                    children: [
                                      Icon(
                                        (wallet['name'] as String).toLowerCase() == 'cash'
                                            ? Icons.money
                                            : Icons.account_balance,
                                        size: 16,
                                        color: (wallet['name'] as String).toLowerCase() == 'cash'
                                            ? Colors.green
                                            : Colors.blue,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(wallet['name'] as String),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setDialogState(() {
                                    selectedWalletId = newValue;
                                    selectedWalletName = wallets.firstWhere(
                                          (w) => w['id'] == newValue,
                                      orElse: () => {'id': '1', 'name': 'Cash'},
                                    )['name'] as String;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Notes",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Enter any notes...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.refresh, size: 16),
                              onPressed: () {
                                notesController.text = autoNotesText;
                              },
                              tooltip: 'Reset to auto text',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate required fields
                    if (dateController.text.isEmpty ||
                        receivedAmountController.text.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Close the dialog
                    Navigator.of(dialogContext).pop();

                    // Format the date from DD/MM/YYYY to DD-MM-YYYY
                    String formattedDate = dateController.text.replaceAll('/', '-');

                    // Remove any commas from amount
                    String formattedAmount = receivedAmountController.text.replaceAll(',', '');

                    // Show loading indicator in main page
                    if (mounted) {
                      setState(() {
                        isLoading = true;
                      });
                    }

                    try {
                      // Prepare clear cheque API request
                      Map<String, dynamic> clearRequestBody = {
                        "unid": unid,
                        "veh": veh,
                        "action": "receivedchequecleared",
                        "chqid": cheque['id'],
                        "wallet": selectedWalletId,
                        "notes": notesController.text,
                        "pd_date": formattedDate,
                        "pd_amt": formattedAmount,
                      };

                      print("📤 Clear Cheque Request Body: ${json.encode(clearRequestBody)}");

                      // Make API call to clear cheque
                      final response = await http.post(
                        Uri.parse(deleteApiUrl),
                        headers: {
                          'Content-Type': 'application/json',
                          'Accept': 'application/json',
                        },
                        body: json.encode(clearRequestBody),
                      );

                      print("📥 Clear Cheque Response Status Code: ${response.statusCode}");
                      print("📥 Clear Cheque Response Body: ${response.body}");

                      // Check if widget is still mounted before updating state
                      if (!mounted) return;

                      if (response.statusCode == 200) {
                        final Map<String, dynamic> responseData = json.decode(response.body);

                        print("📊 Clear Cheque API Response Parsed:");
                        print("   Result: ${responseData['result']}");

                        // Clean HTML tags from message
                        String cleanMessage = '';
                        if (responseData['message'] != null) {
                          cleanMessage = responseData['message'].toString().replaceAll(RegExp(r'<[^>]*>'), '').trim();
                        }
                        print("   Message: $cleanMessage");

                        if (responseData['result'] == "1") {
                          // Successfully cleared from API
                          print("✅ Cheque cleared successfully via API");

                          // Update local list
                          setState(() {
                            final index = cheques.indexWhere(
                                  (c) => c['id'] == cheque['id'],
                            );
                            if (index != -1) {
                              cheques[index]['status'] = 'cleared';
                              cheques[index]['date'] = dateController.text;
                              cheques[index]['wallet'] = selectedWalletName;
                              cheques[index]['walletId'] = selectedWalletId;
                              cheques[index]['amount'] = '₹${receivedAmountController.text}';
                            }
                          });

                          // Re-apply filter
                          _applyFilter();

                          // Hide loading indicator
                          setState(() {
                            isLoading = false;
                          });

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cheque #${cheque['chequeNo']} cleared successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          print("✅ Cheque Cleared Details:");
                          print("   Cheque No: ${cheque['chequeNo']}");
                          print("   Date: ${dateController.text}");
                          print("   Formatted Date: $formattedDate");
                          print("   Amount: ₹${receivedAmountController.text}");
                          print("   Wallet: $selectedWalletName");
                          print("   Notes: ${notesController.text}");
                        } else {
                          // API returned error
                          print("❌ Clear Cheque API Error: $cleanMessage");

                          setState(() {
                            isLoading = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to clear cheque: $cleanMessage'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      } else {
                        print("❌ Clear Cheque HTTP Error: ${response.statusCode}");

                        setState(() {
                          isLoading = false;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Server error: ${response.statusCode}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      print("❌ Clear Cheque Exception occurred: $e");

                      if (mounted) {
                        setState(() {
                          isLoading = false;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Network error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Confirm Clear"),
                ),
              ],
            );
          },
        );
      },
    );
  }  void _markAsBouncedWithPopup(Map<String, dynamic> cheque) {
    print("📝 Opening bounce popup for cheque: ${cheque['chequeNo']}");

    // Auto-generated reason text with cheque number
    final String autoReasonText = "Bounced cheque no ${cheque['chequeNo']}";
    TextEditingController reasonController = TextEditingController(
      text: autoReasonText,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: const Text(
              "Bounce Cheque",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cheque No (Non-editable)
                _buildPopupField(
                  label: "Cheque No",
                  value: cheque['chequeNo'],
                  isEditable: false,
                ),
                const SizedBox(height: 12),

                // Reason (Editable with auto-generated text)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Reason",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Enter reason for bounce...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh, size: 16),
                          onPressed: () {
                            // Reset to auto-generated text
                            reasonController.text = autoReasonText;
                          },
                          tooltip: 'Reset to auto text',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate required field
                if (reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a reason'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Close the dialog
                Navigator.pop(context);

                // Call API to mark as bounced
                await _markAsBouncedViaApi(cheque['id'], reasonController.text, cheque['chequeNo']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Confirm Bounce"),
            ),
          ],
        );
      },
    );
  }

  // Mark cheque as bounced via API
  Future<void> _markAsBouncedViaApi(String chequeId, String reason, String chequeNo) async {
    print("🔄 Marking cheque as bounced via API...");
    print("   Cheque ID: $chequeId");
    print("   Cheque No: $chequeNo");
    print("   Reason: ${reason.isEmpty ? 'Not provided' : reason}");

    // Show loading indicator
    setState(() {
      isLoading = true;
    });

    try {
      // Prepare request body
      Map<String, dynamic> requestBody = {
        "unid": unid,
        "veh": veh,
        "action": "bounced",
        "chqid": chequeId,
        "reason": reason.isEmpty ? "yes" : reason
      };

      print("📤 Bounce Request Body: ${json.encode(requestBody)}");

      // Make API call
      final response = await http.post(
        Uri.parse(bounceApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print("📥 Bounce Response Status Code: ${response.statusCode}");
      print("📥 Bounce Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        print("📊 Bounce API Response Parsed:");
        print("   Result: ${responseData['result']}");
        print("   Message: ${responseData['message']}");

        if (responseData['result'] == "1") {
          // Successfully marked as bounced from API
          print("✅ Cheque marked as bounced successfully via API");

          // Update local list
          setState(() {
            final index = cheques.indexWhere((c) => c['id'] == chequeId);
            if (index != -1) {
              cheques[index]['status'] = 'bounced';
            }
          });

          // Re-apply filter to update the displayed list
          _applyFilter();

          // Hide loading indicator
          setState(() {
            isLoading = false;
          });

          // Show success message
          String message = "Cheque #$chequeNo marked as bounced successfully";
          if (reason.isNotEmpty) {
            message += "\nReason: $reason";
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );

          // Log to console
          print("❌ Cheque Bounced Details:");
          print("   Cheque No: $chequeNo");
          print("   Reason: ${reason.isEmpty ? 'Not provided' : reason}");
        } else {
          // API returned error
          String message = responseData['message'] ?? 'Unknown error';
          // Clean HTML tags from message if needed
          String cleanMessage = message.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          print("❌ Bounce API Error: $cleanMessage");

          setState(() {
            isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to mark as bounced: $cleanMessage'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print("❌ Bounce HTTP Error: ${response.statusCode}");

        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("❌ Bounce Exception occurred: $e");

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update cheque status via API
  Future<void> _updateChequeStatus(String chequeId, String status) async {
    print("🔄 Updating cheque status via API...");
    print("   Cheque ID: $chequeId");
    print("   New Status: $status");

    // You'll need to implement the actual API call here
    // based on your backend requirements
  }

  // Delete cheque with API integration
  void _deleteCheque(String chequeId, String chequeNo) {
    print("🗑️ Deleting cheque: $chequeNo (ID: $chequeId)");

    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Cheque"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Are you sure you want to delete cheque #$chequeNo?"),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for deletion (optional)',
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              String reason = reasonController.text.trim();

              // Close the dialog
              Navigator.pop(context);

              // Call API to delete
              await _deleteChequeViaApi(chequeId, reason, chequeNo);
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
  }

  // Delete cheque via API
  Future<void> _deleteChequeViaApi(String chequeId, String reason, String chequeNo) async {
    print("🔄 Deleting cheque via API...");
    print("   Cheque ID: $chequeId");
    print("   Cheque No: $chequeNo");
    print("   Reason: ${reason.isEmpty ? 'Not provided' : reason}");

    // Show loading indicator
    setState(() {
      isLoading = true;
    });

    try {
      // Prepare request body
      Map<String, dynamic> requestBody = {
        "unid": unid,
        "veh": veh,
        "action": "delete",
        "chqid": chequeId,
        "reason": reason.isEmpty ? "yes" : reason // If no reason provided, send "yes" as default
      };

      print("📤 Delete Request Body: ${json.encode(requestBody)}");

      // Make API call
      final response = await http.post(
        Uri.parse(deleteApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print("📥 Delete Response Status Code: ${response.statusCode}");
      print("📥 Delete Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        print("📊 Delete API Response Parsed:");
        print("   Result: ${responseData['result']}");
        print("   Message: ${responseData['message']}");

        if (responseData['result'] == "1") {
          // Successfully deleted from API
          print("✅ Cheque deleted successfully from API");

          // Remove from local list
          setState(() {
            cheques.removeWhere((c) => c['id'] == chequeId);
          });

          // Re-apply filter to update the displayed list
          _applyFilter();

          // Hide loading indicator
          setState(() {
            isLoading = false;
          });

          // Show success message
          String message = "Cheque #$chequeNo deleted successfully";
          if (reason.isNotEmpty) {
            message += "\nReason: $reason";
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );

          // Log to console
          print("✅ Cheque deleted. Reason: ${reason.isEmpty ? 'Not provided' : reason}");
        } else {
          // API returned error
          String message = responseData['message'] ?? 'Unknown error';
          print("❌ Delete API Error: $message");

          setState(() {
            isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print("❌ Delete HTTP Error: ${response.statusCode}");

        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("❌ Delete Exception occurred: $e");

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Build non-editable field for popup
  Widget _buildPopupField({
    required String label,
    required String value,
    bool isEditable = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: isEditable ? Colors.white : Colors.grey.shade50,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isEditable ? Colors.black : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Build editable field for popup
  Widget _buildPopupEditableField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool isAmount = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            prefixText: isAmount ? '₹ ' : null,
          ),
        ),
      ],
    );
  }

  // Edit cheque - Updated to navigate to ChequeEditPage
  void _editCheque(Map<String, dynamic> cheque) {
    print("✏️ Editing cheque: ${cheque['chequeNo']}");

    // Navigate to ChequeEditPage and wait for result
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChequeEditPage(cheque: cheque)),
    ).then((updatedCheque) {
      // Handle the updated cheque data returned from ChequeEditPage
      if (updatedCheque != null && updatedCheque is Map<String, dynamic>) {
        setState(() {
          final index = cheques.indexWhere((c) => c['id'] == cheque['id']);
          if (index != -1) {
            cheques[index] = updatedCheque;
          }
        });

        // Re-apply filter to update the displayed list
        _applyFilter();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cheque updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  // Show edit dialog
  void _showEditDialog(Map<String, dynamic> cheque) {
    TextEditingController customerController = TextEditingController(
      text: cheque['customerName'],
    );
    TextEditingController chequeNoController = TextEditingController(
      text: cheque['chequeNo'],
    );
    TextEditingController dateController = TextEditingController(
      text: cheque['date'],
    );
    TextEditingController walletController = TextEditingController(
      text: cheque['wallet'],
    );
    TextEditingController bankNameController = TextEditingController(
      text: cheque['bankName'] ?? '',
    );
    TextEditingController amountController = TextEditingController(
      text: cheque['amount'].toString().replaceAll('₹', ''),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Cheque"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditField("Customer Name", customerController),
                const SizedBox(height: 8),
                _buildEditField("Cheque No", chequeNoController),
                const SizedBox(height: 8),
                _buildEditField("Date (DD/MM/YYYY)", dateController),
                const SizedBox(height: 8),
                _buildEditField("Wallet (Cash/Bank)", walletController),
                const SizedBox(height: 8),
                _buildEditField("Bank Name", bankNameController),
                const SizedBox(height: 8),
                _buildEditField("Amount", amountController, isAmount: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final index = cheques.indexWhere(
                        (c) => c['id'] == cheque['id'],
                  );
                  if (index != -1) {
                    cheques[index] = {
                      ...cheques[index],
                      'customerName': customerController.text,
                      'chequeNo': chequeNoController.text,
                      'date': dateController.text,
                      'wallet': walletController.text,
                      'bankName': bankNameController.text,
                      'amount': '₹${amountController.text}',
                    };
                  }
                });

                // Re-apply filter to update the displayed list
                _applyFilter();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cheque updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditField(
      String label,
      TextEditingController controller, {
        bool isAmount = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter $label",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            prefixText: isAmount ? '₹ ' : null,
          ),
        ),
      ],
    );
  }

  // Updated: Navigate to NewChequePage
  void _addNewCheque() {
    print("➕ Navigating to NewChequePage");

    // Navigate to NewChequePage and wait for result
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewChequePage()),
    ).then((newCheque) {
      // Handle the new cheque data returned from NewChequePage
      if (newCheque != null && newCheque is Map<String, dynamic>) {
        setState(() {
          // Add the new cheque to the beginning of the list
          cheques.insert(0, {
            ...newCheque,
            "id": (cheques.length + 1).toString(),
            "status": "pending",
          });
        });

        // Re-apply filter to update the displayed list
        _applyFilter();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cheque added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  // Refresh data
  Future<void> _refreshData() async {
    print("🔄 Refreshing cheques data from API");
    await _fetchChequesFromApi();
  }

  @override
  Widget build(BuildContext context) {
    print("🎨 Building ChequesMainPage UI...");
    print("   Cheques count: ${cheques.length}");
    print("   Filtered cheques: ${filteredCheques.length}");
    print("   Selected filter: ${selectedFilter ?? 'All'}");
    print("   Is loading: $isLoading");
    print("   Error message: $errorMessage");

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Cheques",
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
            onPressed: _addNewCheque,
            tooltip: 'Add New Cheque',
          ),
        ],
      ),
      body: _buildBody(),
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
            Text('Loading cheques from server...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Cheques',
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

    if (cheques.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Cheques Found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add your first cheque',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search Section with Filter Button (replaced Clear button)
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
                      hintText: "Search by customer, cheque no or bank name...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
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
                      _applyFilter();
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Filter Button with badge indicator
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: selectedFilter != null
                            ? Colors.blue.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.filter_list,
                          color: selectedFilter != null
                              ? Colors.blue.shade800
                              : Colors.black,
                        ),
                        onPressed: _showFilterOptions,
                        tooltip: 'Filter cheques',
                      ),
                    ),
                    if (selectedFilter != null)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Active Filter Indicator (shows when filter is applied)
        if (selectedFilter != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(selectedFilter!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getStatusColor(selectedFilter!).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selectedFilter == 'pending' ? Icons.pending_actions :
                        selectedFilter == 'cleared' ? Icons.check_circle :
                        Icons.cancel,
                        size: 14,
                        color: _getStatusColor(selectedFilter!),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_getStatusText(selectedFilter!)} Cheques',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(selectedFilter!),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFilter = null;
                            _applyFilter();
                          });
                        },
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: _getStatusColor(selectedFilter!),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${filteredCheques.length} cheques',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

        // Summary Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Total Cheques
              Expanded(
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Cheques",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cheques.length.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Total Amount
              Expanded(
                child: Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Amount",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _calculateTotalAmount(),
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
              const SizedBox(width: 8),

              // Pending Amount
              Expanded(
                child: Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pending Amount",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _calculatePendingAmount(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
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

        // Status Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusLegend("Pending", Colors.blue),
              _buildStatusLegend("Cleared", Colors.green),
              _buildStatusLegend("Bounced", Colors.red),
            ],
          ),
        ),

        // Cheques List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: filteredCheques.length,
            itemBuilder: (context, index) {
              final cheque = filteredCheques[index];
              return _chequeCard(cheque);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusLegend(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _chequeCard(Map<String, dynamic> cheque) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with customer name, date and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Info with Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cheque['customerName'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cheque['date'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(cheque['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getStatusColor(cheque['status']),
                    ),
                  ),
                  child: Text(
                    _getStatusText(cheque['status']),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(cheque['status']),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Cheque No and Bank Name row
            Row(
              children: [
                // Cheque No
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Cheque No",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cheque['chequeNo'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bank Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bank Name",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance,
                            size: 14,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cheque['bankName'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      cheque['amount'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Amount",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action Buttons - ALL IN ONE ROW FOR PENDING CHEQUES
            if (cheque['status'] == 'pending')
              Row(
                children: [
                  // Clear Button with Popup (UPDATED with Wallet API)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsClearedWithPopup(cheque),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text("Clear"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade50,
                        foregroundColor: Colors.green.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Bounce Button with Popup
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsBouncedWithPopup(cheque),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text("Bounce"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Edit Button - icon only (no text)
                  IconButton(
                    onPressed: () => _editCheque(cheque),
                    icon: const Icon(Icons.edit, size: 20),
                    color: Colors.blue,
                    tooltip: 'Edit',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Delete Button - icon only (no text)
                  IconButton(
                    onPressed: () => _deleteCheque(cheque['id'], cheque['chequeNo']),
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red,
                    tooltip: 'Delete',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              )
            else
            // For CLEARED or BOUNCED cheques: Show status message
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(cheque['status']).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(cheque['status']).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          cheque['status'] == 'cleared'
                              ? Icons.check_circle
                              : Icons.warning,
                          size: 16,
                          color: _getStatusColor(cheque['status']),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cheque['status'] == 'cleared'
                              ? 'Cheque has been cleared'
                              : 'Cheque has been bounced',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(cheque['status']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Show wallet info for cleared cheques
                    if (cheque['status'] == 'cleared' && cheque['wallet'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              cheque['wallet'].toLowerCase() == 'cash'
                                  ? Icons.money
                                  : Icons.account_balance,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Amount added to ${cheque['wallet']}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
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
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            "$label:",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}