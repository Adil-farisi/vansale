import 'package:flutter/material.dart';
import 'expense_storage.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text("Delete Expense"),
        content: const Text("Are you sure you want to delete this expense?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete",style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text(
          "Expense List",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
        elevation: 0,
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ExpenseStorage.loadExpenses(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No Expenses Found",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final expenses = snapshot.data!.reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: expenses.length,
            itemBuilder: (context, index) {

              final exp = expenses[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// HEADER ROW
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.blue.shade50,
                                child: Icon(
                                  Icons.category,
                                  color: Colors.blue.shade800,
                                  size: 20,
                                ),
                              ),

                              const SizedBox(width: 10),

                              Text(
                                exp["category"] ?? "",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) async {

                              if (value == "delete") {
                                bool yes = await _confirmDelete(context);

                                if (yes) {
                                  await ExpenseStorage.deleteExpense(index);

                                  setState(() {});
                                }
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: "delete",
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text("Delete"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      const Divider(height: 1),

                      const SizedBox(height: 10),

                      /// AMOUNT HIGHLIGHT
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Amount",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "₹ ${exp["amount"]}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      _infoRow(Icons.calendar_today, "Date", exp["date"]),
                      _infoRow(Icons.account_balance_wallet, "Payment", exp["paymentMethod"]),
                      _infoRow(Icons.note, "Remark", exp["remark"] ?? "-"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [

          Icon(icon, size: 18, color: Colors.blue.shade700),

          const SizedBox(width: 10),

          SizedBox(
            width: 80,
            child: Text(
              "$label :",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value ?? "",
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
