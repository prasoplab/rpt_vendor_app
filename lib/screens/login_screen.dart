import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import 'search_vendor_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;

  // 🌟 1. นำ URL ที่ได้จากการ Deploy Google Apps Script มาวางตรงนี้ครับ
  final String googleScriptUrl = 'https://script.google.com/macros/s/AKfycbx6GvQzNAHR4wu30XHpNzWgatMhZWUwVxKDN912nZtDqjWbwSKd8tatImuf8tGCQni3/exec';

  void _handleLogin() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('กรุณากรอกรหัสพนักงานและรหัสผ่านให้ครบถ้วน', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 🌟 2. ยิงข้อมูลเชื่อมต่อไปยัง Google Sheet API ของเรา
      final response = await http.post(
        Uri.parse(googleScriptUrl),
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode({
          'action': 'login', // บอก API ว่าเราต้องการใช้ฟังก์ชันเข้าสู่ระบบ
          'username': username, // ส่งรหัสพนักงาน (เทียบกับคอลัมน์ A)
          'password': password, // ส่งรหัสผ่าน (เทียบกับคอลัมน์ B)
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          // ดึงชื่อจริงและสิทธิ์การใช้งาน ที่ส่งกลับมาจาก Sheet (คอลัมน์ C และ E)
          String fullNameFromDatabase = data['name'] ?? 'ไม่ระบุชื่อ'; 
          // String userRole = data['role'] ?? ''; // (เผื่อใช้แบ่งสิทธิ์ในอนาคต)

          if (mounted) {
            _showSnackBar('ยินดีต้อนรับคุณ $fullNameFromDatabase', Colors.green);
            
            // เปลี่ยนหน้าไปยังหน้าค้นหา พร้อมส่งชื่อจาก Google Sheet ไปออกรายงาน PDF
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SearchVendorScreen(
                  userName: fullNameFromDatabase, 
                ),
              ),
            );
          }
        } else {
          // กรณี Username/Password ไม่ตรงกับใน Sheet
          _showSnackBar('รหัสพนักงานหรือรหัสผ่านไม่ถูกต้อง', Colors.red);
        }
      } else {
        _showSnackBar('การเชื่อมต่อเซิร์ฟเวอร์ผิดพลาด (${response.statusCode})', Colors.orange);
      }
    } catch (e) {
      print('==== ERROR CONNECTION ====');
      print(e.toString());
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.engineering, size: 60, color: Colors.blue.shade900),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'CIVIL - RPT Checker',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    ),
                    const SizedBox(height: 8),
                    const Text('เข้าสู่ระบบตรวจสอบบุคคลเกี่ยวโยง', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 32),

                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'รหัสพนักงาน (Employee ID)',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'รหัสผ่าน (Password)',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onSubmitted: (_) => _handleLogin(), 
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}