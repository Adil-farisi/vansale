import 'package:flutter/material.dart';
import 'package:van_go/Vangoui/stocks/stock_section_switcher.dart';

class TradingItemsPage extends StatefulWidget {
  const TradingItemsPage({super.key});

  @override
  State<TradingItemsPage> createState() => _TradingItemsPageState();
}

class _TradingItemsPageState extends State<TradingItemsPage> {
  /// 🔹 HARD-CODED TRADING ITEMS
  List<Map<String, dynamic>> items = [
    {
      "name": "Sugar 1 KG",
      "code": "SUG001",
      "category": "Grocery",
      "rate": 40.0,
      "active": true,
    },
    {
      "name": "Rice 5 KG",
      "code": "RIC005",
      "category": "Grocery",
      "rate": 250.0,
      "active": true,
    },
    {
      "name": "Tea Powder",
      "code": "TEA001",
      "category": "Beverages",
      "rate": 180.0,
      "active": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Trading Items",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          /// STOCK SECTION SWITCHER
          IconButton(
            icon: const Icon(Icons.grid_view),
            tooltip: "Switch Stock Section",
            onPressed: () {
              showStockSectionSwitcher(
                context,
                "Trading Items",
              );
            },
          ),

          /// EXISTING ADD BUTTON (UNCHANGED)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Add Item (UI only)")),
              );
            },
          ),
        ],
      ),


      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// LEFT ICON
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: Colors.blue,
                    ),
                  ),

                  const SizedBox(width: 14),

                  /// ITEM DETAILS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["name"],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        _infoRow("Code", item["code"]),
                        _infoRow("Category", item["category"]),
                        _infoRow(
                          "Rate",
                          "₹${item["rate"].toStringAsFixed(2)}",
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Text(
                              "Status: ",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              item["active"] ? "Active" : "Inactive",
                              style: TextStyle(
                                color:
                                item["active"] ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  /// ACTIONS
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Edit (UI only)")),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            items.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
