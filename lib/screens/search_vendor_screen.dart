import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rpt_vendor_app/models/rpt_models.dart';
import 'package:rpt_vendor_app/screens/evaluation_screen.dart';

class SearchVendorScreen extends StatefulWidget {
  final String userName; 

  const SearchVendorScreen({
    super.key,
    required this.userName,
  });

  @override
  State<SearchVendorScreen> createState() => _SearchVendorScreenState();
}

class _SearchVendorScreenState extends State<SearchVendorScreen> {
  final TextEditingController _vendorNameCtrl = TextEditingController();
  final TextEditingController _productTypeCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _contactPersonCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  
  final TextEditingController _directorNameCtrl = TextEditingController();
  
  final List<DirectorMatch> _rptResults = []; 
  bool _isCheckingRpt = false;

  @override
  void dispose() {
    _vendorNameCtrl.dispose();
    _productTypeCtrl.dispose();
    _addressCtrl.dispose();
    _contactPersonCtrl.dispose();
    _phoneCtrl.dispose();
    _directorNameCtrl.dispose();
    super.dispose();
  }

  // 🌟 ฟังก์ชันเช็ค RPT จากฐานข้อมูล
  Future<void> _addDirectorToList() async {
    if (_directorNameCtrl.text.isEmpty) return;
    
    String nameInput = _directorNameCtrl.text.trim();

    setState(() {
      _isCheckingRpt = true; 
    });

    try {
      final String scriptUrl = 'https://script.google.com/macros/s/AKfycbxl01N5r_wjweW_AMlA8kE-P3vkDKU86kxSWNF3UmwlTdy1O16XnktaH1wYMgEScONJ/exec';

      final response = await http.post(
        Uri.parse(scriptUrl),
        body: {
          "action": "check_rpt",
          "names": jsonEncode([nameInput]), 
          "vendorName": _vendorNameCtrl.text.isNotEmpty ? _vendorNameCtrl.text : "ไม่ระบุ Vendor",
          "searchBy": widget.userName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        final List<dynamic> result = jsonDecode(response.body);
        
        if (result.isNotEmpty) {
          final matchData = result[0];
          
          setState(() {
            _rptResults.add(
              DirectorMatch(
                directorId: matchData['directorId']?.toString() ?? "MANUAL-${_rptResults.length + 1}",
                name: matchData['name'] ?? nameInput,
                isMatch: matchData['isMatch'] ?? false,
                relation: matchData['relation']?.toString() ?? "-",
              ),
            );
            _directorNameCtrl.clear(); 
          });
        }
      } else {
        _showWarning('เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ (Code: ${response.statusCode})');
      }
    } catch (e) {
      _showWarning('เกิดข้อผิดพลาดในการตรวจสอบข้อมูล: $e');
    } finally {
      setState(() {
        _isCheckingRpt = false; 
      });
    }
  }

  void _removeDirector(int index) {
    setState(() {
      _rptResults.removeAt(index);
    });
  }

  // 🌟 ฟังก์ชันก้าวไปหน้าประเมิน (จุดที่แก้ปัญหาข้อมูลหาย!)
  void _goToEvaluationPage() {
    if (_vendorNameCtrl.text.isEmpty) {
      _showWarning('กรุณากรอกชื่อผู้ขาย / ซัพพลายเออร์');
      return;
    }
    if (_productTypeCtrl.text.isEmpty) {
      _showWarning('กรุณากรอกประเภทสินค้า/บริการ');
      return;
    }

    final SupplierEvaluation temporaryEval = SupplierEvaluation();
    temporaryEval.vendorName = _vendorNameCtrl.text;
    temporaryEval.productType = _productTypeCtrl.text;
    temporaryEval.address = _addressCtrl.text.isEmpty ? '-' : _addressCtrl.text;
    temporaryEval.contactPerson = _contactPersonCtrl.text.isEmpty ? '-' : _contactPersonCtrl.text;
    temporaryEval.phone = _phoneCtrl.text.isEmpty ? '-' : _phoneCtrl.text;

    bool hasRpt = _rptResults.any((element) => element.isMatch);
    temporaryEval.rptStatus = hasRpt ? 'MATCH' : 'CLEAR';

    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => EvaluationScreen(
          userName: widget.userName,
          initialEvalData: temporaryEval, 
          rptResults: _rptResults, // 🚀 ส่งไม้ผลัด (รายชื่อกรรมการ) พ่วงไปให้หน้าประเมินตรงนี้ครับ!
        ),
      ),
    );
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontSize: 13)), backgroundColor: Colors.orange.shade800),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('ข้อมูลซัพพลายเออร์ & ตรวจสอบ RPT', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ข้อมูลทั่วไปของผู้ขาย (Vendor Profile)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 4),
            
            _buildFormLabel('ชื่อผู้ขาย / ซัพพลายเออร์ *'),
            _buildCompactInputField(controller: _vendorNameCtrl, hint: 'บริษัท ตัวอย่าง จำกัด', icon: Icons.business_rounded),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormLabel('ประเภทสินค้า / บริการ *'),
                      _buildCompactInputField(controller: _productTypeCtrl, hint: 'เช่น คอนกรีต, เหล็กเส้น', icon: Icons.category_rounded),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormLabel('เบอร์โทรศัพท์ติดต่อ'),
                      _buildCompactInputField(controller: _phoneCtrl, hint: '02-XXX-XXXX', icon: Icons.phone_rounded, isPhone: true),
                    ],
                  ),
                ),
              ],
            ),
            
            _buildFormLabel('ชื่อผู้ติดต่อ / เซลล์'),
            _buildCompactInputField(controller: _contactPersonCtrl, hint: 'คุณสมชาย ใจดี', icon: Icons.person_outline_rounded),
            
            _buildFormLabel('ที่อยู่บริษัท / สำนักงานใหญ่'),
            SizedBox(
              height: 34,
              child: TextField(
                controller: _addressCtrl,
                decoration: InputDecoration(
                  hintText: 'เลขที่, ถนน, เขต, จังหวัด...',
                  hintStyle: const TextStyle(fontSize: 11.5, color: Colors.black38),
                  prefixIcon: const Icon(Icons.location_on_rounded, size: 16),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: Divider(height: 1),
            ),

            const Text('ระบุรายชื่อกรรมการ / ผู้ถือหุ้นตามหนังสือรับรอง (RPT Check)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _directorNameCtrl,
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ ชื่อ-นามสกุล กรรมการทีละรายชื่อ...',
                        hintStyle: const TextStyle(fontSize: 11.5, color: Colors.black38),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800, 
                      foregroundColor: Colors.white, 
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
                    ),
                    onPressed: _isCheckingRpt ? null : _addDirectorToList, 
                    child: _isCheckingRpt 
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search, size: 14),
                            SizedBox(width: 4),
                            Text('ตรวจชื่อ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(4)),
                child: _rptResults.isEmpty
                    ? const Center(child: Text('ยังไม่มีการระบุรายชื่อกรรมการ (พิมพ์ชื่อแล้วกดตรวจ)', style: TextStyle(fontSize: 11.5, color: Colors.black38)))
                    : ListView.builder(
                        itemCount: _rptResults.length,
                        itemBuilder: (context, index) {
                          final item = _rptResults[index];
                          return Container(
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                            child: ListTile(
                              dense: true,
                              visualDensity: const VisualDensity(vertical: -3),
                              title: Text(item.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                item.isMatch ? '⚠️ ติดสถานะ RPT (${item.relation})' : '✅ ผ่านเกณฑ์ปกติ (CLEAR)',
                                style: TextStyle(fontSize: 11, color: item.isMatch ? Colors.red.shade800 : Colors.green.shade800),
                              ),
                              trailing: InkWell(
                                onTap: () => _removeDirector(index),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(Icons.cancel_rounded, color: Colors.red, size: 16),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: _goToEvaluationPage,
                icon: const Icon(Icons.navigate_next_rounded, size: 20),
                label: const Text('ยืนยันข้อมูล & ไปทำแบบประเมินต่อ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, top: 4),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54)),
    );
  }

  Widget _buildCompactInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPhone = false,
  }) {
    return Container(
      height: 34,
      margin: const EdgeInsets.only(bottom: 4),
      child: TextField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 11.5, color: Colors.black38),
          prefixIcon: Icon(icon, size: 15, color: Colors.black45),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
        ),
        style: const TextStyle(fontSize: 12.5),
      ),
    );
  }
}