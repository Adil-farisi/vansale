import 'package:flutter/material.dart';

class CollectionReportPage extends StatefulWidget {
  const CollectionReportPage({super.key});

  @override
  State<CollectionReportPage> createState() => _CollectionReportPageState();
}

class _CollectionReportPageState extends State<CollectionReportPage> {
  DateTime? fromDate;
  DateTime? toDate;

  // UPDATED SAMPLE DATA WITH RECEIPT, COLLECTED, PENDING & TOTAL
  List<Map<String, String>> allCollectionData = [
    {
      "date": "18/01/2026",
      "customer": "Rahul",
      "receipt": "RCPT-001",
      "amount": "1500",
      "pending": "500",
      "mode": "Cash"
    },
    {
      "date": "19/01/2026",
      "customer": "Arun",
      "receipt": "RCPT-002",
      "amount": "3200",
      "pending": "0",
      "mode": "Bank"
    },
    {
      "date": "20/01/2026",
      "customer": "Kiran",
      "receipt": "RCPT-003",
      "amount": "2100",
      "pending": "900",
      "mode": "Card"
    },
  ];

  List<Map<String, String>> filteredCollectionData = [];

  @override
  void initState() {
    super.initState();
    filteredCollectionData = List.from(allCollectionData);
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
    filteredCollectionData.sort((a, b) {
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
      filteredCollectionData = allCollectionData.where((item) {
        DateTime collectionDate = parseDate(item["date"]!);

        return collectionDate.isAfter(fromDate!.subtract(const Duration(days: 1))) &&
            collectionDate.isBefore(toDate!.add(const Duration(days: 1)));
      }).toList();

      sortByDate();
    });
  }

  int getTotalCollection() {
    int total = 0;

    for (var item in filteredCollectionData) {
      total += int.tryParse(item["amount"] ?? "0") ?? 0;
    }

    return total;
  }

  int getTotalPending() {
    int total = 0;

    for (var item in filteredCollectionData) {
      total += int.tryParse(item["pending"] ?? "0") ?? 0;
    }

    return total;
  }

  int getGrandTotal() {
    return getTotalCollection() + getTotalPending();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Collection Report",
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
                    "Total Amount",
                    "₹ ${getGrandTotal()}",
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard(
                    "Collected",
                    "₹ ${getTotalCollection()}",
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    "Pending",
                    "₹ ${getTotalPending()}",
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Expanded(
              child: filteredCollectionData.isEmpty
                  ? const Center(
                child: Text(
                  "No collection found",
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: filteredCollectionData.length,
                itemBuilder: (context, index) {
                  final item = filteredCollectionData[index];

                  int collected =
                      int.tryParse(item["amount"] ?? "0") ?? 0;
                  int pending =
                      int.tryParse(item["pending"] ?? "0") ?? 0;

                  int total = collected + pending;

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
                                item["receipt"]!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(item["date"]!),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            item["customer"]!,
                            style: const TextStyle(fontSize: 15),
                          ),

                          const SizedBox(height: 6),

                          Text("Mode: ${item["mode"]}"),

                          const Divider(height: 20),

                          Text(
                            "Total Amount: ₹ $total",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Collected: ₹ $collected"),
                              Text(
                                "Pending: ₹ $pending",
                                style: const TextStyle(
                                  color: Colors.red,
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
