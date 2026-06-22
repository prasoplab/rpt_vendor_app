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

  const VendorRegistrationScreen({
    super.key,
    required this.userName,
    required this.initialVendorName,
  });

  @override
  State<VendorRegistrationScreen> createState() =>
      _VendorRegistrationScreenState();
}

class _VendorRegistrationScreenState extends State<VendorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _existingReqId;
  bool _isLoading = true;

  // 🌟 ตัวแปรเก็บฐานข้อมูลที่อยู่ประเทศไทย
  static List<ThaiAddress> _allAddresses = [];
  bool _isLoadingAddress = false;

  late TextEditingController _vendorNameCtrl;
  final TextEditingController _searchTermCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _subDistrictCtrl = TextEditingController();
  final TextEditingController _districtCtrl = TextEditingController();
  final TextEditingController _provinceCtrl = TextEditingController();
  final TextEditingController _zipCodeCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController(text: 'TH');

  final TextEditingController _contactCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _taxIdCtrl = TextEditingController();

  bool _isWht3 = false;
  bool _isWht53 = false;
  final TextEditingController _wht3CodeCtrl = TextEditingController();
  final TextEditingController _wht53CodeCtrl = TextEditingController();

  String? _selectedBank;
  final TextEditingController _bankBranchCtrl = TextEditingController();
  final TextEditingController _bankAccountCtrl = TextEditingController();
  final TextEditingController _acctHolderCtrl = TextEditingController();

  bool _payTransfer = false;
  bool _payCheque = false;
  bool _payPN = false;
  final TextEditingController _currencyCtrl = TextEditingController(
    text: 'THB',
  );
  final TextEditingController _productsCtrl = TextEditingController();

  String _objective = 'สร้างใหม่';
  String _accountGroup = 'Z001 เจ้าหนี้การค้า';
  String _reconAccount = '221020 เจ้าหนี้การค้า-ในประเทศ';
  String _paymentTerm = 'S030 Due in 30 days';
  String _purchasingGroup = '103 จัดซื้อเหล็ก';

  bool _cc1000 = false;
  bool _cc2000 = false;
  bool _cc3000 = false;
  bool _cc6000 = false;
  bool _grBased = true;
  bool _srvBased = false;

  final List<String> _bankList = [
    'BBL - ธนาคารกรุงเทพ',
    'KBANK - ธนาคารกสิกรไทย',
    'KTB - ธนาคารกรุงไทย',
    'SCB - ธนาคารไทยพาณิชย์',
    'BAY - ธนาคารกรุงศรีอยุธยา',
    'TTB - ธนาคารทหารไทยธนชาต',
    'GSB - ธนาคารออมสิน',
  ];

  @override
  void initState() {
    super.initState();
    _vendorNameCtrl = TextEditingController(text: widget.initialVendorName);
    _fetchExistingData();
    _fetchThaiAddressData();
  }

  // =====================================
  // 🌟 โหลดฐานข้อมูล 7,400 ตำบลประเทศไทย (แก้บั๊กจังหวัดไม่ขึ้นแล้ว)
  // =====================================
  Future<void> _fetchThaiAddressData() async {
    if (_allAddresses.isNotEmpty) return;

    setState(() => _isLoadingAddress = true);
    const String url =
        'https://raw.githubusercontent.com/kongvut/thai-province-data/master/api/latest/sub_district_with_district_and_province.json';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        List<ThaiAddress> tempList = [];
        for (var item in data) {
          // 🌟 สแกนหาชื่อจังหวัดให้ทะลุปรุโปร่ง ไม่ว่าจะซ้อนอยู่ชั้นไหน
          String pName =
              item['province']?['name_th']?.toString() ??
              item['district']?['province']?['name_th']?.toString() ??
              '';

          tempList.add(
            ThaiAddress(
              subDistrict: item['name_th']?.toString() ?? '',
              district: item['district']?['name_th']?.toString() ?? '',
              province: pName, // ใส่ชื่อจังหวัดที่ดึงได้ลงไป
              zipCode: item['zip_code']?.toString() ?? '',
            ),
          );
        }

        setState(() => _allAddresses = tempList);
      }
    } catch (e) {
      debugPrint("Address Load Error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _fetchExistingData() async {
    const String scriptUrl =
        'https://script.google.com/macros/s/AKfycbw9U7rcS469vPjpHujj8ih9_mKcK4yZhQEDejK_T7z0teB69EeX5QjkZ7elleN-QW5u/exec';
    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        body: {
          "action": "get_vendor_form",
          "vendorName": widget.initialVendorName,
        },
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success' && result['data'] != null) {
          var d = result['data'];
          setState(() {
            _existingReqId = d['reqId'];
            _objective = d['objective'] ?? 'สร้างใหม่';
            _accountGroup = d['accountGroup'] ?? 'Z001 เจ้าหนี้การค้า';
            _searchTermCtrl.text = d['searchTerm'] ?? '';
            _addressCtrl.text = d['address'] ?? '';
            _subDistrictCtrl.text = d['subDistrict'] ?? '';
            _districtCtrl.text = d['district'] ?? '';
            _provinceCtrl.text = d['province'] ?? '';
            _zipCodeCtrl.text = d['zipCode'] ?? '';
            _countryCtrl.text = d['country'] ?? 'TH';
            _contactCtrl.text = d['contactName'] ?? '';
            _phoneCtrl.text = d['phone'] ?? '';
            _mobileCtrl.text = d['mobile'] ?? '';
            _emailCtrl.text = d['email'] ?? '';
            _taxIdCtrl.text = d['taxId'] ?? '';

            String cc = d['companyCode'] ?? '';
            _cc1000 = cc.contains('1000');
            _cc2000 = cc.contains('2000');
            _cc3000 = cc.contains('3000');
            _cc6000 = cc.contains('6000');

            String wht1 = d['wht1'] ?? '';
            if (wht1.contains('ภ.ง.ด.3')) {
              _isWht3 = true;
              _wht3CodeCtrl.text =
                  RegExp(r'\((.*?)\)').firstMatch(wht1)?.group(1) ?? '';
            }
            String wht2 = d['wht2'] ?? '';
            if (wht2.contains('ภ.ง.ด.53')) {
              _isWht53 = true;
              _wht53CodeCtrl.text =
                  RegExp(r'\((.*?)\)').firstMatch(wht2)?.group(1) ?? '';
            }

            String bankStr = d['bankKey'] ?? '';
            if (bankStr.contains(' สาขา ')) {
              var parts = bankStr.split(' สาขา ');
              _selectedBank = _bankList.contains(parts[0]) ? parts[0] : null;
              _bankBranchCtrl.text = parts[1];
            }
            _bankAccountCtrl.text = d['bankAccount'] ?? '';
            _acctHolderCtrl.text = d['acctHolder'] ?? '';

            String paym = d['paymentMethod'] ?? '';
            _payTransfer = paym.contains('โอนเงิน');
            _payCheque = paym.contains('เช็คธนาคาร');
            _payPN = paym.contains('ตั๋วสัญญาใช้เงิน');

            _reconAccount =
                d['reconAccount'] ?? '221020 เจ้าหนี้การค้า-ในประเทศ';
            _paymentTerm = d['paymentTerm'] ?? 'S030 Due in 30 days';
            _purchasingGroup = d['purchasingGroup'] ?? '103 จัดซื้อเหล็ก';
            _currencyCtrl.text = d['currency'] ?? 'THB';
            _grBased = (d['grBased'] == 'X');
            _srvBased = (d['srvBased'] == 'X');
            _productsCtrl.text = d['products'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint("Load error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAndPrintForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    const String scriptUrl =
        'https://script.google.com/macros/s/AKfycbw9U7rcS469vPjpHujj8ih9_mKcK4yZhQEDejK_T7z0teB69EeX5QjkZ7elleN-QW5u/exec';

    List<String> ccList = [];
    if (_cc1000) ccList.add('1000');
    if (_cc2000) ccList.add('2000');
    if (_cc3000) ccList.add('3000');
    if (_cc6000) ccList.add('6000');

    List<String> paymentMethods = [];
    if (_payTransfer) paymentMethods.add('โอนเงิน');
    if (_payCheque) paymentMethods.add('เช็คธนาคาร');
    if (_payPN) paymentMethods.add('ตั๋วสัญญาใช้เงิน');

    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        body: {
          "action": _existingReqId != null
              ? "update_vendor_registration"
              : "save_vendor_registration",
          "reqId": _existingReqId ?? "",
          "objective": _objective,
          "companyCode": ccList.join(', '),
          "accountGroup": _accountGroup,
          "vendorName": _vendorNameCtrl.text.trim(),
          "searchTerm": _searchTermCtrl.text.trim(),
          "address": _addressCtrl.text.trim(),
          "subDistrict": _subDistrictCtrl.text.trim(),
          "district": _districtCtrl.text.trim(),
          "province": _provinceCtrl.text.trim(),
          "zipCode": _zipCodeCtrl.text.trim(),
          "country": _countryCtrl.text.trim(),
          "contactName": _contactCtrl.text.trim(),
          "phone": _phoneCtrl.text.trim(),
          "mobile": _mobileCtrl.text.trim(),
          "email": _emailCtrl.text.trim(),
          "taxId": _taxIdCtrl.text.trim(),
          "wht1": _isWht3 ? "ภ.ง.ด.3 (${_wht3CodeCtrl.text})" : "",
          "wht2": _isWht53 ? "ภ.ง.ด.53 (${_wht53CodeCtrl.text})" : "",
          "bankKey": "${_selectedBank ?? ''} สาขา ${_bankBranchCtrl.text}",
          "bankAccount": _bankAccountCtrl.text.trim(),
          "acctHolder": _acctHolderCtrl.text.trim(),
          "reconAccount": _reconAccount,
          "paymentTerm": _paymentTerm,
          "paymentMethod": paymentMethods.join(', '),
          "purchasingGroup": _purchasingGroup,
          "currency": _currencyCtrl.text.trim(),
          "grBased": _grBased ? 'X' : '',
          "srvBased": _srvBased ? 'X' : '',
          "products": _productsCtrl.text.trim(),
          "addedBy": widget.userName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ บันทึกข้อมูลสำเร็จ!'),
              backgroundColor: Colors.green,
            ),
          );
          await _printPdfDocument(context, result['req_id'] ?? 'VEN-0000');
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _printPdfDocument(BuildContext context, String reqId) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async =>
          await _generatePdf(format, reqId),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, String reqId) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();
    final dateStr =
        '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year + 543}';

    pw.Widget buildInfoRow(String title, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 120,
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 9,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value.isEmpty ? '-' : value,
                style: pw.TextStyle(font: fontRegular, fontSize: 9),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget pdfCheckbox(String text, bool isChecked) {
      return pw.Row(
        children: [
          pw.Container(
            width: 8,
            height: 8,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 0.5, color: PdfColors.black),
            ),
            child: isChecked
                ? pw.Center(
                    child: pw.Text(
                      'X',
                      style: pw.TextStyle(font: fontBold, fontSize: 6),
                    ),
                  )
                : null,
          ),
          pw.SizedBox(width: 4),
          pw.Text(text, style: pw.TextStyle(font: fontRegular, fontSize: 9)),
        ],
      );
    }

    List<String> paymentMethods = [];
    if (_payTransfer) paymentMethods.add('โอนเงิน');
    if (_payCheque) paymentMethods.add('เช็คธนาคาร');
    if (_payPN) paymentMethods.add('ตั๋วสัญญาใช้เงิน');

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(30),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ใบอนุมัติเปิดหน้าบัญชี (FM-AD-05)',
                        style: pw.TextStyle(fontSize: 14, fontBold: fontBold),
                      ),
                      pw.Text(
                        '(Vendor Master Maintenance)',
                        style: pw.TextStyle(fontSize: 11, fontBold: fontBold),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'รหัสอ้างอิง: $reqId',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'วันที่: $dateStr',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.Row(
                children: [
                  pw.Text(
                    'วัตถุประสงค์: $_objective   |   Account Group: $_accountGroup   |   Company Code: ',
                    style: pw.TextStyle(fontSize: 10, fontBold: fontBold),
                  ),
                  pdfCheckbox('1000', _cc1000),
                  pw.SizedBox(width: 6),
                  pdfCheckbox('2000', _cc2000),
                  pw.SizedBox(width: 6),
                  pdfCheckbox('3000', _cc3000),
                  pw.SizedBox(width: 6),
                  pdfCheckbox('6000', _cc6000),
                ],
              ),
              pw.SizedBox(height: 8),

              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'General Data / การติดต่อ',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontBold: fontBold,
                        background: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    buildInfoRow(
                      'ชื่อร้านค้า/บริษัท (Name):',
                      _vendorNameCtrl.text,
                    ),
                    buildInfoRow('Search term 1:', _searchTermCtrl.text),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: buildInfoRow(
                            'เลขประจำตัวผู้เสียภาษี:',
                            _taxIdCtrl.text,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Row(
                            children: [
                              pw.Text(
                                'ข้อมูลภาษีหัก ณ ที่จ่าย: ',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 9,
                                  color: PdfColors.blue900,
                                ),
                              ),
                              pw.Text(
                                '1. ${_isWht3 ? "ภ.ง.ด.3 (${_wht3CodeCtrl.text})" : "-"}   2. ${_isWht53 ? "ภ.ง.ด.53 (${_wht53CodeCtrl.text})" : "-"}',
                                style: pw.TextStyle(
                                  font: fontRegular,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    buildInfoRow(
                      'ที่อยู่ (Address):',
                      '${_addressCtrl.text} ต.${_subDistrictCtrl.text} อ.${_districtCtrl.text} จ.${_provinceCtrl.text} ${_zipCodeCtrl.text}',
                    ),
                    pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: buildInfoRow(
                            'ชื่อผู้ติดต่อ:',
                            _contactCtrl.text,
                          ),
                        ),
                        pw.Expanded(
                          child: buildInfoRow(
                            'มือถือ (Mobile):',
                            _mobileCtrl.text,
                          ),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: buildInfoRow(
                            'โทรศัพท์ (Tel):',
                            _phoneCtrl.text,
                          ),
                        ),
                        pw.Expanded(
                          child: buildInfoRow(
                            'อีเมล (E-Mail):',
                            _emailCtrl.text,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Payment Transaction / ธุรกรรมธนาคาร',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontBold: fontBold,
                        background: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    buildInfoRow(
                      'ธนาคาร (Bank):',
                      '${_selectedBank ?? ''} สาขา ${_bankBranchCtrl.text}',
                    ),
                    buildInfoRow(
                      'เลขที่บัญชี (Bank Account):',
                      _bankAccountCtrl.text,
                    ),
                    buildInfoRow(
                      'ชื่อบัญชี (Acct holder):',
                      _acctHolderCtrl.text,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SAP Data (ข้อมูลทางบัญชีและจัดซื้อ)',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontBold: fontBold,
                        background: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: buildInfoRow('Recon Account:', _reconAccount),
                        ),
                        pw.Expanded(
                          child: buildInfoRow('Pur. Group:', _purchasingGroup),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: buildInfoRow('Term of Payment:', _paymentTerm),
                        ),
                        pw.Expanded(
                          child: buildInfoRow(
                            'สกุลเงิน (Currency):',
                            _currencyCtrl.text,
                          ),
                        ),
                      ],
                    ),
                    buildInfoRow(
                      'รูปแบบการชำระหนี้:',
                      paymentMethods.isEmpty ? '-' : paymentMethods.join(', '),
                    ),
                    pw.Row(
                      children: [
                        pw.SizedBox(width: 120),
                        pdfCheckbox('GR-based inv.verif', _grBased),
                        pw.SizedBox(width: 20),
                        pdfCheckbox('Srv-based inv.verif', _srvBased),
                      ],
                    ),
                    pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                    buildInfoRow(
                      'สินค้า/บริการที่จำหน่าย:',
                      _productsCtrl.text,
                    ),
                  ],
                ),
              ),
              pw.Spacer(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'ผู้ขออนุมัติ / ผู้รวบรวมข้อมูล',
                        style: pw.TextStyle(fontSize: 10, fontBold: fontBold),
                      ),
                      pw.SizedBox(height: 30),
                      pw.Container(
                        height: 0.5,
                        width: 120,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '( ${widget.userName} )',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'วันที่ ....... / ....... / .......',
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'ผู้อนุมัติ (Authorized Sign)',
                        style: pw.TextStyle(fontSize: 10, fontBold: fontBold),
                      ),
                      pw.SizedBox(height: 30),
                      pw.Container(
                        height: 0.5,
                        width: 120,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '( ......................................... )',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'วันที่ ....... / ....... / .......',
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  // =====================================
  // 🌟 ฟังก์ชันวาดกล่อง ค้นหาที่อยู่อัจฉริยะ
  // =====================================
  Widget _buildAutoAddressRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Autocomplete<ThaiAddress>(
            optionsBuilder: (TextEditingValue textVal) {
              if (textVal.text.isEmpty || _allAddresses.isEmpty)
                return const Iterable<ThaiAddress>.empty();
              return _allAddresses
                  .where(
                    (addr) =>
                        addr.subDistrict.contains(textVal.text) ||
                        addr.zipCode.contains(textVal.text) ||
                        addr.district.contains(textVal.text),
                  )
                  .take(30);
            },
            displayStringForOption: (ThaiAddress option) => option.subDistrict,
            onSelected: (ThaiAddress selection) {
              setState(() {
                _subDistrictCtrl.text = selection.subDistrict;
                _districtCtrl.text = selection.district;
                _provinceCtrl.text = selection.province;
                _zipCodeCtrl.text = selection.zipCode;
              });
            },
            fieldViewBuilder:
                (context, controller, focusNode, onEditingComplete) {
                  controller.text = _subDistrictCtrl.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (val) => _subDistrictCtrl.text = val,
                    decoration: InputDecoration(
                      labelText: _isLoadingAddress
                          ? 'กำลังโหลดฐานข้อมูล ปณ. ทั่วไทย...'
                          : 'ตำบล / แขวง / รหัสไปรษณีย์ 🔍',
                      filled: true,
                      fillColor: Colors.yellow.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: _isLoadingAddress
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Icon(Icons.search, size: 18),
                    ),
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 60,
                    height: 250,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(
                            'ต.${option.subDistrict} อ.${option.district} จ.${option.province}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: Text(
                            option.zipCode,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildTextField('อำเภอ / เขต', _districtCtrl)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'ฟอร์ม FM-AD-05',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    'กำลังค้นหาประวัติข้อมูลในระบบ...',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildCardSection(
                    'ส่วนที่ 1: วัตถุประสงค์',
                    Icons.flag_rounded,
                    [
                      _buildDropdown(
                        'วัตถุประสงค์',
                        _objective,
                        ['สร้างใหม่', 'เปลี่ยนแปลงข้อมูล'],
                        (v) => setState(() => _objective = v!),
                      ),
                      _buildDropdown(
                        'Account Group',
                        _accountGroup,
                        [
                          'Z001 เจ้าหนี้การค้า',
                          'Z002 เจ้าหนี้ผู้รับเหมา',
                          'Z003 เจ้าหนี้อื่น',
                          'Z004 เจ้าหนี้การค้าต่างประเทศ',
                          'Z005 เจ้าหนี้พนักงาน',
                          'Z006 Petty cash',
                        ],
                        (v) => setState(() => _accountGroup = v!),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          'Company Code (เลือกได้มากกว่า 1)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        children: [
                          _buildCheck(
                            title: '1000',
                            value: _cc1000,
                            onChanged: (v) => setState(() => _cc1000 = v!),
                          ),
                          _buildCheck(
                            title: '2000',
                            value: _cc2000,
                            onChanged: (v) => setState(() => _cc2000 = v!),
                          ),
                          _buildCheck(
                            title: '3000',
                            value: _cc3000,
                            onChanged: (v) => setState(() => _cc3000 = v!),
                          ),
                          _buildCheck(
                            title: '6000',
                            value: _cc6000,
                            onChanged: (v) => setState(() => _cc6000 = v!),
                          ),
                        ],
                      ),
                    ],
                  ),

                  _buildCardSection(
                    'ส่วนที่ 2: ข้อมูลทั่วไป (General Data)',
                    Icons.business_rounded,
                    [
                      _buildTextField(
                        'ชื่อร้านค้า/บริษัท (Name) *',
                        _vendorNameCtrl,
                        isRequired: true,
                      ),
                      _buildTextField('Search term 1', _searchTermCtrl),
                      _buildTextField(
                        'เลขประจำตัวผู้เสียภาษี 13 หลัก',
                        _taxIdCtrl,
                      ),
                      _buildTextField(
                        'บ้านเลขที่ / ถนน / ซอย',
                        _addressCtrl,
                        maxLines: 2,
                      ),

                      _buildAutoAddressRow(),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField('จังหวัด', _provinceCtrl),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTextField(
                              'รหัสไปรษณีย์',
                              _zipCodeCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      _buildTextField('ประเทศ (Country)', _countryCtrl),
                    ],
                  ),

                  _buildCardSection(
                    'ส่วนที่ 3: การติดต่อ (Communication)',
                    Icons.contact_phone_rounded,
                    [
                      _buildTextField('ชื่อผู้ติดต่อ', _contactCtrl),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              'เบอร์โทรศัพท์',
                              _phoneCtrl,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTextField(
                              'มือถือ (Mobile)',
                              _mobileCtrl,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      _buildTextField(
                        'อีเมล (E-Mail)',
                        _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),

                  _buildCardSection(
                    'ส่วนที่ 4: ข้อมูลธนาคาร (Payment Transaction)',
                    Icons.account_balance_rounded,
                    [
                      _buildDropdown(
                        'ธนาคาร (Bank Name)',
                        _selectedBank,
                        _bankList,
                        (v) => setState(() => _selectedBank = v),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              'สาขา (Branch)',
                              _bankBranchCtrl,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTextField(
                              'เลขที่บัญชี',
                              _bankAccountCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      _buildTextField(
                        'ชื่อบัญชี (Acct holder)',
                        _acctHolderCtrl,
                      ),
                    ],
                  ),

                  _buildCardSection(
                    'ส่วนที่ 5: ข้อมูลทางบัญชีและจัดซื้อ (SAP Data)',
                    Icons.settings_applications_rounded,
                    [
                      const Text(
                        'ข้อมูลภาษีหัก ณ ที่จ่าย (WHT)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildCheck(
                              title: 'ภ.ง.ด.3',
                              value: _isWht3,
                              onChanged: (v) => setState(() => _isWht3 = v!),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              'รหัส WHT (SAP)',
                              _wht3CodeCtrl,
                              hintText: 'เช่น 03',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildCheck(
                              title: 'ภ.ง.ด.53',
                              value: _isWht53,
                              onChanged: (v) => setState(() => _isWht53 = v!),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              'รหัส WHT (SAP)',
                              _wht53CodeCtrl,
                              hintText: 'เช่น 53',
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      const Text(
                        'รูปแบบการชำระหนี้ (Payment Method)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 15,
                        children: [
                          _buildCheck(
                            title: 'โอนเงิน',
                            value: _payTransfer,
                            onChanged: (v) => setState(() => _payTransfer = v!),
                          ),
                          _buildCheck(
                            title: 'เช็คธนาคาร',
                            value: _payCheque,
                            onChanged: (v) => setState(() => _payCheque = v!),
                          ),
                          _buildCheck(
                            title: 'ตั๋วสัญญาใช้เงิน',
                            value: _payPN,
                            onChanged: (v) => setState(() => _payPN = v!),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      _buildDropdown(
                        'Reconciliation Account',
                        _reconAccount,
                        [
                          '112020 เงินสดย่อยตั้งพัก',
                          '221010 เจ้าหนี้การค้า-บริษัทที่เกี่ยวข้องกัน',
                          '221020 เจ้าหนี้การค้า-ในประเทศ',
                          '221030 เจ้าหนี้การค้า-ต่างประเทศ',
                          '221040 เจ้าหนี้อื่น-บริษัทที่เกี่ยวข้องกัน',
                          '221050 เจ้าหนี้อื่น-ในประเทศ',
                          '221060 เจ้าหนี้อื่น-ต่างประเทศ',
                        ],
                        (v) => setState(() => _reconAccount = v!),
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildDropdown(
                              'เงื่อนไขการชำระเงิน',
                              _paymentTerm,
                              [
                                'S000 Due immediately/Cash',
                                'P030 Due on next month',
                                'S030 Due in 30 days',
                                'S045 Due in 45 days',
                                'S060 Due in 60 days',
                                'S090 Due in 90 days',
                                'S120 Due in 120 days',
                              ],
                              (v) => setState(() => _paymentTerm = v!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: _buildTextField('สกุลเงิน', _currencyCtrl),
                          ),
                        ],
                      ),
                      _buildDropdown(
                        'พนักงานจัดซื้อ (Purchasing Group)',
                        _purchasingGroup,
                        [
                          '101 อุปกรณ์สำนักงาน',
                          '102 จัดซื้ออะไหล่',
                          '103 จัดซื้อเหล็ก',
                          '104 จัดซื้อน้ำมัน',
                          '105 จัดซื้อยางมะตอย',
                          '106 วัสดุโครงการ',
                          '107 งานบริการ',
                          '108 โรงงานผลิต',
                        ],
                        (v) => setState(() => _purchasingGroup = v!),
                      ),

                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildCheck(
                                title: 'GR-based inv.verif',
                                value: _grBased,
                                onChanged: (v) => setState(() => _grBased = v!),
                              ),
                            ),
                            Expanded(
                              child: _buildCheck(
                                title: 'Srv-based inv.verif',
                                value: _srvBased,
                                onChanged: (v) =>
                                    setState(() => _srvBased = v!),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildTextField(
                        'สินค้า/บริการที่จัดจำหน่าย (พร้อมระบุยี่ห้อ)',
                        _productsCtrl,
                        maxLines: 2,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _existingReqId != null
                          ? Colors.orange.shade800
                          : Colors.green.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _submitAndPrintForm,
                    icon: const Icon(Icons.print_rounded),
                    label: Text(
                      _existingReqId != null
                          ? 'อัปเดตข้อมูล และพิมพ์ฟอร์ม (แก้ไข)'
                          : 'บันทึกข้อมูล และพิมพ์ฟอร์มเปิดบัญชี',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildCheck({
    required String title,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue.shade900,
        ),
        Text(title, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildCardSection(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade900, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator: isRequired
            ? (v) => v!.isEmpty ? 'กรุณากรอกข้อมูล' : null
            : null,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// 🌟 โมเดลสำหรับฐานข้อมูลที่อยู่
class ThaiAddress {
  final String subDistrict, district, province, zipCode;
  ThaiAddress({
    required this.subDistrict,
    required this.district,
    required this.province,
    required this.zipCode,
  });
}
