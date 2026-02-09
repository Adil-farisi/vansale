import 'package:flutter/material.dart';

class EditReceiptPage extends StatefulWidget {
  final Map<String, dynamic> receipt;
  final Function(Map<String, dynamic>) onSave;

  const EditReceiptPage({
    super.key,
    required this.receipt,
    required this.onSave,
  });

  @override
  State<EditReceiptPage> createState() => _EditReceiptPageState();
}

class _EditReceiptPageState extends State<EditReceiptPage> {
  bool showError = false;

  late TextEditingController customerCtrl;
  late TextEditingController totalCtrl;
  late TextEditingController gstCtrl;
  late TextEditingController discountCtrl;
  late TextEditingController billCtrl;
  late TextEditingController receivedCtrl;
  late TextEditingController balanceCtrl;
  late TextEditingController notesCtrl;

  String? paymentMethod;

  @override
  void initState() {
    super.initState();

    customerCtrl = TextEditingController(
      text: widget.receipt["customer"] ?? "",
    );

    totalCtrl = TextEditingController(text: widget.receipt["total"] ?? "0");

    gstCtrl = TextEditingController(text: widget.receipt["gst"] ?? "0");

    discountCtrl = TextEditingController(
      text: widget.receipt["discount"] ?? "0",
    );

    billCtrl = TextEditingController(text: widget.receipt["billAmount"] ?? "0");

    receivedCtrl = TextEditingController(
      text: widget.receipt["received"] ?? "0",
    );

    balanceCtrl = TextEditingController(text: widget.receipt["balance"] ?? "0");

    notesCtrl = TextEditingController(text: widget.receipt["notes"] ?? "");

    paymentMethod = widget.receipt["paymentMethod"];

    /// 🔥 Auto recalc
    billCtrl.addListener(_recalculateBalance);
    receivedCtrl.addListener(_recalculateBalance);
  }

  void _recalculateBalance() {
    final bill = double.tryParse(billCtrl.text) ?? 0;
    final received = double.tryParse(receivedCtrl.text) ?? 0;

    final bal = bill - received;

    balanceCtrl.text = bal.toStringAsFixed(2);
  }

  @override
  void dispose() {
    billCtrl.removeListener(_recalculateBalance);
    receivedCtrl.removeListener(_recalculateBalance);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Receipt",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _label("Customer"),
            _lockedBox(customerCtrl.text),

            const SizedBox(height: 14),

            _label("Payment Method"),
            _dropdown(),

            const SizedBox(height: 14),

            // NOT EDITABLE
            _field("Total Amount", controller: totalCtrl, readOnly: true),
            _field("GST Amount", controller: gstCtrl, readOnly: true),
            _field("Discount", controller: discountCtrl, readOnly: true),
            _field("Bill Amount", controller: billCtrl, readOnly: true),

            // EDITABLE
            _field("Received Amount", controller: receivedCtrl),

            // LOCKED BALANCE
            _lockedField("Balance", balanceCtrl),

            // EDITABLE
            _field("Notes", controller: notesCtrl, maxLines: 4),

            const SizedBox(height: 24),

            _saveButton(),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      t,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );

  Widget _lockedBox(String value) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      value,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    ),
  );

  Widget _dropdown() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: paymentMethod,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: "Cash", child: Text("Cash")),
              DropdownMenuItem(value: "Bank", child: Text("Bank")),
            ],
            onChanged: (v) => setState(() => paymentMethod = v),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label, {
    required TextEditingController controller,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _label(label),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              readOnly: readOnly,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔒 NON-EDITABLE BALANCE FIELD
  Widget _lockedField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _label(label),
          Card(
            elevation: 0,
            color: Colors.grey.shade200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              controller: controller,
              readOnly: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade800,
        minimumSize: const Size(220, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () {
        if (paymentMethod == null) {
          setState(() => showError = true);
          return;
        }

        widget.onSave({
          "receiptNo": widget.receipt["receiptNo"],
          "customer": customerCtrl.text,
          "paymentMethod": paymentMethod,
          "total": totalCtrl.text,
          "gst": gstCtrl.text,
          "discount": discountCtrl.text,
          "billAmount": billCtrl.text,
          "received": receivedCtrl.text,
          "balance": balanceCtrl.text,
          "notes": notesCtrl.text,
          "date": widget.receipt["date"],
          "time": widget.receipt["time"],
          "items": widget.receipt["items"],
        });

        Navigator.pop(context);
      },
      child: const Text(
        "Save Changes",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
