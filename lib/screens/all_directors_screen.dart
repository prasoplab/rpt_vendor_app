import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class AllDirectorsScreen extends StatefulWidget {
  final String userName;
  const AllDirectorsScreen({super.key, required this.userName});

  @override
  State<AllDirectorsScreen> createState() => _AllDirectorsScreenState();
}

class _AllDirectorsScreenState extends State<AllDirectorsScreen> {
  List<Map<String, dynamic>> _allDirectors = [];
  List<Map<String, dynamic>> _filteredDirectors = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await ApiService.getAllDirectors();
    if (mounted) setState(() { _allDirectors = data; _filteredDirectors = data; _isLoading = false; });
  }

  void _filterSearch(String query) {
    setState(() {
      if (query.isEmpty) { _filteredDirectors = _allDirectors; } 
      else {
        _filteredDirectors = _allDirectors.where((dir) {
          return "${dir['first_name']} ${dir['last_name']}".toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ฐานข้อมูลบุคคลเกี่ยวโยง', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue.shade900,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl, 
              onChanged: _filterSearch,
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อ-นามสกุล...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _filteredDirectors.isEmpty 
                    ? const Center(child: Text('ไม่พบข้อมูลกรรมการ', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _filteredDirectors.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5, indent: 56), 
                        itemBuilder: (context, index) => _buildCompactListTile(_filteredDirectors[index]),
                      ),
          ),
        ],
      ),
    );
  }

  // 🌟 วิดเจ็ตรายการสไตล์มินิมอล (แก้บั๊กเส้นแดงเรียบร้อย)
  Widget _buildCompactListTile(Map<String, dynamic> dir) {
    bool isActive = (dir['active_status'] == 'ยังเกี่ยวข้อง' || dir['active_status'] == '');
    String fullName = '${dir['first_name']} ${dir['last_name']}';
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isActive ? Colors.green.shade50 : Colors.red.shade50,
        child: Icon(
          isActive ? Icons.person_outline_rounded : Icons.person_off_outlined, // 🌟 แก้ชื่อไอคอนแล้ว
          size: 18, 
          color: isActive ? Colors.green.shade700 : Colors.red.shade700
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              fullName, 
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.w600, 
                color: isActive ? Colors.black87 : Colors.grey.shade500,
                decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough
              ),
            ),
          ),
          if (!isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
              child: Text(
                'พ้นสภาพ ${dir['end_date']}', 
                style: TextStyle(fontSize: 10, color: Colors.red.shade800, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2.0), // 🌟 แก้ไขการพิมพ์ Padding แล้ว
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${dir['relationship']}  •  วันเกิด: ${dir['dob']} (${dir['age_status']})',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              'ID: ${dir['director_id']}  •  ครอบครัว: ${dir['marital_status']}  •  โดย: ${dir['created_by'] ?? '-'}',
              style: TextStyle(fontSize: 10, color: Colors.black38),
            ),
          ],
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined, size: 18),
        color: Colors.grey.shade400,
        onPressed: () => _showEditDialog(dir), // 🌟 เปลี่ยน onTap เป็น onPressed แล้ว
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> dir) {
    final formKey = GlobalKey<FormState>();
    final firstNameCtrl = TextEditingController(text: dir['first_name']);
    final lastNameCtrl = TextEditingController(text: dir['last_name']);
    String relationship = dir['relationship'] ?? 'กรรมการบริษัท';
    String maritalStatus = dir['marital_status'] ?? 'โสด';
    String activeStatus = dir['active_status'] ?? 'ยังเกี่ยวข้อง';
    String endDateStr = dir['end_date'] ?? '';
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('แก้ไขข้อมูลกรรมการ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: firstNameCtrl, decoration: const InputDecoration(labelText: 'ชื่อ'), style: const TextStyle(fontSize: 14)),
                  TextFormField(controller: lastNameCtrl, decoration: const InputDecoration(labelText: 'นามสกุล'), style: const TextStyle(fontSize: 14)),
                  DropdownButtonFormField<String>(
                    value: activeStatus, 
                    items: ['ยังเกี่ยวข้อง', 'พ้นสภาพ'].map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 14)))).toList(), 
                    onChanged: (v) => setDialogState(() => activeStatus = v!), 
                    decoration: const InputDecoration(labelText: 'สถานะ')
                  ),
                  if (activeStatus == 'พ้นสภาพ') 
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(endDateStr.isEmpty ? 'เลือกวันที่พ้นสภาพ' : 'วันที่พ้นสภาพ: $endDateStr', style: const TextStyle(fontSize: 13)), 
                      trailing: const Icon(Icons.calendar_today, size: 16),
                      onTap: () async { 
                        final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); 
                        if (p != null) setDialogState(() => endDateStr = "${p.day}/${p.month}/${p.year}"); 
                      }
                    ),
                  DropdownButtonFormField<String>(
                    value: relationship, 
                    items: ['กรรมการบริษัท', 'ผู้ถือหุ้นใหญ่', 'ผู้บริหารระดับสูง', 'เครือญาติ'].map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 14)))).toList(), 
                    onChanged: (v) => setDialogState(() => relationship = v!), 
                    decoration: const InputDecoration(labelText: 'ความสัมพันธ์')
                  ),
                  DropdownButtonFormField<String>(
                    value: maritalStatus, 
                    items: ['โสด', 'สมรส', 'หย่าร้าง'].map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 14)))).toList(), 
                    onChanged: (v) => setDialogState(() => maritalStatus = v!), 
                    decoration: const InputDecoration(labelText: 'สถานะครอบครัว')
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900, foregroundColor: Colors.white),
              onPressed: isSaving ? null : () async {
                setDialogState(() => isSaving = true);
                bool success = await ApiService.editDirector({
                  "director_id": dir['director_id'], "first_name": firstNameCtrl.text.trim(), "last_name": lastNameCtrl.text.trim(),
                  "relationship": relationship, "marital_status": maritalStatus, "active_status": activeStatus, "end_date": endDateStr, "edited_by": widget.userName
                });
                if (success) { Navigator.pop(context); _fetchData(); }
                else { setDialogState(() => isSaving = false); }
              }, 
              child: isSaving 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('บันทึก')
            ),
          ],
        ),
      ),
    );
  }
}