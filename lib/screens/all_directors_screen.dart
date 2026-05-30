import 'package:flutter/material.dart';
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
    if (query.isEmpty) { setState(() => _filteredDirectors = _allDirectors); return; }
    setState(() {
      _filteredDirectors = _allDirectors.where((dir) {
        return "${dir['first_name']} ${dir['last_name']}".toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _showEditDialog(Map<String, dynamic> dir) {
    final formKey = GlobalKey<FormState>();
    final firstNameCtrl = TextEditingController(text: dir['first_name']);
    final lastNameCtrl = TextEditingController(text: dir['last_name']);
    
    String relationship = dir['relationship']?.toString().trim() ?? 'กรรมการบริษัท';
    String maritalStatus = dir['marital_status']?.toString().trim() ?? 'โสด';
    String activeStatus = dir['active_status']?.toString().trim() ?? 'ยังเกี่ยวข้อง';
    String endDateStr = dir['end_date']?.toString().trim() ?? '';

    List<String> relItems = ['กรรมการบริษัท', 'ผู้ถือหุ้นใหญ่', 'ผู้บริหารระดับสูง', 'เครือญาติ'];
    List<String> marItems = ['โสด', 'สมรส', 'หย่าร้าง'];
    List<String> activeItems = ['ยังเกี่ยวข้อง', 'พ้นสภาพ'];

    if (!relItems.contains(relationship)) { relationship.isEmpty || relationship == 'กรรมการ' ? relationship = 'กรรมการบริษัท' : relItems.add(relationship); }
    if (!marItems.contains(maritalStatus)) { maritalStatus.isEmpty ? maritalStatus = 'โสด' : marItems.add(maritalStatus); }
    if (!activeItems.contains(activeStatus)) { activeStatus.isEmpty ? activeStatus = 'ยังเกี่ยวข้อง' : activeItems.add(activeStatus); }

    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('แก้ไขข้อมูลกรรมการ'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(controller: firstNameCtrl, decoration: const InputDecoration(labelText: 'ชื่อ', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'กรอกชื่อ' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: lastNameCtrl, decoration: const InputDecoration(labelText: 'นามสกุล', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'กรอกนามสกุล' : null),
                    const SizedBox(height: 12),
                    
                    // --- Dropdown สถานะ ---
                    DropdownButtonFormField<String>(
                      initialValue: activeStatus,
                      decoration: const InputDecoration(labelText: 'สถานะปัจจุบัน', border: OutlineInputBorder()),
                      items: activeItems.map((v) => DropdownMenuItem(value: v, child: Text(v, style: TextStyle(color: v == 'พ้นสภาพ' ? Colors.red : Colors.green)))).toList(),
                      onChanged: (v) => setDialogState(() {
                        activeStatus = v!;
                        if (activeStatus == 'ยังเกี่ยวข้อง') endDateStr = ''; 
                      }),
                    ),
                    if (activeStatus == 'พ้นสภาพ') ...[
                      const SizedBox(height: 8),
                      ListTile(
                        shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                        title: Text(endDateStr.isEmpty ? 'คลิกเพื่อเลือกวันที่พ้นสภาพ' : 'พ้นสภาพ: $endDateStr', style: const TextStyle(fontSize: 14)),
                        trailing: const Icon(Icons.date_range, color: Colors.red),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (picked != null) setDialogState(() => endDateStr = "${picked.day}/${picked.month}/${picked.year}");
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    // ------------------------

                    DropdownButtonFormField<String>(initialValue: relationship, decoration: const InputDecoration(labelText: 'ความสัมพันธ์', border: OutlineInputBorder()), items: relItems.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setDialogState(() => relationship = v!)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(initialValue: maritalStatus, decoration: const InputDecoration(labelText: 'สถานะครอบครัว', border: OutlineInputBorder()), items: marItems.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setDialogState(() => maritalStatus = v!)),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('ยกเลิก')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900, foregroundColor: Colors.white),
                onPressed: isSaving ? null : () async {
                  if (formKey.currentState!.validate()) {
                    if (activeStatus == 'พ้นสภาพ' && endDateStr.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาระบุวันที่พ้นสภาพ'))); return;
                    }
                    setDialogState(() => isSaving = true);
                    bool success = await ApiService.editDirector({
                      "director_id": dir['director_id'], "first_name": firstNameCtrl.text.trim(), "last_name": lastNameCtrl.text.trim(),
                      "dob": dir['dob']?.toString() ?? '', "age_status": dir['age_status']?.toString() ?? '', 
                      "relationship": relationship, "marital_status": maritalStatus, "edited_by": widget.userName,
                      "active_status": activeStatus, "end_date": endDateStr
                    });
                    setDialogState(() => isSaving = false);
                    if (success) {
                      Navigator.pop(context); _fetchData();
                      ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('อัปเดตข้อมูลสำเร็จ'), backgroundColor: Colors.green));
                    }
                  }
                },
                child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('บันทึก'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ฐานข้อมูลบุคคลเกี่ยวโยงทั้งหมด'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchCtrl, onChanged: _filterSearch,
              decoration: InputDecoration(hintText: 'ค้นหาชื่อ-นามสกุล...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)), contentPadding: const EdgeInsets.symmetric(horizontal: 20)),
            ),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator()) : _filteredDirectors.isEmpty ? const Center(child: Text('ไม่พบข้อมูลกรรมการ'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _filteredDirectors.length,
                  itemBuilder: (context, index) {
                    var dir = _filteredDirectors[index];
                    bool isActive = (dir['active_status'] == 'ยังเกี่ยวข้อง' || dir['active_status'] == '');
                    
                    return Card(
                      elevation: 2, margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive ? Colors.blue.shade900 : Colors.grey,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text('${dir['first_name']} ${dir['last_name']}', style: TextStyle(fontWeight: FontWeight.bold, decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough))),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ตำแหน่ง: ${dir['relationship']} | รหัส: ${dir['director_id']}'),
                            const SizedBox(height: 4),
                            // แสดงป้ายสถานะ
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: isActive ? Colors.green.shade100 : Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                              child: Text(isActive ? 'ยังเกี่ยวข้อง' : 'พ้นสภาพ (${dir['end_date']})', style: TextStyle(fontSize: 12, color: isActive ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                        isThreeLine: true,
                        trailing: IconButton(icon: const Icon(Icons.edit_document, color: Colors.blue), onPressed: () => _showEditDialog(dir)),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}