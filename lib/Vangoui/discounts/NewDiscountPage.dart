import 'package:flutter/material.dart';

class NewDiscountPage extends StatefulWidget {
  const NewDiscountPage({super.key});

  @override
  State<NewDiscountPage> createState() => _NewDiscountPageState();
}

class _NewDiscountPageState extends State<NewDiscountPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _dueAmountController = TextEditingController(
    text: '₹2,500', // Hardcoded due amount
  );
  final TextEditingController _discountDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _customerNameController.dispose();
    _dueAmountController.dispose();
    _discountDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // In NewDiscountPage.dart, update the _saveDiscount method:
  void _saveDiscount() {
    if (_formKey.currentState!.validate()) {
      // Prepare discount data to return
      final discountData = {
        'customerName': _customerNameController.text,
        'date': _discountDateController.text,
        'notes': _notesController.text,
        'discountAmount': '₹500', // You can make this dynamic if needed
      };

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discount saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Wait for the snackbar to show, then pop with data
      Future.delayed(const Duration(milliseconds: 100), () {
        Navigator.pop(context, discountData);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final formattedDate =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      _discountDateController.text = formattedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Discount',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title
              const Center(
                child: Text(
                  'Add Discount Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Customer Name Field
              _buildFormField(
                label: 'Customer Name',
                hintText: 'Enter customer name',
                controller: _customerNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
                icon: Icons.person,
              ),
              const SizedBox(height: 16),

              // Due Amount Field (Read Only)
              _buildReadOnlyField(
                label: 'Due Amount',
                value: '₹2,500', // Hardcoded due amount
                icon: Icons.currency_rupee,
              ),
              const SizedBox(height: 16),

              // Discount Date Field
              _buildFormField(
                label: 'Discount Date',
                hintText: 'DD/MM/YYYY',
                controller: _discountDateController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter discount date';
                  }
                  return null;
                },
                icon: Icons.calendar_today,
                onTap: () {
                  // Show date picker
                  _selectDate(context);
                },
              ),
              const SizedBox(height: 16),

              // Notes Field
              _buildFormField(
                label: 'Notes',
                hintText: 'Enter discount notes (optional)',
                controller: _notesController,
                validator: (value) {
                  // Notes are optional, so no validation needed
                  return null;
                },
                icon: Icons.note,
                maxLines: 3,
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveDiscount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Save Discount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build editable form field
  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required IconData icon,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          onTap: onTap,
          readOnly: onTap != null,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(
              icon,
              color: Colors.blue.shade600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 14,
            ),
            suffixIcon: onTap != null
                ? Icon(
              Icons.calendar_month,
              color: Colors.grey.shade600,
            )
                : null,
          ),
        ),
      ],
    );
  }

  // Build read-only field for Due Amount
  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(
                Icons.lock,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Due amount is read-only',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}