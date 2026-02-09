import 'package:flutter/material.dart';
import 'package:van_go/Vangoui/stocks/stock_data.dart';
import 'package:van_go/Vangoui/stocks/stock_section_switcher.dart';

class LoadStockPage extends StatefulWidget {
  const LoadStockPage({super.key});

  @override
  State<LoadStockPage> createState() => _LoadStockPageState();
}

class _LoadStockPageState extends State<LoadStockPage> {

  final List<Map<String, dynamic>> invoiceItems = [
    {"name":"Sugar 1 KG","code":"SUG001","rate":40.0,"qty":50},
    {"name":"Rice 5 KG","code":"RIC005","rate":250.0,"qty":10},
    {"name":"Tea Powder","code":"TEA001","rate":180.0,"qty":20},
  ];

  double get totalQty =>
      invoiceItems.fold(0, (sum, item) => sum + item["qty"]);

  double get totalValue =>
      invoiceItems.fold(0, (sum, item) => sum + (item["qty"] * item["rate"]));


  void applyLoadToStock() {
    for (var invoiceItem in invoiceItems) {
      final existing = stockData.firstWhere(
            (s) => s["code"] == invoiceItem["code"],
        orElse: () => {},
      );

      if (existing.isNotEmpty) {
        existing["qty"] += invoiceItem["qty"];
      } else {
        stockData.add({
          "name": invoiceItem["name"],
          "code": invoiceItem["code"],
          "qty": invoiceItem["qty"],
          "rate": invoiceItem["rate"],
          "category": "Grocery"
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          "Load Stock",
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
                "Load Stock",
              );
            },
          ),
        ],
      ),



      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [

            /// -------- INVOICE HEADER --------
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [

                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(Icons.receipt_long,
                          color: Colors.blue.shade700, size: 26),
                    ),

                    const SizedBox(width: 14),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Invoice No : INV-1023",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text("Invoice Date : 05 Jan 2026"),
                      ],
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),


            /// -------- SUMMARY --------
            Row(
              children: [
                _summaryCard("Items", invoiceItems.length.toString(), Icons.list),
                _summaryCard("Total Qty", totalQty.toStringAsFixed(0), Icons.storage),
                _summaryCard("Value", "₹${totalValue.toStringAsFixed(2)}",
                    Icons.currency_rupee),
              ],
            ),

            const SizedBox(height: 12),


            /// -------- STOCK LIST --------
            Expanded(
              child: ListView.builder(
                itemCount: invoiceItems.length,
                itemBuilder: (context, index) {

                  final row = invoiceItems[index];

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// NAME + CODE
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(row["name"],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text("Code: ${row["code"]}",
                                    style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          /// QTY + RATE
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _chip("Qty: ${row["qty"]}", Colors.deepPurple),
                              _chip("Rate: ₹${row["rate"]}", Colors.green),
                            ],
                          ),

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


            /// -------- CONFIRM BUTTON --------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle,color: Colors.white,),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {

                  bool? confirm = await showDialog(
                    context: context,
                    builder: (context)=>AlertDialog(
                      title: const Text("Confirm Load Stock"),
                      content: const Text(
                          "Do you want to confirm & load invoice stock to van?"),
                      actions: [
                        TextButton(
                            onPressed: ()=>Navigator.pop(context,false),
                            child: const Text("Cancel")),

                        ElevatedButton(
                            onPressed: ()=>Navigator.pop(context,true),
                            child: const Text("Confirm"))
                      ],
                    ),
                  );

                  if(confirm != true) return;

                  applyLoadToStock();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Stock Loaded Successfully")),
                  );

                  Navigator.pop(context);
                },
                label: const Text(
                  "CONFIRM & LOAD STOCK",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }


  /// -------- SUMMARY CARD --------
  Widget _summaryCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 3,
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


  /// -------- SMALL INFO TAG --------
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
