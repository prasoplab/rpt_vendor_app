import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddDirectorScreen extends StatefulWidget {
  final String userName; 

  const AddDirectorScreen({super.key, required this.userName});

  @override
  State<AddDirectorScreen> createState() => _AddDirectorScreenState();
}

class _AddDirectorScreenState extends State<AddDirectorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _relatedDirectorsCtrl = TextEditingController(); // ช่องเก็บกรรมการพ่วง

  DateTime? _selectedDate;
  DateTime? _endDate;

  String _prefix = 'นาย'; 
  String _ageStatus = 'รอระบุวันเกิด';
  String _maritalStatus = 'โสด';
  String _relationship = 'กรรมการบริษัท';
  String _activeStatus = 'ยังเกี่ยวข้อง';
  bool _isLoading = false;

  bool _isCompanyPrefix(String p) => p == 'บจ.' || p == 'บมจ.' || p == 'หจก.';

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
            content: Text('กรุณาระบุวันเกิด / วันจดทะเบียน', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_activeStatus == 'พ้นสภาพ' && _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาระบุวันที่พ้นสภาพ', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      // ประกอบร่างชื่อ
      String firstNameStr = _firstNameCtrl.text.trim();
      String lastNameStr = _isCompanyPrefix(_prefix) ? "" : _lastNameCtrl.text.trim();
      
      String fullName = _prefix == 'ไม่มี' 
          ? "$firstNameStr $lastNameStr".trim()
          : "$_prefix $firstNameStr $lastNameStr".trim();

      // 🌟 ใช้ URL ของพี่ต้นตามที่ส่งมาก่อนหน้านี้
      const String scriptUrl = 'https://script.google.com/macros/s/AKfycbw9U7rcS469vPjpHujj8ih9_mKcK4yZhQEDejK_T7z0teB69EeX5QjkZ7elleN-QW5u/exec';

      try {
        final response = await http.post(
          Uri.parse(scriptUrl),
          body: {
            "action": "add_director",
            "directorName": fullName, 
            "firstName": _prefix == 'ไม่มี' ? firstNameStr : "$_prefix $firstNameStr", 
            "lastName": lastNameStr,
            "dob": "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
            "ageStatus": _ageStatus,
            "relation": _relationship,
            "maritalStatus": _maritalStatus,
            "activeStatus": _activeStatus,
            "endDate": _endDate != null ? "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}" : "-",
            "addedBy": widget.userName, 
            "relatedDirectors": _relatedDirectorsCtrl.text.trim(), // ✅ เพิ่มบรรทัดนี้แล้ว บันทึกข้อมูลเข้าคอลัมน์ L 100%
          },
        );

        if (response.statusCode == 200 || response.statusCode == 302) {
          final result = jsonDecode(response.body);
          if (result['status'] == 'success') {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ บันทึกข้อมูลเรียบร้อยแล้ว'), backgroundColor: Colors.green),
            );

            // ล้างข้อมูลหลังบันทึก
            _firstNameCtrl.clear();
            _lastNameCtrl.clear();
            _relatedDirectorsCtrl.clear();
            setState(() {
              _prefix = 'นาย';
              _selectedDate = null;
              _endDate = null;
              _ageStatus = 'รอระบุวันเกิด';
              _maritalStatus = 'โสด';
              _relationship = 'กรรมการบริษัท';
              _activeStatus = 'ยังเกี่ยวข้อง';
            });

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('เพิ่มข้อมูลบุคคลเกี่ยวโยง', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  Text('กำลังบันทึกข้อมูล...', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _prefix,
                            decoration: InputDecoration(
                              labelText: 'สถานะ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true, fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            items: ['นาย', 'นาง', 'นางสาว', 'บจ.', 'บมจ.', 'หจก.', 'ไม่มี']
                                .map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) => setState(() {
                              _prefix = v!;
                              if (_isCompanyPrefix(_prefix)) {
                                _lastNameCtrl.clear();
                                _maritalStatus = 'หย่าร้าง'; 
                              }
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 5,
                          child: TextFormField(
                            controller: _firstNameCtrl,
                            decoration: InputDecoration(
                              labelText: _isCompanyPrefix(_prefix) ? 'ชื่อบริษัท/ห้างหุ้นส่วน *' : 'ชื่อจริง (ไม่ต้องคีย์คำนำหน้า) *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true, fillColor: Colors.white,
                            ),
                            validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อ' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (!_isCompanyPrefix(_prefix)) ...[
                      TextFormField(
                        controller: _lastNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'นามสกุล *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true, fillColor: Colors.white,
                        ),
                        validator: (v) => v!.isEmpty ? 'กรุณากรอกนามสกุล' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      title: Text(
                        _selectedDate == null
                            ? 'คลิกเพื่อเลือกวันเกิด / วันก่อตั้งนิติบุคคล'
                            : 'วันที่จดทะเบียน/เกิด: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        'สถานะ: $_ageStatus',
                        style: TextStyle(
                          color: _selectedDate == null ? Colors.red.shade700 : Colors.green.shade700,
                          fontSize: 12, fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Icon(Icons.calendar_today, color: Colors.blue.shade700),
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 16),

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
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              fillColor: Colors.white, filled: true,
                            ),
                            items: ['ยังเกี่ยวข้อง', 'พ้นสภาพ'].map((String v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                            onChanged: (v) => setState(() {
                              _activeStatus = v!;
                              if (_activeStatus == 'ยังเกี่ยวข้อง') _endDate = null;
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
                              trailing: const Icon(Icons.date_range, color: Colors.red),
                              onTap: () => _selectEndDate(context),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _relationship,
                      decoration: InputDecoration(
                        labelText: 'ความสัมพันธ์ (RPT)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true, fillColor: Colors.white,
                      ),
                      items: ['กรรมการบริษัท', 'ผู้ถือหุ้นใหญ่', 'ผู้บริหารระดับสูง', 'เครือญาติ', 'นิติบุคคลเกี่ยวโยง']
                          .map((String v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) => setState(() => _relationship = v!),
                    ),
                    const SizedBox(height: 16),

                    if (_isCompanyPrefix(_prefix)) ...[
                      TextFormField(
                        controller: _relatedDirectorsCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'รายชื่อกรรมการตามหนังสือรับรอง (คั่นด้วยเครื่องหมาย , )',
                          hintText: 'เช่น นายสมชาย สายเสมอ, นางวิภา ใจดี, นายวิชัย เรียนดี',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true, fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (!_isCompanyPrefix(_prefix)) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _maritalStatus,
                        decoration: InputDecoration(
                          labelText: 'สถานะครอบครัว',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true, fillColor: Colors.white,
                        ),
                        items: ['โสด', 'สมรส', 'หย่าร้าง'].map((String v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                        onChanged: (v) => setState(() => _maritalStatus = v!),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isLoading ? null : _saveData,
                      icon: const Icon(Icons.save),
                      label: const Text('บันทึกข้อมูลเข้าฐานข้อมูล', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}