import 'package:flutter/material.dart';

class SalesReturnReportPage extends StatefulWidget {
  const SalesReturnReportPage({super.key});

  @override
  State<SalesReturnReportPage> createState() => _SalesReturnReportPageState();
}

class _SalesReturnReportPageState extends State<SalesReturnReportPage> {
  DateTime? fromDate;
  DateTime? toDate;

  // UPDATED SALES RETURN DATA WITH ITEM DETAILS
  List<Map<String, dynamic>> allReturnData = [
    {
      "date": "18/01/2026",
      "invoice": "RTN-001",
      "customer": "Rahul",
      "amount": "500",
      "reason": "Damaged Item",
      "items": [
        {"name": " Rice", "qty": "1", "value": "300"},
        {"name": "Sugar", "qty": "2", "value": "200"},
      ]
    },
    {
      "date": "19/01/2026",
      "invoice": "RTN-002",
      "customer": "Arun",
      "amount": "1200",
      "reason": "Wrong Product",
      "items": [
        {"name": "Dates", "qty": "3", "value": "1200"},
      ]
    },
    {
      "date": "20/01/2026",
      "invoice": "RTN-003",
      "customer": "Kiran",
      "amount": "800",
      "reason": "Quality Issue",
      "items": [
        {"name": "Coke", "qty": "1", "value": "500"},
        {"name": "Milk", "qty": "1", "value": "300"},
      ]
    },
  ];

  List<Map<String, dynamic>> filteredReturnData = [];

  @override
  void initState() {
    super.initState();
    filteredReturnData = List.from(allReturnData);
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
    filteredReturnData.sort((a, b) {
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
      filteredReturnData = allReturnData.where((item) {
        DateTime returnDate = parseDate(item["date"]!);

        return returnDate.isAfter(fromDate!.subtract(const Duration(days: 1))) &&
            returnDate.isBefore(toDate!.add(const Duration(days: 1)));
      }).toList();

      sortByDate();
    });
  }

  int getTotalReturnAmount() {
    int total = 0;

    for (var item in filteredReturnData) {
      total += int.tryParse(item["amount"] ?? "0") ?? 0;
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sales Return Report",
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
                    "Total Returns",
                    "₹ ${getTotalReturnAmount()}",
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard(
                    "Total Bills",
                    filteredReturnData.length.toString(),
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Expanded(
              child: filteredReturnData.isEmpty
                  ? const Center(
                child: Text(
                  "No sales return found",
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: filteredReturnData.length,
                itemBuilder: (context, index) {
                  final item = filteredReturnData[index];

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
                                item["invoice"],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(item["date"]),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Text(item["customer"]),

                          const SizedBox(height: 6),

                          Text("Reason: ${item["reason"]}"),

                          const Divider(),

                          const Text(
                            "Returned Items:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 6),

                          Column(
                            children: List.generate(
                              item["items"].length,
                                  (i) {
                                var product = item["items"][i];

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(product["name"]),
                                      ),
                                      Text("Qty: ${product["qty"]}"),
                                      const SizedBox(width: 10),
                                      Text("₹ ${product["value"]}"),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          const Divider(),

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Return Amount"),
                              Text(
                                "₹ ${item["amount"]}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
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
            Text(title),
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
