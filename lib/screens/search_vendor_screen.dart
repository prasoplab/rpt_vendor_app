import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rpt_vendor_app/models/rpt_models.dart';
import 'package:rpt_vendor_app/screens/evaluation_screen.dart';

class SearchVendorScreen extends StatefulWidget {
  final String userName;
  final SupplierEvaluation? initialEvalData;
  final List<DirectorMatch>? initialDirectors;

  const SearchVendorScreen({
    super.key,
    required this.userName,
    this.initialEvalData,
    this.initialDirectors,
  });

  @override
  State<SearchVendorScreen> createState() => _SearchVendorScreenState();
}

class _SearchVendorScreenState extends State<SearchVendorScreen> {
  final _formKey = GlobalKey<FormState>();

  // 🌟 Controllers ข้อมูลพื้นฐานซัพพลายเออร์ (ดึงกลับมาครบถ้วนแล้วครับ)
  final TextEditingController _vendorNameCtrl = TextEditingController();
  final TextEditingController _productTypeCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _contactPersonCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  final TextEditingController _directorNameCtrl = TextEditingController();

  List<DirectorMatch> _directorList = [];
  bool _isCheckingInline = false; // ตัวแปรคุมโหลดดิ้งตอนกดเพิ่มชื่อกรรมการ

  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลเก่ามาแสดงกรณีที่เป็นโหมดแก้ไขจากหน้าประวัติ
    if (widget.initialEvalData != null) {
      _vendorNameCtrl.text = widget.initialEvalData!.vendorName;
      _productTypeCtrl.text = widget.initialEvalData!.productType;
      _addressCtrl.text = widget.initialEvalData!.address;
      _contactPersonCtrl.text = widget.initialEvalData!.contactPerson;
      _phoneCtrl.text = widget.initialEvalData!.phone;
    }
    if (widget.initialDirectors != null) {
      _directorList = List.from(widget.initialDirectors!);
    }
  }

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

  // ========================================================
  // 🚀 เพิ่มชื่อกรรมการปุ๊บ วิ่งไปสแกนตรวจสอบ RPT ทันที (แสดงผลเรียลไทม์)
  // ========================================================
  Future<void> _addDirectorAndCheck() async {
    final name = _directorNameCtrl.text.trim();
    if (name.isEmpty) return;

    if (_directorList.any((d) => d.name.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ รายชื่อกรรมการนี้มีอยู่แล้วในรายการ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCheckingInline = true);
    _directorNameCtrl.clear(); // ล้างช่องพิมพ์รอไว้เลย

    const String scriptUrl =
        'https://script.google.com/macros/s/AKfycbw9U7rcS469vPjpHujj8ih9_mKcK4yZhQEDejK_T7z0teB69EeX5QjkZ7elleN-QW5u/exec';

    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        body: {"action": "check_director", "directorName": name},
      );

      DirectorMatch checkedDirector;

      if (response.statusCode == 200 || response.statusCode == 302) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' && result['isMatch'] == true) {
          checkedDirector = DirectorMatch(
            name: name,
            isMatch: true,
            relation: result['relation'] ?? 'พบประวัติเกี่ยวโยง',
          );
        } else {
          checkedDirector = DirectorMatch(
            name: name,
            isMatch: false,
            relation: 'ไม่พบรายการที่เกี่ยวข้อง',
          );
        }
      } else {
        checkedDirector = DirectorMatch(
          name: name,
          isMatch: false,
          relation: 'ระบบตรวจสอบขัดข้อง',
        );
      }

      setState(() {
        _directorList.add(checkedDirector);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isCheckingInline = false);
    }
  }

  void _removeDirector(int index) {
    setState(() {
      _directorList.removeAt(index);
    });
  }

  void _navigateToEvaluation() {
    if (!_formKey.currentState!.validate()) return;
    if (_directorList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ กรุณาระบุรายชื่อกรรมการอย่างน้อย 1 ท่าน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ประมวลผลภาพรวม RPT จากลิสต์ที่เราเช็คเรียลไทม์ไว้แล้ว
    bool anyMatch = _directorList.any((d) => d.isMatch == true);

    SupplierEvaluation passData =
        widget.initialEvalData ?? SupplierEvaluation();
    passData.vendorName = _vendorNameCtrl.text.trim();
    passData.productType = _productTypeCtrl.text.trim();
    passData.address = _addressCtrl.text.trim();
    passData.contactPerson = _contactPersonCtrl.text.trim();
    passData.phone = _phoneCtrl.text.trim();
    passData.rptStatus = anyMatch ? 'MATCH' : 'CLEAR';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvaluationScreen(
          userName: widget.userName,
          initialEvalData: passData,
          rptResults: _directorList,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.initialEvalData != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          isEditMode
              ? 'แก้ไขข้อมูลและตรวจสอบ RPT'
              : 'ตรวจสอบบุคคลเกี่ยวโยง (RPT)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 🌟 ส่วนที่ 1: ข้อมูลซัพพลายเออร์ (ดึงกลับมาครบถ้วนทุกช่องแล้วครับ)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.business_rounded,
                          color: Colors.blue.shade900,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ข้อมูลซัพพลายเออร์พื้นฐาน',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    TextFormField(
                      controller: _vendorNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อร้านค้า / บริษัทซัพพลายเออร์ *',
                        prefixIcon: Icon(Icons.store_rounded),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'กรุณากรอกชื่อซัพพลายเออร์' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _productTypeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ประเภทสินค้า / บริการ *',
                        prefixIcon: Icon(Icons.category_rounded),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'กรุณากรอกประเภทสินค้า' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'ที่อยู่สถานประกอบการ *',
                        prefixIcon: Icon(Icons.location_on_rounded),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => v!.isEmpty ? 'กรุณากรอกที่อยู่' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _contactPersonCtrl,
                            decoration: const InputDecoration(
                              labelText: 'ชื่อผู้ติดต่อ',
                              prefixIcon: Icon(Icons.person_rounded),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'เบอร์โทรศัพท์ติดต่อ',
                              prefixIcon: Icon(Icons.phone_rounded),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ส่วนที่ 2: จัดการรายชื่อคณะกรรมการ และแสดงผลลัพธ์ RPT ทันที
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          color: Colors.blue.shade900,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'รายชื่อคณะกรรมการบริษัท (ตรวจสอบ RPT อัตโนมัติ)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _directorNameCtrl,
                            enabled: !_isCheckingInline,
                            decoration: InputDecoration(
                              labelText: _isCheckingInline
                                  ? 'กำลังสแกนฐานข้อมูล...'
                                  : 'เพิ่มชื่อ-นามสกุลกรรมการ',
                              prefixIcon: const Icon(
                                Icons.person_add_alt_1_rounded,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            onFieldSubmitted: (_) => _isCheckingInline
                                ? null
                                : _addDirectorAndCheck(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade900,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(60, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isCheckingInline
                              ? null
                              : _addDirectorAndCheck,
                          child: _isCheckingInline
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ผลการตรวจสอบประวัติกรรมการแยกรายบุคคล:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_directorList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'ยังไม่มีรายชื่อกรรมการในรายการ\n(ระบบจะสแกน RPT ทันทีเมื่อพิมพ์เพิ่มชื่อ)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _directorList.length,
                        itemBuilder: (context, index) {
                          final isMatch = _directorList[index].isMatch;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isMatch
                                  ? Colors.orange.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isMatch
                                    ? Colors.orange.shade200
                                    : Colors.green.shade200,
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(
                                isMatch
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_outline_rounded,
                                color: isMatch
                                    ? Colors.orange.shade800
                                    : Colors.green.shade800,
                              ),
                              title: Text(
                                _directorList[index].name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // 🌟 แสดงผลความเกี่ยวโยง RPT ใต้ชื่อกรรมการทันที!
                              subtitle: Text(
                                'ผลเช็ค: ${_directorList[index].relation}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isMatch
                                      ? Colors.orange.shade900
                                      : Colors.green.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeDirector(index),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ปุ่มไปขั้นตอนถัดไป
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isCheckingInline ? null : _navigateToEvaluation,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                isEditMode
                    ? 'ไปหน้าแก้ไขคะแนนประเมิน'
                    : 'ไปขั้นตอนถัดไป (ให้คะแนนประเมิน)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
