import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rpt_vendor_app/models/rpt_models.dart';
import 'package:rpt_vendor_app/screens/result_screen.dart';

class EvaluationScreen extends StatefulWidget {
  final String userName;
  final SupplierEvaluation? initialEvalData;
  final List<DirectorMatch> rptResults;

  const EvaluationScreen({
    super.key,
    required this.userName,
    this.initialEvalData,
    required this.rptResults, // บังคับส่งข้อมูลจากหน้าตรวจสอบมาเสมอ
  });

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState(); // ✅ เรียกให้ถูกชื่อแล้ว
}

// ✅ แก้ไขชื่อ Class ให้ถูกต้อง
class _EvaluationScreenState extends State<EvaluationScreen> {
  final _formKey = GlobalKey<FormState>();
  late SupplierEvaluation evalData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    evalData = widget.initialEvalData ?? SupplierEvaluation();
  }

  Future<void> _submitEvaluation() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    const String scriptUrl =
        'https://script.google.com/macros/s/AKfycbwy3Sb2boSoBUi78CWbk32pqACnyOqM-tTOTNPWZeT8NcvYrCcueJlEuAska5jfV-Bl/exec';

    final Map<String, dynamic> payload = {
      "action": evalData.evalId != null
          ? "update_evaluation"
          : "save_evaluation",
      "evalId": evalData.evalId ?? "",
      "vendorName": evalData.vendorName,
      "productType": evalData.productType,
      "address": evalData.address,
      "contactPerson": evalData.contactPerson,
      "phone": evalData.phone,
      "evaluatedBy": widget.userName,
      "rptStatus": evalData.rptStatus,
      "evaluationType": evalData.evaluationType,
      "scoreSpec": evalData.scoreSpec.toString(),
      "scorePayment": evalData.scorePayment.toString(),
      "scoreDelivery": evalData.scoreDelivery.toString(),
      "commentSpec": evalData.commentSpec,
      "commentPayment": evalData.commentPayment,
      "commentDelivery": evalData.commentDelivery,
      "scoreExperience": evalData.scoreExperience.toString(),
      "scoreReadiness": evalData.scoreReadiness.toString(),
      "commentExperience": evalData.commentExperience,
      "commentReadiness": evalData.commentReadiness,
      "scoreService": evalData.scoreService.toString(),
      "scoreIso9001": evalData.scoreIso9001.toString(),
      "scoreIso14001": evalData.scoreIso14001.toString(),
      "commentService": evalData.commentService,
      "commentIso9001": evalData.commentIso9001,
      "commentIso14001": evalData.commentIso14001,
      "rptDirectors": jsonEncode(
        widget.rptResults
            .map(
              (e) => {
                "name": e.name,
                "isMatch": e.isMatch,
                "relation": e.relation,
              },
            )
            .toList(),
      ),
    };

    try {
      final response = await http.post(Uri.parse(scriptUrl), body: payload);

      if (response.statusCode == 200 || response.statusCode == 302) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ บันทึกข้อมูลสำเร็จ!')),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ResultScreen(
                  userName: widget.userName,
                  evalData: evalData,
                  searchResults: widget.rptResults,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          evalData.evalId != null ? 'แก้ไขการประเมิน' : 'ให้คะแนนซัพพลายเออร์',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ประเภทแบบประเมิน:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text(
                                    'ร้านค้า',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  value: 'ร้านค้า',
                                  groupValue: evalData.evaluationType,
                                  activeColor: Colors.blue.shade900,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (value) => setState(() {
                                    evalData.evaluationType = value!;
                                    evalData.scoreExperience = 0;
                                    evalData.scoreReadiness = 0;
                                  }),
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text(
                                    'ผู้รับเหมา',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  value: 'ผู้รับเหมา',
                                  groupValue: evalData.evaluationType,
                                  activeColor: Colors.orange.shade900,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (value) => setState(() {
                                    evalData.evaluationType = value!;
                                    evalData.scoreSpec = 0;
                                    evalData.scorePayment = 0;
                                    evalData.scoreDelivery = 0;
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      ' ข้อมูลพื้นฐาน',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue: evalData.vendorName,
                            decoration: const InputDecoration(
                              labelText: 'ชื่อผู้ขาย / ซัพพลายเออร์',
                              isDense: true,
                            ),
                            onSaved: (val) => evalData.vendorName = val ?? '',
                          ),
                          TextFormField(
                            initialValue: evalData.productType,
                            decoration: const InputDecoration(
                              labelText: 'ประเภทสินค้า/บริการ',
                              isDense: true,
                            ),
                            onSaved: (val) => evalData.productType = val ?? '',
                          ),
                          TextFormField(
                            initialValue: evalData.address,
                            decoration: const InputDecoration(
                              labelText: 'ที่อยู่',
                              isDense: true,
                            ),
                            onSaved: (val) => evalData.address = val ?? '',
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: evalData.contactPerson,
                                  decoration: const InputDecoration(
                                    labelText: 'ผู้ติดต่อ',
                                    isDense: true,
                                  ),
                                  onSaved: (val) =>
                                      evalData.contactPerson = val ?? '',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  initialValue: evalData.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'เบอร์โทร',
                                    isDense: true,
                                  ),
                                  onSaved: (val) => evalData.phone = val ?? '',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ' เกณฑ์การประเมิน (${evalData.evaluationType})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'รวม: ${evalData.totalScore} คะแนน',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (evalData.evaluationType == 'ร้านค้า') ...[
                      _buildChoiceField(
                        title:
                            '1. Spec สินค้า ข้อกำหนดของผู้ขายสอดคล้องกับข้อกำหนดที่ต้องการหรือไม่ (Max 20)',
                        currentScore: evalData.scoreSpec,
                        initialComment: evalData.commentSpec,
                        options: [
                          {'text': 'ก. ตรงตามข้อกำหนดทุกประการ', 'score': 20},
                          {
                            'text': 'ข. ไม่ตรงข้อกำหนด แต่ใช้งานได้',
                            'score': 15,
                          },
                          {
                            'text': 'ค. ให้ความมั่นใจว่าตอบสนองได้',
                            'score': 10,
                          },
                          {'text': 'ง. ใช้ไม่ได้', 'score': 0},
                        ],
                        onScoreChanged: (val) =>
                            setState(() => evalData.scoreSpec = val),
                        onCommentChanged: (val) => evalData.commentSpec = val,
                      ),
                      _buildChoiceField(
                        title: '2. เงื่อนไขการชำระเงิน (Max 25)',
                        currentScore: evalData.scorePayment,
                        initialComment: evalData.commentPayment,
                        options: [
                          {
                            'text': 'ก. กำหนดการชำระเงินภายใน 90 วัน',
                            'score': 25,
                          },
                          {
                            'text': 'ข. กำหนดการชำระเงินภายใน 60 วัน',
                            'score': 20,
                          },
                          {
                            'text': 'ค. กำหนดการชำระเงินภายใน 30 วัน',
                            'score': 15,
                          },
                          {'text': 'ง. ชำระเงินทันที', 'score': 10},
                        ],
                        onScoreChanged: (val) =>
                            setState(() => evalData.scorePayment = val),
                        onCommentChanged: (val) =>
                            evalData.commentPayment = val,
                      ),
                      _buildChoiceField(
                        title: '3. ระยะเวลาในการส่งมอบ (Max 20)',
                        currentScore: evalData.scoreDelivery,
                        initialComment: evalData.commentDelivery,
                        options: [
                          {'text': 'ก. 3-7 วัน', 'score': 20},
                          {'text': 'ข. 8-15 วัน', 'score': 15},
                          {'text': 'ค. 16-30 วัน', 'score': 10},
                          {'text': 'ง. 30 วันขึ้นไป', 'score': 5},
                        ],
                        onScoreChanged: (val) =>
                            setState(() => evalData.scoreDelivery = val),
                        onCommentChanged: (val) =>
                            evalData.commentDelivery = val,
                      ),
                      _buildChoiceField(
                        title:
                            '4. ความสนใจในลูกค้า และการอำนวยความสะดวก (Max 15)',
                        currentScore: evalData.scoreService,
                        initialComment: evalData.commentService,
                        options: [
                          {'text': 'ก. ดีเยี่ยม', 'score': 15},
                          {'text': 'ข. ดี', 'score': 10},
                          {'text': 'ค. พอใช้', 'score': 5},
                          {'text': 'ง. ควรปรับปรุง', 'score': 0},
                        ],
                        onScoreChanged: (val) =>
                            setState(() => evalData.scoreService = val),
                        onCommentChanged: (val) =>
                            evalData.commentService = val,
                      ),
                    ] else ...[
                      _buildChoiceField(
                        title:
                            '1. ประสบการณ์และผลงาน ในอดีต และงานที่ระหว่างทำอยู่ในปัจจุบัน (Max 30)',
                        currentScore: evalData.scoreExperience,
                        initialComment: evalData.commentExperience,
                        options: [
                          {
                            'text': 'ก. มี Web site และ company profile',
                            'score': 30,
                          },
                          {
                            'text': 'ข. มี Web site หรือ company profile',
                            'score': 25,
                          },
                          {
                            'text': 'ค. ได้ข้อมูลสัมภาษณ์ผ่านโทรศัพท์',
                            'score': 20,
                          },
                          {'text': 'ง. ไม่ให้ข้อมูล', 'score': 0},
                        ],
                        onScoreChanged: (val) =>
                            setState(() => evalData.scoreExperience = val),
                        onCommentChanged: (val) =>
                            evalData.commentExperience = val,
                      ),
                      // ✅ แก้ไขตัวแปร evalData.scoreReadiness ให้ถูกต้อง
                      _buildChoiceField(
                        title:
                            '2. ความพร้อมที่จะเข้าดำเนินการหลังการสั่งจ้าง (Max 30)',
                        currentScore: evalData.scoreReadiness,
                        initialComment: evalData.commentReadiness,
                        options: [
                          {'text': 'ก. 3-7 วัน', 'score': 30},
                          {'text': 'ข. 8-15 วัน', 'score': 25},
                          {'text': 'ค. 16-30 วัน', 'score': 20},
                          {'text': 'ง. 30 วันขึ้นไป', 'score': 15},
                        ],
                        onScoreChanged: (val) =>
                            setState(() => evalData.scoreReadiness = val),
                        onCommentChanged: (val) =>
                            evalData.commentReadiness = val,
                      ),
                      _buildChoiceField(
                        title:
                            '3. ความสนใจในลูกค้า และการอำนวยความสะดวก (Max 20)',
                        currentScore: evalData.scoreService,
                        initialComment: evalData.commentService,
                        options: [
                          {'text': 'ก. ดีเยี่ยม', 'score': 20},
                          {'text': 'ข. ดี', 'score': 15},
                          {'text': 'ค. พอใช้', 'score': 10},
                          {'text': 'ง. ควรปรับปรุง', 'score': 0},
                        ],
                        onScoreChanged: (val) =>
                            setState(() => evalData.scoreService = val),
                        onCommentChanged: (val) =>
                            evalData.commentService = val,
                      ),
                    ],

                    _buildChoiceField(
                      title:
                          '${evalData.evaluationType == 'ร้านค้า' ? '5' : '4'}. ระบบบริหารคุณภาพ ภายในบริษัทได้รับ ISO 9001 แล้วหรือไม่ (Max 10)',
                      currentScore: evalData.scoreIso9001,
                      initialComment: evalData.commentIso9001,
                      options: [
                        {'text': 'ก. ได้รับใบรับรองแล้ว ISO 9001', 'score': 10},
                        {'text': 'ข. กำลังจัดทำ ISO 9001', 'score': 7},
                        {'text': 'ค. คิดที่จะทำในช่วง 1-2 ปี', 'score': 5},
                        {'text': 'ง. ไม่สนใจที่จะทำ', 'score': 0},
                      ],
                      onScoreChanged: (val) =>
                          setState(() => evalData.scoreIso9001 = val),
                      onCommentChanged: (val) => evalData.commentIso9001 = val,
                    ),
                    _buildChoiceField(
                      title:
                          '${evalData.evaluationType == 'ร้านค้า' ? '6' : '5'}. ระบบบริหารความปลอดภัยและสิ่งแวดล้อม ภายในบริษัทได้รับ ISO 14001 และ 45001 แล้วหรือไม่ (Max 10)',
                      currentScore: evalData.scoreIso14001,
                      initialComment: evalData.commentIso14001,
                      options: [
                        {
                          'text': 'ก. ได้รับใบรับรองแล้ว ISO 14001 และ 45001',
                          'score': 10,
                        },
                        {
                          'text': 'ข. กำลังจัดทำ ISO 14001 และ 45001',
                          'score': 7,
                        },
                        {'text': 'ค. คิดที่จะทำในช่วง 1-2 ปี', 'score': 5},
                        {'text': 'ง. ไม่สนใจที่จะทำ', 'score': 0},
                      ],
                      onScoreChanged: (val) =>
                          setState(() => evalData.scoreIso14001 = val),
                      onCommentChanged: (val) => evalData.commentIso14001 = val,
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _submitEvaluation,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text(
                          'บันทึกข้อมูลการประเมิน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChoiceField({
    required String title,
    required int currentScore,
    required String initialComment,
    required List<Map<String, dynamic>> options,
    required void Function(int) onScoreChanged,
    required void Function(String) onCommentChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...options.map((opt) {
            return InkWell(
              onTap: () => onScoreChanged(opt['score']),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Radio<int>(
                        value: opt['score'],
                        groupValue: currentScore,
                        onChanged: (val) => onScoreChanged(val!),
                        activeColor: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${opt['text']} (${opt['score']} คะแนน)',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: initialComment,
            decoration: InputDecoration(
              labelText: 'หลักฐาน / บันทึกความเห็น อื่นๆ',
              labelStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              isDense: true,
              prefixIcon: const Icon(
                Icons.comment_rounded,
                size: 16,
                color: Colors.black38,
              ),
            ),
            onChanged: onCommentChanged,
          ),
        ],
      ),
    );
  }
}
