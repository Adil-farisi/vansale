import 'package:flutter/material.dart';

import '../stocks/TradingItemsPage.dart';
import '../stocks/FinishedGoodsPage.dart';
import '../stocks/BatchWiseStockPage.dart';
import '../stocks/current_stock_page.dart';
import '../stocks/load_stock_page.dart';
import '../stocks/return_stock_page.dart';

void showStockSectionSwitcher(
    BuildContext context,
    String currentPage,
    ) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      Widget tile(String title, IconData icon, Widget page) {
        final bool isActive = title == currentPage;

        return ListTile(
          leading: Icon(
            icon,
            color: isActive ? Colors.blue : Colors.black54,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight:
              isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.blue : Colors.black,
            ),
          ),
          trailing:
          isActive ? const Icon(Icons.check, color: Colors.blue) : null,
          onTap: isActive
              ? null
              : () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
          },
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Switch Stock Section",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            tile("Trading Items", Icons.inventory_2,
                const TradingItemsPage()),
            tile("Finished Goods", Icons.inventory,
                const FinishedGoodsPage()),
            tile("Batch-wise Stock", Icons.confirmation_number,
                const BatchWiseStockPage()),
            tile("Current Stock", Icons.assignment_turned_in,
                const CurrentStockPage()),
            tile("Load Stock", Icons.add_box,
                const LoadStockPage()),
            tile("Return Stock", Icons.move_down,
                const ReturnStockPage()),

            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}
