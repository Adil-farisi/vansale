import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:van_go/Vangoui/invoice/InvoiceCustomerPage.dart';
import 'package:van_go/Vangoui/receipt/ReceiptsMainPage.dart';
import 'package:van_go/Vangoui/reports/ReportsMainPage.dart';
import 'package:van_go/Vangoui/stocks/BatchWiseStockPage.dart';
import 'package:van_go/Vangoui/stocks/FinishedGoodsPage.dart';
import 'package:van_go/Vangoui/stocks/StockMainPage.dart';
import 'package:van_go/Vangoui/stocks/TradingItemsPage.dart';

import '../settings/ChangePasswordPage.dart';
import 'Login.dart';
import 'InvoiceListPage.dart';
import 'cheque/ChequesMainPage.dart';
import 'customerpage.dart';
import 'debug_helper.dart';
import 'discounts/DiscountMainPage.dart';
import 'expenses/expense_list_page.dart';
import 'expenses/new_voucher_page.dart';
import 'logosplashscreen.dart';
import 'receiptpage.dart';
import 'NewBillingPage.dart';

import 'stocks/current_stock_page.dart';
import 'stocks/load_stock_page.dart';
import 'stocks/return_stock_page.dart';
import 'permissions/permission_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// CONTROLS WHICH DRAWER SECTION IS OPEN
  String? expandedSection;

  String username = "";

  Future<void> loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString("username") ?? "";
    });
  }

  @override
  void initState() {
    super.initState();
    DebugHelper.printStoredData();
    loadUsername();

    // Add permission debug log
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logPermissions();
    });
  }

  void _logPermissions() {
    final permissionProvider = Provider.of<PermissionProvider>(
      context,
      listen: false,
    );

    print("=== HomePage Permissions ===");
    print("Provider loaded: ${permissionProvider.isLoaded}");
    print("Can add customer: ${permissionProvider.canAddCustomer()}");
    print("Can create new bill: ${permissionProvider.canCreateNewBill()}");
    print("Can view invoice: ${permissionProvider.canViewInvoice()}");
    print("Can view stock: ${permissionProvider.canViewStock()}");
    print("Can add receipt: ${permissionProvider.canAddReceipt()}");
    print("Can view sales report: ${permissionProvider.canViewSalesReport()}");
    print("=============================");
  }

  /// ---------- HELPERS ----------
  void openDrawerCollapsed() {
    setState(() => expandedSection = null);
    _scaffoldKey.currentState?.openDrawer();
  }

  void openDrawerWithStockExpanded() {
    setState(() => expandedSection = "stock");
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final permissionProvider = context.watch<PermissionProvider>();

    return Scaffold(
      key: _scaffoldKey,

      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: Text(
          username.isEmpty ? 'Home' : 'Welcome, $username',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          // Show loading indicator if permissions are loading
          if (permissionProvider.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),

      // =================== DRAWER ===================
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              /// HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blue.shade600],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        color: Colors.blue.shade700,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "VanGo Menu",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      username.isEmpty ? "User" : username,
                      style: const TextStyle(color: Colors.white70),
                    ),

                    // Permission status badge
                    if (permissionProvider.permissions != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          permissionProvider.canCreateNewBill() ? 'Sales User' : 'Limited Access',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // =================== MENU ===================
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    const SizedBox(height: 10),

                    // ================= TRANSACTIONS =================
                    // Only show if user has any transaction permissions
                    if (permissionProvider.canAddReceipt())
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 4),
                        child: Text(
                          "Transactions",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),

                    if (permissionProvider.canAddReceipt())
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            key: ValueKey(expandedSection == "transactions"),
                            initiallyExpanded:
                            expandedSection == "transactions",
                            onExpansionChanged: (expanded) {
                              setState(() {
                                expandedSection =
                                expanded ? "transactions" : null;
                              });
                            },
                            leading:
                            const Icon(Icons.receipt_long_outlined),
                            title: const Text("Transactions"),
                            childrenPadding: const EdgeInsets.only(
                              left: 16,
                              right: 10,
                              bottom: 10,
                            ),
                            children: [
                              ListTile(
                                leading: const Icon(Icons.receipt),
                                title: const Text("Receipts"),
                                onTap: () async {
                                  Navigator.pop(context);
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ReceiptsMainPage(),
                                    ),
                                  );
                                  openDrawerCollapsed();
                                },
                              ),
                              // ADDED CHEQUES OPTION
                              ListTile(
                                leading: const Icon(Icons.account_balance_wallet),
                                title: const Text("Cheques"),
                                onTap: () async {
                                  Navigator.pop(context);
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ChequesMainPage(),
                                    ),
                                  );
                                  openDrawerCollapsed();
                                },
                              ),
                              // ADDED DISCOUNTS OPTION
                              ListTile(
                                leading: const Icon(Icons.discount),
                                title: const Text("Discounts"),
                                onTap: () async {
                                  Navigator.pop(context);
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const DiscountMainPage(),
                                    ),
                                  );
                                  openDrawerCollapsed();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 15),

                    // ================= SALES =================
                    // Only show if user has any sales permissions
                    if (permissionProvider.canCreateNewBill() || permissionProvider.canViewInvoice())
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 4),
                        child: Text(
                          "Sales",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),

                    if (permissionProvider.canCreateNewBill() || permissionProvider.canViewInvoice())
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            key: ValueKey(expandedSection == "sales"),
                            initiallyExpanded: expandedSection == "sales",
                            onExpansionChanged: (expanded) {
                              setState(() {
                                expandedSection = expanded ? "sales" : null;
                              });
                            },
                            leading: const Icon(Icons.point_of_sale_outlined),
                            title: const Text("Sales"),
                            childrenPadding: const EdgeInsets.only(
                              left: 16,
                              right: 10,
                              bottom: 10,
                            ),
                            children: [
                              // Only show New Billing if user has permission
                              if (permissionProvider.canCreateNewBill())
                                ListTile(
                                  leading: const Icon(Icons.add_shopping_cart_outlined),
                                  title: const Text("New Billing"),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const NewBillingPage(),
                                      ),
                                    );
                                    openDrawerCollapsed();
                                  },
                                ),

                              // Only show Invoices if user has permission
                              if (permissionProvider.canViewInvoice())
                                ListTile(
                                  leading: const Icon(Icons.receipt_long_outlined),
                                  title: const Text("Invoices"),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const InvoiceListPage(),
                                      ),
                                    );
                                    openDrawerCollapsed();
                                  },
                                ),

                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 15),

                    // ================= EXPENSE =================
                    // Always show Expense section (assuming all users can access)
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        "Expense",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),

                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          key: ValueKey(expandedSection == "expense"),
                          initiallyExpanded:
                          expandedSection == "expense",
                          onExpansionChanged: (expanded) {
                            setState(() {
                              expandedSection =
                              expanded ? "expense" : null;
                            });
                          },
                          leading:
                          const Icon(Icons.money_off_csred_outlined),
                          title: const Text("Expense"),
                          childrenPadding: const EdgeInsets.only(
                            left: 16,
                            right: 10,
                            bottom: 10,
                          ),
                          children: [
                            ListTile(
                              leading: const Icon(Icons.add_circle_outline),
                              title: const Text("New Voucher"),
                              onTap: () async {
                                Navigator.pop(context);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NewVoucherPage(),
                                  ),
                                );
                                openDrawerCollapsed();
                              },
                            ),

                            ListTile(
                              leading: const Icon(Icons.list_alt),
                              title: const Text("Expenses"),
                              onTap: () async {
                                Navigator.pop(context);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ExpenseListPage(),
                                  ),
                                );
                                openDrawerCollapsed();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 15), // ADDED SPACING

                    // ================= SETTINGS =================
                    // Settings section - Always show to all users
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        "Settings",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),

                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          key: ValueKey(expandedSection == "settings"),
                          initiallyExpanded:
                          expandedSection == "settings",
                          onExpansionChanged: (expanded) {
                            setState(() {
                              expandedSection =
                              expanded ? "settings" : null;
                            });
                          },
                          leading:
                          const Icon(Icons.settings_outlined),
                          title: const Text("Settings"),
                          childrenPadding: const EdgeInsets.only(
                            left: 16,
                            right: 10,
                            bottom: 10,
                          ),
                          children: [
                            ListTile(
                              leading: const Icon(Icons.lock_reset),
                              title: const Text("Change Password"),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ChangePasswordPage(),
                                  ),
                                );
                              },
                            ),
                            // You can add more settings options here later
                            // ListTile(
                            //   leading: const Icon(Icons.notifications),
                            //   title: const Text("Notifications"),
                            //   onTap: () {
                            //     // Add notification settings
                            //   },
                            // ),
                          ],
                        ),
                      ),
                    ),

                    // Show message if no permissions
                    if (!permissionProvider.isLoaded && !permissionProvider.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'Permissions not loaded',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),

                    if (permissionProvider.isLoaded &&
                        !permissionProvider.canCreateNewBill() &&
                        !permissionProvider.canViewStock() &&
                        !permissionProvider.canAddReceipt() &&
                        !permissionProvider.canViewSalesReport())
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'Limited access - Contact administrator',
                            style: TextStyle(
                              color: Colors.orange,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(),

              /// PERMISSION STATUS
              if (permissionProvider.permissions != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Permissions:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${permissionProvider.canCreateNewBill() ? "Sales" : ""} '
                            '${permissionProvider.canViewStock() ? "Stock" : ""} '
                            '${!permissionProvider.canCreateNewBill() && !permissionProvider.canViewStock() ? "View Only" : ""}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              /// LOGOUT
              ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    bool confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Logout"),
                        content: const Text("Are you sure you want to logout?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              "Logout",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ) ?? false;

                    if (confirm) {
                      final prefs = await SharedPreferences.getInstance();

                      // ✅ ONLY CLEAR LOGIN SESSION
                      await prefs.setBool("isLoggedIn", false);

                      // Clear permission cache on logout
                      final permissionProvider = Provider.of<PermissionProvider>(
                        context,
                        listen: false,
                      );
                      permissionProvider.clearPermissions();

                      // Navigate to Login page
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const Login()),
                            (route) => false,
                      );
                    }
                  }
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),

      // =================== BODY ===================
      body:
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // CUSTOMERS CARD - Only show if user has customer view permission
            if (permissionProvider.canViewCustomer())
              GestureDetector(
                onTap: () {
                  if (permissionProvider.canViewCustomer()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CustomerPage()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You do not have permission to view customers'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    child: Row(
                      children: const [
                        Icon(Icons.person,
                            size: 40, color: Colors.blue),
                        SizedBox(width: 20),
                        Text(
                          "Customers",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (permissionProvider.canViewCustomer())
              const SizedBox(height: 14),

            // REPORTS CARD - Only show if user has report permissions
            if (permissionProvider.canViewSalesReport())
              GestureDetector(
                onTap: () {
                  if (permissionProvider.canViewSalesReport()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ReportsMainPage()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You do not have permission to view reports'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    child: Row(
                      children: const [
                        Icon(Icons.bar_chart,
                            size: 40, color: Colors.green),
                        SizedBox(width: 20),
                        Text(
                          "Reports",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (permissionProvider.canViewSalesReport())
              const SizedBox(height: 14),

            // STOCK CARD - Only show if user has stock view permission
            if (permissionProvider.canViewStock())
              GestureDetector(
                onTap: () {
                  if (permissionProvider.canViewStock()) {
                    // Navigate to Stock Main Page (you'll need to create this)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const StockMainPage()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You do not have permission to view stock'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    child: Row(
                      children: const [
                        Icon(Icons.inventory,
                            size: 40, color: Colors.orange),
                        SizedBox(width: 20),
                        Text(
                          "Stock",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Show message if no cards are visible
            if (!permissionProvider.canViewCustomer() &&
                !permissionProvider.canViewSalesReport() &&
                !permissionProvider.canViewStock())
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 60,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Limited Access',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        permissionProvider.canCreateNewBill()
                            ? 'You can only create new bills'
                            : 'Contact administrator for access',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (permissionProvider.canCreateNewBill())
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NewBillingPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                          ),
                          child: const Text(
                            'Go to New Billing',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),

      // FLOATING ACTION BUTTON for New Billing (if user has permission)
      floatingActionButton: permissionProvider.canCreateNewBill()
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NewBillingPage(),
            ),
          );
        },
        backgroundColor: Colors.blue.shade800,
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: const Text(
          'New Bill',
          style: TextStyle(color: Colors.white),
        ),
      )
          : null,

    );
  }
}