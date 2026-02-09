import 'package:flutter/material.dart';
import 'HomePage.dart';
import 'customerpage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;

  final List<Widget> _pages = const [
    HomePage(),
    CustomerPage(),
  ];

  void _onItemTapped(int index) {
    if (_isDrawerOpen) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Detect drawer open / close
      onDrawerChanged: (isOpen) {
        setState(() {
          _isDrawerOpen = isOpen;
        });
      },

      drawer: Drawer(
        child: Column(
          children: const [
            DrawerHeader(
              child: Text("VanGo Menu"),
            ),
            // keep your existing drawer content here
          ],
        ),
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // ✅ HIDE bottom bar when drawer is open
      bottomNavigationBar: _isDrawerOpen
          ? null
          : BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Customers',
          ),
        ],
      ),
    );
  }
}
