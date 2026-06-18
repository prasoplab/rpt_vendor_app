import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class VendorRegistrationScreen extends StatefulWidget {
  final String userName;
  final String initialVendorName;

  const VendorRegistrationScreen({super.key, required this.userName, required this.initialVendorName});

  @override
  State<VendorRegistrationScreen> createState() => _VendorRegistrationScreenState();
}

class _VendorRegistrationScreenState extends State<VendorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers สำหรับรับค่าฟอร์ม
  late TextEditingController _vendorNameCtrl;
  final TextEditingController _searchTermCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _taxIdCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _bankAccountCtrl = TextEditingController();

  // Dropdowns (อ้างอิงจาก FM-AD-05)
  String _accountGroup = 'Z001 เจ้าหนี้การค้า';
  String _reconAccount = '221020 เจ้าหนี้การค้า-ในประเทศ';
  String _paymentTerm = 'S030 Due in 30 days';
  String _purchasingGroup = '103 จัดซื้อเหล็ก'; 
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _vendorNameCtrl = TextEditingController(text: widget.initialVendorName);
  }

  // ==========================================
  // 🚀 1. ฟังก์ชันบันทึกข้อมูลลง Google Sheet
  // ==========================================
  Future<void> _submitAndPrintForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // 🌟 ใส่ URL ของ Google Apps Script ตรงนี้
    const String scriptUrl = 'https://script.google.com/macros/s/AKfycbxl01N5r_wjweW_AMlA8kE-P3vkDKU86kxSWNF3UmwlTdy1O16XnktaH1wYMgEScONJ/exec';

    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        body: {
          "action": "save_vendor_registration",
          "accountGroup": _accountGroup,
          "vendorName": _vendorNameCtrl.text.trim(),
          "searchTerm": _searchTermCtrl.text.trim(),
          "address": _addressCtrl.text.trim(),
          "taxId": _taxIdCtrl.text.trim(),
          "contactName": _contactCtrl.text.trim(),
          "phone": _phoneCtrl.text.trim(),
          "email": _emailCtrl.text.trim(),
          "bankName": _bankNameCtrl.text.trim(),
          "bankAccount": _bankAccountCtrl.text.trim(),
          "reconAccount": _reconAccount,
          "paymentTerm": _paymentTerm,
          "purchasingGroup": _purchasingGroup,
          "addedBy": widget.userName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ บันทึกข้อมูลเข้าระบบเรียบร้อย!'), backgroundColor: Colors.green));
          
          // บันทึกเสร็จปุ๊บ สั่งเปิดหน้า Print PDF ทันที
          await _printPdfDocument(context, result['req_id'] ?? 'VEN-0000');
        } else {
          _showError(result['message']);
        }
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $msg'), backgroundColor: Colors.red));
  }

  // ==========================================
  // 🖨️ 2. ฟังก์ชันสร้างและพิมพ์ PDF (FM-AD-05)
  // ==========================================
  Future<void> _printPdfDocument(BuildContext context, String reqId) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => await _generatePdf(format, reqId));
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, String reqId) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();
    
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year + 543}';

    // วิดเจ็ตกล่องข้อมูลย่อยใน PDF
    pw.Widget buildInfoRow(String title, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(width: 140, child: pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900))),
            pw.Expanded(child: pw.Text(value.isEmpty ? '-' : value, style: pw.TextStyle(font: fontRegular, fontSize: 10))),
          ]
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(30),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 🌟 หัวเอกสาร
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ใบอนุมัติเปิดหน้าบัญชี', style: pw.TextStyle(fontSize: 16, fontBold: fontBold)),
                      pw.Text('(Vendor Master Maintenance)', style: pw.TextStyle(fontSize: 12, fontBold: fontBold)),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('รหัสอ้างอิง: $reqId', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text('วันที่: $dateStr', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ]
                  ),
                ]
              ),
              pw.SizedBox(height: 15),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 15),

              // 🌟 กล่องข้อมูลส่วนที่ 1: ข้อมูลทั่วไป
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.5), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ส่วนที่ 1: ข้อมูลทั่วไป (General Data)', style: pw.TextStyle(fontSize: 11, fontBold: fontBold, background: const pw.BoxDecoration(color: PdfColors.grey200))),
                    pw.SizedBox(height: 10),
                    buildInfoRow('Account Group:', _accountGroup),
                    buildInfoRow('ชื่อร้านค้า/บริษัท (Name):', _vendorNameCtrl.text),
                    buildInfoRow('Search term 1:', _searchTermCtrl.text),
                    buildInfoRow('เลขประจำตัวผู้เสียภาษี:', _taxIdCtrl.text),
                    buildInfoRow('ที่อยู่ (Address):', _addressCtrl.text),
                    pw.SizedBox(height: 8),
                    pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                    pw.SizedBox(height: 8),
                    pw.Text('การติดต่อ (Communication)', style: pw.TextStyle(fontSize: 10, fontBold: fontBold)),
                    pw.SizedBox(height: 6),
                    buildInfoRow('ชื่อผู้ติดต่อ:', _contactCtrl.text),
                    buildInfoRow('โทรศัพท์ (Telephone):', _phoneCtrl.text),
                    buildInfoRow('อีเมล (E-Mail):', _emailCtrl.text),
                  ]
                )
              ),
              pw.SizedBox(height: 10),

              // 🌟 กล่องข้อมูลส่วนที่ 2: ธนาคาร & SAP
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.5), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ส่วนที่ 2: ธุรกรรมและบัญชี (Payment & SAP Data)', style: pw.TextStyle(fontSize: 11, fontBold: fontBold, background: const pw.BoxDecoration(color: PdfColors.grey200))),
                    pw.SizedBox(height: 10),
                    buildInfoRow('รหัสธนาคาร (Bank key):', _bankNameCtrl.text),
                    buildInfoRow('เลขที่บัญชี (Bank Account):', _bankAccountCtrl.text),
                    pw.SizedBox(height: 8),
                    pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                    pw.SizedBox(height: 8),
                    buildInfoRow('Reconciliation Account:', _reconAccount),
                    buildInfoRow('เงื่อนไขการชำระเงิน:', _paymentTerm),
                    buildInfoRow('พนักงานที่รับผิดชอบจัดซื้อ:', _purchasingGroup),
                  ]
                )
              ),
              pw.Spacer(),

              // 🌟 ลายเซ็น
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(children: [
                    pw.Text('ผู้ขออนุมัติ / ผู้รวบรวมข้อมูล', style: pw.TextStyle(fontSize: 10, fontBold: fontBold)),
                    pw.SizedBox(height: 30),
                    pw.Container(height: 0.5, width: 120, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('( ${widget.userName} )', style: pw.TextStyle(fontSize: 10)),
                    pw.Text('วันที่ ....... / ....... / .......', style: pw.TextStyle(fontSize: 9)),
                  ]),
                  pw.Column(children: [
                    pw.Text('ผู้อนุมัติ (Authorized Sign)', style: pw.TextStyle(fontSize: 10, fontBold: fontBold)),
                    pw.SizedBox(height: 30),
                    pw.Container(height: 0.5, width: 120, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('( ......................................... )', style: pw.TextStyle(fontSize: 10)),
                    pw.Text('วันที่ ....... / ....... / .......', style: pw.TextStyle(fontSize: 9)),
                  ]),
                ]
              )
            ]
          );
        },
      ),
    );
    return pdf.save();
  }

  // ==========================================
  // 📱 3. UI หน้าจอโทรศัพท์ (หน้ากรอกฟอร์ม)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('ฟอร์มเปิดหน้าบัญชีร้านค้า', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('กำลังบันทึกและสร้าง PDF...', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
            ],
          ))
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSectionHeader('1. ข้อมูลทั่วไป (General Data)', Icons.business_rounded),
                _buildDropdown('Account Group', _accountGroup, ['Z001 เจ้าหนี้การค้า', 'Z002 เจ้าหนี้ผู้รับเหมา', 'Z003 เจ้าหนี้อื่น', 'Z004 เจ้าหนี้การค้าต่างประเทศ', 'Z005 เจ้าหนี้พนักงาน', 'Z006 Petty cash'], (v) => setState(() => _accountGroup = v!)),
                _buildTextField('ชื่อร้านค้า/บริษัท *', _vendorNameCtrl, isRequired: true),
                _buildTextField('Search term 1', _searchTermCtrl),
                _buildTextField('เลขประจำตัวผู้เสียภาษี 13 หลัก', _taxIdCtrl),
                _buildTextField('ที่อยู่ (Address)', _addressCtrl, maxLines: 3),
                
                _buildSectionHeader('2. การติดต่อ (Communication)', Icons.contact_phone_rounded),
                _buildTextField('ชื่อผู้ติดต่อ', _contactCtrl),
                _buildTextField('เบอร์โทรศัพท์', _phoneCtrl, keyboardType: TextInputType.phone),
                _buildTextField('อีเมล (E-Mail)', _emailCtrl, keyboardType: TextInputType.emailAddress),

                _buildSectionHeader('3. ข้อมูลบัญชีธนาคาร (Payment Transaction)', Icons.account_balance_rounded),
                _buildTextField('ประเทศ / รหัสธนาคาร', _bankNameCtrl, hintText: 'เช่น TH / KBANK'),
                _buildTextField('เลขที่บัญชี (Bank Account)', _bankAccountCtrl, keyboardType: TextInputType.number),

                _buildSectionHeader('4. ข้อมูลทางบัญชีและจัดซื้อ (SAP Data)', Icons.settings_applications_rounded),
                _buildDropdown('Reconciliation Account', _reconAccount, ['112020 เงินสดย่อยตั้งพัก', '221010 เจ้าหนี้การค้า-บริษัทที่เกี่ยวข้องกัน', '221020 เจ้าหนี้การค้า-ในประเทศ', '221030 เจ้าหนี้การค้า-ต่างประเทศ', '221040 เจ้าหนี้อื่น-บริษัทที่เกี่ยวข้องกัน', '221050 เจ้าหนี้อื่น-ในประเทศ', '221060 เจ้าหนี้อื่น-ต่างประเทศ'], (v) => setState(() => _reconAccount = v!)),
                _buildDropdown('เงื่อนไขการชำระเงิน (Term of Payment)', _paymentTerm, ['S000 Due immediately/Cash', 'P030 Due on next month', 'S030 Due in 30 days', 'S045 Due in 45 days', 'S060 Due in 60 days', 'S090 Due in 90 days', 'S120 Due in 120 days'], (v) => setState(() => _paymentTerm = v!)),
                _buildDropdown('พนักงานจัดซื้อ (Purchasing Group)', _purchasingGroup, ['101 อุปกรณ์สำนักงาน', '102 จัดซื้ออะไหล่', '103 จัดซื้อเหล็ก', '104 จัดซื้อน้ำมัน', '105 จัดซื้อยางมะตอย', '106 วัสดุโครงการ', '107 งานบริการ', '108 โรงงานผลิต'], (v) => setState(() => _purchasingGroup = v!)),

                const SizedBox(height: 30),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700, foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  onPressed: _submitAndPrintForm, // 🌟 กดปุ๊บ บันทึกและโชว์ PDF
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('บันทึกข้อมูล และพิมพ์ใบอนุมัติ (PDF)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(padding: const EdgeInsets.only(top: 24, bottom: 12), child: Row(children: [Icon(icon, color: Colors.blue.shade800, size: 20), const SizedBox(width: 8), Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue.shade900))]));
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = false, int maxLines = 1, TextInputType? keyboardType, String? hintText}) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(controller: controller, maxLines: maxLines, keyboardType: keyboardType, decoration: InputDecoration(labelText: label, hintText: hintText, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)), validator: isRequired ? (v) => v!.isEmpty ? 'กรุณากรอกข้อมูล' : null : null));
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: DropdownButtonFormField<String>(value: value, isExpanded: true, decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)), items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(), onChanged: onChanged));
  }
}