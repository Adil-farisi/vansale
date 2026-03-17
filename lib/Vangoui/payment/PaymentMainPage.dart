import 'package:flutter/material.dart';
import 'EditPaymentPage.dart';
import 'NewPaymentPage.dart';
import 'PaymentVoucherPage.dart'; // Add this import

class PaymentMainPage extends StatefulWidget {
  const PaymentMainPage({super.key});

  @override
  State<PaymentMainPage> createState() => _PaymentMainPageState();
}

class _PaymentMainPageState extends State<PaymentMainPage> {
  // Hardcoded payment data
  final List<Map<String, dynamic>> payments = [
    {
      'id': 1,
      'date': '12-03-2026',
      'voucherNo': 'PMT-2026-001',
      'supplierName': 'Ganesh Traders',
      'wallet': 'Bank',
      'notes': 'Payment for invoice INV-2026-001',
      'paidAmount': 25000.00,
    },
    {
      'id': 2,
      'date': '11-03-2026',
      'voucherNo': 'PMT-2026-002',
      'supplierName': 'Kumar Enterprises',
      'wallet': 'Bank',
      'notes': 'Advance payment for materials',
      'paidAmount': 15000.50,
    },
    {
      'id': 3,
      'date': '10-03-2026',
      'voucherNo': 'PMT-2026-003',
      'supplierName': 'Sri Lakshmi Agencies',
      'wallet': 'Cash',
      'notes': 'Partial payment',
      'paidAmount': 5000.00,
    },
    {
      'id': 4,
      'date': '09-03-2026',
      'voucherNo': 'PMT-2026-004',
      'supplierName': 'Murugan Store',
      'wallet': 'Bank',
      'notes': 'Final settlement',
      'paidAmount': 45200.75,
    },
    {
      'id': 5,
      'date': '08-03-2026',
      'voucherNo': 'PMT-2026-005',
      'supplierName': 'Vinayaga Enterprises',
      'wallet': 'Cash',
      'notes': 'Payment due',
      'paidAmount': 8750.25,
    },
    {
      'id': 6,
      'date': '07-03-2026',
      'voucherNo': 'PMT-2026-006',
      'supplierName': 'Balaji Traders',
      'wallet': 'Bank',
      'notes': 'Regular payment',
      'paidAmount': 12300.00,
    },
    {
      'id': 7,
      'date': '06-03-2026',
      'voucherNo': 'PMT-2026-007',
      'supplierName': 'Sri Venkateswara Stores',
      'wallet': 'Cash',
      'notes': 'Urgent payment',
      'paidAmount': 32500.00,
    },
  ];

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Filtered payments list
  List<Map<String, dynamic>> filteredPayments = [];

  @override
  void initState() {
    super.initState();
    filteredPayments = payments;
    _searchController.addListener(_filterPayments);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPayments);
    _searchController.dispose();
    super.dispose();
  }

  void _filterPayments() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredPayments = payments;
      } else {
        filteredPayments = payments.where((payment) {
          return payment['supplierName'].toLowerCase().contains(query) ||
              payment['voucherNo'].toLowerCase().contains(query) ||
              payment['wallet'].toLowerCase().contains(query) ||
              (payment['notes']?.toLowerCase() ?? '').contains(query);
        }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  String _formatCurrency(double amount) {
    return '₹ ${amount.toStringAsFixed(2)}';
  }

  Color _getWalletColor(String wallet) {
    return wallet == 'Cash' ? Colors.green : Colors.blue;
  }

  IconData _getWalletIcon(String wallet) {
    return wallet == 'Cash' ? Icons.money : Icons.account_balance;
  }

  void _editPayment(int id) {
    final payment = payments.firstWhere((p) => p['id'] == id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPaymentPage(payment: payment),
      ),
    ).then((updatedPayment) {
      if (updatedPayment != null) {
        setState(() {
          final index = payments.indexWhere((p) => p['id'] == id);
          if (index != -1) {
            payments[index] = updatedPayment;
          }
          _filterPayments();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _viewVoucher(int id) {
    final payment = payments.firstWhere((p) => p['id'] == id);

    // Add additional fields for the voucher
    final Map<String, dynamic> voucherData = {
      ...payment,
      'address': 'calicut, kerala', // You would get this from your data
      'gst': 'gst54321', // You would get this from your data
      'phone': '7654321098', // You would get this from your data
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentVoucherPage(payment: voucherData),
      ),
    );
  }

  void _deletePayment(int id) {
    print('Delete payment: $id');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text('Are you sure you want to delete this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                payments.removeWhere((p) => p['id'] == id);
                _filterPayments();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete',style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  void _addNewPayment() {
    print('Add new payment');

    // Navigate to NewPaymentPage and wait for result
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewPaymentPage(),
      ),
    ).then((result) {
      // Handle when returning from NewPaymentPage
      if (result == true) {
        // Show a confirmation snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Refresh the payment list if needed
        // You can add your refresh logic here
        // For example: _fetchPayments();
      }
    });
  }

  double _calculateTotalAmount() {
    double total = 0;
    for (var payment in filteredPayments) {
      total += payment['paidAmount'];
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      // App Bar with New Payment button
      appBar: AppBar(
        title: const Text(
          'Payments',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade800,
        elevation: 2,
        centerTitle: true,
        actions: [
          // New Payment Button
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _addNewPayment,
            tooltip: 'New Payment',
          ),

          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _filterPayments();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshed'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Refresh',
          ),
        ],
      ),

      // Search Bar
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by supplier, voucher, wallet...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: _clearSearch,
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Total Payments
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade50, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.receipt,
                                  size: 16,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            filteredPayments.length.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Total Amount
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade50, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.currency_rupee,
                                  size: 16,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Amount',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatCurrency(_calculateTotalAmount()),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Payments List
          Expanded(
            child: filteredPayments.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No payments found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchController.text.isEmpty
                        ? 'Add your first payment'
                        : 'Try a different search term',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredPayments.length,
              itemBuilder: (context, index) {
                final payment = filteredPayments[index];
                return _buildPaymentCard(payment, index + 1);
              },
            ),
          ),
        ],
      ),

      // FLOATING ACTION BUTTON REMOVED
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment, int serialNo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: S.No, Date, Voucher No, Three-dot Menu
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '#$serialNo',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 10,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              payment['date'],
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Icon(
                              Icons.receipt,
                              size: 10,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              payment['voucherNo'],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editPayment(payment['id']);
                          break;
                        case 'voucher':
                          _viewVoucher(payment['id']);
                          break;
                        case 'delete':
                          _deletePayment(payment['id']);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 14, color: Colors.orange),
                            SizedBox(width: 6),
                            Text('Edit', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'voucher',
                        child: Row(
                          children: [
                            Icon(Icons.receipt, size: 14, color: Colors.blue),
                            SizedBox(width: 6),
                            Text('View Voucher', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 14, color: Colors.red),
                            SizedBox(width: 6),
                            Text('Delete', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 14,
                      color: Colors.blue.shade800,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        payment['supplierName'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _getWalletColor(payment['wallet']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            _getWalletIcon(payment['wallet']),
                            size: 12,
                            color: _getWalletColor(payment['wallet']),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wallet',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                payment['wallet'],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _getWalletColor(payment['wallet']),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Paid',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.green.shade800,
                          ),
                        ),
                        Text(
                          _formatCurrency(payment['paidAmount']),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (payment['notes'] != null && payment['notes'].isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          payment['notes'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}