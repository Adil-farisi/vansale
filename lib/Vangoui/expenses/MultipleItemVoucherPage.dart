import 'package:flutter/material.dart';

class MultipleItemVoucherPage extends StatefulWidget {
  const MultipleItemVoucherPage({super.key});

  @override
  State<MultipleItemVoucherPage> createState() => _MultipleItemVoucherPageState();
}

class _MultipleItemVoucherPageState extends State<MultipleItemVoucherPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController payToCtrl = TextEditingController();
  final TextEditingController voucherNoCtrl = TextEditingController();
  final TextEditingController purchaseRefCtrl = TextEditingController();
  final TextEditingController particularsCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();
  final TextEditingController roundoffCtrl = TextEditingController();
  final TextEditingController paidAmountCtrl = TextEditingController();

  // Focus Nodes
  final FocusNode _roundoffFocusNode = FocusNode();
  final FocusNode _paidAmountFocusNode = FocusNode();

  // Data
  List<Map<String, dynamic>> items = [];
  String? selectedCategory;
  String selectedAmountFrom = "Cash";
  String? selectedItemCategory;

  static int _voucherCounter = 1;

  final List<String> categories = [
    "Petrol",
    "Food",
    "Travel",
    "Maintenance",
    "Office",
    "Bill",
    "Misc"
  ];

  @override
  void initState() {
    super.initState();
    _setTodayDate();
    _setNextVoucherNumber();
    roundoffCtrl.text = "0";
    paidAmountCtrl.text = "0";

    // Add focus listeners
    _roundoffFocusNode.addListener(_onRoundoffFocusChange);
    _paidAmountFocusNode.addListener(_onPaidAmountFocusChange);
  }

  void _onRoundoffFocusChange() {
    if (_roundoffFocusNode.hasFocus && roundoffCtrl.text == "0") {
      // Clear the field when it gains focus and contains "0"
      WidgetsBinding.instance.addPostFrameCallback((_) {
        roundoffCtrl.text = "";
      });
    }
  }

  void _onPaidAmountFocusChange() {
    if (_paidAmountFocusNode.hasFocus && paidAmountCtrl.text == "0") {
      // Clear the field when it gains focus and contains "0"
      WidgetsBinding.instance.addPostFrameCallback((_) {
        paidAmountCtrl.text = "";
      });
    }
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

  void _addItem() {
    if (particularsCtrl.text.isNotEmpty &&
        selectedItemCategory != null &&
        amountCtrl.text.isNotEmpty) {

      setState(() {
        items.add({
          'sno': items.length + 1,
          'particulars': particularsCtrl.text,
          'category': selectedItemCategory,
          'amount': double.parse(amountCtrl.text),
        });

        // Clear item fields
        particularsCtrl.clear();
        amountCtrl.clear();
        selectedItemCategory = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill Particulars, Category and Amount"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _deleteItem(int index) {
    setState(() {
      items.removeAt(index);
      for (int i = 0; i < items.length; i++) {
        items[i]['sno'] = i + 1;
      }
    });
  }

  double get _totalAmount {
    return items.fold(0.0, (sum, item) => sum + (item['amount'] as double));
  }

  double get _roundoff {
    // If field is empty, treat as 0
    if (roundoffCtrl.text.isEmpty) return 0.0;
    return double.tryParse(roundoffCtrl.text) ?? 0.0;
  }

  double get _netAmount {
    return _totalAmount + _roundoff;
  }

  double get _paidAmount {
    // If field is empty, treat as 0
    if (paidAmountCtrl.text.isEmpty) return 0.0;
    return double.tryParse(paidAmountCtrl.text) ?? 0.0;
  }

  double get _balanceDue {
    return _netAmount - _paidAmount;
  }

  @override
  void dispose() {
    // Remove focus listeners
    _roundoffFocusNode.removeListener(_onRoundoffFocusChange);
    _paidAmountFocusNode.removeListener(_onPaidAmountFocusChange);

    // Dispose focus nodes
    _roundoffFocusNode.dispose();
    _paidAmountFocusNode.dispose();

    payToCtrl.dispose();
    voucherNoCtrl.dispose();
    purchaseRefCtrl.dispose();
    particularsCtrl.dispose();
    amountCtrl.dispose();
    dateCtrl.dispose();
    notesCtrl.dispose();
    roundoffCtrl.dispose();
    paidAmountCtrl.dispose();
    super.dispose();
  }

  void _saveVoucher() {
    if (_formKey.currentState!.validate() && items.isNotEmpty) {
      _voucherCounter++;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Voucher #${_voucherCounter - 1} added successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _clearForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least one item"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _clearForm() {
    payToCtrl.clear();
    purchaseRefCtrl.clear();
    particularsCtrl.clear();
    amountCtrl.clear();
    notesCtrl.clear();
    roundoffCtrl.text = "0";
    paidAmountCtrl.text = "0";
    _setTodayDate();

    setState(() {
      items.clear();
      selectedCategory = null;
      selectedItemCategory = null;
      selectedAmountFrom = "Cash";
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
            fontSize: 20,
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Voucher Details Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Voucher Details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Divider(height: 20),

                    // Pay To
                    _buildLabel("Pay To"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: payToCtrl,
                      decoration: _inputDec("Enter payee name", Icons.person),
                      validator: (v) => v == null || v.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),

                    // Date and Voucher No
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Date"),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => _selectDate(context),
                                child: Container(
                                  height: 45,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade800),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(dateCtrl.text)),
                                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Voucher No"),
                              const SizedBox(height: 6),
                              Container(
                                height: 45,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade100,
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.numbers, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    Text(voucherNoCtrl.text),
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
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: purchaseRefCtrl,
                      decoration: _inputDec("Enter reference", Icons.receipt),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Add Items Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Add Items",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Divider(height: 20),

                    // Particulars
                    _buildLabel("Particulars"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: particularsCtrl,
                      decoration: _inputDec("Enter particulars", Icons.description),
                    ),
                    const SizedBox(height: 12),

                    // Category and Amount Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Category"),
                              const SizedBox(height: 6),
                              Container(
                                height: 45,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedItemCategory,
                                    hint: const Text("Select category"),
                                    isExpanded: true,
                                    icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                    items: categories.map((c) =>
                                        DropdownMenuItem(value: c, child: Text(c))
                                    ).toList(),
                                    onChanged: (v) => setState(() => selectedItemCategory = v),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Amount"),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: amountCtrl,
                                decoration: _inputDec("Amount", Icons.currency_rupee),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Add Product Button
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          " Add ",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Items List Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Added Items",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        if (items.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              if (items.isEmpty) return;

                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text(
                                      "Clear All Items",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    content: const Text(
                                      "Are you sure you want to clear all items? ",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          "Cancel",
                                          style: TextStyle(color: Colors.grey.shade700),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            items.clear();
                                          });
                                          Navigator.pop(context);

                                          // Optional: Show a snackbar confirmation
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("All items cleared"),
                                              backgroundColor: Colors.orange,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text("Clear All"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 18),
                            label: const Text("Clear All", style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),

                    if (items.isEmpty) ...[
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              "No items added",
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Divider(height: 20),

                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Center(child: Text("S.No", style: _headerStyle))),
                            Expanded(flex: 3, child: Text("Particulars", style: _headerStyle)),
                            Expanded(flex: 2, child: Text("Category", style: _headerStyle)),
                            Expanded(flex: 2, child: Text("Amount", style: _headerStyle, textAlign: TextAlign.right)),
                            Expanded(flex: 1, child: Center(child: Text("", style: _headerStyle))),
                          ],
                        ),
                      ),

                      // Items List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(flex: 1, child: Center(child: Text(item['sno'].toString()))),
                                Expanded(flex: 3, child: Text(item['particulars'])),
                                Expanded(flex: 2, child: Text(item['category'])),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "₹${item['amount'].toStringAsFixed(0)}",
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      onPressed: () {
                                        final item = items[index];

                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text(
                                                "Delete Item",
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              content: Text(
                                                "Are you sure you want to delete '${item['particulars']}'?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text(
                                                    "Cancel",
                                                    style: TextStyle(color: Colors.grey.shade700),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    _deleteItem(index);
                                                    Navigator.pop(context);

                                                    // Optional: Show a snackbar confirmation
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text("Item deleted successfully"),
                                                        backgroundColor: Colors.orange,
                                                        behavior: SnackBarBehavior.floating,
                                                        duration: const Duration(seconds: 1),
                                                      ),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                  child: const Text("Delete"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bill Summary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryRow("Total Amount", _totalAmount),
                    const SizedBox(height: 12),

                    // Roundoff
                    Row(
                      children: [
                        Expanded(child: Text("Roundoff", style: _summaryLabelStyle)),
                        Expanded(
                          child: TextFormField(
                            controller: roundoffCtrl,
                            focusNode: _roundoffFocusNode,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              hintText: "0",
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Net Amount
                    _buildSummaryRow("Net Amount", _netAmount, isBold: true),
                    const Divider(height: 20),

                    // Paid Amount with Dropdown
                    Row(
                      children: [
                        Expanded(child: Text("Paid Amount", style: _summaryLabelStyle)),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedAmountFrom,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down),
                                      items: const [
                                        DropdownMenuItem(value: "Cash", child: Text("Cash")),
                                        DropdownMenuItem(value: "Bank", child: Text("Bank")),
                                      ],
                                      onChanged: (v) => setState(() => selectedAmountFrom = v!),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: paidAmountCtrl,
                                  focusNode: _paidAmountFocusNode,
                                  textAlign: TextAlign.right,
                                  decoration: InputDecoration(
                                    hintText: "0",
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Balance Due
                    Row(
                      children: [
                        Expanded(child: Text("Balance Due", style: _summaryLabelStyle)),
                        Expanded(
                          child: Text(
                            "₹ ${_balanceDue.toStringAsFixed(0)}",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _balanceDue > 0 ? Colors.orange.shade800 : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Notes
                    Row(
                      children: [
                        Expanded(child: Text("Notes", style: _summaryLabelStyle)),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: notesCtrl,
                            decoration: InputDecoration(
                              hintText: "Enter notes...",
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveVoucher,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  "SAVE & NEW",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 3,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  InputDecoration _inputDec(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
      prefixIcon: Icon(icon, size: 18, color: Colors.blue.shade800),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: isBold ? Colors.blue.shade800 : Colors.grey.shade800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "₹ ${value.toStringAsFixed(0)}",
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.green.shade700 : null,
            ),
          ),
        ),
      ],
    );
  }

  final TextStyle _headerStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.bold);
  final TextStyle _summaryLabelStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
}