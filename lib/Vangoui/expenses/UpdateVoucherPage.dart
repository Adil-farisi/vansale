import 'package:flutter/material.dart';

class UpdateVoucherPage extends StatefulWidget {
  final Map<String, dynamic> voucher;

  const UpdateVoucherPage({super.key, required this.voucher});

  @override
  State<UpdateVoucherPage> createState() => _UpdateVoucherPageState();
}

class _UpdateVoucherPageState extends State<UpdateVoucherPage> {
  late Map<String, dynamic> voucherData;

  // List to store multiple items
  List<Map<String, dynamic>> items = [];

  // Controllers for the input section
  late TextEditingController particularsCtrl;
  late TextEditingController categoryCtrl;
  late TextEditingController amountCtrl;

  // Controllers for the third section
  late TextEditingController totalAmountCtrl;
  late TextEditingController roundoffCtrl;
  late TextEditingController netAmountCtrl;
  late TextEditingController supplierNameCtrl;
  late TextEditingController purchaseRefCtrl;
  late TextEditingController notesCtrl;

  // Variables for edit functionality
  int? editingIndex;
  bool isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _itemFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    voucherData = widget.voucher;

    // Initialize items list from voucher data
    if (voucherData['items'] != null) {
      items = List<Map<String, dynamic>>.from(voucherData['items']);
    } else {
      // Add default item if none exists
      items = [
        {
          'particulars': 'Dffdfsdfsf',
          'category': 'Bill',
          'amount': 2600.00,
        }
      ];
    }

    // Initialize controllers
    particularsCtrl = TextEditingController();
    categoryCtrl = TextEditingController();
    amountCtrl = TextEditingController();

    totalAmountCtrl = TextEditingController(
      text: _calculateTotalAmount().toStringAsFixed(2),
    );
    roundoffCtrl = TextEditingController(text: '0.00');
    netAmountCtrl = TextEditingController(
      text: _calculateNetAmount().toStringAsFixed(2),
    );
    supplierNameCtrl = TextEditingController(
      text: voucherData['paidTo'] ?? 'ashal',
    );
    purchaseRefCtrl = TextEditingController(
      text: voucherData['purchaseRef']?.toString() ?? '',
    );
    notesCtrl = TextEditingController(text: 'Update');
  }

  @override
  void dispose() {
    particularsCtrl.dispose();
    categoryCtrl.dispose();
    amountCtrl.dispose();
    totalAmountCtrl.dispose();
    roundoffCtrl.dispose();
    netAmountCtrl.dispose();
    supplierNameCtrl.dispose();
    purchaseRefCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  double _calculateTotalAmount() {
    double total = 0;
    for (var item in items) {
      total += (item['amount'] as num).toDouble();
    }
    return total;
  }

  double _calculateNetAmount() {
    double total = _calculateTotalAmount();
    double roundoff = double.tryParse(roundoffCtrl.text) ?? 0;
    return total + roundoff;
  }

  void _updateAmounts() {
    setState(() {
      totalAmountCtrl.text = _calculateTotalAmount().toStringAsFixed(2);
      netAmountCtrl.text = _calculateNetAmount().toStringAsFixed(2);
    });
  }

  void _clearItemForm() {
    particularsCtrl.clear();
    categoryCtrl.clear();
    amountCtrl.clear();
    setState(() {
      isEditing = false;
      editingIndex = null;
    });
  }

  void _addOrUpdateItem() {
    if (_itemFormKey.currentState?.validate() ?? false) {
      setState(() {
        Map<String, dynamic> newItem = {
          'particulars': particularsCtrl.text,
          'category': categoryCtrl.text,
          'amount': double.parse(amountCtrl.text),
        };

        if (isEditing && editingIndex != null) {
          // Update existing item
          items[editingIndex!] = newItem;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Item updated successfully"), backgroundColor: Colors.blue, duration: Duration(seconds: 1)),
          );
        } else {
          // Add new item
          items.add(newItem);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Item added successfully"), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
          );
        }

        _clearItemForm();
        _updateAmounts();
      });
    }
  }

  void _editItem(int index) {
    setState(() {
      particularsCtrl.text = items[index]['particulars'];
      categoryCtrl.text = items[index]['category'];
      amountCtrl.text = items[index]['amount'].toString();
      isEditing = true;
      editingIndex = index;
    });

    // Scroll to the top
    Scrollable.ensureVisible(
      context,
      alignment: 0.1,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Item"),
          content: const Text("Are you sure you want to delete this item?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  items.removeAt(index);
                  if (editingIndex == index) {
                    _clearItemForm();
                  }
                  _updateAmounts();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Item deleted successfully"), backgroundColor: Colors.red, duration: Duration(seconds: 1)),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("DELETE"),
            ),
          ],
        );
      },
    );
  }

  void _updateVoucher() {
    if (_formKey.currentState?.validate() ?? false) {
      // Update voucher logic here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Voucher updated successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          "Update Voucher No : ${voucherData['voucherNo'] ?? '8'}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION 1: Add/Edit Item Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _itemFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Particulars",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Category",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Amount",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(width: 60), // Space for button
                          ],
                        ),
                      ),

                      // Input Fields Row
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Particulars Field
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: particularsCtrl,
                                decoration: InputDecoration(
                                  hintText: "Enter particulars",
                                  hintStyle: const TextStyle(fontSize: 11),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 10,
                                  ),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 12),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Category Field
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: categoryCtrl,
                                decoration: InputDecoration(
                                  hintText: "Category",
                                  hintStyle: const TextStyle(fontSize: 11),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 10,
                                  ),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 12),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Amount Field
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: amountCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                decoration: InputDecoration(
                                  hintText: "0.00",
                                  hintStyle: const TextStyle(fontSize: 11),
                                  prefixText: '₹ ',
                                  prefixStyle: const TextStyle(fontSize: 11),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 10,
                                  ),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 12),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Empty space for button alignment
                            const SizedBox(width: 60),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Button Row (separate row for buttons)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Cancel button (only when editing)
                          if (isEditing) ...[
                            TextButton(
                              onPressed: _clearItemForm,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                minimumSize: const Size(0, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: const Text("Cancel", style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Add/Update Button
                          SizedBox(
                            width: 80,
                            child: ElevatedButton(
                              onPressed: _addOrUpdateItem,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEditing ? Colors.orange : Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                minimumSize: const Size(0, 40),
                              ),
                              child: Text(
                                isEditing ? "UPDATE" : "ADD",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // SECTION 2: Items List Section
              if (items.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 35,
                              child: Text(
                                "S.No",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Particulars",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Category",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Amount",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: const Icon(Icons.more_vert, size: 16, color: Colors.transparent),
                            ),
                          ],
                        ),
                      ),

                      // Items List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                // S.No
                                Container(
                                  width: 35,
                                  child: Text(
                                    "${index + 1}",
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                // Particulars
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    item['particulars'],
                                    style: const TextStyle(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Category
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item['category'],
                                    style: const TextStyle(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Amount
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '₹ ${_formatCurrency((item['amount'] as num).toDouble())}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                  ),
                                ),
                                // 3-dot menu for edit/delete
                                Container(
                                  width: 40,
                                  alignment: Alignment.center,
                                  child: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 18),
                                    padding: EdgeInsets.zero,
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editItem(index);
                                      } else if (value == 'delete') {
                                        _deleteItem(index);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 16, color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Edit', style: TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 16, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // SECTION 3: Voucher Details Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First Row: Total, Roundoff, Net Amount
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Total",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "₹",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      totalAmountCtrl.text,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Roundoff",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              TextFormField(
                                controller: roundoffCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  prefixText: '₹ ',
                                  prefixStyle: const TextStyle(fontSize: 11),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 11),
                                onChanged: (value) {
                                  setState(() {
                                    netAmountCtrl.text = _calculateNetAmount().toStringAsFixed(2);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Net",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  border: Border.all(color: Colors.green.shade200),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "₹",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    Text(
                                      netAmountCtrl.text,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
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

                    const SizedBox(height: 12),

                    // Supplier Name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Supplier",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        TextFormField(
                          controller: supplierNameCtrl,
                          decoration: InputDecoration(
                            hintText: "Enter supplier name",
                            hintStyle: const TextStyle(fontSize: 11),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 12),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Purchase Reference
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Ref No",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        TextFormField(
                          controller: purchaseRefCtrl,
                          decoration: InputDecoration(
                            hintText: "Enter reference",
                            hintStyle: const TextStyle(fontSize: 11),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Notes
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Notes",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        TextFormField(
                          controller: notesCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: "Enter notes",
                            hintStyle: const TextStyle(fontSize: 11),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Update Voucher Button
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _updateVoucher,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          "UPDATE VOUCHER",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}