import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReceiptUpdatePage extends StatefulWidget {
  final Map<String, dynamic> receiptData;

  const ReceiptUpdatePage({
    super.key,
    required this.receiptData,
  });

  @override
  State<ReceiptUpdatePage> createState() => _ReceiptUpdatePageState();
}

class _ReceiptUpdatePageState extends State<ReceiptUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _dueAmountController = TextEditingController();
  final TextEditingController _receivedDateController = TextEditingController();
  final TextEditingController _receivedAmountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedPaymentMode = ''; // Will be set from API
  DateTime _selectedDate = DateTime.now();

  // Lists for dropdowns
  List<Map<String, dynamic>> _paymentModes = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];

  // Search and loading states
  bool _isLoadingWallets = true;
  bool _isLoadingCustomers = true;
  bool _isUpdating = false;
  bool _showSearchResults = false;
  String _errorMessage = '';
  Timer? _debounceTimer;
  FocusNode _customerSearchFocusNode = FocusNode();

  // Session variables
  String unid = '';
  String veh = '';

  // Customer ID (from receipt data or selected customer)
  String _customerId = '';

  @override
  void initState() {
    super.initState();

    print("🚀 ReceiptUpdatePage initialized");
    print("📋 Receipt data received: ${widget.receiptData}");

    // Pre-fill form with existing receipt data
    _customerNameController.text = widget.receiptData['customerName']?.toString() ?? '';
    _customerId = widget.receiptData['customerId']?.toString() ?? widget.receiptData['custid']?.toString() ?? '';
    _dueAmountController.text = widget.receiptData['dueAmount']?.toString() ?? '';
    _receivedAmountController.text = widget.receiptData['receivedAmount']?.toString() ?? widget.receiptData['pd_amt']?.toString() ?? '';
    _notesController.text = widget.receiptData['notes']?.toString() ?? '';

    // Set payment mode from receipt data
    _selectedPaymentMode = widget.receiptData['paymentModeId']?.toString() ??
        widget.receiptData['wallet']?.toString() ?? '';

    // Parse and set date
    if (widget.receiptData['date'] != null ||
        widget.receiptData['receivedDate'] != null ||
        widget.receiptData['pd_date'] != null) {

      final dateStr = widget.receiptData['date']?.toString() ??
          widget.receiptData['receivedDate']?.toString() ??
          widget.receiptData['pd_date']?.toString() ?? '';

      try {
        if (dateStr.contains('/')) {
          // Format: dd/MM/yyyy
          final parts = dateStr.split('/');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            _selectedDate = DateTime(year, month, day);
            print("📅 Parsed date from / format: $_selectedDate");
          }
        } else if (dateStr.contains('-')) {
          // Format: dd-MM-yyyy
          final parts = dateStr.split('-');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            _selectedDate = DateTime(year, month, day);
            print("📅 Parsed date from - format: $_selectedDate");
          }
        }
      } catch (e) {
        print("⚠️ Error parsing date: $e");
      }
    }

    // Set current date using manual formatting
    _receivedDateController.text = _formatDate(_selectedDate);

    // Setup focus listener for customer search
    _customerSearchFocusNode.addListener(() {
      if (_customerSearchFocusNode.hasFocus && _customerNameController.text.isEmpty) {
        setState(() {
          _showSearchResults = true;
        });
      }
    });

    // Load session data and fetch data
    _loadSessionDataAndFetch();

    print("✅ Form fields initialized with receipt data");
    print("📊 Customer ID: $_customerId");
    print("📊 Payment Mode ID: $_selectedPaymentMode");
  }

  Future<void> _loadSessionDataAndFetch() async {
    try {
      print('🔍 DEBUG: Loading session data');
      final prefs = await SharedPreferences.getInstance();
      unid = prefs.getString('unid') ?? '';
      veh = prefs.getString('veh') ?? '';

      print('🔍 DEBUG: Loaded from SharedPreferences - unid: $unid, veh: $veh');

      if (unid.isEmpty || veh.isEmpty) {
        print('❌ DEBUG: Session data missing');
        setState(() {
          _isLoadingWallets = false;
          _isLoadingCustomers = false;
          _errorMessage = 'Session data missing. Please login again.';
        });
        return;
      }

      print('✅ DEBUG: Session data loaded successfully');

      // Fetch wallets and customers in parallel
      await Future.wait([
        _fetchWallets(),
        _fetchCustomers(),
      ]);
    } catch (e) {
      print('❌ DEBUG: Error loading session data: $e');
      setState(() {
        _isLoadingWallets = false;
        _isLoadingCustomers = false;
        _errorMessage = 'Failed to load session data: $e';
      });
    }
  }

  Future<void> _fetchCustomers() async {
    print('👥 DEBUG: Starting _fetchCustomers');
    print('👥 DEBUG: API URL: http://192.168.20.103/gst-3-3-production/mobile-service/vansales/get_customers.php');
    print('👥 DEBUG: Request body: {"unid": "$unid", "veh": "$veh"}');

    setState(() {
      _isLoadingCustomers = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.20.103/gst-3-3-production/mobile-service/vansales/get_customers.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "unid": unid,
          "veh": veh,
        }),
      );

      print('👥 DEBUG: Customer API response status: ${response.statusCode}');
      print('👥 DEBUG: Customer API raw response:');
      print('========================================');
      print(response.body);
      print('========================================');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('👥 DEBUG: Customer API parsed response result: ${data['result']}');
        print('👥 DEBUG: Full Customer API response:');
        print(json.encode(data));

        if (data['result'] == "1") {
          final List<dynamic> customerList = data['customerdet'] ?? [];
          final List<Map<String, dynamic>> customers = [];

          // Debug: Print raw customer data structure
          print('👥 DEBUG: Number of customers received: ${customerList.length}');
          print('👥 DEBUG: First customer raw data: ${customerList.isNotEmpty ? customerList[0] : "No customers"}');

          for (var customer in customerList) {
            // Extract fields based on your API response structure
            final custid = customer['custid']?.toString() ?? '';
            final custName = customer['cust_name']?.toString() ?? '';
            final outstandingAmt = customer['outstand_amt']?.toString() ?? '0.00';

            print('👥 DEBUG: Raw customer - custid: "$custid", cust_name: "$custName", outstand_amt: "$outstandingAmt"');

            if (custid.isNotEmpty && custName.isNotEmpty) {
              customers.add({
                'custid': custid,
                'cust_name': custName,
                'outstand_amt': outstandingAmt,
              });
            }
          }

          // Sort customers alphabetically by name
          customers.sort((a, b) => (a['cust_name'] ?? '').compareTo(b['cust_name'] ?? ''));

          setState(() {
            _customers = customers;
            _filteredCustomers = customers;
            print('✅ DEBUG: Loaded ${customers.length} customers from API');

            // Debug: Print all customers with their exact data
            for (int i = 0; i < customers.length; i++) {
              print('✅ DEBUG: Customer $i: custid: "${customers[i]['custid']}", cust_name: "${customers[i]['cust_name']}", outstand_amt: "${customers[i]['outstand_amt']}"');

              // Check if this matches the current customer
              if (customers[i]['custid'] == _customerId ||
                  customers[i]['cust_name'] == _customerNameController.text) {
                print('🎯 DEBUG: FOUND MATCHING CUSTOMER - custid: "${customers[i]['custid']}", cust_name: "${customers[i]['cust_name']}"');
              }
            }

            // Try to find matching customer in the loaded list
            if (_customerId.isNotEmpty || _customerNameController.text.isNotEmpty) {
              Map<String, dynamic>? matchingCustomer;

              // First try by ID
              if (_customerId.isNotEmpty) {
                matchingCustomer = customers.firstWhere(
                      (c) => c['custid'] == _customerId,
                  orElse: () => {},
                );
              }

              // If not found by ID, try by name
              if (matchingCustomer?.isEmpty ?? true && _customerNameController.text.isNotEmpty) {
                matchingCustomer = customers.firstWhere(
                      (c) => (c['cust_name'] ?? '').toLowerCase() == _customerNameController.text.toLowerCase(),
                  orElse: () => {},
                );
              }

              if (matchingCustomer?.isNotEmpty ?? false) {
                // Update with exact customer data from API
                _customerNameController.text = matchingCustomer!['cust_name'] ?? '';
                _customerId = matchingCustomer['custid'] ?? '';
                _dueAmountController.text = matchingCustomer['outstand_amt'] ?? '0.00';
                print('✅ DEBUG: Updated customer data from API match');
              }
            }
          });
        } else {
          print('❌ DEBUG: Customer API returned result: ${data['result']}');
          print('❌ DEBUG: Customer API message: ${data['message']}');
          print('❌ DEBUG: Full error response: ${json.encode(data)}');
          // Don't set error - continue with other data
        }
      } else {
        print('❌ DEBUG: Customer API HTTP error: ${response.statusCode}');
        print('❌ DEBUG: Error response body: ${response.body}');
        // Don't set error - continue with other data
      }
    } catch (e) {
      print('❌ DEBUG: Exception in _fetchCustomers: $e');
      print('❌ DEBUG: Stack trace: ${e.toString()}');
      // Don't set error - continue with other data
    } finally {
      setState(() {
        _isLoadingCustomers = false;
      });
    }
  }

  Future<void> _fetchWallets() async {
    print('💰 DEBUG: Starting _fetchWallets');
    print('💰 DEBUG: API URL: http://192.168.20.103/gst-3-3-production/mobile-service/vansales/get_wallets.php');
    print('💰 DEBUG: Request body: {"unid": "$unid", "veh": "$veh"}');

    setState(() {
      _isLoadingWallets = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.20.103/gst-3-3-production/mobile-service/vansales/get_wallets.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "unid": unid,
          "veh": veh,
        }),
      );

      print('💰 DEBUG: Wallet API response status: ${response.statusCode}');
      print('💰 DEBUG: Wallet API raw response:');
      print('========================================');
      print(response.body);
      print('========================================');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('💰 DEBUG: Wallet API parsed response: $data');
        print('💰 DEBUG: Full Wallet API response:');
        print(json.encode(data));

        if (data['result'] == "1") {
          final List<dynamic> walletList = data['walletdet'] ?? [];
          final List<Map<String, dynamic>> wallets = [];

          print('💰 DEBUG: Number of wallets received: ${walletList.length}');
          print('💰 DEBUG: First wallet raw data: ${walletList.isNotEmpty ? walletList[0] : "No wallets"}');

          for (var wallet in walletList) {
            final wltid = wallet['wltid']?.toString() ?? '';
            final wltName = wallet['wlt_name']?.toString() ?? '';

            print('💰 DEBUG: Wallet - wltid: "$wltid", wlt_name: "$wltName"');

            if (wltid.isNotEmpty && wltName.isNotEmpty) {
              wallets.add({
                'id': wltid,
                'name': wltName,
              });
            }
          }

          if (wallets.isNotEmpty) {
            // Check if the selected payment mode exists in the wallets list
            bool selectedModeExists = wallets.any((wallet) => wallet['id'] == _selectedPaymentMode);

            print('💰 DEBUG: Checking if selected payment mode exists in wallets');
            print('💰 DEBUG: Selected payment mode from receipt: $_selectedPaymentMode');
            print('💰 DEBUG: Available wallet IDs: ${wallets.map((w) => w['id']).toList()}');

            // If not, try to find by name
            if (!selectedModeExists && _selectedPaymentMode.isNotEmpty) {
              // Try to find by name (case-insensitive)
              for (var wallet in wallets) {
                final walletName = wallet['name']?.toString().toLowerCase() ?? '';
                final receiptPaymentMode = widget.receiptData['paymentMode']?.toString().toLowerCase() ??
                    widget.receiptData['wallet']?.toString().toLowerCase() ?? '';

                print('💰 DEBUG: Comparing - wallet name: "$walletName", receipt payment mode: "$receiptPaymentMode"');

                if (walletName.contains(receiptPaymentMode) || receiptPaymentMode.contains(walletName)) {
                  _selectedPaymentMode = wallet['id']?.toString() ?? '';
                  selectedModeExists = true;
                  print("💳 Found matching wallet by name: ${wallet['name']} (ID: ${wallet['id']})");
                  break;
                }
              }
            }

            // If still not found, use first wallet
            if (!selectedModeExists) {
              _selectedPaymentMode = wallets.first['id']?.toString() ?? '';
              print("💳 Using first wallet: ${wallets.first['name']} (ID: ${wallets.first['id']})");
            }

            setState(() {
              _paymentModes = wallets;
              print('✅ DEBUG: Loaded ${wallets.length} wallets from API');
              print('✅ DEBUG: Selected payment mode ID: $_selectedPaymentMode');
              print('✅ DEBUG: Selected payment mode name: ${_getPaymentModeName(_selectedPaymentMode)}');
              print('✅ DEBUG: All payment modes: ${wallets.map((w) => '${w['id']}: ${w['name']}').toList()}');
            });
          } else {
            print('⚠️ DEBUG: No wallets found in API response');
            setState(() {
              _errorMessage = 'No wallets found. Using default options.';
              _loadDefaultWallets();
            });
          }
        } else {
          print('❌ DEBUG: Wallet API returned result: ${data['result']}');
          print('❌ DEBUG: Wallet API message: ${data['message']}');
          print('❌ DEBUG: Full error response: ${json.encode(data)}');
          setState(() {
            _errorMessage = data['message']?.toString() ?? 'Failed to load wallets';
            _loadDefaultWallets();
          });
        }
      } else {
        print('❌ DEBUG: Wallet API HTTP error: ${response.statusCode}');
        print('❌ DEBUG: Error response body: ${response.body}');
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _loadDefaultWallets();
        });
      }
    } catch (e) {
      print('❌ DEBUG: Exception in _fetchWallets: $e');
      print('❌ DEBUG: Stack trace: ${e.toString()}');
      setState(() {
        _errorMessage = 'Connection error: $e';
        _loadDefaultWallets();
      });
    } finally {
      setState(() {
        _isLoadingWallets = false;
      });
    }
  }

  void _loadDefaultWallets() {
    print('⚠️ DEBUG: Loading default wallets');

    // Set default wallets
    final defaultWallets = [
      {'id': '1', 'name': 'Cash'},
      {'id': '2', 'name': 'Bank'},
    ];

    // Check if the selected payment mode exists in default wallets
    bool selectedModeExists = defaultWallets.any((wallet) => wallet['id'] == _selectedPaymentMode);

    // If not, try to find by name
    if (!selectedModeExists && _selectedPaymentMode.isNotEmpty) {
      final receiptPaymentMode = widget.receiptData['paymentMode']?.toString().toLowerCase() ??
          widget.receiptData['wallet']?.toString().toLowerCase() ?? '';

      for (var wallet in defaultWallets) {
        final walletName = wallet['name']?.toString().toLowerCase() ?? '';
        if (walletName.contains(receiptPaymentMode) || receiptPaymentMode.contains(walletName)) {
          _selectedPaymentMode = wallet['id']?.toString() ?? '';
          selectedModeExists = true;
          print("💳 Found matching default wallet by name: ${wallet['name']} (ID: ${wallet['id']})");
          break;
        }
      }
    }

    // If still not found, use first wallet
    if (!selectedModeExists) {
      _selectedPaymentMode = defaultWallets.first['id']?.toString() ?? '';
      print("💳 Using first default wallet: ${defaultWallets.first['name']}");
    }

    setState(() {
      _paymentModes = defaultWallets;
    });
  }

  String _getPaymentModeName(String id) {
    try {
      final wallet = _paymentModes.firstWhere(
            (w) => (w['id']?.toString() ?? '') == id,
      );
      return wallet['name']?.toString() ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  IconData _getPaymentModeIcon(String modeName) {
    final lowerName = modeName.toLowerCase();
    if (lowerName.contains('cash')) {
      return Icons.money;
    } else if (lowerName.contains('bank')) {
      return Icons.account_balance;
    } else {
      return Icons.payment;
    }
  }

  // Search customers function with debounce
  void _searchCustomers(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer with 300ms delay
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (query.isEmpty) {
        setState(() {
          _filteredCustomers = _customers;
          _showSearchResults = _customerSearchFocusNode.hasFocus;
        });
        return;
      }

      final searchQuery = query.toLowerCase();
      final results = _customers.where((customer) {
        final name = customer['cust_name']?.toString().toLowerCase() ?? '';
        final id = customer['custid']?.toString().toLowerCase() ?? '';
        return name.contains(searchQuery) || id.contains(searchQuery);
      }).toList();

      setState(() {
        _filteredCustomers = results;
        _showSearchResults = _customerSearchFocusNode.hasFocus;
      });
    });
  }

  // Select customer from search results
  void _selectCustomer(Map<String, dynamic> customer) {
    setState(() {
      _customerNameController.text = customer['cust_name'] ?? '';
      _customerId = customer['custid'] ?? '';

      // Auto-populate the due amount with Cr/Dr labels preserved
      final outstandingAmount = customer['outstand_amt'] ?? '0.00';
      _dueAmountController.text = outstandingAmount;

      _showSearchResults = false;
      _customerSearchFocusNode.unfocus(); // Remove focus to hide keyboard

      print('✅ DEBUG: Selected customer - cust_name: "${customer['cust_name']}", custid: "${customer['custid']}", outstanding: "$outstandingAmount"');
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _customerNameController.dispose();
    _dueAmountController.dispose();
    _receivedDateController.dispose();
    _receivedAmountController.dispose();
    _notesController.dispose();
    _customerSearchFocusNode.dispose();
    super.dispose();
  }

  // Format date as dd/MM/yyyy for display
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  // Format date for API (dd-MM-yyyy)
  String _formatDateForApi(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day-$month-$year';
  }

  Future<void> _selectDate(BuildContext context) async {
    print("📅 Opening date picker");
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      print("📅 Date selected: $picked");
      setState(() {
        _selectedDate = picked;
        _receivedDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _updateReceipt() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPaymentMode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a payment mode'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_customerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a customer from the dropdown'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate that the selected customer exists in the list
      final selectedCustomerName = _customerNameController.text.trim();
      bool customerExists = false;

      for (var customer in _customers) {
        final custid = customer['custid']?.toString().trim() ?? '';
        final custName = customer['cust_name']?.toString().trim() ?? '';

        if (custName == selectedCustomerName && custid == _customerId) {
          customerExists = true;
          break;
        }
      }

      if (!customerExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected customer not found in list. Please select from dropdown.\nName: $selectedCustomerName'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      print("✅ Form validation passed");
      print("📋 Form data to be sent:");
      print("  • unid: $unid");
      print("  • veh: $veh");
      print("  • rcpid: ${widget.receiptData['rcpid']}");
      print("  • cust_name: ${_customerNameController.text.trim()}");
      print("  • custid: $_customerId");
      print("  • wallet: $_selectedPaymentMode");
      print("  • pd_date: ${_formatDateForApi(_selectedDate)}");
      print("  • pd_amt: ${_receivedAmountController.text.trim()}");
      print("  • notes: ${_notesController.text.trim()}");

      // Show loading indicator
      setState(() {
        _isUpdating = true;
      });

      try {
        // Prepare API request data
        final Map<String, dynamic> requestData = {
          "unid": unid,
          "veh": veh,
          "action": "update",
          "rcpid": widget.receiptData['rcpid']?.toString() ??
              widget.receiptData['receiptNo']?.toString() ??
              widget.receiptData['receiptNumber']?.toString() ?? '',
          "cust_name": _customerNameController.text.trim(),
          "custid": _customerId,
          "wallet": _selectedPaymentMode,
          "pd_date": _formatDateForApi(_selectedDate),
          "pd_amt": _receivedAmountController.text.trim(),
          "notes": _notesController.text.trim(),
        };

        print('💾 DEBUG: Sending receipt update data to API:');
        print('💾 DEBUG: API URL: http://192.168.20.103/gst-3-3-production/mobile-service/vansales/action/receipt.php');
        print('💾 DEBUG: Request body:');
        print(json.encode(requestData));
        print('💾 DEBUG: Formatted request body for debugging:');
        requestData.forEach((key, value) {
          print('  $key: $value');
        });

        // Make API call
        final response = await http.post(
          Uri.parse('http://192.168.20.103/gst-3-3-production/mobile-service/vansales/action/receipt.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestData),
        );

        print('💾 DEBUG: API response status: ${response.statusCode}');
        print('💾 DEBUG: API raw response:');
        print('========================================');
        print(response.body);
        print('========================================');

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          print('💾 DEBUG: API parsed response:');
          print(json.encode(responseData));
          print('💾 DEBUG: Formatted response for debugging:');
          responseData.forEach((key, value) {
            if (value is Map || value is List) {
              print('  $key: ${json.encode(value)}');
            } else {
              print('  $key: $value');
            }
          });

          if (responseData['result'] == "1") {
            // Success - prepare updated receipt data to return
            final walletName = _getPaymentModeName(_selectedPaymentMode);
            final updatedReceiptData = {
              ...widget.receiptData, // Keep original data
              'customerName': _customerNameController.text,
              'customerId': _customerId,
              'dueAmount': _dueAmountController.text,
              'date': _receivedDateController.text,
              'receivedDate': _receivedDateController.text,
              'receivedAmount': _receivedAmountController.text,
              'paymentMode': walletName,
              'paymentModeId': _selectedPaymentMode,
              'wallet': _selectedPaymentMode,
              'notes': _notesController.text,
              'updatedTimestamp': DateTime.now().toIso8601String(),
              'unid': unid,
              'veh': veh,
              'apiResponse': responseData,
            };

            print('✅ DEBUG: Update successful! Updated receipt data:');
            print(json.encode(updatedReceiptData));

            // Show success dialog
            await _showSuccessDialog(context, updatedReceiptData);
          } else {
            // API returned error
            String errorMessage = responseData['message']?.toString() ?? 'Failed to update receipt';
            // Extract plain text from HTML message
            errorMessage = errorMessage.replaceAll(RegExp(r'<[^>]*>'), '');
            errorMessage = errorMessage
                .replaceAll('&lt;', '<')
                .replaceAll('&gt;', '>')
                .replaceAll('&amp;', '&')
                .replaceAll('&quot;', '"')
                .replaceAll('&#39;', "'");

            print('❌ DEBUG: API error message (cleaned): $errorMessage');
            print('❌ DEBUG: Full error response: ${json.encode(responseData)}');
            _showErrorDialog(errorMessage);
          }
        } else {
          // HTTP error
          print('❌ DEBUG: HTTP Error ${response.statusCode}');
          print('❌ DEBUG: Error response body: ${response.body}');
          _showErrorDialog('HTTP Error: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ DEBUG: Exception in _updateReceipt: $e');
        print('❌ DEBUG: Stack trace: ${e.toString()}');
        _showErrorDialog('Network Error: $e');
      } finally {
        setState(() {
          _isUpdating = false;
        });
      }
    } else {
      print("❌ Form validation failed");
    }
  }

  Future<void> _showSuccessDialog(BuildContext context, Map<String, dynamic> updatedReceiptData) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: const Text('Receipt updated successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              print("📌 Update success dialog closed");
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, updatedReceiptData); // Return to previous screen with updated data
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _retryFetchData() {
    print("🔄 Retrying to fetch data...");
    setState(() {
      _errorMessage = '';
      _isLoadingWallets = true;
      _isLoadingCustomers = true;
    });
    _loadSessionDataAndFetch();
  }

  @override
  Widget build(BuildContext context) {
    print("🎨 Building ReceiptUpdatePage UI");
    print("💳 Current selected payment mode ID: $_selectedPaymentMode");
    print("💳 Current selected payment mode name: ${_selectedPaymentMode.isNotEmpty ? _getPaymentModeName(_selectedPaymentMode) : 'Not set'}");
    print("💳 Available payment modes count: ${_paymentModes.length}");
    print("💳 Available customers count: ${_customers.length}");
    print("💳 Is loading wallets: $_isLoadingWallets");
    print("💳 Is loading customers: $_isLoadingCustomers");
    print("💳 Customer ID: $_customerId");

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Update Receipt",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            print("↩️ Back button pressed");
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with receipt number - REMOVED rcpid display
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.receipt, color: Colors.blue.shade800),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Receipt Number",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              widget.receiptData['receiptNo']?.toString() ?? 'N/A',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Customer Name Field with autocomplete search
              const Text(
                'Customer Name *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  TextFormField(
                    controller: _customerNameController,
                    focusNode: _customerSearchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search or select customer',
                      prefixIcon: const Icon(Icons.search, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                      ),
                      suffixIcon: _customerNameController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _customerNameController.clear();
                            _customerId = '';
                            _dueAmountController.clear();
                            _filteredCustomers = _customers;
                          });
                        },
                      )
                          : null,
                    ),
                    onChanged: _searchCustomers,
                    onTap: () {
                      setState(() {
                        _showSearchResults = true;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a customer';
                      }
                      return null;
                    },
                  ),

                  // Autocomplete search results dropdown
                  if (_showSearchResults && _filteredCustomers.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 5,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          final outstanding = customer['outstand_amt'] ?? '0.00';
                          final isCr = outstanding.contains('Cr');
                          final isDr = outstanding.contains('Dr');

                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: isCr ? Colors.red.shade100 : (isDr ? Colors.green.shade100 : Colors.blue.shade100),
                              radius: 18,
                              child: Text(
                                customer['cust_name']?.toString().substring(0, 1).toUpperCase() ?? '?',
                                style: TextStyle(
                                  color: isCr ? Colors.red.shade800 : (isDr ? Colors.green.shade800 : Colors.blue.shade800),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              customer['cust_name'] ?? 'Unknown',
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Outstanding: ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      outstanding,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isCr ? Colors.red : (isDr ? Colors.green : Colors.orange),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () => _selectCustomer(customer),
                          );
                        },
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Due Amount Field (auto-populated from customer selection)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Due Amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _dueAmountController,
                    readOnly: true, // Make it read-only since it's auto-filled
                    decoration: InputDecoration(
                      hintText: 'Auto-filled from customer selection',
                      prefixIcon: const Icon(Icons.money_off, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Received Date Field with Date Picker
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildTextField(
                    label: 'Received Date *',
                    controller: _receivedDateController,
                    icon: Icons.calendar_today,
                    hintText: 'Select date',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select date';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Received Amount Field
              _buildTextField(
                label: 'Received Amount *',
                controller: _receivedAmountController,
                icon: Icons.money,
                hintText: 'Enter received amount',
                keyboardType: TextInputType.number,
                prefixText: '₹ ',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter received amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Payment Mode Dropdown - Loaded from API
              const Text(
                'Payment Mode *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              if (_isLoadingWallets)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Loading payment options...'),
                    ],
                  ),
                )
              else if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _retryFetchData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                            foregroundColor: Colors.red.shade700,
                          ),
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_paymentModes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'No payment options available',
                      style: TextStyle(color: Colors.orange),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPaymentMode.isNotEmpty ? _selectedPaymentMode : null,
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                        elevation: 16,
                        style: const TextStyle(color: Colors.black87, fontSize: 16),
                        isExpanded: true,
                        hint: const Text('Select payment mode'),
                        onChanged: (String? newValue) {
                          print("💰 Payment mode changed to: $newValue");
                          if (newValue != null) {
                            setState(() {
                              _selectedPaymentMode = newValue;
                            });
                          }
                        },
                        items: _paymentModes.map<DropdownMenuItem<String>>((wallet) {
                          final walletName = wallet['name']?.toString() ?? 'Unknown';
                          final walletId = wallet['id']?.toString() ?? '';
                          return DropdownMenuItem<String>(
                            value: walletId,
                            child: Row(
                              children: [
                                Icon(
                                  _getPaymentModeIcon(walletName),
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(walletName),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

              const SizedBox(height: 16),

              // Notes Field
              _buildTextField(
                label: 'Notes',
                controller: _notesController,
                icon: Icons.note,
                hintText: 'Enter any additional notes',
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoadingWallets || _isLoadingCustomers || _isUpdating) ? null : _updateReceipt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 3,
                  ),
                  child: _isUpdating
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Updating...'),
                    ],
                  )
                      : (_isLoadingWallets || _isLoadingCustomers)
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Loading...'),
                    ],
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.update, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Update Receipt',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: Colors.blue.shade700),
            prefixText: prefixText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: maxLines > 1 ? 16 : 0,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}