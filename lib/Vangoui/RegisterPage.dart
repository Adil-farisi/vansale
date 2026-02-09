import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'Login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController urlCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;

  // ===================== GENERATE UNID =====================
  String generateUnid() {
    final DateTime now = DateTime.now();

    String unid =
        "${now.year.toString().padLeft(4, '0')}"
        "${now.month.toString().padLeft(2, '0')}"
        "${now.day.toString().padLeft(2, '0')}"
        "${now.hour.toString().padLeft(2, '0')}"
        "${now.minute.toString().padLeft(2, '0')}"
        "${now.second.toString().padLeft(2, '0')}";

    print("==================================");
    print("Generated UNID: $unid");
    print("==================================");

    return unid;
  }

  // ===================== CALL REGISTER API =====================
  Future<void> registerWithApi() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    String baseUrl = urlCtrl.text.trim();
    String phone = phoneCtrl.text.trim();
    String password = passwordCtrl.text.trim();

    String unid = generateUnid();

    String apiUrl = "$baseUrl/registration.php";

    final Map<String, String> body = {
      "user_name": phone,
      "unid": unid,
      "password": password,
    };

    print("===== API REQUEST =====");
    print("URL: $apiUrl");
    print("BODY: ${json.encode(body)}");
    print("=======================");

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      print("===== API RESPONSE =====");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("========================");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["result"] == "1") {
          // Registration Success

          String veh = data["veh"] ?? "";

          final prefs = await SharedPreferences.getInstance();

          await prefs.setBool('isRegistered', true);
          await prefs.setBool('isLoggedIn', false);

          await prefs.setString('server_url', baseUrl);
          await prefs.setString('reg_username', phone);
          await prefs.setString('reg_password', password);
          await prefs.setString('unid', unid);
          await prefs.setString('veh', veh);

          print("Saved VEH from API: $veh");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data["message"] ?? "Registered Successfully"),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Login()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data["message"] ?? "Registration Failed"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Server Error: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("===== ERROR =====");
      print(e.toString());
      print("=================");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  InputDecoration _inputStyle(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 90),

              Center(
                child: Text(
                  "VanGo",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                "Register",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              TextFormField(
                controller: urlCtrl,
                decoration: _inputStyle("Server URL"),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return "Server URL is required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputStyle("Phone Number"),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return "Phone number is required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: passwordCtrl,
                obscureText: _obscure,
                decoration: _inputStyle(
                  "Password (3 Characters)",
                  suffix: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscure = !_obscure);
                    },
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return "Password is required";
                  }
                  if (v.length != 3) {
                    return "Password must be exactly 3 characters";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: confirmCtrl,
                obscureText: _obscure,
                decoration: _inputStyle("Confirm Password"),
                validator: (v) {
                  if (v != passwordCtrl.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isLoading ? null : registerWithApi,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "REGISTER",
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
