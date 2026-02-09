import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;


class ReceiptPreviewPage extends StatelessWidget {
  final Map<String, dynamic> receipt;

  const ReceiptPreviewPage({super.key, required this.receipt});

  // ---------------- AMOUNT IN WORDS ----------------

  String amountInWords(String? amount) {
    if (amount == null || amount.isEmpty) {
      return "Zero Rupees Only";
    }

    final cleanAmount = amount.replaceAll(',', '');

    final value = double.tryParse(cleanAmount);
    if (value == null) return "Zero Rupees Only";

    final int rupees = value.toInt();

    return "${_convertNumberToWords(rupees)} Rupees Only";
  }

  String _convertNumberToWords(int number) {
    if (number == 0) return "Zero";

    final units = [
      "",
      "One",
      "Two",
      "Three",
      "Four",
      "Five",
      "Six",
      "Seven",
      "Eight",
      "Nine",
      "Ten",
      "Eleven",
      "Twelve",
      "Thirteen",
      "Fourteen",
      "Fifteen",
      "Sixteen",
      "Seventeen",
      "Eighteen",
      "Nineteen"
    ];

    final tens = [
      "",
      "",
      "Twenty",
      "Thirty",
      "Forty",
      "Fifty",
      "Sixty",
      "Seventy",
      "Eighty",
      "Ninety"
    ];

    if (number < 20) return units[number];

    if (number < 100) {
      return tens[number ~/ 10] +
          (number % 10 != 0 ? " ${units[number % 10]}" : "");
    }

    if (number < 1000) {
      return "${units[number ~/ 100]} Hundred${number % 100 != 0 ? " ${_convertNumberToWords(number % 100)}" : ""}";
    }

    if (number < 100000) {
      return "${_convertNumberToWords(number ~/ 1000)} Thousand${number % 1000 != 0 ? " ${_convertNumberToWords(number % 1000)}" : ""}";
    }

    if (number < 10000000) {
      return "${_convertNumberToWords(number ~/ 100000)} Lakh${number % 100000 != 0 ? " ${_convertNumberToWords(number % 100000)}" : ""}";
    }

    return number.toString();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final displayDate =
        receipt["date"] ?? "${now.day}/${now.month}/${now.year}";

    final displayTime = receipt["time"] ??
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Receipt",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: _printReceipt,
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long,
                          size: 40, color: Colors.blue.shade800),
                      const SizedBox(height: 6),
                      const Text(
                        "RECEIPT",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Divider(thickness: 1.3, color: Colors.grey.shade400),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// DETAILS
                _sectionTitle("Receipt Details"),
                _infoRow("Received From", receipt["customer"] ?? ""),
                _infoRow("Date & Time", "$displayDate • $displayTime"),

                // Using date as fallback receipt no (or your own stored value)
                _infoRow("Receipt No", receipt["receiptNo"] ?? displayDate),

                const SizedBox(height: 18),
                Divider(color: Colors.grey.shade300),

                /// PAYMENT
                const SizedBox(height: 12),
                _sectionTitle("Payment Information"),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Amount",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(
                        "₹ ${receipt["received"] ?? '0.00'}",

                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Text("Amount in Words",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),

                Text(
                  amountInWords(receipt["received"]),
                  style: const TextStyle(color: Colors.black87),
                ),

                const SizedBox(height: 24),
                Divider(color: Colors.grey.shade300),







                /// SIGNATURES
                const SizedBox(height: 16),
                _sectionTitle("Authorization"),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _SignatureBox(title: "Authorized Signature"),
                    _SignatureBox(title: "Approved By"),
                  ],
                ),

                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    children: const [
                      SizedBox(width: 140, child: Divider(thickness: 1)),
                      Text("Signature",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text("$label :",
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt() async {
    await Printing.layoutPdf(
      onLayout: (format) async {
        final pdf = pw.Document();

        pdf.addPage(
          pw.Page(
            build: (context) {
              final items = List<Map<String, dynamic>>.from(
                  receipt["items"] ?? []);

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [

                  pw.Center(
                    child: pw.Text(
                      "VanGo Sales",
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 8),

                  pw.Center(
                    child: pw.Text(
                      "Receipt #${receipt["receiptNo"] ?? ''}",
                      style: pw.TextStyle(fontSize: 14),
                    ),
                  ),

                  pw.SizedBox(height: 10),
                  pw.Divider(),

                  pw.Text("Customer : ${receipt["customer"]}"),
                  pw.Text("Payment  : ${receipt["paymentMethod"]}"),
                  pw.Text("Date     : ${receipt["date"]}"),

                  pw.Divider(),

                  pw.SizedBox(height: 6),
                  pw.Text("Items",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold)),

                  pw.SizedBox(height: 6),

                  /// TABLE HEADER
                  pw.Row(children: [
                    pw.Expanded(flex: 4, child: pw.Text("Name")),
                    pw.Expanded(flex: 2,
                        child: pw.Text("Qty",
                            textAlign: pw.TextAlign.center)),
                    pw.Expanded(flex: 2,
                        child: pw.Text("Price",
                            textAlign: pw.TextAlign.center)),
                    pw.Expanded(flex: 2,
                        child: pw.Text("Total",
                            textAlign: pw.TextAlign.right)),
                  ]),

                  pw.Divider(),

                  /// ITEMS
                  ...items.map((e) => pw.Row(children: [
                    pw.Expanded(
                        flex: 4,
                        child: pw.Text("${e["productName"]}")),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text("${e["qty"]}",
                            textAlign: pw.TextAlign.center)),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text("₹${e["rate"]}",
                            textAlign: pw.TextAlign.center)),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text("₹${e["total"]}",
                            textAlign: pw.TextAlign.right)),
                  ])),

                  pw.Divider(),
                  pw.SizedBox(height: 6),

                  _amount("Total Amount", receipt["total"]),
                  _amount("GST Amount", receipt["gst"]),
                  _amount(
                    "Other Charges",
                    receipt["otherCharges"] ?? "0.00",

                  ),

                  _amount("Discount", receipt["discount"]),
                  _amount("Bill Amount", receipt["billAmount"],
                      bold: true),
                  _amount("Received", receipt["received"]),
                  _amount("Balance", receipt["balance"]),

                  pw.SizedBox(height: 12),
                  pw.Divider(),

                  pw.Center(
                    child: pw.Text(
                      "Thank You — Visit Again",
                      style: pw.TextStyle(fontSize: 12),
                    ),
                  )
                ],
              );
            },
          ),
        );

        return pdf.save();
      },
    );
  }

  /// Helper for aligned rows
  pw.Widget _amount(String label, dynamic value, {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label),
        pw.Text(
          "₹ $value",
          style: pw.TextStyle(
            fontWeight:
            bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }


}


/// SIGNATURE BOX
class _SignatureBox extends StatelessWidget {
  final String title;

  const _SignatureBox({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 130,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
