import 'package:flutter/material.dart';

class ViewSupplierPage extends StatefulWidget {
  final Map<String, dynamic> supplier;

  const ViewSupplierPage({super.key, required this.supplier});

  @override
  State<ViewSupplierPage> createState() => _ViewSupplierPageState();
}

class _ViewSupplierPageState extends State<ViewSupplierPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      // App Bar
      appBar: AppBar(
        title: const Text(
          'Supplier Details',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Supplier Name Card
            _buildDetailCard(
              icon: Icons.business_outlined,
              title: 'Supplier Name',
              value: widget.supplier['name'] ?? 'N/A',
              iconColor: Colors.blue,
            ),

            const SizedBox(height: 16),

            // GST Number Card
            _buildDetailCard(
              icon: Icons.numbers,
              title: 'GST Number',
              value:
                  widget.supplier['gst']?.isNotEmpty == true
                      ? widget.supplier['gst']
                      : 'N/A',
              iconColor: Colors.purple,
            ),

            const SizedBox(height: 16),

            // Contact Information Section
            _buildSectionHeader("Contact Information"),
            const SizedBox(height: 12),

            // Email Card
            _buildDetailCard(
              icon: Icons.email_outlined,
              title: 'Email',
              value:
                  widget.supplier['email']?.isNotEmpty == true
                      ? widget.supplier['email']
                      : 'N/A',
              iconColor: Colors.red,
            ),

            const SizedBox(height: 12),

            // Phone Number Card
            _buildDetailCard(
              icon: Icons.phone_outlined,
              title: 'Phone Number',
              value:
                  widget.supplier['phone']?.isNotEmpty == true
                      ? widget.supplier['phone']
                      : 'N/A',
              iconColor: Colors.green,
            ),

            const SizedBox(height: 12),

            // Land Phone Number Card
            _buildDetailCard(
              icon: Icons.phone,
              title: 'Land Phone Number',
              value:
                  widget.supplier['landPhone']?.isNotEmpty == true
                      ? widget.supplier['landPhone']
                      : 'N/A',
              iconColor: Colors.orange,
            ),

            const SizedBox(height: 12),

            // Address Card
            _buildDetailCard(
              icon: Icons.location_on_outlined,
              title: 'Address',
              value:
                  widget.supplier['address']?.isNotEmpty == true
                      ? widget.supplier['address']
                      : 'N/A',
              iconColor: Colors.teal,
            ),

            const SizedBox(height: 16),

            // Location Information Section
            _buildSectionHeader("Location Information"),
            const SizedBox(height: 12),

            // State and State Code in a row
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    icon: Icons.map_outlined,
                    title: 'State',
                    value:
                        widget.supplier['state']?.isNotEmpty == true
                            ? widget.supplier['state']
                            : 'N/A',
                    iconColor: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailCard(
                    icon: Icons.pin_outlined,
                    title: 'State Code',
                    value:
                        widget.supplier['stateCode']?.isNotEmpty == true
                            ? widget.supplier['stateCode']
                            : 'N/A',
                    iconColor: Colors.cyan,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Financial Information Section
            _buildSectionHeader("Financial Information"),
            const SizedBox(height: 12),

            // Opening Balance and Balance Type in a row
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Opening Balance',
                    value:
                        widget.supplier['balance'] != null
                            ? _formatCurrency(widget.supplier['balance'])
                            : '₹ 0.00',
                    iconColor: Colors.deepPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailCard(
                    icon: Icons.compare_arrows,
                    title: 'Balance Type',
                    value: widget.supplier['balanceType'] ?? 'Dr',
                    iconColor: Colors.amber.shade800,
                    valueColor:
                        widget.supplier['balanceType'] == 'Dr'
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status Card
            _buildDetailCard(
              icon: Icons.circle,
              title: 'Status',
              value:
                  widget.supplier['isActive'] == true ? 'Active' : 'Inactive',
              iconColor:
                  widget.supplier['isActive'] == true
                      ? Colors.green
                      : Colors.red,
              valueColor:
                  widget.supplier['isActive'] == true
                      ? Colors.green.shade700
                      : Colors.red.shade700,
            ),

            const SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to edit page
                      Navigator.pop(context, 'edit');
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue.shade800,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    Color? valueColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),

          // Title and value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹ 0.00';

    double value = 0.0;
    if (amount is int) {
      value = amount.toDouble();
    } else if (amount is double) {
      value = amount;
    } else if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    }

    return '₹ ${value.toStringAsFixed(2)}';
  }
}
