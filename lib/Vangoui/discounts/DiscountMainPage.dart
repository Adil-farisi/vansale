import 'package:flutter/material.dart';

// Add this import for NewDiscountPage
import 'EditDiscountPage.dart';
import 'NewDiscountPage.dart';

class DiscountMainPage extends StatefulWidget {
  const DiscountMainPage({super.key});

  @override
  State<DiscountMainPage> createState() => _DiscountMainPageState();
}

class _DiscountMainPageState extends State<DiscountMainPage> {
  List<Map<String, dynamic>> discounts = [];
  bool isLoading = false;
  final TextEditingController searchController = TextEditingController();

  // Hardcoded sample data - Removed status field
  final List<Map<String, dynamic>> sampleDiscounts = [
    {
      "id": "1",
      "customerName": "John Smith",
      "date": "15/03/2024",
      "notes": "Loyal customer discount",
      "discountAmount": "₹500",
    },
    {
      "id": "2",
      "customerName": "Rajesh Kumar",
      "date": "20/03/2024",
      "notes": "Bulk purchase discount",
      "discountAmount": "₹1,200",
    },
    {
      "id": "3",
      "customerName": "Priya Sharma",
      "date": "25/03/2024",
      "notes": "Festival season discount",
      "discountAmount": "₹750",
    },
    {
      "id": "4",
      "customerName": "Amit Patel",
      "date": "28/03/2024",
      "notes": "First purchase discount",
      "discountAmount": "₹300",
    },
    {
      "id": "5",
      "customerName": "Sneha Verma",
      "date": "01/04/2024",
      "notes": "Referral bonus discount",
      "discountAmount": "₹1,000",
    },
    {
      "id": "6",
      "customerName": "Rahul Mehta",
      "date": "05/04/2024",
      "notes": "Clearance sale discount",
      "discountAmount": "₹2,500",
    },
    {
      "id": "7",
      "customerName": "Anjali Gupta",
      "date": "10/04/2024",
      "notes": "Seasonal discount",
      "discountAmount": "₹600",
    },
    {
      "id": "8",
      "customerName": "Vikram Singh",
      "date": "12/04/2024",
      "notes": "Corporate discount",
      "discountAmount": "₹1,800",
    },
  ];

  @override
  void initState() {
    super.initState();
    print("🚀 DiscountMainPage initialized");
    _loadDiscountsData();
  }

  Future<void> _loadDiscountsData() async {
    print("📋 Loading discounts data...");
    setState(() {
      isLoading = true;
    });

    // Simulate API loading delay
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      discounts = List.from(sampleDiscounts);
      isLoading = false;
    });

    print("✅ Loaded ${discounts.length} discounts");
  }

  // Filter discounts based on search
  List<Map<String, dynamic>> get filteredDiscounts {
    if (searchController.text.isEmpty) {
      return discounts;
    }

    final query = searchController.text.toLowerCase();
    return discounts.where((discount) {
      return discount['customerName'].toLowerCase().contains(query) ||
          discount['notes'].toLowerCase().contains(query);
    }).toList();
  }

  // Calculate total discount amount
  String _calculateTotalDiscount() {
    double total = 0;
    for (var discount in discounts) {
      final amountStr = discount['discountAmount']
          .toString()
          .replaceAll('₹', '')
          .replaceAll(',', '');
      final amount = double.tryParse(amountStr) ?? 0;
      total += amount;
    }
    return '₹${total.toStringAsFixed(2)}';
  }

  // Edit discount
  // Edit discount - Updated to navigate to EditDiscountPage
  void _editDiscount(Map<String, dynamic> discount) {
    print("✏️ Editing discount for: ${discount['customerName']}");

    // Navigate to EditDiscountPage and wait for result
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDiscountPage(discount: discount),
      ),
    ).then((updatedDiscount) {
      // Handle the updated discount data returned from EditDiscountPage
      if (updatedDiscount != null && updatedDiscount is Map<String, dynamic>) {
        setState(() {
          final index = discounts.indexWhere(
                (c) => c['id'] == discount['id'],
          );
          if (index != -1) {
            discounts[index] = updatedDiscount;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discount updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  // Delete discount
  void _deleteDiscount(String discountId) {
    print("🗑️ Deleting discount: $discountId");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Discount"),
        content: const Text("Are you sure you want to delete this discount?"),
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
                discounts.removeWhere((c) => c['id'] == discountId);
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Discount deleted successfully"),
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

  // Show edit dialog - Removed status dropdown
  void _showEditDialog(Map<String, dynamic> discount) {
    TextEditingController customerController = TextEditingController(
      text: discount['customerName'],
    );
    TextEditingController dateController = TextEditingController(
      text: discount['date'],
    );
    TextEditingController notesController = TextEditingController(
      text: discount['notes'],
    );
    TextEditingController amountController = TextEditingController(
      text: discount['discountAmount'].toString().replaceAll('₹', ''),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Discount"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditField("Customer Name", customerController),
                const SizedBox(height: 8),
                _buildEditField("Date (DD/MM/YYYY)", dateController),
                const SizedBox(height: 8),
                _buildEditField("Notes", notesController, maxLines: 3),
                const SizedBox(height: 8),
                _buildEditField("Discount Amount", amountController, isAmount: true),
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
                  final index = discounts.indexWhere(
                        (c) => c['id'] == discount['id'],
                  );
                  if (index != -1) {
                    discounts[index] = {
                      ...discounts[index],
                      'customerName': customerController.text,
                      'date': dateController.text,
                      'notes': notesController.text,
                      'discountAmount': '₹${amountController.text}',
                    };
                  }
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Discount updated successfully'),
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

  // Updated: Navigate to NewDiscountPage
  // Updated: Navigate to NewDiscountPage
  void _addNewDiscount() {
    print("➕ Navigating to NewDiscountPage");

    // Navigate to NewDiscountPage and wait for result
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewDiscountPage(),
      ),
    ).then((newDiscount) {
      // Handle the new discount data returned from NewDiscountPage
      if (newDiscount != null && newDiscount is Map<String, dynamic>) {
        setState(() {
          // Generate a unique ID for the new discount
          final newId = (discounts.length + 1).toString();

          // Add the new discount to the beginning of the list
          discounts.insert(0, {
            "id": newId,
            "customerName": newDiscount['customerName'] ?? 'New Customer',
            "date": newDiscount['date'] ?? '01/01/2024',
            "notes": newDiscount['notes'] ?? 'No notes',
            "discountAmount": newDiscount['discountAmount'] ?? '₹0',
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discount added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  // Refresh data
  Future<void> _refreshData() async {
    print("🔄 Refreshing discounts data");
    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      discounts = List.from(sampleDiscounts);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("🎨 Building DiscountMainPage UI...");
    print("   Discounts count: ${discounts.length}");
    print("   Filtered discounts: ${filteredDiscounts.length}");

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Discounts ",
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
            onPressed: _addNewDiscount, // Now navigates to NewDiscountPage
            tooltip: 'Add New Discount',
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
            Text('Loading discounts...'),
          ],
        ),
      );
    }

    if (discounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.discount,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Discounts Found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add your first discount',
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
                      hintText: "Search by customer or notes...",
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
              // Total Discounts
              Expanded(
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Discounts",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          discounts.length.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Total Discount Amount
              Expanded(
                child: Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Discount Amount",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _calculateTotalDiscount(),
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
            ],
          ),
        ),

        // Discounts List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: filteredDiscounts.length,
            itemBuilder: (context, index) {
              final discount = filteredDiscounts[index];
              return _discountCard(discount);
            },
          ),
        ),
      ],
    );
  }

  Widget _discountCard(Map<String, dynamic> discount) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Customer Name and Date in one row (without labels)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Customer Name (without label)
                Expanded(
                  child: Text(
                    discount['customerName'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Date (without label)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        discount['date'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 2: Notes and Discount Amount in one row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Notes
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Notes",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        discount['notes'],
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Discount Amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Discount Amount",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        discount['discountAmount'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Row 3: Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit Button
                IconButton(
                  onPressed: () => _editDiscount(discount),
                  icon: const Icon(Icons.edit, size: 18),
                  color: Colors.blue,
                  tooltip: 'Edit',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(width: 8),

                // Delete Button
                IconButton(
                  onPressed: () => _deleteDiscount(discount['id']),
                  icon: const Icon(Icons.delete, size: 18),
                  color: Colors.red,
                  tooltip: 'Delete',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}