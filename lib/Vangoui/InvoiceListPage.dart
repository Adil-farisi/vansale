import 'package:flutter/material.dart';

// Hardcoded receipt history data
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

// Mock ReceiptPreviewPage class (you need to define this separately)
class ReceiptPreviewPage extends StatelessWidget {
  final Map<String, dynamic> receipt;

  const ReceiptPreviewPage({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Preview'),
      ),
      body: Center(
        child: Text('Receipt for ${receipt["customer"]}'),
      ),
    );
  }
}

// Mock EditReceiptPage class (you need to define this separately)
class EditReceiptPage extends StatelessWidget {
  final Map<String, dynamic> receipt;
  final Function(Map<String, dynamic>) onSave;

  const EditReceiptPage({super.key, required this.receipt, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Receipt'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            onSave(receipt); // Mock save
            Navigator.pop(context);
          },
          child: const Text('Save Changes'),
        ),
      ),
    );
  }
}

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text("Delete Invoice"),
        content: const Text("Are you sure you want to delete this invoice?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Invoice",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
      ),

      body: receiptHistory.isEmpty
          ? const Center(
        child: Text(
          "No Invoice Found",
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: receiptHistory.length,
        itemBuilder: (context, index) {
          final receipt = receiptHistory[index];

          return Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Invoice #${receiptHistory.length - index}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatDate(receipt["date"]),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          if (value == 'view') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReceiptPreviewPage(receipt: receipt),
                              ),
                            );
                          } else if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditReceiptPage(
                                  receipt: receipt,
                                  onSave: (updatedReceipt) {
                                    setState(() {
                                      receiptHistory[index] =
                                          updatedReceipt;
                                    });
                                  },
                                ),
                              ),
                            );
                          } else if (value == 'delete') {
                            bool yes = await _confirmDelete(context);
                            if (yes) {
                              setState(() {
                                receiptHistory.removeAt(index);
                              });
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.receipt_long,
                                    size: 18,
                                    color: Colors.indigo),
                                SizedBox(width: 8),
                                Text("View"),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit,
                                    size: 18,
                                    color: Colors.blue),
                                SizedBox(width: 8),
                                Text("Edit"),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete,
                                    size: 18,
                                    color: Colors.red),
                                SizedBox(width: 8),
                                Text("Delete"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _info("Customer", receipt["customer"]),
                  _info("Payment Method", receipt["paymentMethod"]),

                  const SizedBox(height: 6),
                  const Divider(),

                  /// ITEMS
                  if (receipt["items"] != null &&
                      receipt["items"].isNotEmpty) ...[
                    const SizedBox(height: 6),
                    const Text(
                      "Items",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: const [
                        Expanded(flex: 4, child: Text("Item", style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text("Qty", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text("Price", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text("Total", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),

                    const SizedBox(height: 6),

                    ...List<Map<String, dynamic>>.from(
                      receipt["items"],
                    ).map((item) {
                      return Padding(
                        padding:
                        const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 4,
                                child: Text(item["productName"] ?? "")),
                            Expanded(
                                flex: 2,
                                child: Text(
                                  "${item["qty"]}",
                                  textAlign: TextAlign.center,
                                )),
                            Expanded(
                                flex: 2,
                                child: Text(
                                  "₹${item["rate"]}",
                                  textAlign: TextAlign.center,
                                )),
                            Expanded(
                                flex: 2,
                                child: Text(
                                  "₹${item["total"]}",
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                )),
                          ],
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 10),
                    const Divider(),
                  ],

                  /// TOTALS
                  _amount("Product Total", receipt["total"]),
                  _amount("GST Amount", receipt["gst"]),
                  _amount(
                    "Other Charges",
                    _otherChargesTotal(receipt).toStringAsFixed(2),
                  ),
                  _amount("Discount", receipt["discount"]),
                  _amount("Bill Amount", receipt["billAmount"], bold: true),
                  _amount("Received", receipt["received"]),
                  _amount("Balance", receipt["balance"],
                      color: Colors.red),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// HELPERS

  Widget _info(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            "$label : ",
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? "",
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  double _otherChargesTotal(Map<String, dynamic> receipt) {
    double total = 0;
    if (receipt["items"] == null) return 0;

    for (var item in receipt["items"]) {
      if (item["account"] == "other_charges") {
        total += double.tryParse(item["total"]?.toString() ?? "0") ?? 0;
      }
    }
    return total;
  }

  Widget _amount(String label, dynamic value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(
            "₹ ${value ?? '0'}",
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String formatDate(dynamic value) {
    if (value == null) return "";
    final text = value.toString();
    return text.length >= 10 ? text.substring(0, 10) : text;
  }
}