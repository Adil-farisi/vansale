import 'package:flutter/material.dart';
import 'package:van_go/Vangoui/stocks/stock_section_switcher.dart';

class ReturnStockPage extends StatefulWidget {
  const ReturnStockPage({super.key});

  @override
  State<ReturnStockPage> createState() => _ReturnStockPageState();
}

class _ReturnStockPageState extends State<ReturnStockPage> {

  final List<String> customers = [
    "Rahman Stores",
    "City Mart",
    "Fresh Traders",
    "ABC Supermarket",
  ];

  final List<Map<String, dynamic>> products = [
    {"name":"Sugar 1 KG","code":"SUG001","rate":40.0},
    {"name":"Rice 5 KG","code":"RIC005","rate":250.0},
    {"name":"Tea Powder","code":"TEA001","rate":180.0},
  ];

  List<Map<String, dynamic>> returnItems = [];

  String returnType = "Customer Return";
  String? selectedCustomer;

  double get totalQty =>
      returnItems.fold(0, (sum, item) => sum + item["qty"]);

  double get totalValue =>
      returnItems.fold(0, (sum, item) => sum + (item["qty"] * item["rate"]));

  void addRow() {
    setState(() {
      returnItems.add({
        "name": null,
        "code": "",
        "rate": 0.0,
        "qty": 0,
        "qtyCtrl": TextEditingController(text: ""),
        "reason": null, // IMPORTANT: empty initially
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          "Return Stock",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          /// STOCK SECTION SWITCHER
          IconButton(
            icon: const Icon(Icons.grid_view),
            tooltip: "Switch Stock Section",
            onPressed: () {
              showStockSectionSwitcher(
                context,
                "Return Stock",
              );
            },
          ),

          /// EXISTING ADD ITEM BUTTON (UNCHANGED)
          TextButton.icon(
            onPressed: addRow,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              "ADD ITEM",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [

            /// RETURN TYPE
            DropdownButtonFormField<String>(
              value: returnType,
              decoration: const InputDecoration(
                labelText: "Return Type",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "Customer Return", child: Text("Customer Return")),
                DropdownMenuItem(value: "Unsold Return", child: Text("Unsold Return")),
                DropdownMenuItem(value: "Damaged Return", child: Text("Damaged Return")),
                DropdownMenuItem(value: "Expired Return", child: Text("Expired Return")),
              ],
              onChanged: (v) {
                setState(() {
                  returnType = v!;
                  selectedCustomer = null;
                });
              },
            ),

            const SizedBox(height: 10),

            /// CUSTOMER
            if (returnType == "Customer Return")
              DropdownButtonFormField<String>(
                value: selectedCustomer,
                decoration: const InputDecoration(
                  labelText: "Customer Name",
                  border: OutlineInputBorder(),
                ),
                items: customers
                    .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c),
                ))
                    .toList(),
                onChanged: (v) => setState(() => selectedCustomer = v),
              ),

            const SizedBox(height: 10),

            /// SUMMARY
            Row(
              children: [
                _summaryCard("Items", returnItems.length.toString(), Icons.list),
                _summaryCard("Total Qty", totalQty.toStringAsFixed(0), Icons.storage),
                _summaryCard("Value", "₹${totalValue.toStringAsFixed(2)}",
                    Icons.currency_rupee),
              ],
            ),

            const SizedBox(height: 10),

            /// ITEM LIST
            Expanded(
              child: ListView.builder(
                itemCount: returnItems.length,
                itemBuilder: (context, index) {
                  final row = returnItems[index];

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// ITEM SELECT
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField(
                                  value: row["name"],
                                  hint: const Text("Select Item"),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  items: products.map((p) =>
                                      DropdownMenuItem(
                                        value: p["name"],
                                        child: Text(p["name"]),
                                      )).toList(),
                                  onChanged: (v) {
                                    final prod = products
                                        .firstWhere((p) => p["name"] == v);
                                    setState(() {
                                      row["name"] = prod["name"];
                                      row["code"] = prod["code"];
                                      row["rate"] = prod["rate"];
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    setState(() => returnItems.removeAt(index)),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Text("Code: ${row["code"]}",
                              style: const TextStyle(color: Colors.grey)),
                          Text("Rate: ₹${row["rate"]}",
                              style: const TextStyle(fontWeight: FontWeight.w600)),

                          const SizedBox(height: 12),

                          /// QTY
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Quantity"),
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: row["qtyCtrl"],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onChanged: (v) =>
                                      setState(() => row["qty"] = int.tryParse(v) ?? 0),
                                ),
                              )
                            ],
                          ),

                          /// RETURN REASON (ONLY FOR CUSTOMER RETURN)
                          if (returnType == "Customer Return") ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: row["reason"],
                              decoration: const InputDecoration(
                                labelText: "Return Reason",
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: "Damaged", child: Text("Damaged")),
                                DropdownMenuItem(value: "Expired", child: Text("Expired")),
                                DropdownMenuItem(value: "Wrong Item", child: Text("Wrong Item")),
                                DropdownMenuItem(value: "Quality Issue", child: Text("Quality Issue")),
                                DropdownMenuItem(value: "Other", child: Text("Other")),
                              ],
                              onChanged: (v) =>
                                  setState(() => row["reason"] = v),
                            ),
                          ],

                          const SizedBox(height: 12),

                          /// VALUE
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "₹${(row["qty"] * row["rate"]).toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /// SUBMIT
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {

                  if (returnType == "Customer Return" &&
                      selectedCustomer == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select customer")),
                    );
                    return;
                  }

                  if (returnType == "Customer Return" &&
                      returnItems.any((e) => e["reason"] == null)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select return reason")),
                    );
                    return;
                  }

                  if (returnItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Add at least one item")),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Return stock updated")),
                  );

                  setState(() {
                    returnItems.clear();
                    selectedCustomer = null;
                  });

                  Navigator.pop(context);
                },
                child: const Text("RETURN & UPDATE STOCK",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: Colors.blue.shade700),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
