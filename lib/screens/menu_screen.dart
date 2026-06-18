import 'package:flutter/material.dart';
import 'package:rpt_vendor_app/screens/search_vendor_screen.dart';
import 'package:rpt_vendor_app/screens/history_screen.dart'; // 🌟 เพิ่มหน้า History เข้ามาในเมนู
// 🚨 อย่าลืม import หน้ากรรมการของพี่ต้นนะครับ
import 'package:rpt_vendor_app/screens/add_director_screen.dart'; 
import 'package:rpt_vendor_app/screens/all_directors_screen.dart'; // ใส่ชื่อไฟล์ของพี่ให้ถูกต้องนะครับ

class MenuScreen extends StatelessWidget {
  final String userName;
  final String role;

  const MenuScreen({
    super.key, 
    required this.userName, 
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    bool isAdmin = role.toLowerCase() == 'admin';

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // พื้นหลังสีเทาอ่อนสุดๆ ให้ดูคลีน
      appBar: AppBar(
        title: const Text('เมนูหลัก', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 👤 ส่วน Header ผู้ใช้งาน (สไตล์ Minimal)
              // ==========================================
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isAdmin ? Colors.red.shade50 : Colors.green.shade50,
                    child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person, color: isAdmin ? Colors.red.shade800 : Colors.green.shade800),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('สวัสดี, $userName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text('สิทธิ์การใช้งาน: $role', style: TextStyle(fontSize: 12, color: isAdmin ? Colors.red.shade700 : Colors.green.shade700)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              const Text(' การจัดการซัพพลายเออร์', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black45)),
              const SizedBox(height: 8),

              // ==========================================
              // 🔲 รายการเมนู (Minimal List)
              // ==========================================
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 🌟 เมนูที่ 1: ประเมิน Vendor (เห็นทุกคน)
                    _buildMinimalTile(
                      title: 'ประเมินซัพพลายเออร์รายใหม่',
                      subtitle: 'สร้างแบบประเมินและตรวจสอบ RPT',
                      icon: Icons.assignment_turned_in_rounded,
                      color: Colors.blue.shade700,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SearchVendorScreen(userName: userName)));
                      },
                    ),

                    // 🌟 เมนูที่ 2: ประวัติการประเมิน (เห็นทุกคน)
                    _buildMinimalTile(
                      title: 'ประวัติการประเมิน',
                      subtitle: 'ดูประวัติย้อนหลัง แก้ไข และพิมพ์ PDF',
                      icon: Icons.history_rounded,
                      color: Colors.purple.shade600,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen(userName: userName)));
                      },
                    ),

                    if (isAdmin) ...[
                      const SizedBox(height: 20),
                      const Text(' การจัดการระบบ (Admin)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black45)),
                      const SizedBox(height: 8),

                      // 🌟 เมนูที่ 3: เพิ่มกรรมการ
                      _buildMinimalTile(
                        title: 'เพิ่มข้อมูลกรรมการ',
                        subtitle: 'เพิ่มรายชื่อกรรมการเข้าสู่ฐานข้อมูล',
                        icon: Icons.person_add_alt_1_rounded,
                        color: Colors.teal.shade600,
                        onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AddDirectorScreen(userName: userName)));
                          _showComingSoon(context);
                        },
                      ),

                      // 🌟 เมนูที่ 4: แก้ไขกรรมการ
                      _buildMinimalTile(
                        title: 'จัดการข้อมูลกรรมการ',
                        subtitle: 'แก้ไขและลบรายชื่อกรรมการในระบบ',
                        icon: Icons.manage_accounts_rounded,
                        color: Colors.orange.shade700,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => AllDirectorsScreen(userName: userName)));
                          _showComingSoon(context);
                        },
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 วิดเจ็ตปุ่มเมนูสไตล์ Minimal (คลีนๆ มีลูกศรชี้)
  Widget _buildMinimalTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), // สีพื้นหลังไอคอนแบบจางๆ
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กำลังพัฒนาหน้านี้...')));
  }
}