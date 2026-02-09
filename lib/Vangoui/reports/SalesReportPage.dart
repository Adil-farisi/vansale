import 'package:flutter/material.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  DateTime? fromDate;
  DateTime? toDate;

  // SAMPLE DATA WITH GST & DISCOUNT
  List<Map<String, String>> allSalesData = [
    {
      "date": "18/01/2026",
      "invoice": "INV-001",
      "customer": "Rahul",
      "amount": "1500",
      "gst": "90",
      "discount": "50"
    },
    {
      "date": "18/01/2026",
      "invoice": "INV-002",
      "customer": "Arun",
      "amount": "3200",
      "gst": "160",
      "discount": "100"
    },
    {
      "date": "19/01/2026",
      "invoice": "INV-003",
      "customer": "Kiran",
      "amount": "2100",
      "gst": "120",
      "discount": "70"
    },
    {
      "date": "20/01/2026",
      "invoice": "INV-004",
      "customer": "Amal",
      "amount": "1800",
      "gst": "90",
      "discount": "30"
    },
  ];

  List<Map<String, String>> filteredSalesData = [];

  @override
  void initState() {
    super.initState();
    filteredSalesData = List.from(allSalesData);
    sortByDate();
  }

  // -------- DATE PICKERS ---------

  Future<void> pickFromDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        fromDate = picked;
      });
    }
  }

  Future<void> pickToDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        toDate = picked;
      });
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return "Select Date";
    return "${date.day}/${date.month}/${date.year}";
  }

  // -------- DATE LOGIC ---------

  DateTime parseDate(String date) {
    List<String> parts = date.split("/");
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  void sortByDate() {
    filteredSalesData.sort((a, b) {
      DateTime d1 = parseDate(a["date"]!);
      DateTime d2 = parseDate(b["date"]!);
      return d1.compareTo(d2);
    });
  }

  void filterReport() {
    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select both dates"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      filteredSalesData = allSalesData.where((sale) {
        DateTime saleDate = parseDate(sale["date"]!);

        return saleDate.isAfter(fromDate!.subtract(const Duration(days: 1))) &&
            saleDate.isBefore(toDate!.add(const Duration(days: 1)));
      }).toList();

      sortByDate();
    });
  }

  // -------- CALCULATIONS ---------

  int getTotalAmount() {
    int total = 0;
    for (var sale in filteredSalesData) {
      total += int.tryParse(sale["amount"] ?? "0") ?? 0;
    }
    return total;
  }

  int getTotalGST() {
    int total = 0;
    for (var sale in filteredSalesData) {
      total += int.tryParse(sale["gst"] ?? "0") ?? 0;
    }
    return total;
  }

  int getTotalDiscount() {
    int total = 0;
    for (var sale in filteredSalesData) {
      total += int.tryParse(sale["discount"] ?? "0") ?? 0;
    }
    return total;
  }

  int getGrandTotal() {
    return getTotalAmount() + getTotalGST() - getTotalDiscount();
  }

  // -------- UI ---------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sales Report",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [

            // -------- DATE FILTER CARD --------

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.date_range),
                            label: Text(formatDate(fromDate)),
                            onPressed: pickFromDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.date_range),
                            label: Text(formatDate(toDate)),
                            onPressed: pickToDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: filterReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                        ),
                        child: const Text(
                          "VIEW REPORT",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // -------- SUMMARY SECTION --------

            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    "Total Sales",
                    "₹ ${getTotalAmount()}",
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard(
                    "Total GST",
                    "₹ ${getTotalGST()}",
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    "Total Discount",
                    "₹ ${getTotalDiscount()}",
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard(
                    "Grand Total",
                    "₹ ${getGrandTotal()}",
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // -------- SALES LIST --------

            Expanded(
              child: filteredSalesData.isEmpty
                  ? const Center(child: Text("No sales data found"))
                  : ListView.builder(
                itemCount: filteredSalesData.length,
                itemBuilder: (context, index) {
                  final sale = filteredSalesData[index];

                  int amount =
                      int.tryParse(sale["amount"] ?? "0") ?? 0;
                  int gst =
                      int.tryParse(sale["gst"] ?? "0") ?? 0;
                  int discount =
                      int.tryParse(sale["discount"] ?? "0") ?? 0;

                  int net = amount + gst - discount;

                  return Card(
                    elevation: 5,
                    margin:
                    const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                sale["customer"]!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(sale["date"]!),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Text("Invoice: ${sale["invoice"]}"),

                          const Divider(),

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Amount: ₹${sale["amount"]}"),
                              Text("GST: ₹${sale["gst"]}"),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Discount: ₹${sale["discount"]}",
                                style:
                                const TextStyle(color: Colors.red),
                              ),
                              Text(
                                "Net: ₹$net",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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

  Widget _summaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
