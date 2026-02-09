import 'package:flutter/material.dart';

class NewChequePage extends StatefulWidget {
  const NewChequePage({super.key});

  @override
  State<NewChequePage> createState() => _NewChequePageState();
}

class _NewChequePageState extends State<NewChequePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _chequeDateController = TextEditingController();
  final TextEditingController _chequeNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

  @override
  void dispose() {
    _customerNameController.dispose();
    _chequeDateController.dispose();
    _chequeNumberController.dispose();
    _amountController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  void _saveCheque() {
    if (_formKey.currentState!.validate()) {
      // Prepare cheque data to return
      final chequeData = {
        'customerName': _customerNameController.text,
        'chequeNo': _chequeNumberController.text,
        'date': _chequeDateController.text,
        'wallet': 'Bank', // Default value
        'bankName': _bankNameController.text.isNotEmpty ? _bankNameController.text : 'Bank', // Use bank name if provided
        'amount': '₹${_amountController.text}',
      };

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cheque saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Wait for the snackbar to show, then pop with data
      Future.delayed(const Duration(milliseconds: 100), () {
        Navigator.pop(context, chequeData);
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
      _chequeDateController.text = formattedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Cheque',
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
                  'Add Cheque Details',
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

              // Cheque Date Field
              _buildFormField(
                label: 'Cheque Date',
                hintText: 'DD/MM/YYYY',
                controller: _chequeDateController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cheque date';
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

              // Cheque Number Field
              _buildFormField(
                label: 'Cheque Number',
                hintText: 'Enter cheque number',
                controller: _chequeNumberController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cheque number';
                  }
                  return null;
                },
                icon: Icons.confirmation_number,
              ),
              const SizedBox(height: 16),

              // Bank Name Field
              _buildFormField(
                label: 'Bank Name',
                hintText: 'Enter bank name (optional)',
                controller: _bankNameController,
                validator: (value) {
                  // Bank name is optional, so no validation needed
                  return null;
                },
                icon: Icons.account_balance,
              ),
              const SizedBox(height: 16),

              // Amount Field
              _buildFormField(
                label: 'Amount',
                hintText: 'Enter amount',
                controller: _amountController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
                icon: Icons.currency_rupee,
                isAmount: true,
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCheque,
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
                    'Save Cheque',
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

  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required IconData icon,
    bool isAmount = false,
    VoidCallback? onTap,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixText: isAmount ? '₹ ' : null,
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
}