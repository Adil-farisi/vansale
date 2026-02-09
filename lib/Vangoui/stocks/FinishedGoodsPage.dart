import 'package:flutter/material.dart';
import 'package:van_go/Vangoui/stocks/stock_section_switcher.dart';

class FinishedGoodsPage extends StatefulWidget {
  const FinishedGoodsPage({super.key});

  @override
  State<FinishedGoodsPage> createState() => _FinishedGoodsPageState();
}

class _FinishedGoodsPageState extends State<FinishedGoodsPage> {
  final TextEditingController searchCtrl = TextEditingController();

  String selectedCategory = "All";
  String selectedSort = "Name";

  final List<Map<String, dynamic>> finishedGoods = const [
    {
      "name": "Sugar 1 KG",
      "code": "FG001",
      "category": "Grocery",
      "qty": 500,
      "rate": 40.0,
    },
    {
      "name": "Rice 5 KG",
      "code": "FG002",
      "category": "Grocery",
      "qty": 200,
      "rate": 250.0,
    },
    {
      "name": "Tea Powder",
      "code": "FG003",
      "category": "Beverages",
      "qty": 100,
      "rate": 180.0,
    },
  ];

  /// FILTER + SORT (UI only)
  List<Map<String, dynamic>> get filteredList {
    List<Map<String, dynamic>> list = finishedGoods.where((item) {
      final query = searchCtrl.text.toLowerCase();

      final matchSearch =
          item["name"].toLowerCase().contains(query) ||
              item["code"].toLowerCase().contains(query);

      final matchCategory =
          selectedCategory == "All" ||
              item["category"] == selectedCategory;

      return matchSearch && matchCategory;
    }).toList();

    if (selectedSort == "Name") {
      list.sort((a, b) => a["name"].compareTo(b["name"]));
    } else if (selectedSort == "Qty") {
      list.sort((a, b) => b["qty"].compareTo(a["qty"]));
    } else if (selectedSort == "Value") {
      list.sort((a, b) =>
          (b["qty"] * b["rate"]).compareTo(a["qty"] * a["rate"]));
    }

    return list;
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
          "Finished Goods",
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
                "Finished Goods",
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
                hintText: "Search by item name or code",
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

            /// CATEGORY + SORT
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
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
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSort,
                    items: const [
                      DropdownMenuItem(
                          value: "Name", child: Text("Sort by Name")),
                      DropdownMenuItem(
                          value: "Qty", child: Text("Sort by Qty")),
                      DropdownMenuItem(
                          value: "Value", child: Text("Sort by Value")),
                    ],
                    onChanged: (val) {
                      setState(() => selectedSort = val!);
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
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// SUMMARY
            Row(
              children: [
                _summaryCard("Items", filteredList.length.toString()),
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
                          /// HEADER
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item["name"],
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item["code"],
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade800),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          /// DETAILS
                          Row(
                            children: [
                              _infoTile(
                                  "Category", item["category"]),
                              _infoTile(
                                  "Qty", item["qty"].toString()),
                              _infoTile(
                                  "Rate", "₹${item["rate"]}"),
                            ],
                          ),

                          const Divider(height: 20),

                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "Value: ₹${(item["qty"] * item["rate"]).toStringAsFixed(2)}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800),
                            ),
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
}
