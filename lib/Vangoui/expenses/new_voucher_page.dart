import 'package:flutter/material.dart';
import 'expense_storage.dart';

class NewVoucherPage extends StatefulWidget {
  const NewVoucherPage({super.key});

  @override
  State<NewVoucherPage> createState() => _NewVoucherPageState();
}

class _NewVoucherPageState extends State<NewVoucherPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController remarkCtrl = TextEditingController();

  String? selectedCategory;
  String paymentMethod = "Cash";

  final List<String> categories = [
    "Petrol",
    "Food",
    "Travel",
    "Vehicle Maintenance",
    "Office Expense",
    "Miscellaneous",
  ];

  String _todayDate() {
    final now = DateTime.now();
    return "${now.day}/${now.month}/${now.year}";
  }

  Future<void> saveVoucher() async {
    if (!_formKey.currentState!.validate()) return;

    final voucher = {
      "voucherNo": "EXP-${DateTime.now().millisecondsSinceEpoch}",
      "date": _todayDate(),
      "category": selectedCategory,
      "amount": amountCtrl.text,
      "paymentMethod": paymentMethod,
      "remark": remarkCtrl.text,
    };

    await ExpenseStorage.saveExpense(voucher);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Voucher Saved Successfully"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  InputDecoration fieldDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.blue.shade800) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text(
          "New Voucher",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              /// MAIN CARD
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Expense Details",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        hint: const Text("Select Category"),
                        decoration: fieldDecoration(
                          "Expense Category",
                          icon: Icons.category,
                        ),

                        items: categories
                            .map(
                              (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          ),
                        )
                            .toList(),

                        onChanged: (v) {
                          setState(() {
                            selectedCategory = v;
                          });
                        },

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please select expense category";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: fieldDecoration(
                          "Amount",
                          icon: Icons.currency_rupee,
                        ),
                        validator: (v) =>
                        v == null || v.isEmpty ? "Enter amount" : null,
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: remarkCtrl,
                        maxLines: 2,
                        decoration: fieldDecoration(
                          "Remark (Optional)",
                          icon: Icons.note,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              /// PAYMENT METHOD CARD
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Payment Method",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text("Cash"),
                            selected: paymentMethod == "Cash",
                            selectedColor: Colors.blue.shade800,
                            labelStyle: TextStyle(
                              color: paymentMethod == "Cash"
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            onSelected: (_) {
                              setState(() {
                                paymentMethod = "Cash";
                              });
                            },
                          ),

                          const SizedBox(width: 12),

                          ChoiceChip(
                            label: const Text("Bank"),
                            selected: paymentMethod == "Bank",
                            selectedColor: Colors.blue.shade800,
                            labelStyle: TextStyle(
                              color: paymentMethod == "Bank"
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            onSelected: (_) {
                              setState(() {
                                paymentMethod = "Bank";
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: saveVoucher,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    "SAVE VOUCHER",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 3,
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
