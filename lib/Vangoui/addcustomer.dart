import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Addcustomer extends StatefulWidget {
  const Addcustomer({super.key});

  @override
  State<Addcustomer> createState() => _AddcustomerState();
}

class _AddcustomerState extends State<Addcustomer> {
  final _formKey = GlobalKey<FormState>();

  String? typeofcustomer;
  String? salesexetype;
  String? valgrp;
  String? perdayroute;

  final customerNameController = TextEditingController();
  final gstController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final landPhoneController = TextEditingController();
  final addressController = TextEditingController();
  final stateController = TextEditingController();
  final stateCodeController = TextEditingController();
  final openingBalanceController = TextEditingController();
  final creditDaysController = TextEditingController();

  // Variables for API data
  List<Map<String, dynamic>> customerTypes = [];
  List<Map<String, dynamic>> salesExecutives = [];
  List<Map<String, dynamic>> routesList = [];
  bool isLoadingCustomerTypes = true;
  bool isLoadingSalesExecutives = true;
  bool isLoadingRoutes = true;
  bool isSubmitting = false;
  String? customerTypesErrorMessage;
  String? salesExecutivesErrorMessage;
  String? routesErrorMessage;

  // New variable to track if form was submitted
  bool formSubmitted = false;

  @override
  void initState() {
    super.initState();
    // Fetch customer types, sales executives, and routes when the page loads
    _fetchCustomerTypes();
    _fetchSalesExecutives();
    _fetchRoutes();
  }

  // API call to get customer types
  Future<void> _fetchCustomerTypes() async {
    setState(() {
      isLoadingCustomerTypes = true;
      customerTypesErrorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.108/gst-3-3-production/mobile-service/vansales/get_customer_types.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "unid": "20260117130317",
          "veh": "MQ--"
        }),
      );

      print('Customer Types API Response Status: ${response.statusCode}');
      print('Customer Types API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['result'] == "1") {
          final List<dynamic> types = responseData['customertypesdet'];
          setState(() {
            customerTypes = types.asMap().entries.map((entry) {
              int index = entry.key;
              var item = entry.value;
              return {
                'id': (item['custtypeid'] ?? index.toString()).toString(),
                'name': item['custtype_name'] ?? 'Customer Type ${index + 1}'
              };
            }).toList();
            isLoadingCustomerTypes = false;
          });
          print('Fetched ${customerTypes.length} customer types');
        } else {
          setState(() {
            customerTypesErrorMessage = responseData['message'] ?? 'Failed to load customer types';
            isLoadingCustomerTypes = false;
          });
        }
      } else {
        setState(() {
          customerTypesErrorMessage = 'Server error: ${response.statusCode}';
          isLoadingCustomerTypes = false;
        });
      }
    } catch (e) {
      print('Error fetching customer types: $e');
      setState(() {
        customerTypesErrorMessage = 'Connection error: $e';
        isLoadingCustomerTypes = false;
      });
    }
  }

  // API call to get sales executives - FIXED DUPLICATE ID ISSUE
  Future<void> _fetchSalesExecutives() async {
    setState(() {
      isLoadingSalesExecutives = true;
      salesExecutivesErrorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.108/gst-3-3-production/mobile-service/vansales/get_sales_executives.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "unid": "20260117130317",
          "veh": "MQ--"
        }),
      );

      print('Sales Executives API Response Status: ${response.statusCode}');
      print('Sales Executives API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['result'] == "1") {
          final List<dynamic> executives = responseData['salesexedet'];

          // Use a map to track unique IDs
          Map<String, Map<String, dynamic>> uniqueExecutives = {};

          for (var i = 0; i < executives.length; i++) {
            var item = executives[i];
            // Get the ID from the item or use index as fallback
            String id = (item['id'] ?? item['executive_id'] ?? i.toString()).toString();
            String name = item['name'] ?? item['executive_name'] ?? 'Executive ${i + 1}';

            // If ID already exists, append index to make it unique
            if (uniqueExecutives.containsKey(id)) {
              id = "${id}_$i";
            }

            uniqueExecutives[id] = {
              'id': id,
              'name': name
            };
          }

          setState(() {
            salesExecutives = uniqueExecutives.values.toList();
            isLoadingSalesExecutives = false;
          });
          print('Fetched ${salesExecutives.length} sales executives');
        } else {
          setState(() {
            salesExecutivesErrorMessage = responseData['message'] ?? 'Failed to load sales executives';
            isLoadingSalesExecutives = false;
          });
        }
      } else {
        setState(() {
          salesExecutivesErrorMessage = 'Server error: ${response.statusCode}';
          isLoadingSalesExecutives = false;
        });
      }
    } catch (e) {
      print('Error fetching sales executives: $e');
      setState(() {
        salesExecutivesErrorMessage = 'Connection error: $e';
        isLoadingSalesExecutives = false;
      });
    }
  }

  // API call to get routes
  Future<void> _fetchRoutes() async {
    setState(() {
      isLoadingRoutes = true;
      routesErrorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.108/gst-3-3-production/mobile-service/vansales/get_routes.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "unid": "20260117130317",
          "veh": "MQ--"
        }),
      );

      print('Routes API Response Status: ${response.statusCode}');
      print('Routes API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['result'] == "1") {
          final List<dynamic> routes = responseData['routedet'];

          // Use a map to track unique IDs for routes too
          Map<String, Map<String, dynamic>> uniqueRoutes = {};

          for (var i = 0; i < routes.length; i++) {
            var item = routes[i];
            String id = (item['rtid'] ?? i.toString()).toString();
            String name = item['route_name'] ?? 'Route ${i + 1}';

            // If ID already exists, append index to make it unique
            if (uniqueRoutes.containsKey(id)) {
              id = "${id}_$i";
            }

            uniqueRoutes[id] = {
              'id': id,
              'name': name
            };
          }

          setState(() {
            routesList = uniqueRoutes.values.toList();
            isLoadingRoutes = false;
          });
          print('Fetched ${routesList.length} routes');

          // Optionally select the first route by default
          if (routesList.isNotEmpty && perdayroute == null) {
            setState(() {
              perdayroute = routesList[0]['id'];
            });
          }
        } else {
          setState(() {
            routesErrorMessage = responseData['message'] ?? 'Failed to load routes';
            isLoadingRoutes = false;
          });
        }
      } else {
        setState(() {
          routesErrorMessage = 'Server error: ${response.statusCode}';
          isLoadingRoutes = false;
        });
      }
    } catch (e) {
      print('Error fetching routes: $e');
      setState(() {
        routesErrorMessage = 'Connection error: $e';
        isLoadingRoutes = false;
      });
    }
  }

  // ========== ADDED: API call to insert customer ==========
  Future<void> _insertCustomer() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      // Find selected values
      final selectedCustomerType = customerTypes.firstWhere(
            (type) => type['id'] == typeofcustomer,
        orElse: () => {'id': '', 'name': ''},
      );

      final selectedSalesExecutive = salesExecutives.firstWhere(
            (exec) => exec['id'] == salesexetype,
        orElse: () => {'id': '', 'name': ''},
      );

      final selectedRoute = routesList.firstWhere(
            (route) => route['id'] == perdayroute,
        orElse: () => {'id': '', 'name': ''},
      );

      // Prepare request body matching your Postman example
      final Map<String, dynamic> requestBody = {
        "unid": "20260117130317",
        "veh": "MQ--",
        "action": "insert",
        "slex": selectedSalesExecutive['name'],
        "cust_type": selectedCustomerType['name'],
        "cust_name": customerNameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "address": addressController.text.trim(),
        "gst_number": gstController.text.trim(),
        "land_phone": landPhoneController.text.trim(),
        "op_bln": openingBalanceController.text.isNotEmpty ? openingBalanceController.text.trim() : "0",
        "op_acc": valgrp ?? "credit",
        "state": stateController.text.trim(),
        "state_code": stateCodeController.text.trim(),
        "credit_days": creditDaysController.text.isNotEmpty ? creditDaysController.text.trim() : "0",
        "route": selectedRoute['name'],
      };

      print('========== CUSTOMER INSERT API CALL ==========');
      print('URL: http://192.168.1.108/gst-3-3-production/mobile-service/vansales/action/customers.php');
      print('Request Body: ${json.encode(requestBody)}');

      // Make API call
      final response = await http.post(
        Uri.parse('http://192.168.20.103/gst-3-3-production/mobile-service/vansales/action/customers.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Customer Insert API Response Status: ${response.statusCode}');
      print('Customer Insert API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['result'] == "1") {
          // Success
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message'] ?? 'Customer added successfully!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );

            // Clear form after successful submission
            _clearForm();

            // Navigate back after delay
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pop(context, true);
              }
            });
          }
        } else {
          // API returned error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message'] ?? 'Failed to add customer. Please try again.'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // HTTP error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server error: ${response.statusCode}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error inserting customer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // Helper method to clear form
  void _clearForm() {
    customerNameController.clear();
    gstController.clear();
    emailController.clear();
    phoneController.clear();
    landPhoneController.clear();
    addressController.clear();
    stateController.clear();
    stateCodeController.clear();
    openingBalanceController.clear();
    creditDaysController.clear();

    setState(() {
      typeofcustomer = null;
      salesexetype = null;
      valgrp = null;
      perdayroute = null;
      formSubmitted = false;
    });
  }

  // Retry functions
  Future<void> _retrySalesExecutives() async {
    await _fetchSalesExecutives();
  }

  Future<void> _retryRoutes() async {
    await _fetchRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Add New Customer",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ================= SECTION 1: BASIC INFO =================
                _buildSectionHeader("Basic Information"),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildCustomerTypeDropdown(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSalesExecutiveDropdown(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: customerNameController,
                        label: "Customer Name",
                        icon: Icons.person_outline,
                        validator: _required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: gstController,
                        label: "GST Number *",
                        icon: Icons.numbers,
                        validator: _required,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ================= SECTION 2: CONTACT INFO =================
                _buildSectionHeader("Contact Information"),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: emailController,
                        label: "Email Address",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: _emailValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: phoneController,
                        label: "Phone Number *",
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: _phoneValidator,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Land Phone field
                _buildTextField(
                  controller: landPhoneController,
                  label: "Land Phone",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: null,
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: addressController,
                  label: "Address *",
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                  validator: _required,
                ),

                const SizedBox(height: 16),

                // State and State Code fields
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: stateController,
                        label: "State",
                        icon: Icons.map_outlined,
                        validator: null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: stateCodeController,
                        label: "State Code",
                        icon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                        validator: null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ================= SECTION 3: FINANCIAL INFO =================
                _buildSectionHeader("Financial Information"),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: creditDaysController,
                        label: "Credit Days *",
                        icon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                        validator: _numberRequired,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: openingBalanceController,
                        label: "Opening Balance *",
                        icon: Icons.account_balance_wallet_outlined,
                        keyboardType: TextInputType.number,
                        validator: _numberRequired,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Dr/Cr Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Balance Type *",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildRadioOption("Dr", Icons.arrow_downward),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildRadioOption("Cr", Icons.arrow_upward),
                        ),
                      ],
                    ),
                    if (valgrp == null && formSubmitted)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text(
                          "Required",
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // ================= SECTION 4: ADDITIONAL INFO =================
                _buildSectionHeader("Additional Information"),
                const SizedBox(height: 16),

                _buildRoutesDropdown(),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: Colors.blue.shade200,
                    ),
                    onPressed: isSubmitting ? null : _submit,
                    child: isSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          "ADD CUSTOMER",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
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

  // ================= UI COMPONENTS =================

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCustomerTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Type of Customer *",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: typeofcustomer,
                isExpanded: true,
                hint: isLoadingCustomerTypes
                    ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      SizedBox(width: 8),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Loading...",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
                    : customerTypesErrorMessage != null
                    ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade400,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Error",
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                )
                    : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Select type",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                items: customerTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['id'],
                    child: Text(
                      type['name'],
                      style: TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    typeofcustomer = newValue;
                  });
                },
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[600],
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        if (typeofcustomer == null && formSubmitted && !isLoadingCustomerTypes && customerTypesErrorMessage == null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              "Required",
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
      ],
    );
  }

  Widget _buildSalesExecutiveDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sales Executive *",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: salesexetype,
                isExpanded: true,
                hint: isLoadingSalesExecutives
                    ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      SizedBox(width: 8),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Loading...",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
                    : salesExecutivesErrorMessage != null
                    ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade400,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Error",
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                )
                    : salesExecutives.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange.shade400,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "No executives",
                          style: TextStyle(
                            color: Colors.orange.shade400,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
                    : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Select executive",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                items: salesExecutives.map((executive) {
                  return DropdownMenuItem<String>(
                    value: executive['id'],
                    child: Text(
                      executive['name'],
                      style: TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    salesexetype = newValue;
                  });
                },
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[600],
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        if (salesExecutivesErrorMessage != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    salesExecutivesErrorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _retrySalesExecutives,
                  child: Text(
                    "Retry",
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (salesexetype == null && formSubmitted && !isLoadingSalesExecutives && salesExecutivesErrorMessage == null && salesExecutives.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              "Required",
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
      ],
    );
  }

  Widget _buildRoutesDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Collection Route *",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: perdayroute,
                isExpanded: true,
                hint: isLoadingRoutes
                    ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      SizedBox(width: 8),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Loading routes...",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
                    : routesErrorMessage != null
                    ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade400,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Error loading routes",
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                )
                    : routesList.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange.shade400,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "No routes available",
                          style: TextStyle(
                            color: Colors.orange.shade400,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
                    : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Select route",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                items: routesList.map((route) {
                  return DropdownMenuItem<String>(
                    value: route['id'],
                    child: Text(
                      route['name'],
                      style: TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    perdayroute = newValue;
                  });
                },
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[600],
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        if (routesErrorMessage != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    routesErrorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _retryRoutes,
                  child: Text(
                    "Retry",
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (perdayroute == null && formSubmitted && !isLoadingRoutes && routesErrorMessage == null && routesList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              "Required",
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade600!, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildRadioOption(String value, IconData icon) {
    return InkWell(
      onTap: () => setState(() => valgrp = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.35,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: valgrp == value
              ? value == "Dr"
              ? Colors.red.shade50
              : Colors.green.shade50
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: valgrp == value
                ? value == "Dr"
                ? Colors.red.shade300
                : Colors.green.shade300
                : Colors.grey[300]!,
            width: valgrp == value ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: valgrp == value
                  ? value == "Dr"
                  ? Colors.red
                  : Colors.green
                  : Colors.grey[600],
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: valgrp == value ? FontWeight.w600 : FontWeight.w500,
                  color: valgrp == value
                      ? value == "Dr"
                      ? Colors.red
                      : Colors.green
                      : Colors.grey[700],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= VALIDATORS =================

  String? _required(String? v) =>
      v == null || v.isEmpty ? "Required" : null;

  String? _numberRequired(String? v) =>
      v == null || int.tryParse(v) == null
          ? "Enter valid number"
          : null;

  String? _emailValidator(String? v) =>
      v == null ||
          !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)
          ? "Enter valid email"
          : null;

  String? _phoneValidator(String? v) =>
      v == null || v.length != 10
          ? "Enter 10 digit phone"
          : null;

  // ================= SUBMIT =================

  void _submit() {
    // Set formSubmitted to true to show validation messages
    setState(() {
      formSubmitted = true;
    });

    // Check if all data is loaded
    if (isLoadingCustomerTypes || isLoadingSalesExecutives || isLoadingRoutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please wait while loading data..."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (customerTypesErrorMessage != null ||
        salesExecutivesErrorMessage != null ||
        routesErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fix errors before submitting"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate text fields first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Then validate dropdowns
    if (typeofcustomer == null ||
        salesexetype == null ||
        valgrp == null ||
        perdayroute == null) {
      // Show specific error messages
      if (typeofcustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select customer type"),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (salesexetype == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select sales executive"),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (perdayroute == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select collection route"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Call the API to insert customer
    _insertCustomer();
  }
}