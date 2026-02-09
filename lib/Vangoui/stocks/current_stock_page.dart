import 'package:flutter/material.dart';
import 'package:van_go/Vangoui/stocks/stock_data.dart';
import 'package:van_go/Vangoui/stocks/stock_section_switcher.dart';

class CurrentStockPage extends StatefulWidget {
  const CurrentStockPage({super.key});

  @override
  State<CurrentStockPage> createState() => _CurrentStockPageState();
}

class _CurrentStockPageState extends State<CurrentStockPage> {
  TextEditingController searchCtrl = TextEditingController();

  String selectedCategory = "All";
  String selectedSort = "Name A-Z";

  List<Map<String, dynamic>> filteredStock = [];

  @override
  void initState() {
    super.initState();
    filteredStock = List.from(stockData);
  }

  void applyFilters() {
    List<Map<String, dynamic>> temp = List.from(stockData);

    if (selectedCategory != "All") {
      temp = temp.where((e) => e["category"] == selectedCategory).toList();
    }

    String q = searchCtrl.text.toLowerCase();
    temp = temp.where((e) =>
    e["name"].toLowerCase().contains(q) ||
        e["code"].toLowerCase().contains(q)).toList();

    if (selectedSort == "Name A-Z") {
      temp.sort((a, b) => a["name"].compareTo(b["name"]));
    } else {
      temp.sort((a, b) => b["qty"].compareTo(a["qty"]));
    }

    setState(() => filteredStock = temp);
  }

  @override
  Widget build(BuildContext context) {
    double totalQty = filteredStock.fold(0, (sum, item) => sum + item["qty"]);
    double totalValue =
    filteredStock.fold(0, (sum, item) => sum + (item["qty"] * item["rate"]));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          "Current Stock",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view),
            tooltip: "Switch Stock Section",
            onPressed: () {
              showStockSectionSwitcher(
                context,
                "Current Stock",
              );
            },
          ),
        ],
      ),


      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [

            /// ---------- SUMMARY ----------
            Row(
              children: [
                _summaryCard("Items", filteredStock.length.toString(), Icons.list),
                _summaryCard("Total Qty", totalQty.toStringAsFixed(0), Icons.storage),
                _summaryCard("Stock Value",
                    "₹${totalValue.toStringAsFixed(2)}", Icons.currency_rupee),
              ],
            ),

            const SizedBox(height: 14),

            /// ---------- FILTER BAR ----------
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.grey.shade100,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: "All", child: Text("All")),
                        DropdownMenuItem(value: "Grocery", child: Text("Grocery")),
                        DropdownMenuItem(value: "Beverages", child: Text("Beverages")),
                      ],
                      onChanged: (v) {
                        selectedCategory = v!;
                        applyFilters();
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: DropdownButtonFormField(
                      value: selectedSort,
                      decoration: const InputDecoration(
                        labelText: "Sort",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Name A-Z", child: Text("Name A-Z")),
                        DropdownMenuItem(value: "Qty High-Low", child: Text("Qty High-Low")),
                      ],
                      onChanged: (v) {
                        selectedSort = v!;
                        applyFilters();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// ---------- SEARCH ----------
            TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: "Search item / code",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => applyFilters(),
            ),

            const SizedBox(height: 12),

            /// ---------- LIST ----------
            Expanded(
              child: ListView.builder(
                itemCount: filteredStock.length,
                itemBuilder: (context, index) {
                  final item = filteredStock[index];

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// NAME + CODE
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(item["name"],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text("Code: ${item["code"]}",
                                    style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          /// STOCK ROW
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _chip("Stock: ${item["qty"]}", Colors.deepPurple),
                              _chip("Rate: ₹${item["rate"]}", Colors.green),
                              Text(
                                "₹${(item["qty"] * item["rate"]).toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blue),
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

  /// ---------- SUMMARY CARD ----------
  Widget _summaryCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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

  /// ---------- TAG STYLE ----------
  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}
