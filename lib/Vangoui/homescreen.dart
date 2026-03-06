import 'package:flutter/material.dart';
import 'HomePage.dart';
import 'customerpage.dart';
import 'financeyear/financial_year.dart';
import 'financeyear/financial_year_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;

  // Financial year variables
  List<FinancialYear> _financialYears = [];
  FinancialYear? _selectedFinancialYear;

  // Loading state
  bool _isLoading = true;
  bool _isRefreshing = false;

  // Animation controller for the FAB
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Widget> _pages = const [
    HomePage(),
    CustomerPage(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeFinancialYears();

    // Initialize animation for the FAB
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  Future<void> _initializeFinancialYears() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to fetch fresh data from API first
      try {
        _financialYears = await FinancialYearService.fetchAndSaveFinancialYears();
        print('Fetched ${_financialYears.length} financial years from API');
      } catch (e) {
        print('API fetch failed, falling back to local storage: $e');
        // Fallback to local storage
        _financialYears = await FinancialYearService.loadAllYears();
      }

      // If still empty, generate default years
      if (_financialYears.isEmpty) {
        print('No years found, generating default years');
        _financialYears = FinancialYear.generateNextYears();
        await FinancialYearService.saveAllYears(_financialYears);
      }

      // Load selected year
      FinancialYear? savedYear = await FinancialYearService.loadSelectedYear();

      if (savedYear != null) {
        // Check if saved year exists in current years list
        bool exists = _financialYears.any((year) => year.id == savedYear.id);
        if (exists) {
          _selectedFinancialYear = savedYear;
        } else {
          // If saved year doesn't exist, use first year from list
          _selectedFinancialYear = _financialYears.first;
          await FinancialYearService.saveSelectedYear(_selectedFinancialYear!);
        }
      } else {
        // If no saved year, use first year
        _selectedFinancialYear = _financialYears.first;
        await FinancialYearService.saveSelectedYear(_selectedFinancialYear!);
      }
    } catch (e) {
      print('Error initializing financial years: $e');
      // Fallback to default
      _financialYears = FinancialYear.generateNextYears();
      _selectedFinancialYear = _financialYears.first;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to refresh financial years from API
  Future<void> _refreshFinancialYears() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refreshing financial years from server...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Fetch from API
      final freshYears = await FinancialYearService.refreshFinancialYears();

      if (freshYears.isNotEmpty) {
        setState(() {
          _financialYears = freshYears;
        });

        // Check if current selected year still exists in the new list
        if (_selectedFinancialYear != null) {
          bool exists = freshYears.any((year) => year.id == _selectedFinancialYear!.id);
          if (!exists) {
            // If selected year doesn't exist, select the first one
            setState(() {
              _selectedFinancialYear = freshYears.first;
            });
            await FinancialYearService.saveSelectedYear(_selectedFinancialYear!);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Your previously selected year is not available. Selected ${freshYears.first.displayName} instead.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Financial years refreshed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error refreshing financial years: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_isDrawerOpen) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  // Show financial year selection dialog
  Future<void> _showFinancialYearDialog() async {
    if (_isLoading) return;

    _animationController.reset();
    _animationController.forward();

    // Refresh the list before showing dialog (optional - can be removed if you don't want auto-refresh)
    if (_financialYears.isEmpty) {
      await _refreshFinancialYears();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header with refresh button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.green),
                        const SizedBox(width: 12),
                        const Text(
                          'Select Financial Year',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // Add refresh button
                        if (!_isRefreshing)
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () async {
                              Navigator.pop(context); // Close current dialog
                              await _refreshFinancialYears();
                              if (mounted) {
                                _showFinancialYearDialog(); // Reopen with fresh data
                              }
                            },
                            tooltip: 'Refresh from server',
                          ),
                        if (_isRefreshing)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  const Divider(),

                  // Current selected year display
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.green.withOpacity(0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Currently selected: ${_selectedFinancialYear?.displayName ?? 'None'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Years list
                  Expanded(
                    child: _financialYears.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No financial years available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _refreshFinancialYears();
                              if (mounted) {
                                _showFinancialYearDialog();
                              }
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _financialYears.length,
                      itemBuilder: (context, index) {
                        final year = _financialYears[index];
                        final isSelected = _selectedFinancialYear?.id == year.id;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green.withOpacity(0.1) : null,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.green : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.green : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSelected ? Icons.check : Icons.calendar_month,
                                color: isSelected ? Colors.white : Colors.grey.shade600,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              year.displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.green : Colors.black87,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${_formatDate(year.startDate)} - ${_formatDate(year.endDate)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                // Show finid in debug mode (optional)
                                if (const bool.fromEnvironment('DEBUG'))
                                  Text(
                                    'ID: ${year.id}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.radio_button_checked, color: Colors.green)
                                : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                            onTap: () async {
                              // Update selected year
                              setState(() {
                                _selectedFinancialYear = year;
                              });

                              // Save to SharedPreferences
                              await FinancialYearService.saveSelectedYear(year);

                              if (context.mounted) {
                                Navigator.pop(context);

                                // Show snackbar for confirmation
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Financial year changed to ${year.displayName}',
                                    ),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  // Footer with additional info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Financial year runs from April to March',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Detect drawer open/close
      onDrawerChanged: (isOpen) {
        setState(() {
          _isDrawerOpen = isOpen;
        });
      },

      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.menu, color: Colors.blue, size: 30),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "VanGo Menu",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedIndex = 0;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Customers'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Financial Years'),
              subtitle: Text(_selectedFinancialYear?.displayName ?? ''),
              trailing: _isRefreshing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _refreshFinancialYears,
                tooltip: 'Refresh from server',
              ),
              onTap: () {
                Navigator.pop(context);
                _showFinancialYearDialog();
              },
            ),
          ],
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // Custom Bottom Navigation Bar with Center Financial Button
      bottomNavigationBar: _isDrawerOpen || _isLoading
          ? null
          : Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home Tab
            Expanded(
              child: InkWell(
                onTap: () => _onItemTapped(0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedIndex == 0
                          ? Icons.home
                          : Icons.home_outlined,
                      color: _selectedIndex == 0
                          ? Colors.blue
                          : Colors.grey,
                      size: 26,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Home',
                      style: TextStyle(
                        color: _selectedIndex == 0
                            ? Colors.blue
                            : Colors.grey,
                        fontSize: 12,
                        fontWeight: _selectedIndex == 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Financial Year Center Button
            Container(
              margin: const EdgeInsets.only(bottom: 25),
              child: FloatingActionButton(
                onPressed: _isRefreshing ? null : _showFinancialYearDialog,
                backgroundColor: Colors.green,
                elevation: 4,
                heroTag: 'financial_year_fab',
                child: _isRefreshing
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    const SizedBox(height: 2),
                    Text(
                      _selectedFinancialYear?.displayName?.substring(2) ?? 'FY',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Customers Tab
            Expanded(
              child: InkWell(
                onTap: () => _onItemTapped(1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _selectedIndex == 1
                          ? Icons.people
                          : Icons.people_outline,
                      color: _selectedIndex == 1
                          ? Colors.blue
                          : Colors.grey,
                      size: 26,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customers',
                      style: TextStyle(
                        color: _selectedIndex == 1
                            ? Colors.blue
                            : Colors.grey,
                        fontSize: 12,
                        fontWeight: _selectedIndex == 1
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}