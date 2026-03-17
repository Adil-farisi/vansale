import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NewVoucherPage extends StatefulWidget {
  const NewVoucherPage({super.key});

  @override
  State<NewVoucherPage> createState() => _NewVoucherPageState();
}

class _NewVoucherPageState extends State<NewVoucherPage> {
  final _formKey = GlobalKey<FormState>();

  // API variables
  String unid = '';
  String veh = '';
  final String suppliersApiUrl = "http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/get_suppliers.php";
  final String expenseAccountApiUrl = "http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/get_expense_account.php";
  final String walletsApiUrl = "http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/get_wallets.php";
  final String expenseActionApiUrl = "http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/action/expenses.php";

  // Controllers for all text fields
  final TextEditingController payToCtrl = TextEditingController();
  final TextEditingController particularsCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController paidAmountCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController();

  // Search controller for category
  final TextEditingController _categorySearchCtrl = TextEditingController();

  // Search controller for supplier
  final TextEditingController _supplierSearchCtrl = TextEditingController();

  // Dropdown values
  String? selectedCategory;
  String? selectedCategoryId;
  String? selectedAmountFrom; // Will be set from API

  // Supplier data
  List<Map<String, dynamic>> allSuppliers = [];
  List<Map<String, dynamic>> filteredSuppliers = [];
  Map<String, dynamic>? selectedSupplier;

  // Category data from API
  List<Map<String, dynamic>> allCategories = [];
  List<Map<String, dynamic>> filteredCategories = [];

  // Wallet data from API
  List<Map<String, dynamic>> allWallets = [];
  Map<String, dynamic>? selectedWallet;

  // Loading states
  bool isLoadingSuppliers = false;
  bool isLoadingCategories = false;
  bool isLoadingWallets = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    // Set default date to today
    _setTodayDate();
    // Load session data and fetch data
    _loadSessionData();

    // Add listener for category search
    _categorySearchCtrl.addListener(_filterCategories);
    // Add listener for supplier search
    _supplierSearchCtrl.addListener(_filterSuppliers);
  }

  Future<void> _loadSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        unid = prefs.getString('unid') ?? '';
        veh = prefs.getString('veh') ?? '';
      });
      print("🔑 Session loaded - unid: $unid, veh: $veh");

      if (unid.isNotEmpty && veh.isNotEmpty) {
        await Future.wait([
          _fetchSuppliers(),
          _fetchExpenseAccounts(),
          _fetchWallets(),
        ]);
      }
    } catch (e) {
      print("❌ Error loading session: $e");
    }
  }

  Future<void> _fetchSuppliers() async {
    setState(() {
      isLoadingSuppliers = true;
    });

    try {
      Map<String, dynamic> requestBody = {
        "unid": unid,
        "veh": veh,
      };

      print("📤 Fetching suppliers: ${json.encode(requestBody)}");

      final response = await http.post(
        Uri.parse(suppliersApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print("📥 Suppliers response status: ${response.statusCode}");
      print("📥 Suppliers response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['result'] == "1") {
          if (responseData['supplierdet'] != null && responseData['supplierdet'] is List) {
            final supplierList = responseData['supplierdet'] as List;

            allSuppliers = supplierList.map<Map<String, dynamic>>((item) {
              return {
                'id': item['suppid']?.toString() ?? '',
                'name': item['supp_name']?.toString() ?? 'Unknown',
                'outstanding': item['outstand_amt']?.toString() ?? '0.00',
              };
            }).toList();

            filteredSuppliers = List.from(allSuppliers);
            print("✅ Loaded ${allSuppliers.length} suppliers");
          }
        }
      }
    } catch (e) {
      print("❌ Error fetching suppliers: $e");
    } finally {
      setState(() {
        isLoadingSuppliers = false;
      });
    }
  }

  Future<void> _fetchExpenseAccounts() async {
    setState(() {
      isLoadingCategories = true;
    });

    try {
      Map<String, dynamic> requestBody = {
        "unid": unid,
        "veh": veh,
      };

      print("📤 Fetching expense accounts: ${json.encode(requestBody)}");

      final response = await http.post(
        Uri.parse(expenseAccountApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print("📥 Expense accounts response status: ${response.statusCode}");
      print("📥 Expense accounts response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['result'] == "1") {
          if (responseData['accountdet'] != null && responseData['accountdet'] is List) {
            final categoryList = responseData['accountdet'] as List;

            allCategories = categoryList.map<Map<String, dynamic>>((item) {
              return {
                'id': item['catid']?.toString() ?? '',
                'name': item['cat_name']?.toString() ?? 'Unknown',
              };
            }).toList();

            filteredCategories = List.from(allCategories);
            print("✅ Loaded ${allCategories.length} expense accounts");
          }
        }
      }
    } catch (e) {
      print("❌ Error fetching expense accounts: $e");
    } finally {
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  Future<void> _fetchWallets() async {
    setState(() {
      isLoadingWallets = true;
    });

    try {
      Map<String, dynamic> requestBody = {
        "unid": unid,
        "veh": veh,
      };

      print("📤 Fetching wallets: ${json.encode(requestBody)}");

      final response = await http.post(
        Uri.parse(walletsApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print("📥 Wallets response status: ${response.statusCode}");
      print("📥 Wallets response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['result'] == "1") {
          if (responseData['walletdet'] != null && responseData['walletdet'] is List) {
            final walletList = responseData['walletdet'] as List;

            allWallets = walletList.map<Map<String, dynamic>>((item) {
              return {
                'id': item['wltid']?.toString() ?? '',
                'name': item['wlt_name']?.toString() ?? 'Unknown',
                'balance': item['wlt_balance']?.toString() ?? '0.00',
              };
            }).toList();

            // Set default selected wallet to first one
            if (allWallets.isNotEmpty) {
              selectedWallet = allWallets.first;
              selectedAmountFrom = selectedWallet!['name'];
            }

            print("✅ Loaded ${allWallets.length} wallets");
          }
        }
      }
    } catch (e) {
      print("❌ Error fetching wallets: $e");
    } finally {
      setState(() {
        isLoadingWallets = false;
      });
    }
  }

  void _filterSuppliers() {
    final query = _supplierSearchCtrl.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredSuppliers = allSuppliers;
      } else {
        filteredSuppliers = allSuppliers.where((supplier) =>
            supplier['name'].toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  void _filterCategories() {
    final query = _categorySearchCtrl.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredCategories = allCategories;
      } else {
        filteredCategories = allCategories.where((category) =>
            category['name'].toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  void _setTodayDate() {
    final now = DateTime.now();
    dateCtrl.text = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        dateCtrl.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  @override
  void dispose() {
    payToCtrl.dispose();
    particularsCtrl.dispose();
    amountCtrl.dispose();
    paidAmountCtrl.dispose();
    notesCtrl.dispose();
    dateCtrl.dispose();
    _categorySearchCtrl.removeListener(_filterCategories);
    _categorySearchCtrl.dispose();
    _supplierSearchCtrl.removeListener(_filterSuppliers);
    _supplierSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndNew() async {
    if (_formKey.currentState!.validate()) {

      // Validate required fields
      if (selectedSupplier == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a supplier"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (selectedCategory == null || selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a category"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (selectedWallet == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a wallet"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        isSaving = true;
      });

      try {
        // Prepare request body for expense API
        Map<String, dynamic> requestBody = {
          "unid": unid,
          "veh": veh,
          "action": "single_insert",
          "suppid": selectedSupplier!['id'],
          "supp_name": selectedSupplier!['name'],
          "expense_date": dateCtrl.text,
          "particulars": particularsCtrl.text,
          "expense_amount": amountCtrl.text,
          "catid": selectedCategoryId,
          "category": selectedCategory,
          "paid_amount": paidAmountCtrl.text.isEmpty ? "" : paidAmountCtrl.text,
          "wallet": selectedWallet!['id'],
          "notes": notesCtrl.text,
        };

        print("📤 Saving expense: ${json.encode(requestBody)}");

        final response = await http.post(
          Uri.parse(expenseActionApiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        ).timeout(const Duration(seconds: 10));

        print("📥 Save response status: ${response.statusCode}");
        print("📥 Save response body: ${response.body}");

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData['result'] == "1") {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        responseData['message'] ?? "Voucher added successfully",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );

            // Clear form for new entry
            _clearForm();
          } else {
            // Show error message from API
            String errorMessage = responseData['message'] ?? 'Failed to save voucher';
            errorMessage = errorMessage.replaceAll(RegExp(r'<[^>]*>'), '');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server error: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print("❌ Error saving voucher: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void _clearForm() {
    payToCtrl.clear();
    particularsCtrl.clear();
    amountCtrl.clear();
    paidAmountCtrl.clear();
    notesCtrl.clear();
    _categorySearchCtrl.clear();
    _supplierSearchCtrl.clear();
    // Reset date to today
    _setTodayDate();

    setState(() {
      selectedCategory = null;
      selectedCategoryId = null;
      selectedSupplier = null;
      // Reset wallet to first one
      if (allWallets.isNotEmpty) {
        selectedWallet = allWallets.first;
        selectedAmountFrom = selectedWallet!['name'];
      }
      filteredSuppliers = allSuppliers;
      filteredCategories = allCategories;
    });
  }

  void _showCategorySearchDialog() {
    _categorySearchCtrl.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Select Category',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _categorySearchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search category...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: isLoadingCategories
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            if (value.isEmpty) {
                              filteredCategories = allCategories;
                            } else {
                              filteredCategories = allCategories.where((category) =>
                                  category['name'].toLowerCase().contains(value.toLowerCase())
                              ).toList();
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category List
                    SizedBox(
                      height: 300,
                      child: filteredCategories.isEmpty
                          ? Center(
                        child: Text(
                          isLoadingCategories ? "Loading categories..." : "No categories found",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                          : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = filteredCategories[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade50,
                              radius: 20,
                              child: Text(
                                category['name'][0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(category['name']),
                            onTap: () {
                              setState(() {
                                selectedCategory = category['name'];
                                selectedCategoryId = category['id'];
                              });
                              _categorySearchCtrl.clear();
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _categorySearchCtrl.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Reset filtered categories when dialog closes
      setState(() {
        filteredCategories = allCategories;
        _categorySearchCtrl.clear();
      });
    });
  }

  void _showSupplierSearchDialog() {
    _supplierSearchCtrl.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Select Supplier',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _supplierSearchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search supplier by name...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: isLoadingSuppliers
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            if (value.isEmpty) {
                              filteredSuppliers = allSuppliers;
                            } else {
                              filteredSuppliers = allSuppliers.where((supplier) =>
                                  supplier['name'].toLowerCase().contains(value.toLowerCase())
                              ).toList();
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Supplier List
                    SizedBox(
                      height: 300,
                      child: filteredSuppliers.isEmpty
                          ? Center(
                        child: Text(
                          isLoadingSuppliers ? "Loading suppliers..." : "No suppliers found",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                          : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredSuppliers.length,
                        itemBuilder: (context, index) {
                          final supplier = filteredSuppliers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              radius: 20,
                              child: Text(
                                supplier['name'][0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(supplier['name']),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                supplier['outstanding'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                selectedSupplier = supplier;
                                payToCtrl.text = supplier['name'];
                              });
                              _supplierSearchCtrl.clear();
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _supplierSearchCtrl.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Reset filtered suppliers when dialog closes
      setState(() {
        filteredSuppliers = allSuppliers;
        _supplierSearchCtrl.clear();
      });
    });
  }

  void _showWalletSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Select Wallet',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: isLoadingWallets
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: allWallets.map((wallet) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: wallet['name'].toLowerCase() == 'cash'
                        ? Colors.green.shade50
                        : Colors.blue.shade50,
                    radius: 20,
                    child: Icon(
                      wallet['name'].toLowerCase() == 'cash'
                          ? Icons.money
                          : Icons.account_balance,
                      size: 18,
                      color: wallet['name'].toLowerCase() == 'cash'
                          ? Colors.green.shade800
                          : Colors.blue.shade800,
                    ),
                  ),
                  title: Text(wallet['name']),
                  subtitle: Text("Balance: ${wallet['balance']}"),
                  onTap: () {
                    setState(() {
                      selectedWallet = wallet;
                      selectedAmountFrom = wallet['name'];
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "New Expense",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Main Voucher Form Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Pay To Field (Searchable Supplier)
                      _buildLabel("Pay To"),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _showSupplierSearchDialog,
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person, size: 18, color: Colors.blue.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedSupplier != null
                                      ? selectedSupplier!['name']
                                      : "Select supplier",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selectedSupplier == null
                                        ? Colors.grey.shade500
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              if (isLoadingSuppliers)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(2),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              else
                                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),
                      if (selectedSupplier != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 12),
                          child: Row(
                            children: [
                              Text(
                                "Outstanding: ",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                selectedSupplier!['outstanding'],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Date Field
                      _buildLabel("Date"),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 18, color: Colors.blue.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dateCtrl.text,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_drop_down,
                                  color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Field (Searchable from API)
                      _buildLabel("Category"),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _showCategorySearchDialog,
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 18, color: Colors.blue.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedCategory ?? "Select category",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selectedCategory == null
                                        ? Colors.grey.shade500
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              if (isLoadingCategories)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(2),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              else
                                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Particulars
                      _buildLabel("Particulars"),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: particularsCtrl,
                        decoration: _buildInputDecoration(
                          hint: "Enter particulars",
                          prefixIcon: Icons.description,
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Row: Amount and Paid Amount
                      Row(
                        children: [
                          // Amount
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Amount"),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: amountCtrl,
                                  decoration: _buildInputDecoration(
                                    hint: "Amount",
                                    prefixIcon: Icons.currency_rupee,
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Required";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Paid Amount (No validation)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Paid Amount"),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: paidAmountCtrl,
                                  decoration: _buildInputDecoration(
                                    hint: "Paid amount (optional)",
                                    prefixIcon: Icons.payments,
                                  ),
                                  keyboardType: TextInputType.number,
                                  // No validator - field is optional
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Amount From (Wallet Selection)
                      _buildLabel("Amount From"),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _showWalletSelectionDialog,
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selectedWallet != null && selectedWallet!['name'].toLowerCase() == 'cash'
                                    ? Icons.money
                                    : Icons.account_balance,
                                size: 18,
                                color: Colors.blue.shade800,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedAmountFrom ?? "Select wallet",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selectedAmountFrom == null
                                        ? Colors.grey.shade500
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              if (isLoadingWallets)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(2),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              else
                                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),
                      if (selectedWallet != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 12),
                          child: Row(
                            children: [
                              Text(
                                "Balance: ",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                selectedWallet!['balance'],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Notes
                      _buildLabel("Notes"),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: notesCtrl,
                        decoration: _buildInputDecoration(
                          hint: "Enter notes (optional)",
                          prefixIcon: Icons.note,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save & New Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : _saveAndNew,
                  icon: isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    isSaving ? "SAVING..." : "SAVE & NEW",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build input decoration
  InputDecoration _buildInputDecoration({
    required String hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.blue.shade800, size: 20)
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  // Helper method to build field labels
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      ),
    );
  }
}