// stocks/stock_main_page.dart
import 'package:flutter/material.dart';
import 'package:van_go/Vangoui/stocks/TradingItemsPage.dart';
import 'package:van_go/Vangoui/stocks/FinishedGoodsPage.dart';
import 'package:van_go/Vangoui/stocks/BatchWiseStockPage.dart';
import 'package:van_go/Vangoui/stocks/current_stock_page.dart';
import 'package:van_go/Vangoui/stocks/load_stock_page.dart';
import 'package:van_go/Vangoui/stocks/return_stock_page.dart';

class StockMainPage extends StatelessWidget {
  const StockMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Select Stock Option',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ),

            // Grid of stock options
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildStockOption(
                    context,
                    icon: Icons.inventory_2,
                    title: 'Trading Items',
                    subtitle: 'View trading items',
                    color: Colors.blue,
                    page: const TradingItemsPage(),
                  ),
                  _buildStockOption(
                    context,
                    icon: Icons.inventory_2,
                    title: 'Finished Goods',
                    subtitle: 'View finished goods',
                    color: Colors.green,
                    page: const FinishedGoodsPage(),
                  ),
                  _buildStockOption(
                    context,
                    icon: Icons.confirmation_number,
                    title: 'Batch-wise Stock',
                    subtitle: 'View batch stock',
                    color: Colors.purple,
                    page: const BatchWiseStockPage(),
                  ),
                  _buildStockOption(
                    context,
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Current Stock',
                    subtitle: 'View current stock',
                    color: Colors.orange,
                    page: const CurrentStockPage(),
                  ),
                  _buildStockOption(
                    context,
                    icon: Icons.add_box_outlined,
                    title: 'Load Stock',
                    subtitle: 'Load new stock',
                    color: Colors.teal,
                    page: const LoadStockPage(),
                  ),
                  _buildStockOption(
                    context,
                    icon: Icons.move_down_outlined,
                    title: 'Return Stock',
                    subtitle: 'Return stock',
                    color: Colors.red,
                    page: const ReturnStockPage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required Widget page,
      }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}