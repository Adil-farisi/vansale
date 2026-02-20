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

class NewChequePage extends StatefulWidget {
  const NewChequePage({super.key});

  @override
  State<NewChequePage> createState() => _NewChequePageState();
}

class _NewChequePageState extends State<NewChequePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _chequeDateController = TextEditingController();
  final TextEditingController _chequeNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

  // Customer related variables
  Customer? _selectedCustomer;
  List<Customer> _customers = [];
  bool _isLoadingCustomers = false;
  bool _isSavingCheque = false;
  bool _hasError = false;
  String _errorMessage = '';

  // API endpoints
  final String _fetchCustomersUrl = 'http://192.168.1.108/gst-3-3-production/mobile-service/vansales/get_customers.php';
  final String _saveChequeUrl = 'http://192.168.1.108:80/gst-3-3-production/mobile-service/vansales/action/cheques.php';

  // Session data
  final String unid = "20260117130317";
  final String veh = "MQ--";

  @override
  void initState() {
    super.initState();
    print('🚀 NewChequePage initialized');
    print('📡 Fetch Customers URL: $_fetchCustomersUrl');
    print('📡 Save Cheque URL: $_saveChequeUrl');
    print('📡 UNID: $unid');
    print('📡 VEH: $veh');
    _fetchCustomers();
  }

  @override
  void dispose() {
    _customerController.dispose();
    _chequeDateController.dispose();
    _chequeNumberController.dispose();
    _amountController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    print('=== 📋 FETCH CUSTOMERS API CALL STARTED ===');
    print('📡 API URL: $_fetchCustomersUrl');

    setState(() {
      _isLoadingCustomers = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final requestBody = {
        'unid': unid,
        'veh': veh,
      };

      print('📤 Request Body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse(_fetchCustomersUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('📊 Parsed Response: $responseData');
        print('   Result: ${responseData['result']}');
        print('   Message: ${responseData['message']}');

        if (responseData.containsKey('customerdet')) {
          print('   customerdet field exists, type: ${responseData['customerdet'].runtimeType}');
        }

        if (responseData['result'] == "1") {
          final customerDet = responseData['customerdet'] as List<dynamic>;
          print('   Number of customers in response: ${customerDet.length}');

          final List<Customer> loadedCustomers = [];

          for (var i = 0; i < customerDet.length; i++) {
            final customer = customerDet[i];
            print('   📝 Customer $i: ID=${customer['custid']}, Name=${customer['cust_name']}, Outstanding=${customer['outstand_amt']}');

            loadedCustomers.add(Customer(
              id: customer['custid']?.toString() ?? '',
              name: customer['cust_name']?.toString() ?? 'Unknown',
              outstandingAmount: customer['outstand_amt']?.toString() ?? '0.00',
            ));
          }

          setState(() {
            _customers = loadedCustomers;
            print('✅ Successfully loaded ${_customers.length} customers');
          });
        } else {
          final errorMessage = responseData['message']?.toString() ?? 'Unknown error from API';
          print('❌ API Error: $errorMessage');
          setState(() {
            _hasError = true;
            _errorMessage = errorMessage;
          });
          _showError('Failed to load customers: $errorMessage');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        setState(() {
          _hasError = true;
          _errorMessage = 'HTTP Error ${response.statusCode}';
        });
        _showError('Failed to load customers. Status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Exception in _fetchCustomers: $e');
      print('   Stack Trace: $stackTrace');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
      _showError('Error loading customers: $e');
    } finally {
      setState(() {
        _isLoadingCustomers = false;
      });
      print('=== 📋 FETCH CUSTOMERS API CALL FINISHED ===\n');
    }
  }

  Future<void> _saveCheque() async {
    print('=== 💾 SAVE CHEQUE API CALL STARTED ===');

    if (_formKey.currentState!.validate()) {
      if (_selectedCustomer == null) {
        print('❌ Validation failed: No customer selected');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a customer'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() {
        _isSavingCheque = true;
      });

      try {
        // Prepare request body
        final requestBody = {
          "unid": unid,
          "veh": veh,
          "action": "insert",
          "cust_name": _selectedCustomer!.name.toLowerCase(),
          "custid": _selectedCustomer!.id,
          "chq_no": _chequeNumberController.text,
          "chq_date": _chequeDateController.text,
          "bank": _bankNameController.text.isNotEmpty ? _bankNameController.text : "Bank",
          "chq_amt": double.parse(_amountController.text).toStringAsFixed(2),
        };

        print('📤 Request Body: ${json.encode(requestBody)}');
        print('   URL: $_saveChequeUrl');
        print('   Headers: Content-Type: application/json');

        final response = await http.post(
          Uri.parse(_saveChequeUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        );

        print('📥 Response Status Code: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          print('📊 Parsed Response: $responseData');
          print('   Result: ${responseData['result']}');
          print('   Message: ${responseData['message']}');

          if (responseData['result'] == "1") {
            // Prepare cheque data to return
            final chequeData = {
              'customerName': _selectedCustomer!.name,
              'customerId': _selectedCustomer!.id,
              'customerOutstanding': _selectedCustomer!.outstandingAmount,
              'chequeNo': _chequeNumberController.text,
              'date': _chequeDateController.text,
              'wallet': 'Bank',
              'bankName': _bankNameController.text.isNotEmpty ? _bankNameController.text : 'Bank',
              'amount': '₹${double.parse(_amountController.text).toStringAsFixed(2)}',
            };

            print('✅ Cheque saved successfully!');
            print('   Cheque Data: $chequeData');

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cheque saved successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            // Wait for the snackbar to show, then pop with data
            Future.delayed(const Duration(milliseconds: 100), () {
              Navigator.pop(context, chequeData);
            });
          } else {
            final errorMessage = responseData['message'] ?? 'Failed to save cheque';
            print('❌ API Error: $errorMessage');
            _showError('Failed to save cheque: $errorMessage');
          }
        } else {
          print('❌ HTTP Error: ${response.statusCode}');
          _showError('Failed to save cheque. Status code: ${response.statusCode}');
        }
      } catch (e, stackTrace) {
        print('❌ Exception in _saveCheque: $e');
        print('   Stack Trace: $stackTrace');
        _showError('Error saving cheque: $e');
      } finally {
        setState(() {
          _isSavingCheque = false;
        });
        print('=== 💾 SAVE CHEQUE API CALL FINISHED ===\n');
      }
    } else {
      print('❌ Form validation failed');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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
      final formattedDate =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      print('📅 Date selected: $formattedDate');
      _chequeDateController.text = formattedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Cheque',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            print('👈 Back button pressed');
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title
                  const Center(
                    child: Text(
                      'Add Cheque Details',
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
                  _buildFormField(
                    label: 'Cheque Date',
                    hintText: 'DD-MM-YYYY',
                    controller: _chequeDateController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter cheque date';
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
                    hintText: 'Enter bank name',
                    controller: _bankNameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter bank name';
                      }
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

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSavingCheque ? null : _saveCheque,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      child: _isSavingCheque
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
                          Text('Saving...'),
                        ],
                      )
                          : const Text(
                        'Save Cheque',
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
          if (_isSavingCheque)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Saving cheque...'),
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

  Widget _buildCustomerSearchField() {
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
        _buildCustomerAutocomplete(),

        // Status messages
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
              'No customers found. Pull down to refresh.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        if (_customers.isNotEmpty && !_isLoadingCustomers)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
          ),
      ],
    );
  }

  Widget _buildCustomerAutocomplete() {
    return Autocomplete<Customer>(
      displayStringForOption: (customer) => customer.name,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _customers;
        }
        return _customers.where((customer) =>
            customer.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (Customer selection) {
        setState(() {
          _selectedCustomer = selection;
        });
        print('✅ Customer selected: ${selection.name} (ID: ${selection.id})');
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted) {
        // Sync with our main controller
        if (_customerController.text != fieldTextEditingController.text) {
          _customerController.text = fieldTextEditingController.text;
        }

        return TextFormField(
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            hintText: 'Search or select customer',
            prefixIcon: Icon(
              Icons.person,
              color: Colors.blue.shade600,
            ),
            suffixIcon: _selectedCustomer != null
                ? IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                setState(() {
                  _selectedCustomer = null;
                  _customerController.clear();
                  fieldTextEditingController.clear();
                });
                print('🧹 Customer selection cleared');
              },
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
            if (_selectedCustomer == null) {
              return 'Please select a customer';
            }
            return null;
          },
        );
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<Customer> onSelected,
          Iterable<Customer> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              width: MediaQuery.of(context).size.width * 0.9,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final Customer option = options.elementAt(index);
                  return _buildCustomerListItem(option, onSelected);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerListItem(Customer customer, AutocompleteOnSelected<Customer> onSelected) {
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
      onTap: () {
        onSelected(customer);
      },
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
          keyboardType: isAmount ? TextInputType.number : TextInputType.text,
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