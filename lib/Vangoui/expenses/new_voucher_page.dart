import 'package:flutter/material.dart';

class NewVoucherPage extends StatefulWidget {
  const NewVoucherPage({super.key});

  @override
  State<NewVoucherPage> createState() => _NewVoucherPageState();
}

class _NewVoucherPageState extends State<NewVoucherPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for all text fields
  final TextEditingController payToCtrl = TextEditingController();
  final TextEditingController voucherNoCtrl = TextEditingController();
  final TextEditingController purchaseRefCtrl = TextEditingController();
  final TextEditingController particularsCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController paidAmountCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController();

  // Dropdown values
  String? selectedCategory;
  String selectedAmountFrom = "Cash"; // Default value

  // Static counter for voucher numbers (persists across instances)
  static int _voucherCounter = 1;

  // Categories list
  final List<String> categories = [
    "Petrol",
    "Food",
    "Travel",
    "Vehicle Maintenance",
    "Office Expense",
    "Miscellaneous",
  ];

  // Amount from options (only Cash and Bank now)
  final List<String> amountFromOptions = [
    "Cash",
    "Bank",
  ];

  @override
  void initState() {
    super.initState();
    _setNextVoucherNumber();
    // Set default date to today
    _setTodayDate();
  }

  void _setTodayDate() {
    final now = DateTime.now();
    dateCtrl.text = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
  }

  void _setNextVoucherNumber() {
    voucherNoCtrl.text = _voucherCounter.toString();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        dateCtrl.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  @override
  void dispose() {
    payToCtrl.dispose();
    voucherNoCtrl.dispose();
    purchaseRefCtrl.dispose();
    particularsCtrl.dispose();
    amountCtrl.dispose();
    paidAmountCtrl.dispose();
    notesCtrl.dispose();
    dateCtrl.dispose();
    super.dispose();
  }

  void _saveAndNew() {
    if (_formKey.currentState!.validate()) {
      // Increment voucher counter for next voucher
      _voucherCounter++;

      // Show snack bar that voucher is added
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Voucher #${_voucherCounter - 1} added successfully",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

      // Clear form for new entry but keep the incremented voucher number
      _clearForm();
    }
  }

  void _clearForm() {
    payToCtrl.clear();
    purchaseRefCtrl.clear();
    particularsCtrl.clear();
    amountCtrl.clear();
    paidAmountCtrl.clear();
    notesCtrl.clear();
    // Reset date to today
    _setTodayDate();

    setState(() {
      selectedCategory = null;
      selectedAmountFrom = "Cash";
      // Set the next voucher number (already incremented)
      voucherNoCtrl.text = _voucherCounter.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "New Expense",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
        elevation: 0,
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
            children: [
              // Main Voucher Form Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Pay To Field
                      _buildLabel("Pay To"),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: payToCtrl,
                        decoration: _buildInputDecoration(
                          hint: "Enter payee name",
                          prefixIcon: Icons.person,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter payee name";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Row: Date and Voucher No
                      Row(
                        children: [
                          // Date Field (Selectable)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Date"),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => _selectDate(context),
                                  child: Container(
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 18, color: Colors.blue.shade800),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            dateCtrl.text,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Icon(Icons.arrow_drop_down,
                                            color: Colors.grey.shade600),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Voucher No Field (Read Only)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Voucher No"),
                                const SizedBox(height: 4),
                                Container(
                                  height: 50,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey.shade100,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.numbers,
                                          size: 18, color: Colors.grey.shade600),
                                      const SizedBox(width: 8),
                                      Text(
                                        voucherNoCtrl.text,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
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
                      const SizedBox(height: 16),

                      // Purchase Reference
                      _buildLabel("Purchase Reference"),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: purchaseRefCtrl,
                        decoration: _buildInputDecoration(
                          hint: "Enter purchase reference",
                          prefixIcon: Icons.receipt,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Particulars
                      _buildLabel("Particulars"),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: particularsCtrl,
                        decoration: _buildInputDecoration(
                          hint: "Enter particulars",
                          prefixIcon: Icons.description,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Category Dropdown
                      _buildLabel("Category"),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: _buildInputDecoration(
                          hint: "Select category",
                          prefixIcon: Icons.category,
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please select a category";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Row: Amount and Paid Amount
                      Row(
                        children: [
                          // Amount
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Amount"),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: amountCtrl,
                                  decoration: _buildInputDecoration(
                                    hint: "Amount",
                                    prefixIcon: Icons.currency_rupee,
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Required";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Paid Amount
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Paid Amount"),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: paidAmountCtrl,
                                  decoration: _buildInputDecoration(
                                    hint: "Paid amount",
                                    prefixIcon: Icons.payments,
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Required";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Amount From (Cash/Bank only)
                      _buildLabel("Amount From"),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _buildAmountFromButton("Cash", 0),
                            _buildAmountFromButton("Bank", 1),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      _buildLabel("Notes"),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: notesCtrl,
                        decoration: _buildInputDecoration(
                          hint: "Enter notes (optional)",
                          prefixIcon: Icons.note,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Only Save & New Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saveAndNew,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    "SAVE & NEW",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build individual amount from buttons
  Widget _buildAmountFromButton(String option, int index) {
    bool isSelected = selectedAmountFrom == option;
    int totalButtons = amountFromOptions.length;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedAmountFrom = option;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade800 : Colors.transparent,
            borderRadius: _getBorderRadius(index, totalButtons),
          ),
          child: Text(
            option,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to get border radius for each button
  BorderRadius? _getBorderRadius(int index, int totalButtons) {
    if (index == 0) {
      // First button: rounded left corners only
      return const BorderRadius.only(
        topLeft: Radius.circular(7),
        bottomLeft: Radius.circular(7),
      );
    } else if (index == totalButtons - 1) {
      // Last button: rounded right corners only
      return const BorderRadius.only(
        topRight: Radius.circular(7),
        bottomRight: Radius.circular(7),
      );
    } else {
      // Middle buttons: no border radius
      return null;
    }
  }

  // Helper method to build input decoration
  InputDecoration _buildInputDecoration({
    required String hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.blue.shade800, size: 20)
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  // Helper method to build field labels
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      ),
    );
  }
}