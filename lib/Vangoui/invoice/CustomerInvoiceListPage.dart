import 'package:flutter/material.dart';
import '../InvoiceListPage.dart';
import '../shared_bills.dart';
import '../receiptbill.dart';   // ✅ FIXED CORRECT PATH

class CustomerInvoiceListPage extends StatelessWidget {
  final String customerName;

  const CustomerInvoiceListPage({
    super.key,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: Text(
          customerName,
          style: const TextStyle(color: Colors.white),
        ),
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: BillStorage.loadBills(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No invoices found",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // -------- FILTER ONLY SELECTED CUSTOMER INVOICES --------
          final allInvoices = snapshot.data!;

          final customerInvoices = allInvoices
              .where((bill) =>
          (bill["customer"] ?? "").toString() == customerName)
              .toList()
              .reversed
              .toList(); // LATEST FIRST

          if (customerInvoices.isEmpty) {
            return const Center(
              child: Text(
                "No invoices for this customer",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: customerInvoices.length,
            itemBuilder: (context, index) {
              final invoice = customerInvoices[index];

              return _invoiceCard(context, invoice);
            },
          );
        },
      ),
    );
  }

  // ---------------- INVOICE CARD ----------------
  Widget _invoiceCard(BuildContext context, Map<String, dynamic> invoice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date + Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Invoice",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDate(invoice["date"]),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Amount Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _amountTile("Total", invoice["total"]),
                _amountTile("Discount", invoice["discount"]),
                _amountTile(
                  "Bill",
                  invoice["billAmount"],
                  bold: true,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InvoiceListPage(),

                    ),
                  );
                },
                child: const Text("View Invoice"),
              ),
            ),

          ],
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------
  Widget _amountTile(String label, dynamic value, {bool bold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          "₹${value ?? 0}",
          style: TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return "-";
    return dateValue.toString().split(" ").first;
  }
}
