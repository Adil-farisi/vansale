import 'package:flutter/material.dart';

import 'InvoiceListPage.dart';


class ReceiptPage extends StatefulWidget {
  const ReceiptPage({super.key});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  bool showError = false;

  final customerNameController = TextEditingController();
  final dueAmountController = TextEditingController();
  final receivedAmountController = TextEditingController();
  final notesController = TextEditingController();
  final receivedDateController = TextEditingController();

  DateTime? receivedDate;
  String? amountTo;

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: receivedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        receivedDate = picked;
        receivedDateController.text =
        "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  void dispose() {
    customerNameController.dispose();
    dueAmountController.dispose();
    receivedAmountController.dispose();
    notesController.dispose();
    receivedDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Receipt',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildField("Customer Name", controller: customerNameController),
            if (showError && customerNameController.text.isEmpty)
              _errorText("Customer Name is required"),

            _buildField(
              "Due Amount",
              controller: dueAmountController,
              keyboardType: TextInputType.number,
            ),
            if (showError &&
                (dueAmountController.text.isEmpty ||
                    double.tryParse(dueAmountController.text) == null))
              _errorText("Enter valid Due Amount"),

            /// RECEIVED DATE (FIXED)
            InkWell(
              onTap: () => _pickDate(context),
              child: IgnorePointer(
                child: _buildField(
                  "Received Date",
                  controller: receivedDateController,
                  readOnly: true,
                  icon: Icons.calendar_today,
                ),
              ),
            ),
            if (showError && receivedDate == null)
              _errorText("Received Date is required"),

            _buildField(
              "Received Amount",
              controller: receivedAmountController,
              keyboardType: TextInputType.number,
            ),
            if (showError &&
                (receivedAmountController.text.isEmpty ||
                    double.tryParse(receivedAmountController.text) == null))
              _errorText("Enter valid Received Amount"),

            _buildDropdown(),

            _buildField(
              "Notes",
              controller: notesController,
              maxLines: 5,
            ),

            const SizedBox(height: 30),
            _saveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      String label, {
        TextEditingController? controller,
        int maxLines = 1,
        bool readOnly = false,
        IconData? icon,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Card(
            elevation: 3,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: TextFormField(
              controller: controller,
              readOnly: readOnly,
              maxLines: maxLines,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: label,
                prefixIcon: icon != null
                    ? Icon(icon, color: Colors.blue.shade800)
                    : null,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Amount To",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Card(
            elevation: 3,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: amountTo,
                  hint: const Text("Select"),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: "Cash", child: Text("Cash")),
                    DropdownMenuItem(value: "Bank", child: Text("Bank")),
                  ],
                  onChanged: (v) => setState(() => amountTo = v),
                ),
              ),
            ),
          ),
          if (showError && amountTo == null)
            _errorText("Please select Amount To"),
        ],
      ),
    );
  }

  Widget _errorText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.red, fontSize: 13),
      ),
    );
  }

  Widget _saveButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade800,
          minimumSize: const Size(200, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          setState(() => showError = true);

          if (customerNameController.text.isNotEmpty &&
              dueAmountController.text.isNotEmpty &&
              double.tryParse(dueAmountController.text) != null &&
              receivedDate != null &&
              receivedAmountController.text.isNotEmpty &&
              double.tryParse(receivedAmountController.text) != null &&
              amountTo != null) {

            /// OPTIONAL: SHOW MESSAGE
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Receipt saved successfully!"),
                duration: Duration(milliseconds: 800),
              ),
            );

            /// ✅ GO TO RECEIPT LIST PAGE
            Future.delayed(const Duration(milliseconds: 800), () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const InvoiceListPage(),
                ),
              );
            });
          }
        },
        child: const Text(
          "Save",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

}