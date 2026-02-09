import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Add this import for navigation
import 'ChequeEditPage.dart';
import 'NewChequePage.dart';

class ChequesMainPage extends StatefulWidget {
  const ChequesMainPage({super.key});

  @override
  State<ChequesMainPage> createState() => _ChequesMainPageState();
}

class _ChequesMainPageState extends State<ChequesMainPage> {
  List<Map<String, dynamic>> cheques = [];
  bool isLoading = false;
  final TextEditingController searchController = TextEditingController();

  // Hardcoded sample data with bankName for ALL entries
  final List<Map<String, dynamic>> sampleCheques = [
    {
      "id": "1",
      "customerName": "John Smith",
      "chequeNo": "CHQ-1001",
      "date": "15/03/2024",
      "wallet": "Bank",
      "bankName": "HDFC Bank",
      "amount": "₹25,000",
      "status": "pending",
    },
    {
      "id": "2",
      "customerName": "Rajesh Kumar",
      "chequeNo": "CHQ-1002",
      "date": "20/03/2024",
      "wallet": "Cash",
      "bankName": "ICICI Bank",
      "amount": "₹18,500",
      "status": "cleared",
    },
    {
      "id": "3",
      "customerName": "Priya Sharma",
      "chequeNo": "CHQ-1003",
      "date": "25/03/2024",
      "wallet": "Bank",
      "bankName": "State Bank of India",
      "amount": "₹42,300",
      "status": "pending",
    },
    {
      "id": "4",
      "customerName": "Amit Patel",
      "chequeNo": "CHQ-1004",
      "date": "28/03/2024",
      "wallet": "Cash",
      "bankName": "Axis Bank",
      "amount": "₹15,750",
      "status": "bounced",
    },
    {
      "id": "5",
      "customerName": "Sneha Verma",
      "chequeNo": "CHQ-1005",
      "date": "01/04/2024",
      "wallet": "Bank",
      "bankName": "Kotak Mahindra Bank",
      "amount": "₹33,200",
      "status": "pending",
    },
    {
      "id": "6",
      "customerName": "Rahul Mehta",
      "chequeNo": "CHQ-1006",
      "date": "05/04/2024",
      "wallet": "Cash",
      "bankName": "Punjab National Bank",
      "amount": "₹22,100",
      "status": "cleared",
    },
    {
      "id": "7",
      "customerName": "Anjali Gupta",
      "chequeNo": "CHQ-1007",
      "date": "10/04/2024",
      "wallet": "Bank",
      "bankName": "Bank of Baroda",
      "amount": "₹29,800",
      "status": "pending",
    },
    {
      "id": "8",
      "customerName": "Vikram Singh",
      "chequeNo": "CHQ-1008",
      "date": "12/04/2024",
      "wallet": "Cash",
      "bankName": "Canara Bank",
      "amount": "₹16,400",
      "status": "pending",
    },
  ];

  @override
  void initState() {
    super.initState();
    print("🚀 ChequesMainPage initialized");
    _loadChequesData();
  }

  Future<void> _loadChequesData() async {
    print("📋 Loading cheques data...");
    setState(() {
      isLoading = true;
    });

    // Simulate API loading delay
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      cheques = List.from(sampleCheques);
      isLoading = false;
    });

    print("✅ Loaded ${cheques.length} cheques");
  }

  // Filter cheques based on search
  List<Map<String, dynamic>> get filteredCheques {
    if (searchController.text.isEmpty) {
      return cheques;
    }

    final query = searchController.text.toLowerCase();
    return cheques.where((cheque) {
      return cheque['customerName'].toLowerCase().contains(query) ||
          cheque['chequeNo'].toLowerCase().contains(query) ||
          (cheque['bankName'] != null &&
              cheque['bankName'].toLowerCase().contains(query));
    }).toList();
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'cleared':
        return Colors.green;
      case 'bounced':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  // Get status text
  String _getStatusText(String status) {
    switch (status) {
      case 'cleared':
        return 'Cleared';
      case 'bounced':
        return 'Bounced';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  // Calculate total amount
  String _calculateTotalAmount() {
    double total = 0;
    for (var cheque in cheques) {
      final amountStr = cheque['amount']
          .toString()
          .replaceAll('₹', '')
          .replaceAll(',', '');
      final amount = double.tryParse(amountStr) ?? 0;
      total += amount;
    }
    return '₹${total.toStringAsFixed(2)}';
  }

  // Calculate pending amount
  String _calculatePendingAmount() {
    double total = 0;
    for (var cheque in cheques) {
      if (cheque['status'] == 'pending') {
        final amountStr = cheque['amount']
            .toString()
            .replaceAll('₹', '')
            .replaceAll(',', '');
        final amount = double.tryParse(amountStr) ?? 0;
        total += amount;
      }
    }
    return '₹${total.toStringAsFixed(2)}';
  }

  // Mark cheque as cleared with popup dialog
  void _markAsClearedWithPopup(Map<String, dynamic> cheque) {
    print("📝 Opening clear popup for cheque: ${cheque['chequeNo']}");

    // Controllers for the popup
    TextEditingController dateController = TextEditingController(
      text: cheque['date'],
    );
    TextEditingController receivedAmountController = TextEditingController(
      text: cheque['amount'].toString().replaceAll('₹', ''),
    );

    // Auto-generated notes text with cheque number
    final String autoNotesText = "Cleared cheque no ${cheque['chequeNo']}";
    TextEditingController notesController = TextEditingController(
      text: autoNotesText,
    );

    // Dropdown value for Amount to (Cash/Bank)
    String selectedOption = cheque['wallet']; // Default to current wallet

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: const Text(
              "Clear Cheque",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cheque No (Non-editable)
                _buildPopupField(
                  label: "Cheque No",
                  value: cheque['chequeNo'],
                  isEditable: false,
                ),
                const SizedBox(height: 12),

                // Date (Editable)
                _buildPopupEditableField(
                  label: "Date",
                  controller: dateController,
                  hintText: "DD/MM/YYYY",
                ),
                const SizedBox(height: 12),

                // Received Amount (Editable)
                _buildPopupEditableField(
                  label: "Received Amount",
                  controller: receivedAmountController,
                  hintText: "Enter amount",
                  isAmount: true,
                ),
                const SizedBox(height: 12),

                // Amount to (Cash/Bank) - Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Amount to",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedOption,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Cash',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.money,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Cash'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Bank',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.account_balance,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Bank'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedOption = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Notes (Editable with auto-generated text)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Notes",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Enter any notes...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh, size: 16),
                          onPressed: () {
                            // Reset to auto-generated text
                            notesController.text = autoNotesText;
                          },
                          tooltip: 'Reset to auto text',
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Auto-generated: $autoNotesText",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate required fields
                if (dateController.text.isEmpty ||
                    receivedAmountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Mark cheque as cleared
                setState(() {
                  final index = cheques.indexWhere(
                    (c) => c['id'] == cheque['id'],
                  );
                  if (index != -1) {
                    cheques[index]['status'] = 'cleared';
                    // Update date if changed
                    cheques[index]['date'] = dateController.text;
                    // Update wallet based on selected option
                    cheques[index]['wallet'] = selectedOption;
                    // Update amount if changed
                    cheques[index]['amount'] =
                        '₹${receivedAmountController.text}';
                  }
                });

                Navigator.pop(context);

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Cheque ${cheque['chequeNo']} cleared successfully',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );

                // Print the data (you can save it to database here)
                print("✅ Cheque Cleared Details:");
                print("   Cheque No: ${cheque['chequeNo']}");
                print("   Date: ${dateController.text}");
                print("   Received Amount: ₹${receivedAmountController.text}");
                print("   Amount to: $selectedOption");
                print("   Notes: ${notesController.text}");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("Confirm Clear"),
            ),
          ],
        );
      },
    );
  }

  // Mark cheque as bounced with popup dialog
  void _markAsBouncedWithPopup(Map<String, dynamic> cheque) {
    print("📝 Opening bounce popup for cheque: ${cheque['chequeNo']}");

    // Auto-generated reason text with cheque number
    final String autoReasonText = "Bounced cheque no ${cheque['chequeNo']}";
    TextEditingController reasonController = TextEditingController(
      text: autoReasonText,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: const Text(
              "Bounce Cheque",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cheque No (Non-editable)
                _buildPopupField(
                  label: "Cheque No",
                  value: cheque['chequeNo'],
                  isEditable: false,
                ),
                const SizedBox(height: 12),

                // Reason (Editable with auto-generated text)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Reason",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Enter reason for bounce...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh, size: 16),
                          onPressed: () {
                            // Reset to auto-generated text
                            reasonController.text = autoReasonText;
                          },
                          tooltip: 'Reset to auto text',
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Auto-generated: $autoReasonText",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate required field
                if (reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a reason'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Mark cheque as bounced
                setState(() {
                  final index = cheques.indexWhere(
                    (c) => c['id'] == cheque['id'],
                  );
                  if (index != -1) {
                    cheques[index]['status'] = 'bounced';
                  }
                });

                Navigator.pop(context);

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Cheque ${cheque['chequeNo']} marked as bounced',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );

                // Print the data (you can save it to database here)
                print("❌ Cheque Bounced Details:");
                print("   Cheque No: ${cheque['chequeNo']}");
                print("   Reason: ${reasonController.text}");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Confirm Bounce"),
            ),
          ],
        );
      },
    );
  }

  // Build non-editable field for popup
  Widget _buildPopupField({
    required String label,
    required String value,
    bool isEditable = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: isEditable ? Colors.white : Colors.grey.shade50,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isEditable ? Colors.black : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Build editable field for popup
  Widget _buildPopupEditableField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool isAmount = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            prefixText: isAmount ? '₹ ' : null,
          ),
        ),
      ],
    );
  }

  // Edit cheque
  // Edit cheque - Updated to navigate to ChequeEditPage
  void _editCheque(Map<String, dynamic> cheque) {
    print("✏️ Editing cheque: ${cheque['chequeNo']}");

    // Navigate to ChequeEditPage and wait for result
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChequeEditPage(cheque: cheque)),
    ).then((updatedCheque) {
      // Handle the updated cheque data returned from ChequeEditPage
      if (updatedCheque != null && updatedCheque is Map<String, dynamic>) {
        setState(() {
          final index = cheques.indexWhere((c) => c['id'] == cheque['id']);
          if (index != -1) {
            cheques[index] = updatedCheque;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cheque updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  // Delete cheque
  void _deleteCheque(String chequeId) {
    print("🗑️ Deleting cheque: $chequeId");

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Cheque"),
            content: const Text("Are you sure you want to delete this cheque?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    cheques.removeWhere((c) => c['id'] == chequeId);
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Cheque deleted successfully"),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  // Show edit dialog
  void _showEditDialog(Map<String, dynamic> cheque) {
    TextEditingController customerController = TextEditingController(
      text: cheque['customerName'],
    );
    TextEditingController chequeNoController = TextEditingController(
      text: cheque['chequeNo'],
    );
    TextEditingController dateController = TextEditingController(
      text: cheque['date'],
    );
    TextEditingController walletController = TextEditingController(
      text: cheque['wallet'],
    );
    TextEditingController bankNameController = TextEditingController(
      text: cheque['bankName'] ?? '',
    );
    TextEditingController amountController = TextEditingController(
      text: cheque['amount'].toString().replaceAll('₹', ''),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Cheque"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditField("Customer Name", customerController),
                const SizedBox(height: 8),
                _buildEditField("Cheque No", chequeNoController),
                const SizedBox(height: 8),
                _buildEditField("Date (DD/MM/YYYY)", dateController),
                const SizedBox(height: 8),
                _buildEditField("Wallet (Cash/Bank)", walletController),
                const SizedBox(height: 8),
                _buildEditField("Bank Name", bankNameController),
                const SizedBox(height: 8),
                _buildEditField("Amount", amountController, isAmount: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final index = cheques.indexWhere(
                    (c) => c['id'] == cheque['id'],
                  );
                  if (index != -1) {
                    cheques[index] = {
                      ...cheques[index],
                      'customerName': customerController.text,
                      'chequeNo': chequeNoController.text,
                      'date': dateController.text,
                      'wallet': walletController.text,
                      'bankName': bankNameController.text,
                      'amount': '₹${amountController.text}',
                    };
                  }
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cheque updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller, {
    bool isAmount = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter $label",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            prefixText: isAmount ? '₹ ' : null,
          ),
        ),
      ],
    );
  }

  // Updated: Navigate to NewChequePage
  void _addNewCheque() {
    print("➕ Navigating to NewChequePage");

    // Navigate to NewChequePage and wait for result
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewChequePage()),
    ).then((newCheque) {
      // Handle the new cheque data returned from NewChequePage
      if (newCheque != null && newCheque is Map<String, dynamic>) {
        setState(() {
          // Add the new cheque to the beginning of the list
          cheques.insert(0, {
            ...newCheque,
            "id": (cheques.length + 1).toString(),
            "status": "pending",
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cheque added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  // Refresh data
  Future<void> _refreshData() async {
    print("🔄 Refreshing cheques data");
    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      cheques = List.from(sampleCheques);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("🎨 Building ChequesMainPage UI...");
    print("   Cheques count: ${cheques.length}");
    print("   Filtered cheques: ${filteredCheques.length}");

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Cheques",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 3,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _addNewCheque, // Now navigates to NewChequePage
            tooltip: 'Add New Cheque',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading cheques...'),
          ],
        ),
      );
    }

    if (cheques.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Cheques Found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add your first cheque',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search Section
        Card(
          margin: const EdgeInsets.all(12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search by customer, cheque no or bank name...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Clear"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Summary Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // Total Cheques
              Expanded(
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Cheques",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cheques.length.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Total Amount
              Expanded(
                child: Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Amount",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _calculateTotalAmount(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Pending Amount
              Expanded(
                child: Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pending Amount",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _calculatePendingAmount(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
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

        // Status Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusLegend("Pending", Colors.orange),
              _buildStatusLegend("Cleared", Colors.green),
              _buildStatusLegend("Bounced", Colors.red),
            ],
          ),
        ),

        // Cheques List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: filteredCheques.length,
            itemBuilder: (context, index) {
              final cheque = filteredCheques[index];
              return _chequeCard(cheque);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusLegend(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _chequeCard(Map<String, dynamic> cheque) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with customer name, date and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Info with Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cheque['customerName'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cheque['date'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(cheque['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getStatusColor(cheque['status']),
                    ),
                  ),
                  child: Text(
                    _getStatusText(cheque['status']),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(cheque['status']),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Cheque No and Bank Name row
            Row(
              children: [
                // Cheque No
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Cheque No",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cheque['chequeNo'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bank Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bank Name",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance,
                            size: 14,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cheque['bankName'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      cheque['amount'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Amount",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action Buttons - ALL IN ONE ROW FOR PENDING CHEQUES
            if (cheque['status'] == 'pending')
              Row(
                children: [
                  // Clear Button with Popup
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsClearedWithPopup(cheque),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text("Clear"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade50,
                        foregroundColor: Colors.green.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Bounce Button with Popup
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsBouncedWithPopup(cheque),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text("Bounce"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Edit Button - icon only (no text)
                  IconButton(
                    onPressed: () => _editCheque(cheque),
                    icon: const Icon(Icons.edit, size: 20),
                    color: Colors.blue,
                    tooltip: 'Edit',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Delete Button - icon only (no text)
                  IconButton(
                    onPressed: () => _deleteCheque(cheque['id']),
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red,
                    tooltip: 'Delete',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              )
            else
              // For CLEARED or BOUNCED cheques: Show status message
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(cheque['status']).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(cheque['status']).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      cheque['status'] == 'cleared'
                          ? Icons.check_circle
                          : Icons.warning,
                      size: 16,
                      color: _getStatusColor(cheque['status']),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cheque['status'] == 'cleared'
                          ? 'Cheque has been cleared'
                          : 'Cheque has been bounced',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(cheque['status']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            "$label:",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
