import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReceiptSavePage extends StatefulWidget {
  final Map<String, dynamic>? customerData;

  const ReceiptSavePage({
    super.key,
    this.customerData,
  });

  @override
  State<ReceiptSavePage> createState() => _ReceiptSavePageState();
}

class _ReceiptSavePageState extends State<ReceiptSavePage> {
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
  bool _isSaving = false;
  bool _showSearchResults = false;
  String _errorMessage = '';
  Timer? _debounceTimer;
  FocusNode _customerSearchFocusNode = FocusNode();

  // Session variables
  String unid = '';
  String veh = '';

  @override
  void initState() {
    super.initState();

    // Pre-fill data if customerData is provided
    if (widget.customerData != null) {
      _customerNameController.text = widget.customerData!['name'] ?? '';
      _dueAmountController.text = widget.customerData!['dueAmount']?.toString() ?? '';
    }

    // Set current date using manual formatting
    _receivedDateController.text = _formatDate(_selectedDate);

    // Initialize filtered customers list
    _filteredCustomers = _customers;

    // Setup focus listener
    _customerSearchFocusNode.addListener(() {
      if (_customerSearchFocusNode.hasFocus && _customerNameController.text.isEmpty) {
        setState(() {
          _showSearchResults = true;
        });
      }
    });

    // Load session data and fetch data
    _loadSessionDataAndFetch();
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
      print('👥 DEBUG: Customer API raw response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('👥 DEBUG: Customer API parsed response result: ${data['result']}');

        if (data['result'] == "1") {
          final List<dynamic> customerList = data['customerdet'] ?? [];
          final List<Map<String, dynamic>> customers = [];

          // Debug: Print raw customer data structure
          print('👥 DEBUG: Number of customers received: ${customerList.length}');

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
              print('✅ DEBUG: Customer $i: custid: "${customers[i]['custid']}", cust_name: "${customers[i]['cust_name']}"');

              // Check if this is "Adil" with ID "NTY4"
              if (customers[i]['custid'] == 'NTY4' || customers[i]['cust_name'].contains('Adil')) {
                print('🎯 DEBUG: FOUND TARGET CUSTOMER - custid: "${customers[i]['custid']}", cust_name: "${customers[i]['cust_name']}"');
              }
            }

            // If we have pre-filled customer data, try to find matching customer
            if (widget.customerData != null) {
              final preFilledName = widget.customerData!['name'] ?? '';
              final preFilledId = widget.customerData!['custid']?.toString() ?? '';

              print('👥 DEBUG: Looking for pre-filled customer - Name: "$preFilledName", ID: "$preFilledId"');

              if (preFilledId.isNotEmpty) {
                final matchingCustomer = customers.firstWhere(
                      (c) => c['custid'] == preFilledId,
                  orElse: () => {},
                );
                if (matchingCustomer.isNotEmpty) {
                  _customerNameController.text = matchingCustomer['cust_name'] ?? '';
                  _dueAmountController.text = matchingCustomer['outstand_amt'] ?? '0.00';
                  print('✅ DEBUG: Found matching customer by ID');
                }
              } else if (preFilledName.isNotEmpty) {
                final matchingCustomer = customers.firstWhere(
                      (c) => (c['cust_name'] ?? '').toLowerCase().contains(preFilledName.toLowerCase()),
                  orElse: () => {},
                );
                if (matchingCustomer.isNotEmpty) {
                  _customerNameController.text = matchingCustomer['cust_name'] ?? '';
                  _dueAmountController.text = matchingCustomer['outstand_amt'] ?? '0.00';
                  print('✅ DEBUG: Found matching customer by name');
                }
              }
            }
          });
        } else {
          print('❌ DEBUG: Customer API returned result: ${data['result']}');
          print('❌ DEBUG: Customer API message: ${data['message']}');
          // Don't set error - continue with other data
        }
      } else {
        print('❌ DEBUG: Customer API HTTP error: ${response.statusCode}');
        // Don't set error - continue with other data
      }
    } catch (e) {
      print('❌ DEBUG: Exception in _fetchCustomers: $e');
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('💰 DEBUG: Wallet API parsed response result: ${data['result']}');

        if (data['result'] == "1") {
          final List<dynamic> walletList = data['walletdet'] ?? [];
          final List<Map<String, dynamic>> wallets = [];

          for (var wallet in walletList) {
            final wltid = wallet['wltid']?.toString() ?? '';
            final wltName = wallet['wlt_name']?.toString() ?? '';

            if (wltid.isNotEmpty && wltName.isNotEmpty) {
              wallets.add({
                'id': wltid,
                'name': wltName,
              });
              print('💰 DEBUG: Wallet $wltid - Name: $wltName');
            }
          }

          if (wallets.isNotEmpty) {
            setState(() {
              _paymentModes = wallets;
              _selectedPaymentMode = wallets.first['id']; // Set default to first wallet
              print('✅ DEBUG: Loaded ${wallets.length} wallets from API');
            });
          } else {
            print('⚠️ DEBUG: No wallets found, loading defaults');
            _loadDefaultWallets();
          }
        } else {
          print('❌ DEBUG: Wallet API returned result: ${data['result']}');
          print('❌ DEBUG: Wallet API message: ${data['message']}');
          _loadDefaultWallets();
        }
      } else {
        print('❌ DEBUG: Wallet API HTTP error: ${response.statusCode}');
        _loadDefaultWallets();
      }
    } catch (e) {
      print('❌ DEBUG: Exception in _fetchWallets: $e');
      _loadDefaultWallets();
    } finally {
      setState(() {
        _isLoadingWallets = false;
      });
    }
  }

  void _loadDefaultWallets() {
    print('⚠️ DEBUG: Loading default wallets');
    setState(() {
      _paymentModes = [
        {'id': '1', 'name': 'Cash'},
        {'id': '2', 'name': 'Bank'},
      ];
      if (_paymentModes.isNotEmpty) {
        _selectedPaymentMode = _paymentModes.first['id'];
      }
    });
  }

  String _getPaymentModeName(String id) {
    final wallet = _paymentModes.firstWhere(
          (w) => w['id'] == id,
      orElse: () => {'id': id, 'name': 'Unknown'},
    );
    return wallet['name'];
  }

  IconData _getPaymentModeIcon(String modeName) {
    switch (modeName.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'bank':
        return Icons.account_balance;
      default:
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

      // Auto-populate the due amount with Cr/Dr labels preserved
      final outstandingAmount = customer['outstand_amt'] ?? '0.00';
      _dueAmountController.text = outstandingAmount;

      _showSearchResults = false;
      _customerSearchFocusNode.unfocus(); // Remove focus to hide keyboard

      print('✅ DEBUG: Selected customer - cust_name: "${customer['cust_name']}", custid: "${customer['custid']}"');
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

  // Format date as dd/MM/yyyy
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

  // Generate receipt ID (simple implementation)
  String _generateReceiptId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();
    return 'RC${timestamp.substring(timestamp.length - 8)}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _receivedDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _saveReceipt() async {
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

      if (_customerNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a customer'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // IMPORTANT: Validate that the customer exists in the customer list
      final selectedCustomerName = _customerNameController.text.trim();

      // Debug: Check what customers are available
      print('🔍 DEBUG: Looking for customer in list:');
      print('🔍 DEBUG: Searching for - cust_name: "$selectedCustomerName"');
      print('🔍 DEBUG: Total customers loaded: ${_customers.length}');

      // Check if customer exists in our loaded customers list
      bool customerExists = false;
      String? selectedCustomerId;
      Map<String, dynamic>? foundCustomer;

      for (var customer in _customers) {
        final custid = customer['custid']?.toString().trim() ?? '';
        final custName = customer['cust_name']?.toString().trim() ?? '';

        print('🔍 DEBUG: Checking customer - custid: "$custid", cust_name: "$custName"');

        if (custName == selectedCustomerName) {
          customerExists = true;
          selectedCustomerId = custid;
          foundCustomer = customer;
          print('✅ DEBUG: Exact match found! custid: "$custid"');
          break;
        }
      }

      if (!customerExists || selectedCustomerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer not found in list. Please select from dropdown.\nName: $selectedCustomerName'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Get the wallet name from the selected ID
      final walletName = _getPaymentModeName(_selectedPaymentMode);

      // Show loading indicator
      setState(() {
        _isSaving = true;
      });

      try {
        // Prepare API request data - use exact field names from customer data
        final Map<String, dynamic> requestData = {
          "unid": unid,
          "veh": veh,
          "action": "insert",
          "rcpid": _generateReceiptId(),
          "cust_name": selectedCustomerName,
          "custid": selectedCustomerId,
          "wallet": _selectedPaymentMode,
          "pd_date": _formatDateForApi(_selectedDate),
          "pd_amt": _receivedAmountController.text.trim(),
          "notes": _notesController.text.trim(),
        };

        print('💾 DEBUG: Sending receipt data to API:');
        print('💾 DEBUG: API URL: http://192.168.20.103/gst-3-3-production/mobile-service/vansales/action/receipt.php');
        print('💾 DEBUG: Request body:');
        print('💾 DEBUG:   unid: ${requestData["unid"]}');
        print('💾 DEBUG:   veh: ${requestData["veh"]}');
        print('💾 DEBUG:   action: ${requestData["action"]}');
        print('💾 DEBUG:   rcpid: ${requestData["rcpid"]}');
        print('💾 DEBUG:   cust_name: "${requestData["cust_name"]}"');
        print('💾 DEBUG:   custid: "${requestData["custid"]}"');
        print('💾 DEBUG:   wallet: ${requestData["wallet"]}');
        print('💾 DEBUG:   pd_date: ${requestData["pd_date"]}');
        print('💾 DEBUG:   pd_amt: ${requestData["pd_amt"]}');
        print('💾 DEBUG:   notes: ${requestData["notes"]}');

        // Make API call
        final response = await http.post(
          Uri.parse('http://192.168.20.103/gst-3-3-production/mobile-service/vansales/action/receipt.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestData),
        );

        print('💾 DEBUG: API response status: ${response.statusCode}');
        print('💾 DEBUG: API raw response: ${response.body}');

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          print('💾 DEBUG: API parsed response: $responseData');

          if (responseData['result'] == "1") {
            // Success - prepare receipt data to return
            final receiptData = {
              'customerName': selectedCustomerName,
              'customerId': selectedCustomerId,
              'dueAmount': _dueAmountController.text,
              'receivedDate': _receivedDateController.text,
              'receivedAmount': _receivedAmountController.text,
              'paymentModeId': _selectedPaymentMode,
              'paymentModeName': walletName,
              'notes': _notesController.text,
              'timestamp': DateTime.now().toIso8601String(),
              'unid': unid,
              'veh': veh,
              'apiResponse': responseData,
            };

            // Show success dialog
            await _showSuccessDialog(context, receiptData);
          } else {
            // API returned error
            String errorMessage = responseData['message']?.toString() ?? 'Failed to save receipt';
            // Extract plain text from HTML message
            errorMessage = errorMessage.replaceAll(RegExp(r'<[^>]*>'), '');
            errorMessage = errorMessage
                .replaceAll('&lt;', '<')
                .replaceAll('&gt;', '>')
                .replaceAll('&amp;', '&')
                .replaceAll('&quot;', '"')
                .replaceAll('&#39;', "'");

            _showErrorDialog(errorMessage);
          }
        } else {
          // HTTP error
          _showErrorDialog('HTTP Error: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ DEBUG: Exception in _saveReceipt: $e');
        _showErrorDialog('Network Error: $e');
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showSuccessDialog(BuildContext context, Map<String, dynamic> receiptData) async {
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
        content: const Text('Receipt saved successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, receiptData); // Return to previous screen with data
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
    setState(() {
      _errorMessage = '';
      _isLoadingWallets = true;
      _isLoadingCustomers = true;
    });
    _loadSessionDataAndFetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Save Receipt",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page title
              const SizedBox(height: 10),

              // Customer Name Field with autocomplete search
              const Text(
                'Customer *',
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
                            _dueAmountController.clear(); // Clear due amount too
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
                      suffixText: _getCrDrLabel(_dueAmountController.text),
                    ),
                  ),
                  if (_dueAmountController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _getCrDrExplanation(_dueAmountController.text),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getCrDrColor(_dueAmountController.text),
                          fontStyle: FontStyle.italic,
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
                        if (newValue != null) {
                          setState(() {
                            _selectedPaymentMode = newValue;
                          });
                        }
                      },
                      items: _paymentModes.map<DropdownMenuItem<String>>((wallet) {
                        final walletName = wallet['name'] ?? 'Unknown';
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

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoadingWallets || _isLoadingCustomers || _isSaving) ? null : _saveReceipt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 3,
                  ),
                  child: _isSaving
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
                      Text('Saving...'),
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
                      Icon(Icons.save, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Save Receipt',
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

  // Helper methods for Cr/Dr labels
  String _getCrDrLabel(String amount) {
    if (amount.contains('Cr')) return 'Cr';
    if (amount.contains('Dr')) return 'Dr';
    return '';
  }

  Color _getCrDrColor(String amount) {
    if (amount.contains('Cr')) return Colors.red;
    if (amount.contains('Dr')) return Colors.green;
    return Colors.orange;
  }

  String _getCrDrExplanation(String amount) {
    if (amount.contains('Cr')) return 'Customer has credit (owes money)';
    if (amount.contains('Dr')) return 'Customer has debit (we owe customer)';
    return 'No outstanding balance';
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? prefixText,
    bool readOnly = false,
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
          readOnly: readOnly,
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