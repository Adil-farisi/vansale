import 'package:flutter/material.dart';

class ProductReportPage extends StatefulWidget {
  const ProductReportPage({super.key});

  @override
  State<ProductReportPage> createState() => _ProductReportPageState();
}

class _ProductReportPageState extends State<ProductReportPage> {
  DateTime? fromDate;
  DateTime? toDate;

  // SAMPLE PRODUCT REPORT DATA
  List<Map<String, String>> allProductData = [
    {
      "date": "18/01/2026",
      "product": "Rice 5kg",
      "qty": "10",
      "amount": "5000"
    },
    {
      "date": "19/01/2026",
      "product": "Oil 1L",
      "qty": "20",
      "amount": "3000"
    },
    {
      "date": "20/01/2026",
      "product": "Sugar 1kg",
      "qty": "15",
      "amount": "1500"
    },
  ];

  List<Map<String, String>> filteredProductData = [];

  @override
  void initState() {
    super.initState();
    filteredProductData = List.from(allProductData);
    sortByDate();
  }

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

  DateTime parseDate(String date) {
    List<String> parts = date.split("/");
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  void sortByDate() {
    filteredProductData.sort((a, b) {
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
      filteredProductData = allProductData.where((item) {
        DateTime productDate = parseDate(item["date"]!);

        return productDate.isAfter(fromDate!.subtract(const Duration(days: 1))) &&
            productDate.isBefore(toDate!.add(const Duration(days: 1)));
      }).toList();

      sortByDate();
    });
  }

  int getTotalQty() {
    int total = 0;

    for (var item in filteredProductData) {
      total += int.tryParse(item["qty"] ?? "0") ?? 0;
    }

    return total;
  }

  int getTotalAmount() {
    int total = 0;

    for (var item in filteredProductData) {
      total += int.tryParse(item["amount"] ?? "0") ?? 0;
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Product Report",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
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

            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    "Total Quantity",
                    getTotalQty().toString(),
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard(
                    "Total Amount",
                    "₹ ${getTotalAmount()}",
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Expanded(
              child: filteredProductData.isEmpty
                  ? const Center(
                child: Text(
                  "No product data found",
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: filteredProductData.length,
                itemBuilder: (context, index) {
                  final item = filteredProductData[index];

                  return Card(
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item["product"]!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                item["date"]!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Quantity: ${item["qty"]}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                "Amount: ₹ ${item["amount"]}",
                                style: const TextStyle(
                                  fontSize: 14,
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
