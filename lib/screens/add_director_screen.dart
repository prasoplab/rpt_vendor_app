import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddDirectorScreen extends StatefulWidget {
  const AddDirectorScreen({super.key});

  @override
  State<AddDirectorScreen> createState() => _AddDirectorScreenState();
}

class _AddDirectorScreenState extends State<AddDirectorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  
  DateTime? _selectedDate;
  DateTime? _endDate; // ตัวแปรเก็บวันที่พ้นสภาพ
  
  String _ageStatus = 'รอระบุวันเกิด';
  String _maritalStatus = 'โสด';
  String _relationship = 'กรรมการบริษัท'; 
  String _activeStatus = 'ยังเกี่ยวข้อง'; // ตัวแปรสถานะการทำงาน
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: DateTime(1980), firstDate: DateTime(1900), lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        int age = DateTime.now().year - picked.year;
        _ageStatus = age >= 20 ? 'บรรลุนิติภาวะ ($age ปี)' : 'ยังไม่บรรลุนิติภาวะ ($age ปี)';
      });
    }
  }

  // ฟังก์ชันเลือกวันที่พ้นสภาพ
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาระบุวันเกิด')));
        return;
      }
      
      // ถ้าเลือกพ้นสภาพ แต่ไม่ใส่วันที่ ให้แจ้งเตือน
      if (_activeStatus == 'พ้นสภาพ' && _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาระบุวันที่พ้นสภาพ')));
        return;
      }

      setState(() => _isLoading = true);

      Map<String, String> directorData = {
        "director_id": "DIR-${DateTime.now().millisecondsSinceEpoch}", 
        "first_name": _firstNameCtrl.text.trim(),
        "last_name": _lastNameCtrl.text.trim(),
        "dob": "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
        "age_status": _ageStatus,
        "relationship": _relationship,
        "marital_status": _maritalStatus,
        "created_by": "System Admin", 
        "active_status": _activeStatus,
        "end_date": _endDate != null ? "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}" : "",
      };

      bool success = await ApiService.addDirector(directorData);
      setState(() => _isLoading = false);

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลกรรมการเรียบร้อยแล้ว'), backgroundColor: Colors.green));
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มข้อมูลบุคคลเกี่ยวโยง'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'ชื่อ (ไม่ต้องใส่คำนำหน้า)', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อ' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'นามสกุล', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'กรุณากรอกนามสกุล' : null),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                title: Text(_selectedDate == null ? 'คลิกเพื่อเลือกวันเกิด' : 'วันเกิด: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                subtitle: Text('สถานะ: $_ageStatus', style: TextStyle(color: _selectedDate == null ? Colors.red : Colors.green)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              
              // --- ส่วนที่เพิ่มใหม่: เลือกสถานะ และ วันที่พ้นสภาพ ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: Colors.blue.shade200), borderRadius: BorderRadius.circular(8), color: Colors.blue.shade50),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _activeStatus,
                      decoration: const InputDecoration(labelText: 'สถานะปัจจุบัน', border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
                      items: ['ยังเกี่ยวข้อง', 'พ้นสภาพ'].map((String v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (v) => setState(() {
                        _activeStatus = v!;
                        if (_activeStatus == 'ยังเกี่ยวข้อง') _endDate = null; // ล้างค่าวันที่ถ้ากลับมา Active
                      }),
                    ),
                    if (_activeStatus == 'พ้นสภาพ') ...[
                      const SizedBox(height: 12),
                      ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                        title: Text(_endDate == null ? 'ระบุวันที่พ้นสภาพ' : 'วันที่พ้นสภาพ: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                        trailing: const Icon(Icons.date_range, color: Colors.red),
                        onTap: () => _selectEndDate(context),
                      ),
                    ]
                  ],
                ),
              ),
              // -------------------------------------------------

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(initialValue: _relationship, decoration: const InputDecoration(labelText: 'ความสัมพันธ์ (RPT)', border: OutlineInputBorder()), items: ['กรรมการบริษัท', 'ผู้ถือหุ้นใหญ่', 'ผู้บริหารระดับสูง', 'เครือญาติ'].map((String v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _relationship = v!)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(initialValue: _maritalStatus, decoration: const InputDecoration(labelText: 'สถานะครอบครัว', border: OutlineInputBorder()), items: ['โสด', 'สมรส', 'หย่าร้าง'].map((String v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _maritalStatus = v!)),
              const SizedBox(height: 24),
              ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)), onPressed: _isLoading ? null : _saveData, icon: _isLoading ? const SizedBox() : const Icon(Icons.save), label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('บันทึกข้อมูล', style: TextStyle(fontSize: 16))),
            ],
          ),
        ),
      ),
    );
  }
}