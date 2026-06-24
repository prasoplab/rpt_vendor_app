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
  
  // ข้อมูลนิติบุคคล
  final List<String> _prefixOptions = ['บจ.', 'บมจ.', 'หจก.', 'หสม.', 'นาย', 'นาง', 'นางสาว', 'อื่นๆ'];
  String _vendorPrefix = 'บจ.';
  final TextEditingController _vendorNameCtrl = TextEditingController();
  
  // สถานะการตรวจสอบบริษัท
  bool _isCheckingCompany = false;
  bool? _isCompanyRptMatch;
  String _companyRptRelation = '';

  // ข้อมูลพื้นฐานและกรรมการ
  final TextEditingController _productTypeCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _contactPersonCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _directorNameCtrl = TextEditingController();
  
  List<DirectorMatch> _directorList = [];
  
  // 🌟 ตัวแปรเก็บรายชื่อกรรมการที่ถูกล็อก (ห้ามลบเด็ดขาด)
  final Set<String> _lockedDirectorNames = {}; 
  bool _isCheckingInline = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEvalData != null) {
      _extractVendorName(widget.initialEvalData!.vendorName);
      _productTypeCtrl.text = widget.initialEvalData!.productType;
      _addressCtrl.text = widget.initialEvalData!.address;
      _contactPersonCtrl.text = widget.initialEvalData!.contactPerson;
      _phoneCtrl.text = widget.initialEvalData!.phone;
    }
    if (widget.initialDirectors != null) {
      _directorList = List.from(widget.initialDirectors!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialEvalData != null && _vendorNameCtrl.text.isNotEmpty) {
        _checkCompanyRpt();
      }
    });
  }

  void _extractVendorName(String fullName) {
    bool found = false;
    for (var p in _prefixOptions) {
      if (fullName.startsWith(p)) {
        _vendorPrefix = p;
        _vendorNameCtrl.text = fullName.substring(p.length).trim();
        found = true;
        break;
      }
    }
    if (!found) {
      _vendorPrefix = 'อื่นๆ';
      _vendorNameCtrl.text = fullName;
    }
  }

  String get fullVendorName {
    if (_vendorPrefix == 'อื่นๆ') return _vendorNameCtrl.text.trim();
    return '$_vendorPrefix ${_vendorNameCtrl.text.trim()}'.trim();
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
  // 🚀 ฟังก์ชันตรวจสอบนิติบุคคล + ดึงรายชื่อผู้เกี่ยวข้องมาล็อกห้ามลบ
  // ========================================================
  Future<void> _checkCompanyRpt() async {
    final name = fullVendorName;
    if (_vendorNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ กรุณากรอกชื่อบริษัทก่อนตรวจสอบ'), backgroundColor: Colors.orange));
      return;
    }

    setState(() {
      _isCheckingCompany = true;
      _lockedDirectorNames.clear(); // ล้างตัวล็อกเก่า
    });

    const String scriptUrl = 'https://script.google.com/macros/s/AKfycbwbUCONxZIid3zPKlPMvQ1BYPDaPeozB-P8HlapH7dgZd-KisapfWlglUFmkuwnvBKy/exec';

    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        body: {"action": "check_director", "directorName": name}, 
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        final result = jsonDecode(response.body);
        setState(() {
          if (result['status'] == 'success' && result['isMatch'] == true) {
            _isCompanyRptMatch = true;
            _companyRptRelation = result['relation'] ?? 'พบประวัติเกี่ยวโยง';
            
            // 🌟 1. ดึงข้อมูลรายชื่อผู้เกี่ยวข้องที่พ่วงมากับนิติบุคคลนี้มาแสดงรอ
            if (result['relatedDirectors'] != null) {
              List<dynamic> related = result['relatedDirectors'];
              for (var dName in related) {
                String cleanName = dName.toString().trim();
                if (cleanName.isNotEmpty) {
                  // เพิ่มเข้าลิสต์ตรวจสอบกรรมการ
                  if (!_directorList.any((element) => element.name.toLowerCase() == cleanName.toLowerCase())) {
                    _directorList.add(DirectorMatch(
                      name: cleanName,
                      isMatch: true,
                      relation: 'เกี่ยวโยงโดยตรงกับ $name (${result['relation']})',
                    ));
                  }
                  // 🔒 ส่งชื่อเข้าบัญชีดำห้ามลบในหน้าแอป
                  _lockedDirectorNames.add(cleanName);
                }
              }
            }
          } else {
            _isCompanyRptMatch = false;
            _companyRptRelation = 'ไม่พบรายการที่เกี่ยวข้อง';
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ เชื่อมต่อผิดพลาด: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isCheckingCompany = false);
    }
  }

  // ========================================================
  // 🚀 ฟังก์ชันเพิ่มกรรมการเพิ่มเติมตามหนังสือรับรอง (เช็คเรียลไทม์)
  // ========================================================
  Future<void> _addDirectorAndCheck() async {
    final name = _directorNameCtrl.text.trim();
    if (name.isEmpty) return;

    if (_directorList.any((d) => d.name.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ มีรายชื่อนี้อยู่แล้วในรายการ'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isCheckingInline = true);
    _directorNameCtrl.clear(); 

    const String scriptUrl = 'https://script.google.com/macros/s/AKfycbwbUCONxZIid3zPKlPMvQ1BYPDaPeozB-P8HlapH7dgZd-KisapfWlglUFmkuwnvBKy/exec';

    try {
      final response = await http.post(Uri.parse(scriptUrl), body: {"action": "check_director", "directorName": name});
      DirectorMatch checkedDirector;

      if (response.statusCode == 200 || response.statusCode == 302) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' && result['isMatch'] == true) {
          checkedDirector = DirectorMatch(name: name, isMatch: true, relation: result['relation'] ?? 'พบประวัติเกี่ยวโยง');
        } else {
          checkedDirector = DirectorMatch(name: name, isMatch: false, relation: 'ไม่พบรายการที่เกี่ยวข้อง');
        }
      } else {
        checkedDirector = DirectorMatch(name: name, isMatch: false, relation: 'ระบบตรวจสอบขัดข้อง');
      }
      setState(() => _directorList.add(checkedDirector));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isCheckingInline = false);
    }
  }

  void _removeDirector(int index) => setState(() => _directorList.removeAt(index));

  void _navigateToEvaluation() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isCompanyRptMatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔒 กรุณากดตรวจสอบ RPT นิติบุคคลก่อนดำเนินการต่อ'), backgroundColor: Colors.red));
      return;
    }

    if (_directorList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ กรุณาระบุรายชื่อกรรมการอย่างน้อย 1 ท่าน'), backgroundColor: Colors.orange));
      return;
    }

    bool anyMatch = (_isCompanyRptMatch == true) || _directorList.any((d) => d.isMatch == true);

    SupplierEvaluation passData = widget.initialEvalData ?? SupplierEvaluation();
    passData.vendorName = fullVendorName;
    passData.productType = _productTypeCtrl.text.trim();
    passData.address = _addressCtrl.text.trim();
    passData.contactPerson = _contactPersonCtrl.text.trim();
    passData.phone = _phoneCtrl.text.trim();
    passData.rptStatus = anyMatch ? 'MATCH' : 'CLEAR';

    Navigator.push(context, MaterialPageRoute(builder: (context) => EvaluationScreen(userName: widget.userName, initialEvalData: passData, rptResults: _directorList)));
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.initialEvalData != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(isEditMode ? 'แก้ไขข้อมูลและตรวจสอบ RPT' : 'ตรวจสอบบุคคลเกี่ยวโยง (RPT)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900, foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ==========================================
            // STEP 1: ข้อมูลนิติบุคคล และปุ่มตรวจสอบ
            // ==========================================
            Card(
              elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business_rounded, color: Colors.blue.shade900), const SizedBox(width: 8),
                        Text('STEP 1: ตรวจสอบสถานะนิติบุคคล', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _vendorPrefix,
                            decoration: const InputDecoration(labelText: 'สถานะ', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                            items: _prefixOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (val) {
                              setState(() { _vendorPrefix = val!; _isCompanyRptMatch = null; _directorList.clear(); }); 
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 5,
                          child: TextFormField(
                            controller: _vendorNameCtrl,
                            decoration: const InputDecoration(labelText: 'ชื่อบริษัท (ไม่ต้องใส่คำนำหน้า) *', border: OutlineInputBorder(), isDense: true),
                            onChanged: (v) => setState(() { _isCompanyRptMatch = null; _directorList.clear(); }), 
                            validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อ' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, height: 45,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: _isCheckingCompany ? null : _checkCompanyRpt,
                        icon: _isCheckingCompany ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.search_rounded, size: 20),
                        label: Text(_isCheckingCompany ? 'กำลังค้นหาในฐานข้อมูล...' : 'ตรวจสอบ RPT นิติบุคคลนี้', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (_isCompanyRptMatch != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16), padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _isCompanyRptMatch! ? Colors.red.shade50 : Colors.green.shade50, border: Border.all(color: _isCompanyRptMatch! ? Colors.red.shade300 : Colors.green.shade300), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(_isCompanyRptMatch! ? Icons.warning_rounded : Icons.check_circle_rounded, color: _isCompanyRptMatch! ? Colors.red.shade800 : Colors.green.shade800, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_isCompanyRptMatch! ? 'แจ้งเตือน: นิติบุคคลนี้ติด RPT!' : 'นิติบุคคลนี้ สถานะปกติ (ไม่ติด RPT)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _isCompanyRptMatch! ? Colors.red.shade900 : Colors.green.shade900)),
                                  Text(_isCompanyRptMatch! ? 'ผลตรวจ: $_companyRptRelation\n(รายชื่อผู้เกี่ยวข้องหลักถูกดึงลงตารางด้านล่างแล้ว)' : 'ผลตรวจ: ไม่พบประวัติความเกี่ยวโยงของนิติบุคคลนี้ในระบบ', style: TextStyle(fontSize: 12, color: _isCompanyRptMatch! ? Colors.red.shade800 : Colors.green.shade800)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ==========================================
            // STEP 2: รายชื่อกรรมการ (เพิ่มเงื่อนไขล็อกปุ่มลบ)
            // ==========================================
            Card(
              elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people_alt_rounded, color: _isCompanyRptMatch == null ? Colors.grey : Colors.blue.shade900), const SizedBox(width: 8),
                        Text('STEP 2: ตรวจสอบกรรมการรายบุคคล', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _isCompanyRptMatch == null ? Colors.grey : Colors.blue.shade900)),
                      ],
                    ),
                    const Divider(height: 24),
                    if (_isCompanyRptMatch == null)
                      Container(
                        padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                        child: const Center(
                          child: Text('🔒 กรุณากดปุ่ม "ตรวจสอบ RPT นิติบุคคลนี้" ใน STEP 1 ให้เสร็จสิ้นก่อน จึงจะสามารถเพิ่มรายชื่อกรรมการได้', textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _directorNameCtrl, enabled: !_isCheckingInline,
                              decoration: InputDecoration(labelText: _isCheckingInline ? 'กำลังสแกนประวัติ...' : 'เพิ่มชื่อ-นามสกุลกรรมการตามหนังสือรับรอง', prefixIcon: const Icon(Icons.person_add_alt_1_rounded), border: const OutlineInputBorder(), isDense: true),
                              onFieldSubmitted: (_) => _isCheckingInline ? null : _addDirectorAndCheck(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900, foregroundColor: Colors.white, minimumSize: const Size(55, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            onPressed: _isCheckingInline ? null : _addDirectorAndCheck,
                            child: _isCheckingInline ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_directorList.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _directorList.length,
                          itemBuilder: (context, index) {
                            final isMatch = _directorList[index].isMatch;
                            // 🌟 ตรวจสอบว่าชื่อกรรมการท่านนี้เป็นคนที่ดึงมาออโต้และโดนล็อกไว้หรือไม่
                            final isLocked = _lockedDirectorNames.contains(_directorList[index].name);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(color: isMatch ? Colors.orange.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: isMatch ? Colors.orange.shade200 : Colors.green.shade200)),
                              child: ListTile(
                                leading: Icon(isMatch ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, color: isMatch ? Colors.orange.shade800 : Colors.green.shade800),
                                title: Row(
                                  children: [
                                    Text(_directorList[index].name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    if (isLocked) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.lock_outline_rounded, size: 14, color: Colors.black54), // โชว์กุญแจบอกสถานะล็อก
                                    ]
                                  ],
                                ),
                                subtitle: Text('ผลเช็ค: ${_directorList[index].relation}', style: TextStyle(fontSize: 12, color: isMatch ? Colors.orange.shade900 : Colors.green.shade900, fontWeight: FontWeight.w500)),
                                // 🌟 ถ้าโดนล็อก จะเอาปุ่มถังขยะออกทันที ป้องกันการแอบกดลบข้อมูลทุจริต
                                trailing: isLocked 
                                  ? const Tooltip(message: 'รายชื่อถูกล็อกโดยระบบ ห้ามลบเด็ดขาด', child: Icon(Icons.lock_rounded, color: Colors.black38))
                                  : IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.red), onPressed: () => _removeDirector(index)),
                              ),
                            );
                          },
                        ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // STEP 3: ข้อมูลอื่นๆ สำหรับประเมิน
            Card(
              elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.blue.shade900), const SizedBox(width: 8),
                        Text('STEP 3: ข้อมูลติดต่อสำหรับใบประเมิน', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                      ],
                    ),
                    const Divider(height: 24),
                    TextFormField(controller: _productTypeCtrl, decoration: const InputDecoration(labelText: 'ประเภทสินค้า / บริการ *', prefixIcon: Icon(Icons.category_rounded), border: OutlineInputBorder(), isDense: true), validator: (v) => v!.isEmpty ? 'กรุณากรอกประเภทสินค้า' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _addressCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'ที่อยู่สถานประกอบการ *', prefixIcon: Icon(Icons.location_on_rounded), border: OutlineInputBorder(), isDense: true), validator: (v) => v!.isEmpty ? 'กรุณากรอกที่อยู่' : null),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _contactPersonCtrl, decoration: const InputDecoration(labelText: 'ชื่อผู้ติดต่อ', prefixIcon: Icon(Icons.person_rounded), border: OutlineInputBorder(), isDense: true))),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'เบอร์โทรศัพท์', prefixIcon: Icon(Icons.phone_rounded), border: OutlineInputBorder(), isDense: true))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ปุ่มไปขั้นตอนถัดไป
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: _isCheckingInline ? null : _navigateToEvaluation,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(isEditMode ? 'ไปหน้าแก้ไขคะแนนประเมิน' : 'ไปขั้นตอนถัดไป (ให้คะแนนประเมิน)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}