import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:van_go/Vangoui/HomePage.dart';
import 'package:van_go/Vangoui/Login.dart';
import 'package:van_go/Vangoui/NewBillingPage.dart';
import 'package:van_go/Vangoui/ReceiptPage.dart';
import 'package:van_go/Vangoui/RegisterPage.dart';
import 'package:van_go/Vangoui/customerpage.dart';
import 'package:van_go/Vangoui/homescreen.dart';
import 'package:van_go/Vangoui/invoice/InvoiceCustomerPage.dart';
import 'package:van_go/Vangoui/logosplashscreen.dart';
import 'package:van_go/Vangoui/stocks/BatchWiseStockPage.dart';

// Import the new screens

// Import permission provider
import 'package:van_go/Vangoui/permissions/permission_provider.dart';

import 'Vangoui/financeyear/FinancialYearSelectionScreen.dart';
import 'Vangoui/financeyear/MainWrapper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Permission provider - initialize immediately
        ChangeNotifierProvider<PermissionProvider>(
          create: (context) => PermissionProvider(),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'VanGo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
        // Change this from Logosplashscreen to MainWrapper
        home: const Logosplashscreen(),

        // Named routes
        routes: {
          '/login': (context) => const Login(),
          '/home': (context) => const HomeScreen(),  // This will now only be accessible after financial year selection
          '/register': (context) => const RegisterPage(),
          '/customer': (context) => const CustomerPage(),
          '/new-bill': (context) => const NewBillingPage(),
          '/receipt': (context) => const ReceiptPage(),
          '/stock': (context) => const BatchWiseStockPage(),
          '/invoice-customer': (context) => const InvoiceCustomerPage(),
          '/homepage': (context) => const HomePage(),

          // Add new routes for financial year flow
          '/financial-year-selection': (context) => const FinancialYearSelectionScreen(),
        },
      ),
    );
  }
}