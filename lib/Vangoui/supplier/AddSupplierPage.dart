import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddSupplierPage extends StatefulWidget {
  const AddSupplierPage({super.key});

  @override
  State<AddSupplierPage> createState() => _AddSupplierPageState();
}

class _AddSupplierPageState extends State<AddSupplierPage> {
  final _formKey = GlobalKey<FormState>();

  // API variables
  String unid = '';
  String veh = '';
  final String apiUrl =
      "http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/action/suppliers.php";

  // Controllers for form fields
  final TextEditingController supplierNameController = TextEditingController();
  final TextEditingController gstController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController landPhoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController stateCodeController = TextEditingController();
  final TextEditingController openingBalanceController =
      TextEditingController();

  // Variables
  String? selectedBalanceType = "Dr"; // Default selection
  bool isSubmitting = false;
  bool formSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  @override
  void dispose() {
    supplierNameController.dispose();
    gstController.dispose();
    emailController.dispose();
    phoneController.dispose();
    landPhoneController.dispose();
    addressController.dispose();
    stateController.dispose();
    stateCodeController.dispose();
    openingBalanceController.dispose();
    super.dispose();
  }

  // Load session data from SharedPreferences
  Future<void> _loadSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        unid = prefs.getString('unid') ?? '';
        veh = prefs.getString('veh') ?? '';
      });
      print("🔑 Session loaded - unid: $unid, veh: $veh");
    } catch (e) {
      print("❌ Error loading session: $e");
    }
  }

  // Validators
  String? _required(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Invalid email';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    String cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^[0-9]{10}$').hasMatch(cleaned)) {
      return '10 digits required';
    }
    return null;
  }

  String? _landPhoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    String cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^[0-9]{8,12}$').hasMatch(cleaned)) {
      return '8-12 digits';
    }
    return null;
  }

  String? _gstValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    if (!RegExp(r'^[0-9]+(\.[0-9]{1,2})?$').hasMatch(value)) {
      return 'Invalid number';
    }
    return null;
  }

  // Submit form to API
  Future<void> _submit() async {
    setState(() {
      formSubmitted = true;
    });

    if (!_formKey.currentState!.validate() || selectedBalanceType == null) {
      if (selectedBalanceType == null && formSubmitted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select balance type (Dr/Cr)'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Prepare request body as per API specification
      Map<String, dynamic> requestBody = {
        "unid": unid,
        "veh": veh,
        "action": "insert",
        "supp_name": supplierNameController.text.trim(),
        "email":
            emailController.text.trim().isEmpty
                ? ""
                : emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "address": addressController.text.trim(),
        "gst_number":
            gstController.text.trim().isEmpty ? "" : gstController.text.trim(),
        "land_phone":
            landPhoneController.text.trim().isEmpty
                ? ""
                : landPhoneController.text.trim(),
        "op_bln": openingBalanceController.text.trim(),
        "op_acc": selectedBalanceType?.toLowerCase() ?? "dr",
        "state": stateController.text.trim(),
        "state_code": stateCodeController.text.trim(),
      };

      print("📤 Sending request to: $apiUrl");
      print("📤 Request body: ${json.encode(requestBody)}");

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

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['result'] == "1") {
          // Success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData['message'] ?? 'Supplier added successfully!',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate back with success result
          Navigator.pop(context, true);
        } else {
          // API returned error
          String errorMessage =
              responseData['message'] ?? 'Failed to add supplier';
          errorMessage = errorMessage.replaceAll(RegExp(r'<[^>]*>'), '');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // HTTP error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error: ${response.statusCode}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print("❌ Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.blue.shade600, size: 20),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.red.shade400),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'Add New Supplier',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
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
                _buildSectionHeader("Basic Information"),

                // Supplier Name and GST Number
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildTextField(
                        controller: supplierNameController,
                        label: "Supplier Name",
                        icon: Icons.business_outlined,
                        validator: _required,
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _buildTextField(
                        controller: gstController,
                        label: "GST No",
                        icon: Icons.numbers,
                        validator: _gstValidator,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _buildSectionHeader("Contact Information"),

                // Email
                _buildTextField(
                  controller: emailController,
                  label: "Email",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                ),

                const SizedBox(height: 16),

                // Phone Number
                _buildTextField(
                  controller: phoneController,
                  label: "Phone No",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: _phoneValidator,
                  isRequired: true,
                ),

                const SizedBox(height: 16),

                // Land Phone
                _buildTextField(
                  controller: landPhoneController,
                  label: "Land Phone",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: _landPhoneValidator,
                ),

                const SizedBox(height: 16),

                // Address
                _buildTextField(
                  controller: addressController,
                  label: "Address",
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                  validator: _required,
                  isRequired: true,
                ),

                const SizedBox(height: 16),

                // State and State Code
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: stateController,
                        label: "State",
                        icon: Icons.map_outlined,
                        validator: _required,
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: stateCodeController,
                        label: "State Code",
                        icon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                        validator: _required,
                        isRequired: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Opening Balance and Balance Type
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Opening Balance
                    Expanded(
                      flex: 1,
                      child: _buildTextField(
                        controller: openingBalanceController,
                        label: "Opening Balance",
                        icon: Icons.account_balance_wallet_outlined,
                        keyboardType: TextInputType.number,
                        validator: _numberValidator,
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Balance Type
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Balance Type",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                ' *',
                                style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    selectedBalanceType == null && formSubmitted
                                        ? Colors.red.shade400
                                        : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Dr Option
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedBalanceType = "Dr";
                                      });
                                    },
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomLeft: Radius.circular(10),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            selectedBalanceType == "Dr"
                                                ? Colors.blue.shade50
                                                : Colors.transparent,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          bottomLeft: Radius.circular(10),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Radio<String>(
                                            value: "Dr",
                                            groupValue: selectedBalanceType,
                                            onChanged: (value) {
                                              setState(() {
                                                selectedBalanceType = value;
                                              });
                                            },
                                            activeColor: Colors.blue.shade700,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          const Text(
                                            "Dr",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Divider
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.grey.shade300,
                                ),

                                // Cr Option
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedBalanceType = "Cr";
                                      });
                                    },
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            selectedBalanceType == "Cr"
                                                ? Colors.blue.shade50
                                                : Colors.transparent,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(10),
                                          bottomRight: Radius.circular(10),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Radio<String>(
                                            value: "Cr",
                                            groupValue: selectedBalanceType,
                                            onChanged: (value) {
                                              setState(() {
                                                selectedBalanceType = value;
                                              });
                                            },
                                            activeColor: Colors.blue.shade700,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          const Text(
                                            "Cr",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
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
                          if (selectedBalanceType == null && formSubmitted)
                            Padding(
                              padding: const EdgeInsets.only(left: 8, top: 4),
                              child: Text(
                                "Required",
                                style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Add Supplier Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: Colors.blue.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isSubmitting ? null : _submit,
                    child:
                        isSubmitting
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  "ADD SUPPLIER",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
