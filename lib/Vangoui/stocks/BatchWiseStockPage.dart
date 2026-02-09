import 'package:flutter/material.dart';
import 'package:van_go/Vangoui/stocks/stock_section_switcher.dart';

class BatchWiseStockPage extends StatefulWidget {
  const BatchWiseStockPage({super.key});

  @override
  State<BatchWiseStockPage> createState() => _BatchWiseStockPageState();
}

class _BatchWiseStockPageState extends State<BatchWiseStockPage> {
  final TextEditingController searchCtrl = TextEditingController();

  /// CHANGED: category instead of item
  String selectedCategory = "All";

  final List<Map<String, dynamic>> batchStock = const [
    {
      "item": "Sugar 1 KG",
      "category": "Grocery",
      "batch": "BATCH-SG-01",
      "expiry": "12/2026",
      "qty": 120,
      "rate": 40.0,
    },
    {
      "item": "Sugar 1 KG",
      "category": "Grocery",
      "batch": "BATCH-SG-02",
      "expiry": "03/2027",
      "qty": 80,
      "rate": 40.0,
    },
    {
      "item": "Rice 5 KG",
      "category": "Grocery",
      "batch": "BATCH-RC-01",
      "expiry": "08/2026",
      "qty": 60,
      "rate": 250.0,
    },
    {
      "item": "Tea Powder",
      "category": "Beverages",
      "batch": "BATCH-TP-01",
      "expiry": "01/2027",
      "qty": 45,
      "rate": 180.0,
    },
  ];

  /// FILTERED LIST (LOGIC FIXED)
  List<Map<String, dynamic>> get filteredList {
    return batchStock.where((item) {
      final query = searchCtrl.text.toLowerCase();

      final matchSearch =
          item["item"].toLowerCase().contains(query) ||
              item["batch"].toLowerCase().contains(query);

      final matchCategory =
          selectedCategory == "All" ||
              item["category"] == selectedCategory;

      return matchSearch && matchCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    double totalQty =
    filteredList.fold(0, (sum, e) => sum + e["qty"]);
    double totalValue =
    filteredList.fold(0, (sum, e) => sum + (e["qty"] * e["rate"]));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Batch-wise Stock",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view),
            tooltip: "Switch Stock Section",
            onPressed: () {
              showStockSectionSwitcher(
                context,
                "Batch-wise Stock",
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// SEARCH
            TextField(
              controller: searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Search item or batch no",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// CATEGORY FILTER (UI SAME, LOGIC CHANGED)
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: const [
                DropdownMenuItem(
                    value: "All", child: Text("All Categories")),
                DropdownMenuItem(
                    value: "Grocery", child: Text("Grocery")),
                DropdownMenuItem(
                    value: "Beverages", child: Text("Beverages")),
              ],
              onChanged: (val) {
                setState(() => selectedCategory = val!);
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// SUMMARY
            Row(
              children: [
                _summaryCard("Batches", filteredList.length.toString()),
                _summaryCard("Total Qty", totalQty.toStringAsFixed(0)),
                _summaryCard(
                    "Value", "₹${totalValue.toStringAsFixed(2)}"),
              ],
            ),

            const SizedBox(height: 12),

            /// LIST
            Expanded(
              child: ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final item = filteredList[index];

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["item"],
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _chip(Icons.confirmation_number, item["batch"]),
                              const SizedBox(width: 8),
                              _chip(Icons.event, "Exp: ${item["expiry"]}"),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _infoTile("Qty", item["qty"].toString()),
                              _infoTile("Rate", "₹${item["rate"]}"),
                              _infoTile(
                                "Value",
                                "₹${(item["qty"] * item["rate"]).toStringAsFixed(2)}",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// SUMMARY CARD
  Widget _summaryCard(String label, String value) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  /// INFO TILE
  Widget _infoTile(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// CHIP
  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue.shade800),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade800)),
        ],
      ),
    );
  }
}
