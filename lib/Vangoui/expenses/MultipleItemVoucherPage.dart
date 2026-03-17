import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MultipleItemVoucherPage extends StatefulWidget {
  const MultipleItemVoucherPage({super.key});

  @override
  State<MultipleItemVoucherPage> createState() => _MultipleItemVoucherPageState();
}

class _MultipleItemVoucherPageState extends State<MultipleItemVoucherPage> {
  final _formKey = GlobalKey<FormState>();

  // API variables
  String unid = '';
  String veh = '';
  final String suppliersApiUrl = "http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/get_suppliers.php";
  final String expenseAccountApiUrl = "http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/get_expense_account.php";
  final String walletsApiUrl = "http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/get_wallets.php";
  final String expenseActionApiUrl = "http://192.168.1.108:7575/gst-3-3-production/mobile-service/vansales/action/expenses.php";

  // Controllers
  final TextEditingController payToCtrl = TextEditingController();
  final TextEditingController particularsCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();
  final TextEditingController paidAmountCtrl = TextEditingController();

  // Search controller for category
  final TextEditingController _categorySearchCtrl = TextEditingController();

  // Search controller for supplier
  final TextEditingController _supplierSearchCtrl = TextEditingController();

  // Focus Nodes
  final FocusNode _paidAmountFocusNode = FocusNode();

  // Data
  List<Map<String, dynamic>> items = [];
  String? selectedCategory;
  String? selectedItemCategory;
  String? selectedItemCategoryId;

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
  String? selectedAmountFrom;

  // Loading states
  bool isLoadingSuppliers = false;
  bool isLoadingCategories = false;
  bool isLoadingWallets = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _setTodayDate();
    paidAmountCtrl.text = "0";

    // Load session data and fetch data
    _loadSessionData();

    // Add listener for category search
    _categorySearchCtrl.addListener(_filterCategories);

    // Add listener for supplier search
    _supplierSearchCtrl.addListener(_filterSuppliers);

    // Add focus listeners
    _paidAmountFocusNode.addListener(_onPaidAmountFocusChange);
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

  void _onPaidAmountFocusChange() {
    if (_paidAmountFocusNode.hasFocus && paidAmountCtrl.text == "0") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        paidAmountCtrl.text = "";
      });
    }
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

  void _addItem() {
    if (particularsCtrl.text.isNotEmpty &&
        selectedItemCategory != null &&
        amountCtrl.text.isNotEmpty) {

      setState(() {
        items.add({
          'sno': items.length + 1,
          'particulars': particularsCtrl.text,
          'category': selectedItemCategory,
          'categoryId': selectedItemCategoryId,
          'amount': double.parse(amountCtrl.text),
        });

        // Clear item fields
        particularsCtrl.clear();
        amountCtrl.clear();
        selectedItemCategory = null;
        selectedItemCategoryId = null;
        _categorySearchCtrl.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill Particulars, Category and Amount"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _deleteItem(int index) {
    setState(() {
      items.removeAt(index);
      for (int i = 0; i < items.length; i++) {
        items[i]['sno'] = i + 1;
      }
    });
  }

  double get _totalAmount {
    return items.fold(0.0, (sum, item) => sum + (item['amount'] as double));
  }

  double get _paidAmount {
    if (paidAmountCtrl.text.isEmpty) return 0.0;
    return double.tryParse(paidAmountCtrl.text) ?? 0.0;
  }

  double get _balanceDue {
    return _totalAmount - _paidAmount;
  }

  @override
  void dispose() {
    _categorySearchCtrl.removeListener(_filterCategories);
    _categorySearchCtrl.dispose();
    _supplierSearchCtrl.removeListener(_filterSuppliers);
    _supplierSearchCtrl.dispose();
    _paidAmountFocusNode.removeListener(_onPaidAmountFocusChange);
    _paidAmountFocusNode.dispose();

    payToCtrl.dispose();
    particularsCtrl.dispose();
    amountCtrl.dispose();
    dateCtrl.dispose();
    notesCtrl.dispose();
    paidAmountCtrl.dispose();
    super.dispose();
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

  Future<void> _saveVoucher() async {
    if (_formKey.currentState!.validate() && items.isNotEmpty) {

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
        // Prepare cart details
        List<Map<String, dynamic>> cartDetails = items.map((item) {
          return {
            "particulars": item['particulars'],
            "expense_amount": item['amount'].toStringAsFixed(0),
            "catid": item['categoryId'],
            "category": item['category'],
          };
        }).toList();

        // Prepare request body for multiple_insert API
        Map<String, dynamic> requestBody = {
          "unid": unid,
          "veh": veh,
          "action": "multiple_insert",
          "voucher_det": {
            "suppid": selectedSupplier!['id'],
            "supp_name": selectedSupplier!['name'],
            "expense_date": dateCtrl.text,
            // FIX: Send empty string when paid_amount is 0, otherwise send the value
            "paid_amount": paidAmountCtrl.text.isEmpty || paidAmountCtrl.text == "0" ? "" : paidAmountCtrl.text,
            "wallet": selectedWallet!['id'],
            "notes": notesCtrl.text,
          },
          "cartdet": cartDetails,
        };

        print("📤 Saving expense voucher: ${json.encode(requestBody)}");

        final response = await http.post(
          Uri.parse(expenseActionApiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        ).timeout(const Duration(seconds: 30));

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
      } on TimeoutException catch (_) {
        print("❌ Request timeout");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Server not responding. Please check your connection and try again."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      } catch (e) {
        print("❌ Error saving voucher: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } finally {
        setState(() {
          isSaving = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least one item"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _clearForm() {
    payToCtrl.clear();
    particularsCtrl.clear();
    amountCtrl.clear();
    notesCtrl.clear();
    paidAmountCtrl.text = "0";
    _setTodayDate();

    setState(() {
      items.clear();
      selectedCategory = null;
      selectedItemCategory = null;
      selectedItemCategoryId = null;
      selectedSupplier = null;
      // Reset wallet to first one
      if (allWallets.isNotEmpty) {
        selectedWallet = allWallets.first;
        selectedAmountFrom = selectedWallet!['name'];
      }
      _categorySearchCtrl.clear();
      _supplierSearchCtrl.clear();
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

                    // Category List (ID removed)
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
                            // Subtitle removed - no ID shown
                            onTap: () {
                              setState(() {
                                selectedItemCategory = category['name'];
                                selectedItemCategoryId = category['id'];
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
      // Clear search controller when dialog closes
      _categorySearchCtrl.clear();
      setState(() {
        filteredCategories = allCategories;
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

                    // Supplier List (ID removed)
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
                            // Subtitle removed - no ID shown
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "New Expense",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Voucher Details Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Voucher Details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Divider(height: 20),

                    // Pay To (Searchable Supplier)
                    _buildLabel("Pay To"),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _showSupplierSearchDialog,
                      child: Container(
                        height: 45,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
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

                    // Date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Date"),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            height: 45,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade800),
                                const SizedBox(width: 8),
                                Expanded(child: Text(dateCtrl.text)),
                                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Add Items Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Add Items",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Divider(height: 20),

                    // Particulars
                    _buildLabel("Particulars"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: particularsCtrl,
                      decoration: _inputDec("Enter particulars", Icons.description),
                    ),
                    const SizedBox(height: 12),

                    // Category and Amount Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Category"),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: _showCategorySearchDialog,
                                child: Container(
                                  height: 45,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.search, size: 18, color: Colors.blue.shade800),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          selectedItemCategory ?? "Select category",
                                          style: TextStyle(
                                            color: selectedItemCategory == null
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
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Amount"),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: amountCtrl,
                                decoration: _inputDec("Amount", Icons.currency_rupee),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Add Product Button
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          " Add ",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Items List Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Added Items",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        if (items.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              if (items.isEmpty) return;

                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text(
                                      "Clear All Items",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    content: const Text(
                                      "Are you sure you want to clear all items? ",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          "Cancel",
                                          style: TextStyle(color: Colors.grey.shade700),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            items.clear();
                                          });
                                          Navigator.pop(context);

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("All items cleared"),
                                              backgroundColor: Colors.orange,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text("Clear All"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 18),
                            label: const Text("Clear All", style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),

                    if (items.isEmpty) ...[
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              "No items added",
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Divider(height: 20),

                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Center(child: Text("S.No", style: _headerStyle))),
                            Expanded(flex: 3, child: Text("Particulars", style: _headerStyle)),
                            Expanded(flex: 2, child: Text("Category", style: _headerStyle)),
                            Expanded(flex: 2, child: Text("Amount", style: _headerStyle, textAlign: TextAlign.right)),
                            Expanded(flex: 1, child: Center(child: Text("", style: _headerStyle))),
                          ],
                        ),
                      ),

                      // Items List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(flex: 1, child: Center(child: Text(item['sno'].toString()))),
                                Expanded(flex: 3, child: Text(item['particulars'])),
                                Expanded(flex: 2, child: Text(item['category'])),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "₹${item['amount'].toStringAsFixed(0)}",
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      onPressed: () {
                                        final item = items[index];

                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text(
                                                "Delete Item",
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              content: Text(
                                                "Are you sure you want to delete '${item['particulars']}'?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text(
                                                    "Cancel",
                                                    style: TextStyle(color: Colors.grey.shade700),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    _deleteItem(index);
                                                    Navigator.pop(context);

                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text("Item deleted successfully"),
                                                        backgroundColor: Colors.orange,
                                                        behavior: SnackBarBehavior.floating,
                                                        duration: const Duration(seconds: 1),
                                                      ),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                  child: const Text("Delete"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bill Summary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryRow("Total Amount", _totalAmount, isBold: true),
                    const Divider(height: 20),

                    // Paid Amount with Wallet Selection
                    Row(
                      children: [
                        Expanded(child: Text("Paid Amount", style: _summaryLabelStyle)),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: GestureDetector(
                                  onTap: _showWalletSelectionDialog,
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            selectedAmountFrom ?? "Select",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: selectedAmountFrom == null
                                                  ? Colors.grey.shade500
                                                  : Colors.black,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isLoadingWallets)
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        else
                                          const Icon(Icons.arrow_drop_down, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: paidAmountCtrl,
                                  focusNode: _paidAmountFocusNode,
                                  textAlign: TextAlign.right,
                                  decoration: InputDecoration(
                                    hintText: "0",
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Balance Due
                    Row(
                      children: [
                        Expanded(child: Text("Balance Due", style: _summaryLabelStyle)),
                        Expanded(
                          child: Text(
                            "₹ ${_balanceDue.toStringAsFixed(0)}",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _balanceDue > 0 ? Colors.orange.shade800 : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Notes
                    Row(
                      children: [
                        Expanded(child: Text("Notes", style: _summaryLabelStyle)),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: notesCtrl,
                            decoration: InputDecoration(
                              hintText: "Enter notes...",
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _saveVoucher,
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 3,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  InputDecoration _inputDec(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
      prefixIcon: Icon(icon, size: 18, color: Colors.blue.shade800),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: isBold ? Colors.blue.shade800 : Colors.grey.shade800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            "₹ ${value.toStringAsFixed(0)}",
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.green.shade700 : null,
            ),
          ),
        ),
      ],
    );
  }

  final TextStyle _headerStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.bold);
  final TextStyle _summaryLabelStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
}