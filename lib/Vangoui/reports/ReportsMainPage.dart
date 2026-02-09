import 'package:flutter/material.dart';

import 'SalesReportPage.dart';
import 'ExpenseReportPage.dart';
import 'CollectionReportPage.dart';
import 'SalesReturnReportPage.dart';
import 'ProductReportPage.dart';

class ReportsMainPage extends StatelessWidget {
  const ReportsMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Reports",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _reportCard(
              context,
              title: "Sales Report",
              icon: Icons.point_of_sale,
              color: Colors.blue.shade700,
              page: const SalesReportPage(),
            ),
            _reportCard(
              context,
              title: "Expense Report",
              icon: Icons.money_off,
              color: Colors.red.shade700,
              page: const ExpenseReportPage(),
            ),
            _reportCard(
              context,
              title: "Collection Report",
              icon: Icons.account_balance_wallet,
              color: Colors.green.shade700,
              page: const CollectionReportPage(),
            ),
            _reportCard(
              context,
              title: "Sales Return Report",
              icon: Icons.assignment_return,
              color: Colors.orange.shade700,
              page: const SalesReturnReportPage(),
            ),
            _reportCard(
              context,
              title: "Product Report",
              icon: Icons.inventory,
              color: Colors.purple.shade700,
              page: const ProductReportPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required Widget page,
      }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.9),
                color.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
