import 'package:flutter/material.dart';

class NewPaymentPage extends StatefulWidget {
  const NewPaymentPage({super.key});

  @override
  State<NewPaymentPage> createState() => _NewPaymentPageState();
}

class _NewPaymentPageState extends State<NewPaymentPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController supplierController = TextEditingController();
  final TextEditingController dueAmountController = TextEditingController(
    text: '25,000.00',
  );
  final TextEditingController paidDateController = TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // Variables
  String? selectedPaymentType = 'Bank'; // 'Cash' or 'Bank'
  bool isSubmitting = false;
  bool formSubmitted = false;

  // Hardcoded supplier list for dropdown
  final List<String> suppliers = [
    'Ganesh Traders',
    'Kumar Enterprises',
    'Sri Lakshmi Agencies',
    'Murugan Store',
    'Vinayaga Enterprises',
    'Balaji Traders',
    'Sri Venkateswara Stores',
  ];

  @override
  void initState() {
    super.initState();
    // Set default date to today
    final now = DateTime.now();
    paidDateController.text =
        "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
  }

  @override
  void dispose() {
    supplierController.dispose();
    dueAmountController.dispose();
    paidDateController.dispose();
    paidAmountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  // Validators
  String? _required(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _amountValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    if (!RegExp(
      r'^[0-9]+(\.[0-9]{1,2})?$',
    ).hasMatch(value.replaceAll(',', ''))) {
      return 'Invalid amount';
    }
    return null;
  }

  String? _dateValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    // Basic date format check (DD-MM-YYYY)
    if (!RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(value)) {
      return 'Use DD-MM-YYYY format';
    }
    return null;
  }

  void _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        paidDateController.text =
            "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
      });
    }
  }

  void _submit() {
    setState(() {
      formSubmitted = true;
    });

    if (_formKey.currentState!.validate() && selectedPaymentType != null) {
      setState(() {
        isSubmitting = true;
      });

      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;

        setState(() {
          isSubmitting = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment to ${supplierController.text} saved successfully!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Navigate back with success result
        Navigator.pop(context, true);
      });
    } else if (selectedPaymentType == null && formSubmitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select payment type (Cash/Bank)'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    bool readOnly = false,
    VoidCallback? onTap,
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
          height: maxLines > 1 ? 100 : 56,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.blue.shade600, size: 20),
              suffixIcon:
                  readOnly && onTap != null
                      ? Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.blue.shade600,
                      )
                      : null,
              filled: true,
              fillColor: readOnly ? Colors.grey.shade100 : Colors.grey.shade50,
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

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
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
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(icon, color: Colors.blue.shade600, size: 20),
              ),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    hint: Text('Select $label'),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    items:
                        items.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Amount From',
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
              color: selectedPaymentType == null && formSubmitted
                  ? Colors.red.shade400
                  : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedPaymentType,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select payment source',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              isExpanded: true,
              icon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey.shade700,
                  size: 24,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'Cash',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.money,
                          size: 18,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Cash',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Bank',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance,
                          size: 18,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Bank',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedPaymentType = value;
                });
              },
            ),
          ),
        ),
        if (selectedPaymentType == null && formSubmitted)
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
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // App Bar
      appBar: AppBar(
        title: const Text(
          'New Payment',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
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
                // Supplier Name Dropdown
                _buildDropdownField(
                  label: 'Supplier Name',
                  icon: Icons.business,
                  value:
                      supplierController.text.isEmpty
                          ? null
                          : supplierController.text,
                  items: suppliers,
                  onChanged: (value) {
                    setState(() {
                      supplierController.text = value ?? '';
                    });
                  },
                  isRequired: true,
                ),

                const SizedBox(height: 16),

                // Due Amount (Read Only)
                _buildTextField(
                  controller: dueAmountController,
                  label: "Due Amount",
                  icon: Icons.account_balance_wallet_outlined,
                  keyboardType: TextInputType.number,
                  validator: _amountValidator,
                  isRequired: true,
                  readOnly: true,
                ),

                const SizedBox(height: 16),

                // Paid Date (with Date Picker)
                _buildTextField(
                  controller: paidDateController,
                  label: "Paid Date",
                  icon: Icons.calendar_today,
                  validator: _dateValidator,
                  isRequired: true,
                  readOnly: true,
                  onTap: _selectDate,
                ),

                const SizedBox(height: 16),

                // Paid Amount
                _buildTextField(
                  controller: paidAmountController,
                  label: "Paid Amount",
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                  validator: _amountValidator,
                  isRequired: true,
                ),

                const SizedBox(height: 16),

                // Amount From (Cash/Bank Selector)
                _buildPaymentTypeSelector(),

                const SizedBox(height: 16),

                // Notes
                _buildTextField(
                  controller: notesController,
                  label: "Notes",
                  icon: Icons.note_outlined,
                  maxLines: 3,
                  validator: null,
                ),

                const SizedBox(height: 40),

                // Save Button
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
                                Icon(Icons.save, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  "SAVE PAYMENT",
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
