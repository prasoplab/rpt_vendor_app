import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rpt_vendor_app/screens/menu_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    FocusScope.of(context).unfocus(); 

    if (_usernameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      _showSnackBar('กรุณากรอกรหัสพนักงานและรหัสผ่านให้ครบถ้วน', Colors.orange.shade800);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    const String scriptUrl = 'https://script.google.com/macros/s/AKfycbxl01N5r_wjweW_AMlA8kE-P3vkDKU86kxSWNF3UmwlTdy1O16XnktaH1wYMgEScONJ/exec';

    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        body: {
          "action": "login",
          "username": _usernameCtrl.text.trim(),
          "password": _passwordCtrl.text.trim(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        final result = jsonDecode(response.body);

        if (result['status'] == 'success') {
          if (mounted) {
            String userName = result['name'] ?? 'ไม่ระบุชื่อ';
            String role = result['role'] ?? 'User';

            _showSnackBar('เข้าสู่ระบบสำเร็จ! ยินดีต้อนรับคุณ $userName', Colors.green.shade700);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MenuScreen(
                  userName: userName,
                  role: role,
                ),
              ),
            );
          }
        } else {
          _showSnackBar('รหัสพนักงาน หรือ รหัสผ่านไม่ถูกต้อง', Colors.red.shade800);
        }
      } else {
        _showSnackBar('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ (Code: ${response.statusCode})', Colors.red.shade800);
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการเชื่อมต่อเครือข่าย', Colors.red.shade800);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.blue.shade200, blurRadius: 10, spreadRadius: 2)],
                ),
                child: Icon(Icons.assignment_ind_rounded, size: 80, color: Colors.blue.shade900),
              ),
              const SizedBox(height: 24),
              Text(
                'ระบบประเมินซัพพลายเออร์\nและตรวจสอบ RPT',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade900, height: 1.3),
              ),
              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _usernameCtrl,
                      decoration: InputDecoration(
                        labelText: 'รหัสพนักงาน',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'รหัสผ่าน',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          // 🌟 แก้ไขตรงนี้เรียบร้อยครับ ลบ onChanged ออกแล้ว
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text('© 2026 Civil Engineering Public Company Limited', style: TextStyle(fontSize: 12, color: Colors.black45)),
            ],
          ),
        ),
      ),
    );
  }
}