import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddDirectorScreen extends StatefulWidget {
  final String userName; // 🌟 เพิ่มตัวแปรรับชื่อพนักงานจากหน้า Menu

  const AddDirectorScreen({super.key, required this.userName});

  @override
  State<AddDirectorScreen> createState() => _AddDirectorScreenState();
}

class _AddDirectorScreenState extends State<AddDirectorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();

  DateTime? _selectedDate;
  DateTime? _endDate;

  String _ageStatus = 'รอระบุวันเกิด';
  String _maritalStatus = 'โสด';
  String _relationship = 'กรรมการบริษัท';
  String _activeStatus = 'ยังเกี่ยวข้อง';
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1980),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        int age = DateTime.now().year - picked.year;
        _ageStatus = age >= 20
            ? 'บรรลุนิติภาวะ ($age ปี)'
            : 'ยังไม่บรรลุนิติภาวะ ($age ปี)';
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'กรุณาระบุวันเกิด',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_activeStatus == 'พ้นสภาพ' && _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'กรุณาระบุวันที่พ้นสภาพ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      // 🌟 จับชื่อ-นามสกุลมารวมกัน เพื่อให้หน้าค้นหา RPT ค้นเจอง่ายๆ
      String fullName =
          "${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}";

      const String scriptUrl =
          'https://script.google.com/macros/s/AKfycbw9U7rcS469vPjpHujj8ih9_mKcK4yZhQEDejK_T7z0teB69EeX5QjkZ7elleN-QW5u/exec';

      try {
        final response = await http.post(
          Uri.parse(scriptUrl),
          body: {
            "action": "add_director",
            "directorName": fullName, // ชื่อเต็ม
            "firstName": _firstNameCtrl.text.trim(),
            "lastName": _lastNameCtrl.text.trim(),
            "dob":
                "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
            "ageStatus": _ageStatus,
            "relation": _relationship,
            "maritalStatus": _maritalStatus,
            "activeStatus": _activeStatus,
            "endDate": _endDate != null
                ? "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}"
                : "-",
            "addedBy": widget.userName, // ส่งชื่อคนล็อกอินไปบันทึก
          },
        );

        if (response.statusCode == 200 || response.statusCode == 302) {
          final result = jsonDecode(response.body);
          if (result['status'] == 'success') {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ บันทึกข้อมูลกรรมการเรียบร้อยแล้ว'),
                backgroundColor: Colors.green,
              ),
            );

            // ล้างข้อมูลหลังบันทึกเสร็จ
            _firstNameCtrl.clear();
            _lastNameCtrl.clear();
            setState(() {
              _selectedDate = null;
              _endDate = null;
              _ageStatus = 'รอระบุวันเกิด';
              _maritalStatus = 'โสด';
              _relationship = 'กรรมการบริษัท';
              _activeStatus = 'ยังเกี่ยวข้อง';
            });

            // กลับไปหน้าเมนู
            Navigator.pop(context);
          } else {
            _showError('เกิดข้อผิดพลาดจากระบบ: ${result['message']}');
          }
        } else {
          _showError('การเชื่อมต่อล้มเหลว (Code: ${response.statusCode})');
        }
      } catch (e) {
        _showError('ข้อผิดพลาดเครือข่าย: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'เพิ่มข้อมูลบุคคลเกี่ยวโยง',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'กำลังบันทึกข้อมูล...',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _firstNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'ชื่อ (ไม่ต้องใส่คำนำหน้า)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อ' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'นามสกุล',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (v) => v!.isEmpty ? 'กรุณากรอกนามสกุล' : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      title: Text(
                        _selectedDate == null
                            ? 'คลิกเพื่อเลือกวันเกิด'
                            : 'วันเกิด: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        'สถานะ: $_ageStatus',
                        style: TextStyle(
                          color: _selectedDate == null
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Icon(
                        Icons.calendar_today,
                        color: Colors.blue.shade700,
                      ),
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 16),

                    // --- ส่วนที่เพิ่มใหม่: เลือกสถานะ และ วันที่พ้นสภาพ ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.blue.shade50,
                      ),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _activeStatus,
                            decoration: InputDecoration(
                              labelText: 'สถานะปัจจุบัน',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                            items: ['ยังเกี่ยวข้อง', 'พ้นสภาพ']
                                .map(
                                  (String v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() {
                              _activeStatus = v!;
                              if (_activeStatus == 'ยังเกี่ยวข้อง')
                                _endDate = null;
                            }),
                          ),
                          if (_activeStatus == 'พ้นสภาพ') ...[
                            const SizedBox(height: 12),
                            ListTile(
                              tileColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              title: Text(
                                _endDate == null
                                    ? 'ระบุวันที่พ้นสภาพ'
                                    : 'วันที่พ้นสภาพ: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: const Icon(
                                Icons.date_range,
                                color: Colors.red,
                              ),
                              onTap: () => _selectEndDate(context),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // -------------------------------------------------
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _relationship,
                      decoration: InputDecoration(
                        labelText: 'ความสัมพันธ์ (RPT)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items:
                          [
                                'กรรมการบริษัท',
                                'ผู้ถือหุ้นใหญ่',
                                'ผู้บริหารระดับสูง',
                                'เครือญาติ',
                              ]
                              .map(
                                (String v) =>
                                    DropdownMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _relationship = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _maritalStatus,
                      decoration: InputDecoration(
                        labelText: 'สถานะครอบครัว',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: ['โสด', 'สมรส', 'หย่าร้าง']
                          .map(
                            (String v) =>
                                DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _maritalStatus = v!),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _saveData,
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'บันทึกข้อมูลกรรมการ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
