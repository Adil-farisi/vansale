import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SingleReceiptViewPage extends StatefulWidget {
  final Map<String, dynamic> receipt;

  const SingleReceiptViewPage({
    super.key,
    required this.receipt,
  });

  @override
  State<SingleReceiptViewPage> createState() => _SingleReceiptViewPageState();
}

class _SingleReceiptViewPageState extends State<SingleReceiptViewPage> {
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  // API data
  Map<String, dynamic>? receiptDetails;
  Map<String, dynamic>? customerDetails;

  // API URL
  final String apiUrl = "http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/single-receipt-view.php";

  @override
  void initState() {
    super.initState();
    print("🚀 SingleReceiptViewPage initialized");
    print("📋 Receipt ID from navigation: ${widget.receipt["rcpid"]}");
    print("📋 Receipt No: ${widget.receipt["receiptNo"]}");
    print("📋 Customer: ${widget.receipt["customerName"]}");

    _fetchReceiptDetails();
  }

  Future<void> _fetchReceiptDetails() async {
    print("🔄 Fetching receipt details from API...");

    // Request body parameters
    final Map<String, String> requestBody = {
      "unid": "20260117130317",
      "veh": "MQ--",
      "rcpid": widget.receipt["rcpid"] ?? ""
    };

    print("🌐 API URL: $apiUrl");
    print("📦 Request Body: $requestBody");

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      print("🌐 Making HTTP POST request...");
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print("✅ HTTP Response received");
      print("📊 Status Code: ${response.statusCode}");
      print("📄 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("📋 Parsed Response Data: ${responseData['result']}");

        if (responseData['result'] == "1") {
          print("✅ API call successful");

          // Extract receipt details
          receiptDetails = {
            "rcp_no": responseData['rcp_no'],
            "rcp_date": responseData['rcp_date'],
            "wlt_name": responseData['wlt_name'],
            "notes": responseData['notes'],
            "rcp_amt": responseData['rcp_amt'],
            "rcp_words": responseData['rcp_words'],
          };

          print("📝 Receipt Details:");
          print("   Receipt No: ${receiptDetails!['rcp_no']}");
          print("   Date: ${receiptDetails!['rcp_date']}");
          print("   Amount: ₹${receiptDetails!['rcp_amt']}");
          print("   Amount in Words: ${receiptDetails!['rcp_words']}");

          // Extract customer details
          if (responseData['customerdet'] != null &&
              responseData['customerdet'].isNotEmpty) {
            customerDetails = responseData['customerdet'][0];
            print("👤 Customer Details:");
            print("   Name: ${customerDetails!['custname']}");
            print("   Phone: ${customerDetails!['phone']}");
            print("   State: ${customerDetails!['state']}");
          } else {
            print("⚠️ No customer details in response");
            // Use data from navigation if available
            customerDetails = {
              "custname": widget.receipt["customerName"],
              "phone": widget.receipt["whatsappNo"] ?? "",
              "state": "",
            };
          }

          setState(() {
            isLoading = false;
          });

          print("✅ Successfully loaded receipt details");
        } else {
          print("❌ API returned result: ${responseData['result']}");
          print("❌ Error message: ${responseData['message']}");
          setState(() {
            hasError = true;
            errorMessage = responseData['message'] ?? 'Failed to load receipt details';
            isLoading = false;
          });
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
        setState(() {
          hasError = true;
          errorMessage = 'HTTP Error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌❌❌ EXCEPTION CAUGHT!");
      print("❌ Error: $e");
      print("❌ Stack trace: ${e.toString()}");
      setState(() {
        hasError = true;
        errorMessage = 'Network Error: $e';
        isLoading = false;
      });
    }

    print("🏁 _fetchReceiptDetails() completed. Loading: $isLoading, Error: $hasError");
  }

  @override
  Widget build(BuildContext context) {
    print("🎨 Building SingleReceiptViewPage UI...");
    print("   isLoading: $isLoading");
    print("   hasError: $hasError");
    print("   receiptDetails: ${receiptDetails != null ? 'Loaded' : 'Not Loaded'}");
    print("   customerDetails: ${customerDetails != null ? 'Loaded' : 'Not Loaded'}");

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Receipt",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            print("↩️ Back button pressed");
            Navigator.pop(context);
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      print("⏳ Showing loading indicator");
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading receipt details...'),
          ],
        ),
      );
    }

    if (hasError) {
      print("❌ Showing error state");
      print("   Error message: $errorMessage");
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading receipt',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print("🔄 Retry button pressed");
                _fetchReceiptDetails();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    print("✅ Showing receipt details");
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple Receipt Title
          const Text(
            "Receipt",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 24),

          // "Received From" Section with phone
          const Text(
            "Received From",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            customerDetails?['custname'] ?? widget.receipt["customerName"],
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          if (customerDetails?['phone'] != null && customerDetails!['phone'].isNotEmpty)
            Text(
              "Ph : ${customerDetails!['phone']}",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          if (customerDetails?['state'] != null && customerDetails!['state'].isNotEmpty)
            Text(
              "State : ${customerDetails!['state']}",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

          const SizedBox(height: 20),

          // Horizontal divider line
          Container(
            height: 1,
            color: Colors.grey.shade300,
          ),

          const SizedBox(height: 20),

          // Date and Receipt No in a row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Date",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    receiptDetails?['rcp_date'] ?? widget.receipt["date"],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Receipt No",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    receiptDetails?['rcp_no'] ?? widget.receipt["receiptNo"],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Divider line (long dash style)
          Container(
            height: 1,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
                style: BorderStyle.none,
              ),
            ),
            child: Row(
              children: List.generate(
                30,
                    (index) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 2),
                    height: 1,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Amount in Words Section
          const Text(
            "Amount In Words",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            receiptDetails?['rcp_words'] ?? _getAmountInWords(widget.receipt["receivedAmount"]?.toString() ?? "0"),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 20),

          // Amount in Numbers
          const Text(
            "Amount",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "₹${_formatAmount(receiptDetails?['rcp_amt'] ?? widget.receipt["receivedAmount"])}",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 20),

          // Notes (if exists)
          if ((receiptDetails?['notes'] != null && receiptDetails!['notes'].isNotEmpty) ||
              (widget.receipt["notes"] != null && widget.receipt["notes"].isNotEmpty))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Notes",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  receiptDetails?['notes'] ?? widget.receipt["notes"],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 40),

          // Simple Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                print("📌 Close button pressed");
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Close",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format amount with commas
  String _formatAmount(String amountStr) {
    try {
      // Remove any existing commas and non-numeric characters
      final cleanAmount = amountStr.replaceAll(RegExp(r'[^0-9.]'), '');
      final amount = double.tryParse(cleanAmount) ?? 0;

      // Format with commas
      final parts = amount.toStringAsFixed(2).split('.');
      final integerPart = parts[0];
      final decimalPart = parts.length > 1 ? parts[1] : '00';

      String formatted = '';
      int count = 0;

      for (int i = integerPart.length - 1; i >= 0; i--) {
        formatted = integerPart[i] + formatted;
        count++;
        if (count % 3 == 0 && i != 0) {
          formatted = ',$formatted';
        }
      }

      return '$formatted.$decimalPart';
    } catch (e) {
      print("⚠️ Error formatting amount: $amountStr - $e");
      return amountStr;
    }
  }

  String _getAmountInWords(String amountStr) {
    print("💰 Converting amount to words: $amountStr");

    // Remove commas and get numeric value
    final cleanAmount = amountStr.replaceAll(RegExp(r'[^0-9.]'), '');
    final amount = double.tryParse(cleanAmount) ?? 0;

    if (amount == 0) return "Zero Rupees Only";

    final rupees = amount.floor();
    final paise = ((amount - rupees) * 100).round();

    String rupeesInWords = _convertToWords(rupees);
    String result = "${rupeesInWords}Rupees";

    if (paise > 0) {
      String paiseInWords = _convertToWords(paise);
      result += " and ${paiseInWords}Paise";
    }

    return result + " Only";
  }

  String _convertToWords(int number) {
    if (number == 0) return "";

    final ones = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten",
      "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen",
      "Eighteen", "Nineteen"];
    final tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];

    if (number < 20) {
      return ones[number] + " ";
    }

    if (number < 100) {
      return tens[number ~/ 10] + (number % 10 != 0 ? " " + ones[number % 10] : "") + " ";
    }

    if (number < 1000) {
      return ones[number ~/ 100] + " Hundred" + (number % 100 != 0 ? " " + _convertToWords(number % 100) : "");
    }

    if (number < 100000) {
      return _convertToWords(number ~/ 1000) + " Thousand" + (number % 1000 != 0 ? " " + _convertToWords(number % 1000) : "");
    }

    if (number < 10000000) {
      return _convertToWords(number ~/ 100000) + " Lakh" + (number % 100000 != 0 ? " " + _convertToWords(number % 100000) : "");
    }

    return _convertToWords(number ~/ 10000000) + " Crore" + (number % 10000000 != 0 ? " " + _convertToWords(number % 10000000) : "");
  }
}