import 'package:flutter/material.dart';

class ExpenseReportPage extends StatefulWidget {
  const ExpenseReportPage({super.key});

  @override
  State<ExpenseReportPage> createState() => _ExpenseReportPageState();
}

class _ExpenseReportPageState extends State<ExpenseReportPage> {
  DateTime? fromDate;
  DateTime? toDate;

  List<Map<String, String>> allExpenseData = [
    {
      "date": "18/01/2026",
      "category": "Fuel",
      "description": "Petrol",
      "amount": "800"
    },
    {
      "date": "18/01/2026",
      "category": "Food",
      "description": "Lunch",
      "amount": "250"
    },
    {
      "date": "19/01/2026",
      "category": "Maintenance",
      "description": "Van Repair",
      "amount": "1200"
    },
    {
      "date": "20/01/2026",
      "category": "Toll",
      "description": "Highway Toll",
      "amount": "300"
    },
  ];

  List<Map<String, String>> filteredExpenseData = [];

  @override
  void initState() {
    super.initState();
    filteredExpenseData = List.from(allExpenseData);
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
    filteredExpenseData.sort((a, b) {
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
      filteredExpenseData = allExpenseData.where((expense) {
        DateTime expenseDate = parseDate(expense["date"]!);

        return expenseDate
            .isAfter(fromDate!.subtract(const Duration(days: 1))) &&
            expenseDate.isBefore(toDate!.add(const Duration(days: 1)));
      }).toList();

      sortByDate();
    });
  }

  int getTotalExpense() {
    int total = 0;

    for (var expense in filteredExpenseData) {
      total += int.tryParse(expense["amount"] ?? "0") ?? 0;
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Expense Report",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
                    "Total Expense",
                    "₹ ${getTotalExpense()}",
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard(
                    "Total Entries",
                    filteredExpenseData.length.toString(),
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Expanded(
              child: filteredExpenseData.isEmpty
                  ? const Center(
                child: Text(
                  "No expenses found",
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: filteredExpenseData.length,
                itemBuilder: (context, index) {
                  final expense = filteredExpenseData[index];

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                                expense["category"]!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                expense["date"]!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            expense["description"]!,
                            style: const TextStyle(fontSize: 14),
                          ),

                          const Divider(height: 20),

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Amount",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "₹ ${expense["amount"]!}",
                                style: const TextStyle(
                                  fontSize: 16,
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
      elevation: 5,
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
