import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rpt_vendor_app/models/rpt_models.dart';
import 'package:rpt_vendor_app/screens/search_vendor_screen.dart';
import 'package:rpt_vendor_app/screens/evaluation_screen.dart';
import 'package:rpt_vendor_app/screens/result_screen.dart';
import 'package:rpt_vendor_app/screens/vendor_registration_screen.dart';

class HistoryScreen extends StatefulWidget {
  final String userName;

  const HistoryScreen({super.key, required this.userName});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SupplierEvaluation> _historyList = [];
  List<SupplierEvaluation> _filteredList = [];
  List<dynamic> _rawResponseData = [];

  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;
  String _debugMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _debugMessage = '';
    });

    const String scriptUrl =
        'https://script.google.com/macros/s/AKfycbwy3Sb2boSoBUi78CWbk32pqACnyOqM-tTOTNPWZeT8NcvYrCcueJlEuAska5jfV-Bl/exec';

    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        body: {"action": "get_evaluations"},
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        try {
          final result = jsonDecode(response.body);

          if (result['status'] == 'success') {
            List<dynamic> data = result['data'];
            setState(() {
              _rawResponseData = data;
              _historyList = data
                  .map((e) => SupplierEvaluation.fromJson(e))
                  .toList();
              _filteredList = _historyList;

              if (_filteredList.isEmpty) {
                _debugMessage =
                    '✅ ดึงข้อมูลสำเร็จ แต่ใน Google Sheet ไม่มีข้อมูลในคอลัมน์ B (ชื่อ Vendor) เลยครับ';
              }
            });
          } else {
            setState(
              () => _debugMessage =
                  '❌ Error จาก Google Sheet:\n${result['message']}',
            );
          }
        } catch (formatErr) {
          setState(
            () => _debugMessage =
                '❌ อ่านข้อมูลไม่ได้ (ไม่ใช่ JSON):\n${response.body.toString().substring(0, 200)}...',
          );
        }
      } else {
        setState(
          () => _debugMessage =
              '❌ เชื่อมต่อเซิร์ฟเวอร์ล้มเหลว (Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      setState(
        () => _debugMessage = '❌ ปัญหาฝั่งแอปพลิเคชัน (Network/App):\n$e',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = _historyList;
      } else {
        _filteredList = _historyList
            .where(
              (item) =>
                  item.vendorName.toLowerCase().contains(query.toLowerCase()) ||
                  item.productType.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  // แกะรายชื่อกรรมการจริงจากฐานข้อมูล
  List<DirectorMatch> _extractRealDirectors(SupplierEvaluation item) {
    var rawItem = _rawResponseData.firstWhere(
      (e) => e['evalId'] == item.evalId,
      orElse: () => null,
    );
    List<DirectorMatch> realDirectors = [];

    if (rawItem != null &&
        rawItem['rptDirectors'] != null &&
        rawItem['rptDirectors'].toString().isNotEmpty) {
      try {
        List<dynamic> dirJson = jsonDecode(rawItem['rptDirectors']);
        realDirectors = dirJson
            .map(
              (d) => DirectorMatch(
                name: d['name'] ?? '',
                isMatch: d['isMatch'] ?? false,
                relation: d['relation'] ?? '',
              ),
            )
            .toList();
      } catch (e) {
        debugPrint("Error parsing directors JSON: $e");
      }
    }
    return realDirectors;
  }

  void _reprintEvaluation(SupplierEvaluation item) {
    List<DirectorMatch> realDirectors = _extractRealDirectors(item);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          userName: widget.userName,
          evalData: item,
          searchResults: realDirectors,
        ),
      ),
    );
  }

  // 🌟 อัปเกรดใหม่: กดแก้ไขแล้วให้เตะย้อนกลับไปหน้าตรวจสอบกรรมการตั้งแต่แรก!
  void _editEvaluation(SupplierEvaluation item) {
    List<DirectorMatch> realDirectors = _extractRealDirectors(item);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchVendorScreen(
          userName: widget.userName,
          initialEvalData: item, // 🌟 ส่งข้อมูลประเมินเดิมกลับไป
          initialDirectors:
              realDirectors, // 🌟 ส่งรายชื่อกรรมการเดิมกลับไปให้ลบ/เพิ่มใหม่ที่หน้าแรก
        ),
      ),
    ).then((value) => _fetchHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'ประวัติการประเมิน',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchHistory),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue.shade900,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อซัพพลายเออร์, ประเภทสินค้า...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _debugMessage.isNotEmpty
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _fetchHistory,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.all(12),
                      itemCount: _filteredList.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(_filteredList[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SearchVendorScreen(userName: widget.userName),
            ),
          ).then((value) => _fetchHistory());
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'ประเมินรายใหม่',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 50,
                color: Colors.red.shade800,
              ),
              const SizedBox(height: 16),
              const Text(
                'ระบบตรวจพบปัญหา',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _debugMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.red.shade900),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchHistory,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองโหลดใหม่อีกครั้ง'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(SupplierEvaluation item) {
    bool isPassed = item.totalScore >= 70;
    bool hasRpt = item.rptStatus == 'MATCH';
    String formattedDate = item.timestamp != null
        ? item.timestamp!.split('T')[0]
        : "-";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.vendorName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.evaluationType,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'สินค้า/บริการ: ${item.productType}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Text(
              'วันที่ประเมิน: $formattedDate',
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(height: 1, thickness: 0.5),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildStatusBadge(
                      text: '${item.totalScore} คะแนน',
                      icon: isPassed ? Icons.check_circle : Icons.cancel,
                      color: isPassed ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    _buildStatusBadge(
                      text: hasRpt ? 'ติด RPT' : 'RPT ปกติ',
                      icon: hasRpt
                          ? Icons.warning_rounded
                          : Icons.shield_rounded,
                      color: hasRpt ? Colors.orange : Colors.green,
                    ),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VendorRegistrationScreen(
                              userName: widget.userName,
                              initialVendorName: item.vendorName,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.app_registration_rounded,
                          size: 20,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _editEvaluation(
                        item,
                      ), // ปุ่มสีส้ม วิ่งย้อนกลับหน้าแรก
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit_note_rounded,
                          size: 20,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _reprintEvaluation(item),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 20,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required String text,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color.shade700),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
