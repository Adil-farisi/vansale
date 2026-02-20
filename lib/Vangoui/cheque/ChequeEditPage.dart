import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Customer {
  final String id;
  final String name;
  final String outstandingAmount;

  Customer({
    required this.id,
    required this.name,
    required this.outstandingAmount,
  });

  @override
  String toString() => name;
}

class ChequeEditPage extends StatefulWidget {
  final Map<String, dynamic> cheque;

  const ChequeEditPage({super.key, required this.cheque});

  @override
  State<ChequeEditPage> createState() => _ChequeEditPageState();
}

class _ChequeEditPageState extends State<ChequeEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _customerController;
  final TextEditingController _chequeDateController = TextEditingController();
  final TextEditingController _chequeNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

  // Customer related variables
  Customer? _selectedCustomer;
  List<Customer> _customers = [];
  bool _isLoadingCustomers = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showCustomerList = false;
  FocusNode _customerFocusNode = FocusNode();

  // API endpoint
  final String _apiUrl = 'http://192.168.1.108/gst-3-3-production/mobile-service/vansales/get_customers.php';
  final String _updateChequeUrl = 'http://192.168.1.108:80/gst-3-3-production/mobile-service/vansales/action/cheques.php';

  // Session data
  final String unid = "20260117130317";
  final String veh = "MQ--";

  bool _isUpdating = false;

  @override
  @override
  void initState() {
    super.initState();

    // Initialize customer controller with existing data
    _customerController = TextEditingController(
      text: widget.cheque['customerName'] ?? '',
    );

    // Initialize other fields
    _chequeNumberController.text = widget.cheque['chequeNo'] ?? '';
    _amountController.text = (widget.cheque['amount'] ?? '').toString().replaceAll('₹', '');
    _bankNameController.text = widget.cheque['bankName'] ?? '';

    // Format the date from DD/MM/YY to DD-MM-YYYY
    String dateStr = widget.cheque['date'] ?? '';
    if (dateStr.isNotEmpty) {
      // If date is in DD/MM/YY format
      if (dateStr.contains('/')) {
        List<String> parts = dateStr.split('/');
        if (parts.length == 3) {
          // If year is 2 digits (YY), convert to YYYY
          String year = parts[2];
          if (year.length == 2) {
            year = '20$year'; // Convert 26 to 2026
          }
          dateStr = "${parts[0]}-${parts[1]}-$year";
        }
      }
      // If date is already in DD-MM-YY format but year is 2 digits
      else if (dateStr.contains('-')) {
        List<String> parts = dateStr.split('-');
        if (parts.length == 3 && parts[2].length == 2) {
          dateStr = "${parts[0]}-${parts[1]}-20${parts[2]}";
        }
      }
    }

    _chequeDateController.text = dateStr;
    print('📅 Formatted date for display: $_chequeDateController.text');

    // Set up focus listener
    _customerFocusNode.addListener(() {
      if (_customerFocusNode.hasFocus && _customers.isNotEmpty) {
        setState(() {
          _showCustomerList = true;
        });
      }
    });

    // Fetch customers
    _fetchCustomers();
  }
  @override
  void dispose() {
    _customerController.dispose();
    _chequeDateController.dispose();
    _chequeNumberController.dispose();
    _amountController.dispose();
    _bankNameController.dispose();
    _customerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoadingCustomers = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'unid': unid,
          'veh': veh,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['result'] == '1' || responseData['result'] == 1) {
          final customerDet = responseData['customerdet'] as List<dynamic>;

          final List<Customer> loadedCustomers = [];

          for (var customer in customerDet) {
            loadedCustomers.add(Customer(
              id: customer['custid']?.toString() ?? '',
              name: customer['cust_name']?.toString() ?? 'Unknown',
              outstandingAmount: customer['outstand_amt']?.toString() ?? '0.00',
            ));
          }

          // Try to find and select the existing customer
          Customer? foundCustomer;
          final existingCustomerName = widget.cheque['customerName'];
          final existingCustomerId = widget.cheque['customerId'];

          if (existingCustomerName != null) {
            // First try to find by ID if available
            if (existingCustomerId != null) {
              foundCustomer = loadedCustomers.firstWhere(
                    (customer) => customer.id == existingCustomerId,
                orElse: () => loadedCustomers.firstWhere(
                      (customer) => customer.name == existingCustomerName,
                  orElse: () => Customer(
                    id: existingCustomerId ?? '',
                    name: existingCustomerName,
                    outstandingAmount: widget.cheque['customerOutstanding'] ?? '0.00',
                  ),
                ),
              );
            } else {
              // Find by name only
              foundCustomer = loadedCustomers.firstWhere(
                    (customer) => customer.name == existingCustomerName,
                orElse: () => Customer(
                  id: '',
                  name: existingCustomerName,
                  outstandingAmount: widget.cheque['customerOutstanding'] ?? '0.00',
                ),
              );
            }
          }

          setState(() {
            _customers = loadedCustomers;
            _selectedCustomer = foundCustomer;
            if (foundCustomer != null) {
              _customerController.text = foundCustomer.name;
            }
          });
        } else {
          final errorMessage = responseData['message']?.toString() ?? 'Unknown error from API';
          setState(() {
            _hasError = true;
            _errorMessage = errorMessage;
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'HTTP Error ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingCustomers = false;
      });
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        // Show all customers when search is empty
        _showCustomerList = true;
      } else {
        // Filter customers based on search query
        _showCustomerList = true;
      }
    });
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _customerController.text = customer.name;
      _showCustomerList = false;
    });
    // Remove focus from the customer field
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _clearCustomerSelection() {
    setState(() {
      _selectedCustomer = null;
      _customerController.clear();
      _showCustomerList = true;
    });
    _customerFocusNode.requestFocus();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _updateCheque() async {
    if (_formKey.currentState!.validate()) {
      if (_customerController.text.isEmpty) {
        _showError('Please select or enter a customer name');
        return;
      }

      setState(() {
        _isUpdating = true;
      });

      try {
        // Get cheque ID
        String chqid = widget.cheque['id'] ?? widget.cheque['chequeId'] ?? '';
        if (chqid.isEmpty) {
          chqid = widget.cheque['chqid'] ?? '';
        }

        // Ensure date is in correct format before sending
        String dateToSend = _chequeDateController.text;
        print('📤 Date before sending: $dateToSend');

        // Prepare request body with lowercase customer name
        final requestBody = {
          "unid": unid,
          "veh": veh,
          "action": "update",
          "chqid": chqid,
          "cust_name": _customerController.text.toLowerCase(),
          "custid": _selectedCustomer?.id ?? widget.cheque['customerId'] ?? '',
          "chq_no": _chequeNumberController.text,
          "chq_date": dateToSend,
          "bank": _bankNameController.text.isNotEmpty ? _bankNameController.text : "Bank",
          "chq_amt": double.parse(_amountController.text).toStringAsFixed(2),
        };

        print('📤 Sending update request: ${json.encode(requestBody)}');

        final response = await http.post(
          Uri.parse(_updateChequeUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        );

        print('📥 Response: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          if (responseData['result'] == "1") {
            // Prepare updated cheque data to return
            final updatedCheque = {
              ...widget.cheque,
              'customerName': _customerController.text,
              'customerId': _selectedCustomer?.id ?? widget.cheque['customerId'] ?? '',
              'customerOutstanding': _selectedCustomer?.outstandingAmount ?? widget.cheque['customerOutstanding'] ?? '',
              'chequeNo': _chequeNumberController.text,
              'date': _chequeDateController.text, // Keep the DD-MM-YYYY format
              'bankName': _bankNameController.text.isNotEmpty ? _bankNameController.text : (widget.cheque['bankName'] ?? 'Bank'),
              'amount': '₹${_amountController.text}',
            };

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cheque updated successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            // Wait for the snackbar to show, then pop with data
            Future.delayed(const Duration(milliseconds: 100), () {
              Navigator.pop(context, updatedCheque);
            });
          } else {
            final errorMessage = responseData['message'] ?? 'Failed to update cheque';
            _showError('Failed to update cheque: $errorMessage');
          }
        } else {
          _showError('Failed to update cheque. Status code: ${response.statusCode}');
        }
      } catch (e) {
        _showError('Error updating cheque: $e');
      } finally {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      // Format as DD-MM-YYYY for API
      final formattedDate =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      print('📅 Date selected: $formattedDate');
      _chequeDateController.text = formattedDate;
    }
  }
  @override
  Widget build(BuildContext context) {
    // Filter customers based on search text
    final filteredCustomers = _customerController.text.isEmpty
        ? _customers
        : _customers.where((customer) =>
        customer.name.toLowerCase().contains(_customerController.text.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Cheque',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: GestureDetector(
        onTap: () {
          // Hide customer list when tapping outside
          if (_showCustomerList) {
            setState(() {
              _showCustomerList = false;
            });
          }
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Title
                const Center(
                  child: Text(
                    'Edit Cheque Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Customer Search Field
                _buildCustomerSearchField(),
                const SizedBox(height: 16),

                // Cheque Date Field
                // Cheque Date Field
                _buildFormField(
                  label: 'Cheque Date',
                  hintText: 'DD-MM-YYYY', // Changed from DD/MM/YYYY
                  controller: _chequeDateController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter cheque date';
                    }
                    // Optional: Add regex validation for DD-MM-YYYY format
                    final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
                    if (!regex.hasMatch(value)) {
                      return 'Please use DD-MM-YYYY format';
                    }
                    return null;
                  },
                  icon: Icons.calendar_today,
                  onTap: () {
                    _selectDate(context);
                  },
                ),
                const SizedBox(height: 16),

                // Cheque Number Field
                _buildFormField(
                  label: 'Cheque Number',
                  hintText: 'Enter cheque number',
                  controller: _chequeNumberController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter cheque number';
                    }
                    return null;
                  },
                  icon: Icons.confirmation_number,
                ),
                const SizedBox(height: 16),

                // Bank Name Field
                _buildFormField(
                  label: 'Bank Name',
                  hintText: 'Enter bank name (optional)',
                  controller: _bankNameController,
                  validator: (value) {
                    return null;
                  },
                  icon: Icons.account_balance,
                ),
                const SizedBox(height: 16),

                // Amount Field
                _buildFormField(
                  label: 'Amount',
                  hintText: 'Enter amount',
                  controller: _amountController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                  icon: Icons.currency_rupee,
                  isAmount: true,
                ),
                const SizedBox(height: 30),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUpdating ? null : _updateCheque,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
                        SizedBox(width: 12),
                        Text('Updating...'),
                      ],
                    )
                        : const Text(
                      'Update Cheque',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSearchField() {
    // Filter customers based on search text
    final filteredCustomers = _customerController.text.isEmpty
        ? _customers
        : _customers.where((customer) =>
        customer.name.toLowerCase().contains(_customerController.text.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Name',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Column(
          children: [
            TextFormField(
              controller: _customerController,
              focusNode: _customerFocusNode,
              onChanged: _filterCustomers,
              onTap: () {
                if (!_showCustomerList && _customers.isNotEmpty) {
                  setState(() {
                    _showCustomerList = true;
                  });
                }
              },
              decoration: InputDecoration(
                hintText: 'Search or select customer',
                prefixIcon: Icon(
                  Icons.person,
                  color: Colors.blue.shade600,
                ),
                suffixIcon: _selectedCustomer != null || _customerController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: _clearCustomerSelection,
                )
                    : _isLoadingCustomers
                    ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                )
                    : const Icon(Icons.arrow_drop_down),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select or enter a customer name';
                }
                return null;
              },
            ),

            // Customer List Dropdown
            if (_showCustomerList && filteredCustomers.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade300),
                ),
                constraints: const BoxConstraints(maxHeight: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with count
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Customers (${filteredCustomers.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() {
                                _showCustomerList = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 0),

                    // Customer list
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = filteredCustomers[index];
                          return _buildCustomerListItem(customer);
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        // Loading or empty state messages
        if (_isLoadingCustomers)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading customers...',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        if (_hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Error: $_errorMessage',
              style: const TextStyle(
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        if (_customers.isEmpty && !_isLoadingCustomers && !_hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'No customers found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        if (_showCustomerList && filteredCustomers.isEmpty && _customerController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'No customers found for "${_customerController.text}"',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCustomerListItem(Customer customer) {
    Color amountColor = Colors.grey;
    if (customer.outstandingAmount.contains('Cr')) {
      amountColor = Colors.green;
    } else if (customer.outstandingAmount.contains('Dr')) {
      amountColor = Colors.red;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: Text(
          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        customer.name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'Outstanding: ${customer.outstandingAmount}',
        style: TextStyle(
          fontSize: 12,
          color: amountColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () => _selectCustomer(customer),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required IconData icon,
    bool isAmount = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          onTap: onTap,
          readOnly: onTap != null,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(
              icon,
              color: Colors.blue.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixText: isAmount ? '₹ ' : null,
            suffixIcon: onTap != null
                ? Icon(
              Icons.calendar_month,
              color: Colors.grey.shade600,
            )
                : null,
          ),
        ),
      ],
    );
  }
}