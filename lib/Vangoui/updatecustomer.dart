import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:van_go/Vangoui/permissions/permission_provider.dart';
import 'package:van_go/Vangoui/customer_api_service.dart';
import 'package:van_go/Vangoui/customer_model.dart';

class Updatecustomer extends StatefulWidget {
  final CustomerModel customer;
  const Updatecustomer({super.key, required this.customer});

  @override
  State<Updatecustomer> createState() => _UpdatecustomerState();
}

class _UpdatecustomerState extends State<Updatecustomer> {
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

  // Track if form was submitted
  bool formSubmitted = false;
  bool isUpdating = false;
  bool isLoadingSessionData = true;
  bool isLoadingDropdowns = false;
  String sessionError = '';
  String dropdownError = '';

  String unid = '';
  String veh = '';
  late CustomerApiService customerApiService;

  // Lists for dropdowns
  List<Map<String, dynamic>> customerTypes = [];
  List<Map<String, dynamic>> salesExecutives = [];
  List<Map<String, dynamic>> routesList = [];

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loadedUnid = prefs.getString('unid') ?? '';
      final loadedVeh = prefs.getString('veh') ?? '';

      print('🔍 UPDATE DEBUG: Loaded from SharedPreferences - unid: $loadedUnid, veh: $loadedVeh');

      if (!mounted) return;

      setState(() {
        unid = loadedUnid;
        veh = loadedVeh;
        isLoadingSessionData = false;
      });

      if (unid.isEmpty || veh.isEmpty) {
        setState(() {
          sessionError = 'Session data missing. Please login again.';
        });
        return;
      }

      customerApiService = CustomerApiService();
      _loadCustomerData();
      await _fetchDropdownData();
    } catch (e) {
      print('❌ UPDATE DEBUG: Error loading session data: $e');
      if (mounted) {
        setState(() {
          isLoadingSessionData = false;
          sessionError = 'Failed to load session data: $e';
        });
      }
    }
  }

  Future<void> _fetchDropdownData() async {
    if (!mounted) return;

    setState(() {
      isLoadingDropdowns = true;
      dropdownError = '';
    });

    try {
      print('📥 UPDATE DEBUG: Fetching dropdown data from API...');

      // Fetch customer types from API
      final List<Map<String, dynamic>> customerTypesFromApi =
      await customerApiService.getCustomerTypes();

      // Fetch sales executives from API
      final List<Map<String, dynamic>> salesExecutivesFromApi =
      await customerApiService.getSalesExecutives();

      // Fetch routes from API
      final List<Map<String, dynamic>> routesFromApi =
      await customerApiService.getRoutes();

      if (!mounted) return;

      // REMOVE DUPLICATES from customer types
      final Map<String, Map<String, dynamic>> uniqueCustomerTypes = {};
      for (var type in customerTypesFromApi) {
        final id = type['id'].toString();
        if (!uniqueCustomerTypes.containsKey(id)) {
          uniqueCustomerTypes[id] = type;
        } else {
          print('⚠️ UPDATE DEBUG: Removing duplicate customer type: $id');
        }
      }
      final List<Map<String, dynamic>> uniqueCustomerTypesList = uniqueCustomerTypes.values.toList();

      // REMOVE DUPLICATES from sales executives
      final Map<String, Map<String, dynamic>> uniqueSalesExecutives = {};
      for (var executive in salesExecutivesFromApi) {
        final id = executive['id'].toString();
        if (!uniqueSalesExecutives.containsKey(id)) {
          uniqueSalesExecutives[id] = executive;
        } else {
          print('⚠️ UPDATE DEBUG: Removing duplicate sales executive: $id');
        }
      }
      final List<Map<String, dynamic>> uniqueSalesExecutivesList = uniqueSalesExecutives.values.toList();

      // Debug: Print all types
      print('🔍 UPDATE DEBUG: Unique customer types:');
      for (var type in uniqueCustomerTypesList) {
        print('🔍 UPDATE DEBUG:   ID: ${type['id']}, Name: ${type['name']}');
      }

      print('🔍 UPDATE DEBUG: Unique sales executives:');
      for (var exec in uniqueSalesExecutivesList) {
        print('🔍 UPDATE DEBUG:   ID: ${exec['id']}, Name: ${exec['name']}');
      }

      print('🔍 UPDATE DEBUG: Routes fetched:');
      for (var route in routesFromApi) {
        print('🔍 UPDATE DEBUG:   ID: ${route['id']}, Name: ${route['name']}');
      }

      // Check if current customer's type exists in API response
      final customerTypeId = widget.customer.custType?.toString() ?? '';
      print('🔍 UPDATE DEBUG: Customer has type ID: $customerTypeId');

      // Find if customer's type exists in API response
      final customerTypeExists = uniqueCustomerTypesList.any(
              (type) => type['id'].toString() == customerTypeId);

      // Check if current customer's sales executive exists in API response
      final salesExecId = widget.customer.slex?.toString() ?? '';
      print('🔍 UPDATE DEBUG: Customer has sales executive ID: $salesExecId');

      // Find if customer's sales executive exists in API response
      final salesExecExists = uniqueSalesExecutivesList.any(
              (exec) => exec['id'].toString() == salesExecId);

      setState(() {
        customerTypes = uniqueCustomerTypesList;
        salesExecutives = uniqueSalesExecutivesList;
        routesList = routesFromApi;

        // Set customer type dropdown value
        if (customerTypeExists && customerTypeId.isNotEmpty) {
          typeofcustomer = customerTypeId;
          print('✅ UPDATE DEBUG: Setting customer type dropdown to: $customerTypeId');
        } else {
          typeofcustomer = null;
          print('⚠️ UPDATE DEBUG: Customer type "$customerTypeId" not found in API, setting to null');
        }

        // Set sales executive dropdown value
        if (salesExecExists && salesExecId.isNotEmpty) {
          salesexetype = salesExecId;
          print('✅ UPDATE DEBUG: Setting sales executive dropdown to: $salesExecId');
        } else {
          salesexetype = null;
          print('⚠️ UPDATE DEBUG: Sales executive "$salesExecId" not found in API, setting to null');
        }

        // Set route dropdown value
        if (routesList.isNotEmpty) {
          perdayroute = routesList[0]['id'].toString();
          print('✅ UPDATE DEBUG: Setting route dropdown to first route: ${routesList[0]['name']}');
        }

        isLoadingDropdowns = false;
      });

      print('✅ UPDATE DEBUG: Dropdown data loaded from API');
      print('✅ UPDATE DEBUG: Customer types: ${customerTypes.length}');
      print('✅ UPDATE DEBUG: Sales executives: ${salesExecutives.length}');
      print('✅ UPDATE DEBUG: Routes: ${routesList.length}');

    } catch (e) {
      print('❌ UPDATE DEBUG: Error fetching dropdown data: $e');
      print('❌ UPDATE DEBUG: Stack trace: ${e.toString()}');
      if (mounted) {
        setState(() {
          isLoadingDropdowns = false;
          dropdownError = 'Failed to load dropdown options: $e';
        });
      }
    }
  }

  void _loadCustomerData() {
    print('📥 UPDATE DEBUG: Loading customer data for ID: ${widget.customer.custid}');
    print('📥 UPDATE DEBUG: Customer type from API: ${widget.customer.custType}');
    print('📥 UPDATE DEBUG: Customer type name from API: ${widget.customer.custTypeName}');
    print('📥 UPDATE DEBUG: Sales executive from API: ${widget.customer.slex}');

    // Load customer data into form fields
    setState(() {
      valgrp = widget.customer.opAcc?.toLowerCase() ?? 'dr';

      // Pre-fill with customer data from API
      customerNameController.text = widget.customer.custname;
      gstController.text = widget.customer.gst;
      emailController.text = widget.customer.email;
      phoneController.text = widget.customer.phone;
      landPhoneController.text = widget.customer.landPhone;
      addressController.text = widget.customer.address;
      stateController.text = widget.customer.state;
      stateCodeController.text = widget.customer.stateCode;
      openingBalanceController.text = widget.customer.opBln.toString();
      creditDaysController.text = widget.customer.creditDays.toString();
    });

    print('✅ UPDATE DEBUG: Customer data loaded into form');
    print('✅ UPDATE DEBUG: Customer has type: ${widget.customer.custType}');
    print('✅ UPDATE DEBUG: Customer has sales executive: ${widget.customer.slex}');
    print('✅ UPDATE DEBUG: Selected balance type: $valgrp');
    print('✅ UPDATE DEBUG: Customer Name: ${customerNameController.text}');
  }

  @override
  Widget build(BuildContext context) {
    // Check permission first
    final permissionProvider = Provider.of<PermissionProvider>(context);

    if (!permissionProvider.canEditCustomer()) {
      return _buildAccessDeniedScreen();
    }

    // Show loading for session data
    if (isLoadingSessionData) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            "Update Customer",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.blue.shade800,
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading session data...'),
            ],
          ),
        ),
      );
    }

    // Show error if session data is missing
    if (sessionError.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            "Update Customer",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.blue.shade800,
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  sessionError,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text('Go Back', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Update Customer",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [


                // Show loading for dropdowns
                if (isLoadingDropdowns) ...[
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading options...'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Show error for dropdowns
                if (dropdownError.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dropdownError,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: _fetchDropdownData,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                        label: "Customer Name *",
                        icon: Icons.person_outline,
                        validator: _required,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: gstController,
                        label: "GST Number",
                        icon: Icons.numbers,
                        validator: null,
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
                  label: "Address",
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                  validator: null,
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
                        label: "Credit Days",
                        icon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                        validator: null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: openingBalanceController,
                        label: "Opening Balance",
                        icon: Icons.account_balance_wallet_outlined,
                        keyboardType: TextInputType.number,
                        validator: null,
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
                      "Balance Type",
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

                _buildRouteDropdown(),

                const SizedBox(height: 32),

                // Update Button
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
                    onPressed: isUpdating ? null : _updateCustomer,
                    child: isUpdating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.update, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          "UPDATE CUSTOMER",
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

  // ================= ACCESS DENIED SCREEN =================
  Scaffold _buildAccessDeniedScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Update Customer",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            const Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'You do not have permission to edit customers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please contact your administrator for access.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
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
              child: DropdownButton<String?>(
                value: typeofcustomer,
                isExpanded: true,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    typeofcustomer == null
                        ? "Select customer type"
                        : "Type ${widget.customer.custType} (not in list)",
                    style: TextStyle(
                      color: typeofcustomer == null ? Colors.grey : Colors.orange,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                items: [
                  // Add the customer's current type if it's not in the list
                  if (typeofcustomer != null &&
                      !customerTypes.any((t) => t['id'].toString() == typeofcustomer))
                    DropdownMenuItem<String?>(
                      value: typeofcustomer,
                      child: Text(
                        "Current Type (${widget.customer.custType})",
                        style: const TextStyle(color: Colors.orange, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ...customerTypes.map((type) {
                    return DropdownMenuItem<String?>(
                      value: type['id'].toString(),
                      child: Text(
                        type['name'].toString(),
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ],
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
        if (typeofcustomer == null && formSubmitted)
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
              child: DropdownButton<String?>(
                value: salesexetype,
                isExpanded: true,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    salesexetype == null
                        ? "Select sales executive"
                        : "Executive ${widget.customer.slex} (not in list)",
                    style: TextStyle(
                      color: salesexetype == null ? Colors.grey : Colors.orange,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                items: [
                  // Add the customer's current sales executive if it's not in the list
                  if (salesexetype != null &&
                      !salesExecutives.any((e) => e['id'].toString() == salesexetype))
                    DropdownMenuItem<String?>(
                      value: salesexetype,
                      child: Text(
                        "Current Executive (${widget.customer.slex})",
                        style: const TextStyle(color: Colors.orange, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ...salesExecutives.map((executive) {
                    return DropdownMenuItem<String?>(
                      value: executive['id'].toString(),
                      child: Text(
                        executive['name'].toString(),
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ],
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
        if (salesexetype == null && formSubmitted)
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

  Widget _buildRouteDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Collection Route",
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
              child: DropdownButton<String?>(
                value: perdayroute,
                isExpanded: true,
                hint: Padding(
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
                  return DropdownMenuItem<String?>(
                    value: route['id'].toString(),
                    child: Text(
                      route['name'].toString(),
                      style: const TextStyle(fontSize: 14),
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
      onTap: () => setState(() => valgrp = value.toLowerCase()),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.35,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: valgrp == value.toLowerCase()
              ? value.toLowerCase() == "dr"
              ? Colors.red.shade50
              : Colors.green.shade50
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: valgrp == value.toLowerCase()
                ? value.toLowerCase() == "dr"
                ? Colors.red.shade300
                : Colors.green.shade300
                : Colors.grey[300]!,
            width: valgrp == value.toLowerCase() ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: valgrp == value.toLowerCase()
                  ? value.toLowerCase() == "dr"
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
                  fontWeight: valgrp == value.toLowerCase() ? FontWeight.w600 : FontWeight.w500,
                  color: valgrp == value.toLowerCase()
                      ? value.toLowerCase() == "dr"
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

  String? _required(String? v) => v == null || v.isEmpty ? "Required" : null;

  String? _emailValidator(String? v) {
    if (v == null || v.isEmpty) return null;
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
      return "Enter valid email";
    }
    return null;
  }

  String? _phoneValidator(String? v) => v == null || v.isEmpty
      ? "Phone number is required"
      : v.length != 10
      ? "Enter 10 digit phone"
      : null;

  // ================= UPDATE FUNCTION WITH API =================

  Future<void> _updateCustomer() async {
    print('🔄 UPDATE DEBUG: Starting update for customer: ${widget.customer.custid}');
    print('🔄 UPDATE DEBUG: Using unid: $unid, veh: $veh');

    // Set formSubmitted to true to show validation messages
    setState(() {
      formSubmitted = true;
    });

    // Validate required fields
    if (typeofcustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select customer type"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (salesexetype == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select sales executive"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate text fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isUpdating = true;
    });

    try {
      // Get selected route name using simple loop instead of firstWhere
      String selectedRouteName = '';
      if (perdayroute != null && routesList.isNotEmpty) {
        for (var route in routesList) {
          if (route['id'].toString() == perdayroute) {
            selectedRouteName = route['name']?.toString() ?? '';
            break;
          }
        }
      }
      print('📤 UPDATE DEBUG: Selected route: $selectedRouteName (ID: $perdayroute)');

      // Call API to update customer
      print('📤 UPDATE DEBUG: Calling update API...');
      print('📤 UPDATE DEBUG: Customer Type ID: $typeofcustomer');
      print('📤 UPDATE DEBUG: Sales Executive ID: $salesexetype');
      print('📤 UPDATE DEBUG: Balance Type: $valgrp');
      print('📤 UPDATE DEBUG: Route Name: $selectedRouteName');

      final result = await customerApiService.updateCustomer(
        cust: widget.customer.custid,
        custType: typeofcustomer ?? '0',
        custName: customerNameController.text,
        slex: salesexetype ?? '',
        email: emailController.text,
        phone: phoneController.text,
        address: addressController.text,
        gstNumber: gstController.text,
        landPhone: landPhoneController.text,
        opBln: openingBalanceController.text.isEmpty ? '0' : openingBalanceController.text,
        opAcc: valgrp ?? 'dr',
        state: stateController.text,
        stateCode: stateCodeController.text,
        creditDays: creditDaysController.text.isEmpty ? '0' : creditDaysController.text,
        route: selectedRouteName,
      );

      setState(() {
        isUpdating = false;
      });

      print('📥 UPDATE DEBUG: API Result: $result');

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Customer updated successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update customer'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isUpdating = false;
      });

      print('❌ UPDATE DEBUG: Error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Clean up controllers
    customerNameController.dispose();
    gstController.dispose();
    emailController.dispose();
    phoneController.dispose();
    landPhoneController.dispose();
    addressController.dispose();
    stateController.dispose();
    stateCodeController.dispose();
    openingBalanceController.dispose();
    creditDaysController.dispose();
    super.dispose();
  }
}