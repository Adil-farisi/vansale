import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:van_go/Vangoui/permissions/permission_provider.dart';
import 'homescreen.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  // FIXED: Hardcoded URL to match your other API calls
  final String baseUrl = "http://192.168.1.108:80/gst-3-3-production/mobile-service/vansales";

  // Show permission loading overlay
  void _showPermissionLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Colors.blue,
              ),
              SizedBox(height: 16),
              Text(
                "Loading Permissions...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ API LOGIN FUNCTION =============
  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // FIXED: Use hardcoded URL instead of fetching from SharedPreferences
      String apiUrl = "$baseUrl/login.php";

      // Get UNID from SharedPreferences (this should be set during registration)
      String? unid = prefs.getString("unid");

      if (unid == null || unid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration data not found. Please register again."),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final Map<String, String> body = {
        "user_name": usernameController.text.trim(),
        "password": passwordController.text.trim(),
        "unid": unid,
      };

      print("===== LOGIN API REQUEST =====");
      print("URL: $apiUrl");
      print("BODY: ${json.encode(body)}");
      print("=============================");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception("Connection timeout. Please check your network.");
        },
      );

      print("===== LOGIN API RESPONSE =====");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("==============================");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["result"] == "1") {
          String veh = data["veh"] ?? "";

          // SAVE LOGIN DATA
          await prefs.setBool("isLoggedIn", true);
          await prefs.setString("username", usernameController.text.trim());
          await prefs.setString("veh", veh);

          // Also save the base URL for other pages to use
          await prefs.setString("server_url", baseUrl);

          print("===== LOGIN SUCCESS =====");
          print("Saved VEH: $veh");
          print("Base URL: $baseUrl");
          print("=========================");

          // Show initial success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data["message"] ?? "Login Successful"),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }

          // ============ FETCH PERMISSIONS ============
          // Add a small delay to ensure login is fully processed
          await Future.delayed(const Duration(milliseconds: 500));

          print("Fetching user permissions...");

          // IMPORTANT: Store context before async operations
          final currentContext = context;

          // Check if widget is still mounted
          if (!mounted) return;

          // Show loading dialog for permissions
          _showPermissionLoading(currentContext);

          try {
            // Get the permission provider using stored context
            final permissionProvider = Provider.of<PermissionProvider>(
                currentContext,
                listen: false
            );

            // Clear any existing permissions first
            await permissionProvider.clearPermissions();

            // Fetch fresh permissions
            final permissionSuccess = await permissionProvider.fetchPermissions();

            // Hide loading dialog
            if (Navigator.canPop(currentContext)) {
              Navigator.pop(currentContext);
            }

            if (!mounted) return;

            if (permissionSuccess && permissionProvider.permissions != null) {
              print("===== PERMISSION FETCH SUCCESS =====");
              print("User can add customer: ${permissionProvider.canAddCustomer()}");
              print("User can create bill: ${permissionProvider.canCreateNewBill()}");
              print("User can view stock: ${permissionProvider.canViewStock()}");
              print("Total permissions loaded: Yes");

              // Show permission success
              ScaffoldMessenger.of(currentContext).showSnackBar(
                const SnackBar(
                  content: Text("All permissions loaded successfully!"),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );

              // Navigate to home screen
              Navigator.pushReplacement(
                currentContext,
                MaterialPageRoute(builder: (_) => HomeScreen()),
              );

            } else {
              print("===== PERMISSION FETCH FAILED =====");
              print("Error: ${permissionProvider.error}");

              // Hide loading dialog if still showing
              if (Navigator.canPop(currentContext)) {
                Navigator.pop(currentContext);
              }

              if (!mounted) return;

              // Show warning but still allow navigation
              showDialog(
                context: currentContext,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Text("Permission Warning"),
                  content: Text(
                    permissionProvider.error ??
                        "Unable to load user permissions. Some features may be limited.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (mounted) {
                          Navigator.pushReplacement(
                            currentContext,
                            MaterialPageRoute(builder: (_) => HomeScreen()),
                          );
                        }
                      },
                      child: const Text("Continue Anyway"),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        // Retry permission fetch
                        if (!mounted) return;
                        _showPermissionLoading(currentContext);
                        try {
                          final permissionProvider = Provider.of<PermissionProvider>(
                              currentContext,
                              listen: false
                          );
                          final retrySuccess = await permissionProvider.fetchPermissions();

                          if (Navigator.canPop(currentContext)) {
                            Navigator.pop(currentContext);
                          }

                          if (!mounted) return;

                          if (retrySuccess) {
                            Navigator.pushReplacement(
                              currentContext,
                              MaterialPageRoute(builder: (_) => HomeScreen()),
                            );
                          }
                        } catch (e) {
                          if (Navigator.canPop(currentContext)) {
                            Navigator.pop(currentContext);
                          }
                          if (mounted) {
                            Navigator.pushReplacement(
                              currentContext,
                              MaterialPageRoute(builder: (_) => HomeScreen()),
                            );
                          }
                        }
                      },
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              );
            }

          } catch (permissionError) {
            print("===== PERMISSION FETCH ERROR =====");
            print("Error: $permissionError");

            // Hide loading dialog if still showing
            if (Navigator.canPop(currentContext)) {
              Navigator.pop(currentContext);
            }

            if (!mounted) return;

            // Show error dialog but allow user to continue
            showDialog(
              context: currentContext,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text("Permission Error"),
                content: Text(
                  "Failed to load permissions: $permissionError\n\n"
                      "You can continue with limited functionality or retry.",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (mounted) {
                        Navigator.pushReplacement(
                          currentContext,
                          MaterialPageRoute(builder: (_) => HomeScreen()),
                        );
                      }
                    },
                    child: const Text("Continue"),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await loginUser(); // Retry the entire login process
                    },
                    child: const Text("Retry Login"),
                  ),
                ],
              ),
            );
          }
          // ============ END OF PERMISSION FETCH ============

        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data["message"] ?? "Login Failed"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Server Error: ${response.statusCode}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("===== LOGIN ERROR =====");
      print(e.toString());
      print("=======================");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Connection Error: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration textFieldStyle(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Text(
                    "VanGo",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                const Text(
                  "Login",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: usernameController,
                  keyboardType: TextInputType.phone,
                  decoration: textFieldStyle("Enter phone number"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Phone number is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscure,
                  decoration: textFieldStyle(
                    "Enter password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : loginUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      "LOGIN",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Show current server URL for debugging



                // Debug button for testing (remove in production)
                if (const bool.fromEnvironment('DEBUG'))
                  Column(
                    children: [
                      const Divider(),
                      const Text("Debug Tools", style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
                          await permissionProvider.fetchPermissions();
                          print("Debug: Manually fetched permissions");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                        child: const Text("Test Permissions"),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}