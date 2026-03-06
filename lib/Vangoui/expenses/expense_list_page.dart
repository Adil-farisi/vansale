import 'package:flutter/material.dart';
import 'package:van_go/Vangoui/expenses/ExpenseVoucherMainPage.dart';

import 'UpdateVoucherPage.dart';
import 'ViewVoucherPage.dart';
import 'new_voucher_page.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  // Your original data structure
  List<Map<String, dynamic>> expenseList = [
    {
      'sno': 1,
      'date': '27-02-2026',
      'voucherNo': '101',
      'purchaseRef': 'PR-001',
      'supplierName': 'Adil Trading Co',
      'items': 3,
      'amount': 1250,
    },
    {
      'sno': 2,
      'date': '26-02-2026',
      'voucherNo': '102',
      'purchaseRef': 'PR-002',
      'supplierName': 'Rahul Enterprises',
      'items': 2,
      'amount': 850,
    },
    {
      'sno': 3,
      'date': '25-02-2026',
      'voucherNo': '103',
      'purchaseRef': 'PR-003',
      'supplierName': 'Priya Stores',
      'items': 5,
      'amount': 3200,
    },
    {
      'sno': 4,
      'date': '24-02-2026',
      'voucherNo': '104',
      'purchaseRef': 'PR-004',
      'supplierName': 'John Supplies',
      'items': 1,
      'amount': 450,
    },
    {
      'sno': 5,
      'date': '23-02-2026',
      'voucherNo': '105',
      'purchaseRef': 'PR-005',
      'supplierName': 'Smith & Co',
      'items': 4,
      'amount': 2100,
    },
  ];

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredExpenseList = [];

  @override
  void initState() {
    super.initState();
    filteredExpenseList = expenseList;
    _searchController.addListener(_filterExpenses);
  }

  void _filterExpenses() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredExpenseList = expenseList;
      } else {
        filteredExpenseList =
            expenseList.where((expense) {
              return expense['supplierName'].toLowerCase().contains(query) ||
                  expense['voucherNo'].toString().contains(query) ||
                  expense['purchaseRef'].toLowerCase().contains(query);
            }).toList();
      }
    });
  }

  String _formatAmount(num amount) {
    if (amount == amount.round()) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }

  void _showActionMenu(Map<String, dynamic> expense) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt, color: Colors.blue.shade800, size: 20),
              ),
              title: const Text('View Voucher'),
              onTap: () {
                Navigator.pop(context);

                Map<String, dynamic> voucherData = {
                  'paidTo': expense['supplierName'],
                  'voucherNo': expense['voucherNo'],
                  'date': expense['date'],
                  'purchaseRef': expense['purchaseRef'],
                  'items': [
                    {
                      'sno': 1,
                      'particulars': 'Item from ${expense['supplierName']}',
                      'category': 'Expense',
                      'amount': expense['amount'],
                    },
                  ],
                  'netAmount': expense['amount'],
                  'authorisedSignature': 'GST DEMO',
                  'approvedBy': '',
                  'signature': '',
                };

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewVoucherPage(voucher: voucherData),
                  ),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit, color: Colors.green.shade700, size: 20),
              ),
              title: const Text('Update Voucher'),
              onTap: () {
                Navigator.pop(context);

                Map<String, dynamic> voucherData = {
                  'paidTo': expense['supplierName'],
                  'voucherNo': expense['voucherNo'],
                  'date': expense['date'],
                  'purchaseRef': expense['purchaseRef'],
                  'items': [
                    {
                      'sno': 1,
                      'particulars': 'Item from ${expense['supplierName']}',
                      'category': 'Expense',
                      'amount': expense['amount'],
                    },
                  ],
                  'netAmount': expense['amount'],
                };

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateVoucherPage(voucher: voucherData),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  void dispose() {
    _searchController.removeListener(_filterExpenses);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = filteredExpenseList.fold(
      0,
      (sum, item) => sum + (item['amount'] as int),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Expense List",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by supplier, voucher no, or reference...",
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: Colors.blue,
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _filterExpenses();
                          },
                          padding: EdgeInsets.zero,
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                isDense: true,
              ),
            ),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt,
                            color: Colors.blue.shade800,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Customers",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              "${filteredExpenseList.length}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: Colors.green.shade700,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Expense",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              "₹ ${_formatAmount(totalAmount)}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Expense List
          Expanded(
            child:
                filteredExpenseList.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_outlined,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "No expenses found",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filteredExpenseList.length,
                      itemBuilder: (context, index) {
                        final expense = filteredExpenseList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              // Row 1: S.No, Supplier Name, Items Count
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            expense['sno'].toString(),
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            expense['supplierName'][0],
                                            style: TextStyle(
                                              color: Colors.blue.shade800,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            expense['supplierName'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            "Items: ${expense['items']}",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "₹${_formatAmount(expense['amount'])}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        "Total Amount",
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Row 2: Voucher No, Date, Purchase Ref, and Three-dot menu
                              Row(
                                children: [
                                  // Voucher No
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.receipt,
                                        size: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        "#${expense['voucherNo']}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),

                                  // Date
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        expense['date'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),

                                  // Purchase Ref
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.receipt_long,
                                        size: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        expense['purchaseRef'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Spacer(),

                                  // Three dot menu
                                  GestureDetector(
                                    onTap: () => _showActionMenu(expense),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.more_horiz,
                                        size: 16,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),

          // Add Button
          Padding(
            padding: const EdgeInsets.all(18),
            child: SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpenseVoucherMainPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  "Add Expense",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
