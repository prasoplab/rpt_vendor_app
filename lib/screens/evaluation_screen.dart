import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rpt_vendor_app/models/rpt_models.dart';
import 'package:rpt_vendor_app/screens/result_screen.dart';

class EvaluationScreen extends StatefulWidget {
  final String userName;
  final String vendorName;
  final List<DirectorMatch> searchResults;

  const EvaluationScreen({
    super.key,
    required this.userName,
    required this.vendorName,
    required this.searchResults,
  });

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  final SupplierEvaluation _evalData = SupplierEvaluation();
  bool _isSaving = false;

  final TextEditingController _commentSpecCtrl = TextEditingController();
  final TextEditingController _commentPaymentCtrl = TextEditingController();
  final TextEditingController _commentDeliveryCtrl = TextEditingController();
  final TextEditingController _commentServiceCtrl = TextEditingController();
  final TextEditingController _commentIso9001Ctrl = TextEditingController();
  final TextEditingController _commentIso14001Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _evalData.vendorName = widget.vendorName;
    
    _evalData.scoreSpec = 20;
    _evalData.scorePayment = 25;
    _evalData.scoreDelivery = 20;
    _evalData.scoreService = 15;
    _evalData.scoreIso9001 = 10;
    _evalData.scoreIso14001 = 10;

    bool hasRptMatch = widget.searchResults.any((element) => element.isMatch);
    _evalData.rptStatus = hasRptMatch ? 'MATCH' : 'CLEAR';
  }

  @override
  void dispose() {
    _commentSpecCtrl.dispose();
    _commentPaymentCtrl.dispose();
    _commentDeliveryCtrl.dispose();
    _commentServiceCtrl.dispose();
    _commentIso9001Ctrl.dispose();
    _commentIso14001Ctrl.dispose();
    super.dispose();
  }

  String _calculateApprovalRoute() {
    bool isRptMatch = _evalData.rptStatus == 'MATCH';
    int score = _evalData.totalScore;
    List<String> route = [];

    if (isRptMatch) {
      route.add("1. สำนักเลขานุการ (รับทราบ)");
    }

    if (score >= 70) {
      route.add("${route.length + 1}. ผู้จัดการแผนกจัดซื้อ (อนุมัติ)");
    } else {
      route.add("${route.length + 1}. ผู้จัดการแผนกจัดซื้อ (ตรวจสอบ)");
      route.add("${route.length + 1}. ประธานเจ้าหน้าที่สายงานบริหารงานทั่วไป (อนุมัติ)");
    }

    return route.join(" ➡️ ");
  }

  Future<void> _saveToGoogleSheetsAndContinue() async {
    _evalData.commentSpec = _commentSpecCtrl.text.isEmpty ? '-' : _commentSpecCtrl.text;
    _evalData.commentPayment = _commentPaymentCtrl.text.isEmpty ? '-' : _commentPaymentCtrl.text;
    _evalData.commentDelivery = _commentDeliveryCtrl.text.isEmpty ? '-' : _commentDeliveryCtrl.text;
    _evalData.commentService = _commentServiceCtrl.text.isEmpty ? '-' : _commentServiceCtrl.text;
    _evalData.commentIso9001 = _commentIso9001Ctrl.text.isEmpty ? '-' : _commentIso9001Ctrl.text;
    _evalData.commentIso14001 = _commentIso14001Ctrl.text.isEmpty ? '-' : _commentIso14001Ctrl.text;

    final String finalApprovalRoute = _calculateApprovalRoute();

    setState(() => _isSaving = true);

    try {
      const String webAppUrl = 'https://script.google.com/macros/s/AKfycbx6GvQzNAHR4wu30XHpNzWgatMhZWUwVxKDN912nZtDqjWbwSKd8tatImuf8tGCQni3/exec';

      final response = await http.post(
        Uri.parse(webAppUrl),
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode({
          'action': 'save_evaluation',
          'vendor_name': _evalData.vendorName,
          'product_type': _evalData.productType,
          'address': _evalData.address,
          'contact_person': _evalData.contactPerson,
          'phone': _evalData.phone,
          'score_spec': _evalData.scoreSpec,
          'score_payment': _evalData.scorePayment,
          'score_delivery': _evalData.scoreDelivery,
          'score_service': _evalData.scoreService,
          'score_iso9001': _evalData.scoreIso9001,
          'score_iso14001': _evalData.scoreIso14001,
          'rpt_status': _evalData.rptStatus,
          'evaluated_by': widget.userName,
          'comment_spec': _evalData.commentSpec,
          'comment_payment': _evalData.commentPayment,
          'comment_delivery': _evalData.commentDelivery,
          'comment_service': _evalData.commentService,
          'comment_iso9001': _evalData.commentIso9001,
          'comment_iso14001': _evalData.commentIso14001,
          'approval_route': finalApprovalRoute,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(
                userName: widget.userName,
                evalData: _evalData,
                searchResults: widget.searchResults,
              ),
            ),
          );
        }
      } else {
        _showError('บันทึกไม่สำเร็จ: ${response.statusCode}');
      }
    } catch (e) {
      _showError('ข้อผิดพลาดการเชื่อมต่อ: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('ประเมินศักยภาพคู่ค้า', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVendorHeader(),
                const SizedBox(height: 6),
                
                _buildRptStatusSection(), // แสดงเฉพาะสถานะตรวจจับ RPT โล่งๆ สบายตา
                const SizedBox(height: 8),
                
                _buildUltraCompactCard(
                  title: '1. Spec สินค้า ข้อกำหนดของผู้ขายสอดคล้องกับข้อกำหนดที่ต้องการหรือไม่',
                  currentVal: _evalData.scoreSpec,
                  commentCtrl: _commentSpecCtrl,
                  options: [
                    _EvaluationOption(label: 'ก. ตรงตามข้อกำหนดทุกประการ (20 คะแนน)', value: 20),
                    _EvaluationOption(label: 'ข. ไม่ตรงข้อกำหนด แต่ใช้งานได้ (15 คะแนน)', value: 15),
                    _EvaluationOption(label: 'ค. ให้ความมั่นใจว่าตอบสนองได้ (10 คะแนน)', value: 10),
                    _EvaluationOption(label: 'ง. ใช้ไม่ได้ (0 คะแนน)', value: 0),
                  ],
                  onChanged: (val) => setState(() => _evalData.scoreSpec = val),
                ),

                _buildUltraCompactCard(
                  title: '2. เงื่อนไขการชำระเงิน',
                  currentVal: _evalData.scorePayment,
                  commentCtrl: _commentPaymentCtrl,
                  options: [
                    _EvaluationOption(label: 'ก. ชำระเงินภายใน 90 วัน (25 คะแนน)', value: 25),
                    _EvaluationOption(label: 'ข. ชำระเงินภายใน 60 วัน (20 คะแนน)', value: 20),
                    _EvaluationOption(label: 'ค. ชำระเงินภายใน 30 วัน (15 คะแนน)', value: 15),
                    _EvaluationOption(label: 'ง. ชำระเงินทันที (10 คะแนน)', value: 10),
                  ],
                  onChanged: (val) => setState(() => _evalData.scorePayment = val),
                ),

                _buildUltraCompactCard(
                  title: '3. ระยะเวลาในการส่งมอบ',
                  currentVal: _evalData.scoreDelivery,
                  commentCtrl: _commentDeliveryCtrl,
                  options: [
                    _EvaluationOption(label: 'ก. 3-7 วัน (20 คะแนน)', value: 20),
                    _EvaluationOption(label: 'ข. 8-15 วัน (15 คะแนน)', value: 15),
                    _EvaluationOption(label: 'ค. 16-30 วัน (10 คะแนน)', value: 10),
                    _EvaluationOption(label: 'ง. 30 วันขึ้นไป (5 คะแนน)', value: 5),
                  ],
                  onChanged: (val) => setState(() => _evalData.scoreDelivery = val),
                ),

                _buildUltraCompactCard(
                  title: '4. ความสนใจในลูกค้า และการอำนวยความสะดวก',
                  currentVal: _evalData.scoreService,
                  commentCtrl: _commentServiceCtrl,
                  options: [
                    _EvaluationOption(label: 'ก. ดีเยี่ยม (15 คะแนน)', value: 15),
                    _EvaluationOption(label: 'ข. ดี (10 คะแนน)', value: 10),
                    _EvaluationOption(label: 'ค. พอใช้ (5 คะแนน)', value: 5),
                    _EvaluationOption(label: 'ง. ควรปรับปรุง (0 คะแนน)', value: 0),
                  ],
                  onChanged: (val) => setState(() => _evalData.scoreService = val),
                ),

                _buildUltraCompactCard(
                  title: '5. ระบบบริหารคุณภาพ ภายในบริษัทได้รับ ISO 9001 แล้วหรือไม่',
                  currentVal: _evalData.scoreIso9001,
                  commentCtrl: _commentIso9001Ctrl,
                  options: [
                    _EvaluationOption(label: 'ก. ได้รับใบรับรองแล้ว ISO 9001 (10 คะแนน)', value: 10),
                    _EvaluationOption(label: 'ข. กำลังจัดทำ ISO 9001 (7 คะแนน)', value: 7),
                    _EvaluationOption(label: 'ค. คิดที่จะทำในช่วง 1-2 ปี (5 คะแนน)', value: 5),
                    _EvaluationOption(label: 'ง. ไม่สนใจที่จะทำ (0 คะแนน)', value: 0),
                  ],
                  onChanged: (val) => setState(() => _evalData.scoreIso9001 = val),
                ),

                _buildUltraCompactCard(
                  title: '6. ระบบบริหารความปลอดภัยและสิ่งแวดล้อม ได้รับ ISO 14001 และ 45001 แล้วหรือไม่',
                  currentVal: _evalData.scoreIso14001,
                  commentCtrl: _commentIso14001Ctrl,
                  options: [
                    _EvaluationOption(label: 'ก. ได้รับใบรับรอง ISO 14001/45001 (10 คะแนน)', value: 10),
                    _EvaluationOption(label: 'ข. กำลังจัดทำ ISO 14001/45001 (7 คะแนน)', value: 7),
                    _EvaluationOption(label: 'ค. คิดที่จะทำในช่วง 1-2 ปี (5 คะแนน)', value: 5),
                    _EvaluationOption(label: 'ง. ไม่สนใจที่จะทำ (0 คะแนน)', value: 0),
                  ],
                  onChanged: (val) => setState(() => _evalData.scoreIso14001 = val),
                ),
                
                const SizedBox(height: 6),
                _buildTotalScoreBoard(),
                const SizedBox(height: 6),
                
                _buildApprovalRouteBoard(),
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  height: 44, 
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: _isSaving ? null : _saveToGoogleSheetsAndContinue,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('บันทึกผลประเมินและส่งอนุมัติ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
          if (_isSaving) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildVendorHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('ซัพพลายเออร์ที่ประเมิน:', style: TextStyle(fontSize: 12, color: Colors.black54)),
          Text(widget.vendorName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildRptStatusSection() {
    final bool isMatch = _evalData.rptStatus == 'MATCH';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMatch ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isMatch ? Colors.red.shade200 : Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isMatch ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                color: isMatch ? Colors.red.shade800 : Colors.green.shade800,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'ผลการตรวจสอบบุคคลเกี่ยวโยง (RPT):',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: isMatch ? Colors.red.shade900 : Colors.green.shade900),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isMatch ? Colors.red.shade700 : Colors.green.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _evalData.rptStatus,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isMatch 
              ? '⚠️ ตรวจพบรายชื่อกรรมการ มีความเกี่ยวข้องกับกลุ่มบุคคลภายในบริษัท (ผ่านกระบวนการรับทราบในฟอร์ม)' 
              : '✅ ไม่พบรายชื่อเกี่ยวโยงกับกลุ่มบุคคลภายในบริษัท',
            style: TextStyle(fontSize: 11.5, color: isMatch ? Colors.red.shade800 : Colors.green.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildUltraCompactCard({
    required String title,
    required int currentVal,
    required List<_EvaluationOption> options,
    required ValueChanged<int> onChanged,
    required TextEditingController commentCtrl,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8), 
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(10.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 2), 
            
            Wrap(
              spacing: 4.0, 
              runSpacing: 0.0, 
              children: options.map((opt) {
                final bool isSelected = currentVal == opt.value;
                return InkWell(
                  onTap: () => onChanged(opt.value),
                  child: IntrinsicWidth( 
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: 0.8, 
                          child: Radio<int>(
                            value: opt.value,
                            groupValue: currentVal,
                            activeColor: Colors.blue.shade800,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, 
                            onChanged: (val) {
                              if (val != null) onChanged(val);
                            },
                          ),
                        ),
                        Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 11.5, 
                            color: isSelected ? Colors.blue.shade900 : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                          ),
                        ),
                        const SizedBox(width: 8), 
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 5), 
            
            SizedBox(
              height: 32, 
              child: TextField(
                controller: commentCtrl,
                decoration: InputDecoration(
                  hintText: 'บันทึกความเห็น หรือระบุหลักฐานประกอบ...',
                  hintStyle: const TextStyle(fontSize: 11, color: Colors.black38),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
                style: const TextStyle(fontSize: 11.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalScoreBoard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _evalData.totalScore >= 70 ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _evalData.totalScore >= 70 ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('คะแนนรวมปัจจุบัน:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          Text('${_evalData.totalScore} / 100 คะแนน', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: _evalData.totalScore >= 70 ? Colors.green.shade900 : Colors.orange.shade900)),
        ],
      ),
    );
  }

  Widget _buildApprovalRouteBoard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_rounded, color: Colors.purple.shade800, size: 16),
              const SizedBox(width: 6),
              Text(
                'สายงานการอนุมัติเอกสาร (Approval Route):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _calculateApprovalRoute(),
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.purple.shade900),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('กำลังบันทึกลง Google Sheets...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EvaluationOption {
  final String label;
  final int value;
  _EvaluationOption({required this.label, required this.value});
}