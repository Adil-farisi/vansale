import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Customer model class
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

class NewDiscountPage extends StatefulWidget {
  const NewDiscountPage({super.key});

  @override
  State<NewDiscountPage> createState() => _NewDiscountPageState();
}

class _NewDiscountPageState extends State<NewDiscountPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _dueAmountController = TextEditingController();
  final TextEditingController _discountDateController = TextEditingController();
  final TextEditingController _discountAmountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Customer data
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  bool isLoadingCustomers = false;
  bool isSaving = false;

  // API endpoint for discount actions
  final String apiUrl = "http://192.168.1.108:80/gst-3-3-production/mobile-service/vansales/action/discounts.php";

  @override
  void initState() {
    super.initState();
    print("🚀 NewDiscountPage initialized");
    _fetchCustomers();
    // Initialize due amount as 0
    _dueAmountController.text = '0.00';
    // Set today's date as default
    _setDefaultDate();
  }

  void _setDefaultDate() {
    final now = DateTime.now();
    final formattedDate = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    _discountDateController.text = formattedDate;
    print("📅 Default date set to: $formattedDate");
  }

  @override
  void dispose() {
    _customerController.dispose();
    _dueAmountController.dispose();
    _discountDateController.dispose();
    _discountAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    print("📋 Fetching customers list...");
    setState(() {
      isLoadingCustomers = true;
    });

    try {
      final url = Uri.parse('http://192.168.1.108/gst-3-3-production/mobile-service/vansales/get_customers.php');

      print("📤 Request URL: $url");
      print("📤 Request body: {\"unid\":\"20260117130317\",\"veh\":\"MQ--\"}");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "unid": "20260117130317",
          "veh": "MQ--"
        }),
      ).timeout(const Duration(seconds: 10));

      print("📥 Response status: ${response.statusCode}");
      print("📥 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['result'] == "1") {
          final customerDet = List<Map<String, dynamic>>.from(data['customerdet']);

          setState(() {
            _customers = customerDet.map((customer) => Customer(
              id: customer['custid'] ?? '',
              name: customer['cust_name'] ?? '',
              outstandingAmount: customer['outstand_amt'] ?? '0.00',
            )).toList();
          });

          print("✅ Loaded ${_customers.length} customers");
        } else {
          print("❌ Failed to load customers: ${data['message']}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load customers: ${data['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print("❌ Server error: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect to server'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("❌ Error fetching customers: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoadingCustomers = false;
      });
    }
  }

  Future<void> _saveDiscount() async {
    print("💾 Attempting to save discount...");

    if (_formKey.currentState!.validate()) {
      // Check if customer is selected
      if (_selectedCustomer == null) {
        print("❌ No customer selected");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a customer'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if discount amount is entered
      if (_discountAmountController.text.isEmpty) {
        print("❌ Discount amount is empty");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter discount amount'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Parse discount amount
      final discountAmount = _discountAmountController.text;
      final parsedDiscountAmount = double.tryParse(discountAmount) ?? 0.0;

      if (parsedDiscountAmount <= 0) {
        print("❌ Invalid discount amount: $discountAmount");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discount amount must be greater than 0'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Format date (ensure it's in DD-MM-YYYY format)
      String formattedDate = _discountDateController.text;
      // Replace / with - if needed
      if (formattedDate.contains('/')) {
        formattedDate = formattedDate.replaceAll('/', '-');
      }

      print("📝 Discount details:");
      print("   - Customer ID: ${_selectedCustomer!.id}");
      print("   - Customer Name: ${_selectedCustomer!.name}");
      print("   - Date: $formattedDate");
      print("   - Amount: $discountAmount");
      print("   - Notes: ${_notesController.text}");

      setState(() {
        isSaving = true;
      });

      try {
        // Prepare API request
        Map<String, dynamic> requestBody = {
          "unid": "20260117130317",
          "veh": "MQ--",
          "action": "insert",
          "cust_name": _selectedCustomer!.name,
          "custid": _selectedCustomer!.id,
          "notes": _notesController.text.isEmpty ? "No notes" : _notesController.text,
          "dsc_date": formattedDate,
          "dsc_amt": discountAmount
        };

        print("📤 Sending to API: $apiUrl");
        print("📤 Request body: $requestBody");

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(requestBody),
        ).timeout(const Duration(seconds: 10));

        print("📥 Response status: ${response.statusCode}");
        print("📥 Response body: ${response.body}");

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData['result'] == "1") {
            print("✅ Discount saved successfully!");
            print("📨 Server message: ${responseData['message']}");

            // Prepare discount data to return
            final discountData = {
              'custid': _selectedCustomer!.id,
              'customerName': _selectedCustomer!.name,
              'date': formattedDate,
              'notes': _notesController.text,
              'outstand_amt': _selectedCustomer!.outstandingAmount,
              'dueAmount': _dueAmountController.text,
              'discountAmount': '₹$discountAmount',
              'dscid': responseData['dscid'] ?? '', // If API returns the new ID
            };

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Discount saved successfully!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );

            // Wait a moment then pop with data
            await Future.delayed(const Duration(milliseconds: 500));

            if (mounted) {
              Navigator.pop(context, discountData);
            }
          } else {
            print("❌ API returned error: ${responseData['message']}");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message'] ?? 'Failed to save discount'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          print("❌ Server error: ${response.statusCode}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server error: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print("❌ Error saving discount: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting to server: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            isSaving = false;
          });
        }
      }
    } else {
      print("❌ Form validation failed");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    print("📅 Opening date picker");
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final formattedDate =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      setState(() {
        _discountDateController.text = formattedDate;
      });
      print("📅 Date selected: $formattedDate");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Discount',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            print("🔙 Navigating back");
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
                      'Add Discount Details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Customer Name Field with Autocomplete
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer Name *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildCustomerAutocomplete(),
                      if (isLoadingCustomers)
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Due Amount Field (Read Only)
                  _buildDueAmountField(),
                  const SizedBox(height: 16),

                  // Discount Date Field
                  _buildFormField(
                    label: 'Discount Date *',
                    hintText: 'DD-MM-YYYY',
                    controller: _discountDateController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter discount date';
                      }
                      return null;
                    },
                    icon: Icons.calendar_today,
                    onTap: () {
                      _selectDate(context);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Discount Amount Field
                  _buildDiscountAmountField(),
                  const SizedBox(height: 16),

                  // Notes Field
                  _buildFormField(
                    label: 'Notes',
                    hintText: 'Enter discount notes (optional)',
                    controller: _notesController,
                    validator: (value) {
                      // Notes are optional
                      return null;
                    },
                    icon: Icons.note,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 30),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _saveDiscount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      child: isSaving
                          ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Saving...'),
                        ],
                      )
                          : const Text(
                        'Save Discount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Debug Info (optional - can be removed in production)
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (isSaving)
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
                        Text('Saving discount...'),
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

  // Build customer autocomplete field
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
          _dueAmountController.text = selection.outstandingAmount;
        });
        print('✅ Selected customer: ${selection.name} (ID: ${selection.id})');
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
                  _dueAmountController.text = '0.00';
                });
                print("🗑️ Customer selection cleared");
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
            if (_selectedCustomer == null && (value == null || value.isEmpty)) {
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

  // Build individual customer list item
  Widget _buildCustomerListItem(
      Customer customer, AutocompleteOnSelected<Customer> onSelected) {
    Color amountColor = Colors.grey;
    if (customer.outstandingAmount.contains('Dr')) {
      amountColor = Colors.red;
    } else if (customer.outstandingAmount.contains('Cr')) {
      amountColor = Colors.green;
    }

    return InkWell(
      onTap: () {
        onSelected(customer);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              radius: 16,
              child: Text(
                customer.name.isNotEmpty ? customer.name[0] : '?',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Outstanding: ${customer.outstandingAmount}',
                    style: TextStyle(
                      fontSize: 11,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedCustomer?.id == customer.id)
              Icon(
                Icons.check,
                color: Colors.blue.shade600,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // Build Due Amount field
  Widget _buildDueAmountField() {
    final dueAmount = _dueAmountController.text;
    Color textColor = Colors.black87;
    if (dueAmount.contains('Dr')) {
      textColor = Colors.red;
    } else if (dueAmount.contains('Cr')) {
      textColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Due Amount',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: [
              Icon(
                Icons.currency_rupee,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dueAmount,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              const Icon(
                Icons.lock,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Due amount updates based on selected customer',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // Build Discount Amount field
  Widget _buildDiscountAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Discount Amount *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _discountAmountController,
          decoration: InputDecoration(
            hintText: 'Enter discount amount',
            prefixIcon: Icon(
              Icons.money_off,
              color: Colors.blue.shade600,
            ),
            prefixText: '₹ ',
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
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter discount amount';
            }
            final parsedValue = double.tryParse(value);
            if (parsedValue == null) {
              return 'Please enter a valid number';
            }
            if (parsedValue <= 0) {
              return 'Discount amount must be greater than 0';
            }
            return null;
          },
        ),
        const SizedBox(height: 4),
        const Text(
          'Enter the amount to be given as discount',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // Build editable form field
  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required IconData icon,
    VoidCallback? onTap,
    int maxLines = 1,
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
          maxLines: maxLines,
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
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 14,
            ),
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