import 'package:flutter/material.dart';

class NewBillingPage extends StatefulWidget {
  const NewBillingPage({super.key});

  @override
  State<NewBillingPage> createState() => _NewBillingPageState();
}

class _NewBillingPageState extends State<NewBillingPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // -------- PAGE 1 CONTROLLERS --------
  final TextEditingController ocQtyCtrl = TextEditingController();
  final TextEditingController ocRateCtrl = TextEditingController();
  final TextEditingController ocGstCtrl = TextEditingController();
  final TextEditingController ocGstAmtCtrl = TextEditingController();
  final TextEditingController ocTotalCtrl = TextEditingController();

  // -------- PAGE 2 CONTROLLERS --------
  final TextEditingController productController = TextEditingController();
  final TextEditingController batchController = TextEditingController();
  final TextEditingController stockQtyController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController rateController = TextEditingController();

  // -------- PAGE 2 EXTRA CONTROLLERS --------
  final TextEditingController discountPercentController =
  TextEditingController();
  final TextEditingController discountAmountController =
  TextEditingController();
  final TextEditingController cgstController = TextEditingController();
  final TextEditingController sgstController = TextEditingController();
  final TextEditingController igstController = TextEditingController();
  final TextEditingController gstAmountController = TextEditingController();
  final TextEditingController totalAmountController = TextEditingController();

  bool includeGST = false;
  bool isCustomerLocked = false;
  bool ocIncludeGST = false;
  bool includeGSTOther = false;

  double _cachedGST = 0;

  // -------- PAGE 4 CONTROLLERS --------
  final TextEditingController totalCtrl = TextEditingController();
  final TextEditingController kfcCtrl = TextEditingController();
  final TextEditingController discCtrl = TextEditingController();
  final TextEditingController roundOffCtrl = TextEditingController();
  final TextEditingController billAmountCtrl = TextEditingController();
  final TextEditingController receivedCtrl = TextEditingController();
  final TextEditingController balanceCtrl = TextEditingController();
  final TextEditingController shippingCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();
  final TextEditingController paymentReceivedCtrl = TextEditingController();

  String amountTo = "Cash";
  String paymentMethod = "Cash";

  // ---------------- CUSTOMER DATA ----------------
  List<String> customers = [
    "Rahul Traders",
    "Anand Stores",
    "Kumar Supermarket",
    "Sree Agencies",
  ];

  // ---------------- PRODUCT MASTER ----------------
  final List<Map<String, dynamic>> products = [
    {
      "code": "P001",
      "name": "Sugar",
      "batch": "B101",
      "stock": "120",
      "rate": "40",
      "gstType": "CGST_SGST",
      "cgst": "2.5",
      "sgst": "2.5",
      "igst": "0",
    },
    {
      "code": "P002",
      "name": "Rice",
      "batch": "R202",
      "stock": "80",
      "rate": "55",
      "gstType": "IGST",
      "cgst": "0",
      "sgst": "0",
      "igst": "5",
    },
  ];

  final List<String> otherChargesList = [
    "Delivery Charge",
    "Service Charge",
    "Packing Charge",
    "Round Off",
    "Labour Charge",
  ];

  final List<Map<String, dynamic>> otherChargesMaster = [
    {"name": "Delivery Charge", "rate": 30.0, "gst": 0.0},
    {"name": "Service Charge", "rate": 50.0, "gst": 18.0},
    {"name": "Packing Charge", "rate": 20.0, "gst": 12.0},
    {"name": "Round Off", "rate": 0.0, "gst": 0.0},
    {"name": "Labour Charge", "rate": 100.0, "gst": 18.0},
  ];

  final Map<String, double> otherChargeGST = {
    "Delivery Charge": 18,
    "Service Charge": 18,
    "Packing Charge": 12,
    "Round Off": 0,
    "Labour Charge": 5,
  };

  Map<String, dynamic>? selectedProduct;

  String? selectedCustomer;
  String? selectedChargeName;

  // ---------------- PRODUCT ACCOUNT ----------------
  String? selectedProductAccount;

  // ---------------- HARDCODED BILLS & RECEIPTS ----------------
  List<Map<String, dynamic>> savedBills = [];
  List<Map<String, dynamic>> receiptHistory = [
    {
      "receiptNo": "1",
      "customer": "Rahul Traders",
      "paymentMethod": "Cash",
      "date": "31/1/2024",
      "time": "14:30",
      "total": "5000.00",
      "gst": "900.00",
      "otherCharges": "100.00",
      "discount": "200.00",
      "billAmount": "5800.00",
      "received": "5800.00",
      "balance": "0.00",
      "items": [
        {
          "productCode": "P001",
          "productName": "Sugar",
          "qty": "100",
          "rate": "40.00",
          "disc": "0.00",
          "gst": "800.00",
          "total": "4000.00",
          "account": "from_stock",
        }
      ],
      "notes": "Sample receipt 1",
    },
    {
      "receiptNo": "2",
      "customer": "Anand Stores",
      "paymentMethod": "Bank",
      "date": "30/1/2024",
      "time": "11:15",
      "total": "3000.00",
      "gst": "540.00",
      "otherCharges": "50.00",
      "discount": "100.00",
      "billAmount": "3490.00",
      "received": "3490.00",
      "balance": "0.00",
      "items": [
        {
          "productCode": "P002",
          "productName": "Rice",
          "qty": "50",
          "rate": "55.00",
          "disc": "50.00",
          "gst": "540.00",
          "total": "2750.00",
          "account": "from_stock",
        }
      ],
      "notes": "Sample receipt 2",
    },
  ];

  String _calculateBalanceInPayment() {
    double bill = double.tryParse(billAmountCtrl.text) ?? 0;
    double received = double.tryParse(paymentReceivedCtrl.text) ?? 0;

    double balance = bill - received;

    return balance.toStringAsFixed(2);
  }

  String formatNumber(dynamic value) {
    if (value == null) return "-";

    final num? number = num.tryParse(value.toString());
    if (number == null) return value.toString();

    // remove decimals
    return number.toStringAsFixed(0);
  }

  // ---------------- UI HELPERS ----------------

  InputDecoration fieldDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
      ),
    );
  }

  Widget _itemTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      color: Colors.grey.shade100,
      child: Row(
        children: const [
          Expanded(
            flex: 1,
            child: Text(
              "No",
              textAlign: TextAlign.left,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Code",
              textAlign: TextAlign.left,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              "Item Name",
              textAlign: TextAlign.left,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Qty",
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "Rate",
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "Amount",
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(flex: 1, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _customerBar() {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 🔹 ROW 1: CUSTOMER + ADD BUTTON
            Row(
              children: [
                Expanded(child: customerDropdown()),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 10),
            // 🔹 ROW 2: PRODUCT ACCOUNT (FULL WIDTH)
            productAccountDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _itemsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Items",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Add Product"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            // 🔐 BUTTON ENABLE RULE
            onPressed: (selectedCustomer == null || selectedProductAccount == null)
                ? null
                : () => _openAddItemDialog(),
          ),
        ],
      ),
    );
  }

  Widget customerDropdown() {
    return TextFormField(
      readOnly: isCustomerLocked,
      onTap: isCustomerLocked
          ? null
          : () async {
        final result = await showCustomerSearch(context);
        if (result != null) {
          setState(() {
            selectedCustomer = result;
            isCustomerLocked = true; // 🔒 LOCK CUSTOMER
          });
        }
      },
      decoration: InputDecoration(
        labelText: "Customer Name",
        hintText: "Select Customer",
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.person),
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      controller: TextEditingController(text: selectedCustomer ?? ""),
    );
  }

  Widget _itemList() {
    if (items.isEmpty) {
      return const Center(child: Text("No items added"));
    }

    return Column(
      children: [
        _itemTableHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    _DataCell("${index + 1}", flex: 1),
                    _DataCell(item["productCode"], flex: 2),
                    _DataCell(item["productName"], flex: 5),
                    _DataCell(
                      formatNumber(item["qty"]),
                      flex: 2,
                      align: TextAlign.right,
                    ),
                    _DataCell(
                      formatNumber(item["rate"]),
                      flex: 2,
                      align: TextAlign.right,
                    ),
                    _DataCell(
                      formatNumber(item["total"]),
                      flex: 3,
                      align: TextAlign.right,
                    ),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == "edit") {
                              _openAddItemDialog(index: index);
                            } else if (value == "delete") {
                              _confirmDelete(index);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: "edit",
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text("Edit"),
                              ),
                            ),
                            PopupMenuItem(
                              value: "delete",
                              child: ListTile(
                                leading: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                title: Text("Delete"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) {
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
                });
                calculatePage4();
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("DELETE"),
            ),
          ],
        );
      },
    );
  }

  Widget _billSummaryBar() {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row("Products Total", totalCtrl.text),
            _row(
              "Other Charges",
              "₹${_otherChargesTotal().toStringAsFixed(2)}",
            ),
            _row("GST Amount", "₹${_totalGST()}"),
            _row("Discount", discCtrl.text),
            const Divider(),
            // BILL AMOUNT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Bill Amount",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  billAmountCtrl.text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: items.isEmpty ? null : saveAndPrintBill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "SAVE & PRINT",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value.isEmpty ? "-" : value),
        ],
      ),
    );
  }

  // ---------------- TEXT FIELD ----------------

  Widget textField(
      String label, {
        IconData? icon,
        bool required = true,
        bool readOnly = false,
        TextEditingController? controller,
      }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: required && !readOnly
          ? (value) => value == null || value.isEmpty ? "$label is required" : null
          : null,
      decoration: fieldDecoration(label, icon: icon),
    );
  }

  // ---------------- PRODUCT ACCOUNT DROPDOWN ----------------

  Widget productAccountDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedProductAccount,
      decoration: fieldDecoration("Product Account", icon: Icons.account_tree),
      items: const [
        DropdownMenuItem(value: "from_stock", child: Text("From Stock")),
        DropdownMenuItem(value: "other_charges", child: Text("Other Charges")),
      ],
      onChanged: (value) {
        setState(() {
          selectedProductAccount = value;
        });
      },
      validator: (value) => value == null ? "Product Account is required" : null,
    );
  }

  // ---------------- TEMPORARY SAVED BILL POPUP ----------------

  List<Map<String, dynamic>> items = [];
  int? editingIndex;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();

    // -------- PRODUCT GST CALCULATION --------
    qtyController.addListener(calculateProductGST);
    rateController.addListener(calculateProductGST);
    discountPercentController.addListener(calculateProductGST);
    cgstController.addListener(calculateProductGST);
    sgstController.addListener(calculateProductGST);
    igstController.addListener(calculateProductGST);

    // -------- BILLING PAGE CALCULATION --------
    receivedCtrl.addListener(calculatePage4);
  }

  String _totalOtherCharges() {
    double total = 0;

    for (var item in items) {
      // Identify Other Charges (no product code)
      if (item["productCode"] == null || item["productCode"] == "") {
        total += double.tryParse(item["total"] ?? "0") ?? 0;
      }
    }

    return total.toStringAsFixed(2);
  }

  String _totalGST() {
    double gst = 0;
    for (var item in items) {
      gst += double.tryParse(item["gst"] ?? "0") ?? 0;
    }
    return gst.toStringAsFixed(2);
  }

  int _itemsTotal() {
    int total = 0;
    for (var item in items) {
      total += int.tryParse(item["total"] ?? "0") ?? 0;
    }
    return total;
  }

  double _otherChargesTotal() {
    double total = 0;
    for (var item in items) {
      if (item["account"] == "other_charges") {
        total += double.tryParse(item["total"] ?? "0") ?? 0;
      }
    }
    return total;
  }

  double _itemsDiscountTotal() {
    double totalDisc = 0;
    for (var item in items) {
      totalDisc += double.tryParse(item["disc"] ?? "0") ?? 0;
    }
    return totalDisc;
  }

  double _toDouble(String text) {
    return double.tryParse(text) ?? 0;
  }

  void calculateProductGST() {
    double qty = _toDouble(qtyController.text);
    double rate = _toDouble(rateController.text);

    double baseAmount = qty * rate;

    // -------- DISCOUNT --------
    double discountPercent = _toDouble(discountPercentController.text);
    double discountAmount = baseAmount * (discountPercent / 100);

    double taxableAmount = baseAmount - discountAmount;

    // -------- GST --------
    double cgst = _toDouble(cgstController.text);
    double sgst = _toDouble(sgstController.text);
    double igst = _toDouble(igstController.text);

    double gstAmount = 0;

    if (includeGST == true) {
      if (igst > 0) {
        gstAmount = taxableAmount * igst / 100;
      } else {
        gstAmount = taxableAmount * (cgst / 100) + taxableAmount * (sgst / 100);
      }
    } else {
      gstAmount = 0;
    }

    double total = taxableAmount + gstAmount;

    setState(() {
      discountAmountController.text = discountAmount.toStringAsFixed(2);
      gstAmountController.text = gstAmount.toStringAsFixed(2);
      totalAmountController.text = total.toStringAsFixed(2);
    });
  }

  /// ===============================
  /// OTHER CHARGES CALCULATION
  /// ===============================
  void calculateOtherCharge() {
    final qty = double.tryParse(ocQtyCtrl.text.trim()) ?? 0;
    final rate = double.tryParse(ocRateCtrl.text.trim()) ?? 0;
    final gstPerc = double.tryParse(ocGstCtrl.text.trim()) ?? 0;

    if (qty <= 0 || rate <= 0) {
      ocGstAmtCtrl.text = "0.00";
      ocTotalCtrl.text = "0.00";
      totalAmountController.text = "0.00";
      return;
    }

    final subtotal = qty * rate;
    double gstAmt = 0;
    double total = 0;

    if (includeGSTOther) {
      // GST APPLIED ONLY WHEN CHECKED
      gstAmt = subtotal * (gstPerc / 100);
      total = subtotal + gstAmt;
    } else {
      // NO GST
      gstAmt = 0;
      total = subtotal;
    }

    ocGstAmtCtrl.text = gstAmt.toStringAsFixed(2);
    ocTotalCtrl.text = total.toStringAsFixed(2);
    totalAmountController.text = total.toStringAsFixed(2);
  }

  void calculatePage4() {
    double productTotal = 0;
    double gstTotal = 0;
    double discountTotal = 0;
    double otherChargesTotal = 0;

    for (var item in items) {
      double lineTotal = double.tryParse(item["total"].toString()) ?? 0;
      double lineGST = double.tryParse(item["gst"].toString()) ?? 0;
      double lineDisc = double.tryParse(item["disc"].toString()) ?? 0;

      // PRODUCTS (From Stock)
      if (item["account"] == "from_stock") {
        productTotal += lineTotal;
        gstTotal += lineGST;
        discountTotal += lineDisc;
      }
      // OTHER CHARGES
      else if (item["account"] == "other_charges") {
        otherChargesTotal += lineTotal;
        gstTotal += lineGST; //  ⭐ INCLUDE GST HERE
      }
    }

    // SHOW VALUES
    totalCtrl.text = productTotal.toStringAsFixed(2);
    discCtrl.text = discountTotal.toStringAsFixed(2);

    // FINAL BILL
    double bill = productTotal + otherChargesTotal + gstTotal - discountTotal;

    billAmountCtrl.text = bill.round().toString();

    // STORE FOR RECEIPT
    _cachedGST = gstTotal;
  }

  void saveAndPrintBill() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔹 TITLE
                  const Text(
                    "Confirm Payment",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // 💰 TOTAL AMOUNT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Amount",
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        "₹${billAmountCtrl.text}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: paymentReceivedCtrl,
                    keyboardType: TextInputType.number,
                    decoration: fieldDecoration("Received Amount"),
                    onChanged: (_) {
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Balance Due",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _calculateBalanceInPayment(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  // 🔘 PAYMENT METHOD (FIXED)
                  Row(
                    children: [
                      const Text(
                        "Payment Method:",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text("Cash"),
                        selected: paymentMethod == "Cash",
                        onSelected: (_) {
                          setModalState(() {
                            paymentMethod = "Cash";
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Bank"),
                        selected: paymentMethod == "Bank",
                        onSelected: (_) {
                          setModalState(() {
                            paymentMethod = "Bank";
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 🔹 ACTION BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("CANCEL"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _finalizeBill();
                          },
                          child: const Text(
                            "CONTINUE",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _finalizeBill() {
    // Generate new receipt number based on existing receipts
    int newReceiptNo = receiptHistory.length + 1;

    final bill = {
      "customer": selectedCustomer ?? "",
      "paymentMethod": paymentMethod,
      // TOTAL BEFORE GST & DISCOUNT
      "total": totalCtrl.text.isEmpty ? "0" : totalCtrl.text,
      // GST
      "gst": _totalGST().toString(),
      // DISCOUNT
      "discount": discCtrl.text.isEmpty ? "0" : discCtrl.text,
      // FINAL BILL
      "billAmount": billAmountCtrl.text.isEmpty ? "0" : billAmountCtrl.text,
      // RECEIVED FROM CUSTOMER
      "received": paymentReceivedCtrl.text.isEmpty ? "0" : paymentReceivedCtrl.text,
      // BALANCE
      "balance": _calculateBalanceInPayment(),
      // DATE
      "date": DateTime.now().toString(),
      // ITEMS
      "items": List<Map<String, dynamic>>.from(items),
    };

    // Save bill to hardcoded list
    savedBills.add(bill);

    /// ---------- CREATE RECEIPT ----------
    final receipt = {
      "receiptNo": newReceiptNo.toString(),
      "customer": selectedCustomer ?? "",
      "paymentMethod": paymentMethod,
      "date": "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
      "time": "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
      // TOTAL BEFORE GST
      "total": totalCtrl.text.isEmpty ? "0" : totalCtrl.text,
      // GST AMOUNT
      "gst": _totalGST().toString(),
      "otherCharges": _otherChargesTotal().toStringAsFixed(2),
      // DISCOUNT
      "discount": discCtrl.text.isEmpty ? "0" : discCtrl.text,
      // FINAL BILL
      "billAmount": billAmountCtrl.text.isEmpty ? "0" : billAmountCtrl.text,
      // RECEIVED FROM CUSTOMER
      "received": paymentReceivedCtrl.text.isEmpty ? "0" : paymentReceivedCtrl.text,
      // BALANCE
      "balance": _calculateBalanceInPayment(),
      "items": List<Map<String, dynamic>>.from(items),
      "notes": "Auto-generated from Billing",
    };

    receiptHistory.insert(0, receipt);

    debugPrint("========== BILL & RECEIPT SAVED ==========");
    debugPrint(receipt.toString());
    debugPrint("=========================================");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Bill saved successfully"),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      items.clear();
      selectedCustomer = null;
      isCustomerLocked = false;
      totalCtrl.clear();
      discCtrl.clear();
      billAmountCtrl.clear();
      paymentReceivedCtrl.clear();
      paymentMethod = "Cash";
      selectedProduct = null;
      selectedProductAccount = null;
    });
  }

  void _openAddItemDialog({int? index}) {
    String? dialogAccount = selectedProductAccount;
    if (index == null) {
      // ADD MODE
      selectedProduct = null;
      productController.clear();
      batchController.clear();
      stockQtyController.clear();
      qtyController.clear();
      rateController.clear();
      discountPercentController.clear();
      discountAmountController.clear();
      gstAmountController.clear();
      totalAmountController.clear();
      includeGST = false;

      dialogAccount = selectedProductAccount;
      includeGSTOther = false;
      selectedChargeName = null;

      ocQtyCtrl.clear();
      ocRateCtrl.clear();
      ocGstCtrl.text = "0";
      ocGstAmtCtrl.clear();
      ocTotalCtrl.clear();
      includeGSTOther = false;
    } else {
      // EDIT MODE
      final item = items[index];
      dialogAccount = item["account"];
      productController.text = item["productName"] ?? "";
      qtyController.text = item["qty"] ?? "";
      rateController.text = item["rate"] ?? "";
      discountAmountController.text = item["disc"] ?? "";
      gstAmountController.text = item["gst"] ?? "";
      totalAmountController.text = item["total"] ?? "";
    }

    final _addProductFormKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.95,
              minChildSize: 0.85,
              maxChildSize: 0.95,
              builder: (_, scrollController) {
                return Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Form(
                      key: _addProductFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 DRAG HANDLE
                          Center(
                            child: Container(
                              width: 50,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          // 🔹 TITLE
                          Text(
                            index == null ? "Add Product" : "Edit Product",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 🔹 PRODUCT
                          // 🔹 SHOW PRODUCT FIELD ONLY IF FROM STOCK
                          if (dialogAccount == "from_stock")
                            TextFormField(
                              readOnly: true,
                              controller: productController,
                              decoration: fieldDecoration(
                                "Product",
                                icon: Icons.inventory_2_outlined,
                              ),
                              validator: (value) => value == null || value.isEmpty
                                  ? "Product is required"
                                  : null,
                              onTap: () async {
                                final result = await showProductSearch(context);
                                if (result != null) {
                                  setDialogState(() {
                                    selectedProduct = result;
                                    productController.text = result["name"];
                                    batchController.text = result["batch"];
                                    stockQtyController.text = result["stock"];
                                    rateController.text = result["rate"];
                                    cgstController.text = result["cgst"];
                                    sgstController.text = result["sgst"];
                                    igstController.text = result["igst"];
                                    discountPercentController.clear();
                                    discountAmountController.clear();
                                    calculateProductGST();
                                  });
                                }
                              },
                            ),
                          const SizedBox(height: 12),
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  /// =========================
                                  /// FROM STOCK MODE
                                  /// =========================
                                  if (dialogAccount == "from_stock") ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: textField(
                                            "Batch",
                                            controller: batchController,
                                            readOnly: true,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: textField(
                                            "Rate",
                                            controller: rateController,
                                            readOnly: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: textField(
                                            "Stock Qty",
                                            controller: stockQtyController,
                                            readOnly: true,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: textField(
                                            "Discount %",
                                            controller: discountPercentController,
                                            required: false,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: qtyController,
                                            keyboardType: TextInputType.number,
                                            decoration: fieldDecoration(
                                              "Quantity",
                                            ),
                                            validator: (v) => v == null || v.isEmpty
                                                ? "Quantity required"
                                                : null,
                                            onChanged: (_) => calculateProductGST(),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: textField(
                                            "GST Amount",
                                            controller: gstAmountController,
                                            readOnly: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Checkbox(
                                          value: includeGST,
                                          onChanged: (v) {
                                            includeGST = v ?? false;
                                            setDialogState(() {});
                                            calculateProductGST();
                                          },
                                          materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity(
                                            horizontal: -2,
                                            vertical: -2,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text("Include GST"),
                                      ],
                                    ),
                                  ],
                                  /// =========================
                                  /// OTHER CHARGES UI
                                  /// =========================
                                  if (dialogAccount == "other_charges") ...[
                                    DropdownButtonFormField<String>(
                                      value: selectedChargeName,
                                      decoration: fieldDecoration(
                                        "Charge Name",
                                      ),
                                      items: otherChargesMaster
                                          .map<DropdownMenuItem<String>>(
                                            (c) => DropdownMenuItem<String>(
                                          value: c["name"] as String,
                                          child: Text(
                                            c["name"] as String,
                                          ),
                                        ),
                                      )
                                          .toList(),
                                      onChanged: (v) {
                                        selectedChargeName = v;
                                        final charge = otherChargesMaster
                                            .firstWhere((e) => e["name"] == v);
                                        // Auto fill
                                        ocRateCtrl.text = charge["rate"].toString();
                                        ocGstCtrl.text = charge["gst"].toString();
                                        setDialogState(() {});
                                        calculateOtherCharge();
                                      },
                                      validator: (v) => v == null ? "Select charge" : null,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: ocQtyCtrl,
                                            keyboardType:
                                            TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                            decoration: fieldDecoration("Qty"),
                                            onChanged: (_) => calculateOtherCharge(),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: ocRateCtrl,
                                            readOnly: true,
                                            decoration: fieldDecoration("Rate"),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: ocGstCtrl,
                                            readOnly: true,
                                            decoration: fieldDecoration(
                                              "GST %",
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: textField(
                                            "GST Amount",
                                            controller: ocGstAmtCtrl,
                                            readOnly: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: includeGSTOther,
                                          onChanged: (v) {
                                            includeGSTOther = v ?? false;
                                            setDialogState(() {});
                                            calculateOtherCharge();
                                          },
                                        ),
                                        const Text("Include GST"),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: totalAmountController,
                            readOnly: true,
                            decoration: fieldDecoration(
                              "Total Amount",
                            ).copyWith(
                              fillColor: Colors.blue.shade50,
                              prefixIcon: const Icon(Icons.currency_rupee),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("CANCEL"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (!_addProductFormKey.currentState!.validate()) {
                                      return;
                                    }
                                    setState(() {
                                      double qty = double.tryParse(qtyController.text) ?? 0;
                                      double rate = double.tryParse(rateController.text) ?? 0;
                                      double total = 0;
                                      Map<String, dynamic> data = {};
                                      // -------- FROM STOCK --------
                                      if (dialogAccount == "from_stock") {
                                        total = qty * rate;
                                        data = {
                                          "productCode": selectedProduct?["code"] ?? "",
                                          "productName": productController.text,
                                          "qty": qty.toStringAsFixed(0),
                                          "rate": rate.toStringAsFixed(2),
                                          "disc": discountAmountController.text,
                                          "gst": gstAmountController.text,
                                          "total": total.toStringAsFixed(2),
                                          "account": "from_stock",
                                        };
                                      }
                                      // -------- OTHER CHARGES --------
                                      else {
                                        double qty = double.tryParse(ocQtyCtrl.text) ?? 0;
                                        double rate = double.tryParse(ocRateCtrl.text) ?? 0;
                                        double gstPerc = double.tryParse(ocGstCtrl.text) ?? 0;
                                        double lineTotal = qty * rate;
                                        double gstAmt = lineTotal * (gstPerc / 100);
                                        data = {
                                          "productCode": "OC",
                                          "productName": selectedChargeName ?? "",
                                          "qty": qty.toStringAsFixed(0),
                                          "rate": rate.toStringAsFixed(2),
                                          "gst": gstAmt.toStringAsFixed(2),
                                          "disc": "0",
                                          "total": lineTotal.toStringAsFixed(2),
                                          "account": "other_charges",
                                        };
                                        gstAmountController.text = gstAmt.toStringAsFixed(2);
                                      }
                                      if (index == null) {
                                        items.add(data);
                                      } else {
                                        items[index] = data;
                                      }
                                    });
                                    calculatePage4();
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Text(index == null ? "ADD" : "UPDATE"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _editItem(int index) {
    final item = items[index];

    // 🔑 FIND PRODUCT FROM MASTER LIST
    final product = products.firstWhere(
          (p) => p["name"] == item["productName"],
      orElse: () => {},
    );

    setState(() {
      editingIndex = index;
      isEditing = true;
      selectedProduct = product;
      productController.text = product["name"] ?? "";
      batchController.text = product["batch"] ?? "";
      stockQtyController.text = product["stock"] ?? "";
      rateController.text = product["rate"] ?? "";
      cgstController.text = product["cgst"] ?? "";
      sgstController.text = product["sgst"] ?? "";
      igstController.text = product["igst"] ?? "";
      qtyController.text = item["qty"] ?? "";
      discountAmountController.text = item["disc"] ?? "";
      gstAmountController.text = item["gst"] ?? "";
      totalAmountController.text = item["total"] ?? "";
    });
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("New Billing", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // 1️⃣ CUSTOMER
            _customerBar(),
            const SizedBox(height: 8),
            _itemsHeader(),
            // 3️⃣ ITEM LIST
            Expanded(child: _itemList()),
            // 4️⃣ BILL SUMMARY (FIXED VISIBILITY)
            _billSummaryBar(),
          ],
        ),
      ),
    );
  }

  Future<String?> showCustomerSearch(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    List<String> filtered = List.from(customers);

    return showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 420,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🔍 SEARCH FIELD
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: "Search customer",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      filtered = customers
                          .where((c) => c.toLowerCase().contains(value.toLowerCase()))
                          .toList();
                      (context as Element).markNeedsBuild();
                    },
                  ),
                  const SizedBox(height: 12),
                  // 📋 CUSTOMER LIST
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text("No customer found"))
                        : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(filtered[index]),
                          onTap: () {
                            Navigator.pop(context, filtered[index]);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> showProductSearch(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> filtered = List.from(products);

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            height: 450,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🔍 SEARCH FIELD
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: "Search product",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      filtered = products
                          .where((p) => p["name"].toLowerCase().contains(value.toLowerCase()))
                          .toList();
                      (context as Element).markNeedsBuild();
                    },
                  ),
                  const SizedBox(height: 12),
                  // 📋 PRODUCT LIST
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text("No product found"))
                        : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return ListTile(
                          title: Text(product["name"]),
                          subtitle: Text(
                            "Stock: ${product['stock']} | Rate: ₹${product['rate']}",
                          ),
                          onTap: () {
                            Navigator.pop(context, product);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;

  const _HeaderCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;
  final FontWeight weight;

  const _DataCell(
      this.text, {
        super.key,
        required this.flex,
        this.align = TextAlign.left,
        this.weight = FontWeight.normal,
      });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, fontWeight: weight),
      ),
    );
  }
}