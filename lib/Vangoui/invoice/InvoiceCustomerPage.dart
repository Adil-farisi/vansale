import 'package:flutter/material.dart';
import '../shared_bills.dart';
import 'CustomerInvoiceListPage.dart';

class InvoiceCustomerPage extends StatelessWidget {
  const InvoiceCustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          "Customers",
          style: TextStyle(color: Colors.white),
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

          final invoices = snapshot.data!;

          // --------- GET UNIQUE CUSTOMERS ONLY ---------
          final Set<String> customerSet = {};

          for (var bill in invoices) {
            String name = bill["customer"] ?? "";
            if (name.isNotEmpty) {
              customerSet.add(name);
            }
          }

          final List<String> customers = customerSet.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];

              return _customerCard(context, customer);
            },
          );
        },
      ),
    );
  }

  // ---------------- CUSTOMER CARD UI ----------------
  Widget _customerCard(BuildContext context, String customer) {
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.person, color: Colors.blue),
        ),
        title: Text(
          customer,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerInvoiceListPage(
                customerName: customer,
              ),
            ),
          );
        },
      ),
    );
  }
}
