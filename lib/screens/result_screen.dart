import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:rpt_vendor_app/models/rpt_models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:rpt_vendor_app/screens/vendor_registration_screen.dart'; // 🌟 เรียกใช้หน้าฟอร์ม SAP

class ResultScreen extends StatelessWidget {
  final String userName;
  final SupplierEvaluation evalData;
  final List<DirectorMatch> searchResults;

  const ResultScreen({
    super.key,
    required this.userName,
    required this.evalData,
    required this.searchResults,
  });

  Future<void> _printPdfDocument(BuildContext context) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => await _generatePdf(format));
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();

    bool hasRpt = searchResults.any((element) => element.isMatch == true);
    bool isPassed = evalData.totalScore >= 70;
    
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year + 543}';

    pw.Widget pdfCheckbox(String text, {bool isChecked = false, PdfColor textColor = PdfColors.black}) {
      return pw.Row(children: [
        pw.Container(
          width: 10, height: 10, 
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1, color: PdfColors.black)),
          child: isChecked ? pw.Center(child: pw.Text('X', style: pw.TextStyle(font: fontBold, fontSize: 8, color: textColor))) : null,
        ),
        pw.SizedBox(width: 5),
        pw.Text(text, style: pw.TextStyle(font: isChecked ? fontBold : fontRegular, fontSize: 10, color: textColor)),
      ]);
    }

    List<pw.Widget> getSignatureBlocks() {
      List<pw.Widget> blocks = [];

      blocks.add(
        pw.Column(children: [
          pw.Text('ผู้จัดทำรายการประเมิน', style: pw.TextStyle(fontSize: 9, color: PdfColors.blue900, fontBold: fontBold)),
          pw.SizedBox(height: 20),
          pw.Container(height: 0.5, width: 80, color: PdfColors.black), 
          pw.SizedBox(height: 4),
          pw.Text(userName, style: pw.TextStyle(fontSize: 9)),
          pw.Text('วันที่ $dateStr', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ])
      );

      if (hasRpt) {
        blocks.add(
          pw.Column(children: [
            pw.Text('สำนักเลขานุการบริษัท', style: pw.TextStyle(fontSize: 9, color: PdfColors.purple900, fontBold: fontBold)),
            pw.SizedBox(height: 20),
            pw.Container(height: 0.5, width: 80, color: PdfColors.black),
            pw.SizedBox(height: 4),
            pw.Text('สถานะ: ตรวจสอบประวัติ RPT', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.Text('วันที่อนุมัติ......./......./.......', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ])
        );
      }

      blocks.add(
        pw.Column(children: [
          pw.Text('ผู้ตรวจสอบ (จัดซื้อ)', style: pw.TextStyle(fontSize: 9, color: PdfColors.blue900, fontBold: fontBold)),
          pw.SizedBox(height: 20),
          pw.Container(height: 0.5, width: 80, color: PdfColors.black),
          pw.SizedBox(height: 4),
          pw.Text('ตำแหน่ง: ผู้จัดการแผนกจัดซื้อ', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.Text('วันที่อนุมัติ......./......./.......', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ])
      );

      if (hasRpt || !isPassed) {
        blocks.add(
          pw.Column(children: [
            pw.Text('ผู้อนุมัติกรณีพิเศษ', style: pw.TextStyle(fontSize: 9, color: PdfColors.red900, fontBold: fontBold)),
            pw.SizedBox(height: 20),
            pw.Container(height: 0.5, width: 80, color: PdfColors.black),
            pw.SizedBox(height: 4),
            pw.Text('ปธ.เจ้าหน้าที่สายงานบริหารทั่วไป', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.Text('วันที่อนุมัติ......./......./.......', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ])
        );
      }

      return blocks;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (pw.Context context) {
          return [
            pw.Center(child: pw.Text('แบบฟอร์มการประเมินซัพพลายเออร์รายใหม่ และตรวจสอบบุคคลเกี่ยวโยง', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 10),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('ชื่อผู้ขาย: ${evalData.vendorName}', style: pw.TextStyle(fontSize: 11)),
                    pw.SizedBox(height: 4),
                    pw.Text('ประเภทสินค้า: ${evalData.productType}', style: pw.TextStyle(fontSize: 11)),
                    pw.SizedBox(height: 4),
                    pw.Text('ที่อยู่: ${evalData.address}', style: pw.TextStyle(fontSize: 11)),
                  ])),
                  pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('ชื่อผู้ติดต่อ: ${evalData.contactPerson}', style: pw.TextStyle(fontSize: 11)),
                    pw.SizedBox(height: 4),
                    pw.Text('โทรศัพท์: ${evalData.phone}', style: pw.TextStyle(fontSize: 11)),
                  ])),
                ]
              )
            ),
            pw.SizedBox(height: 10),

            pw.Text('1. รายงานผลการตรวจสอบบุคคลเกี่ยวโยง (Related Party Transaction)', style: pw.TextStyle(fontSize: 11, color: PdfColors.blue900, fontBold: fontBold)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: ['ลำดับ', 'รายชื่อกรรมการที่ตรวจสอบ', 'ผลการตรวจสอบ RPT', 'ความสัมพันธ์ / ตำแหน่ง'],
              data: searchResults.isEmpty 
                ? [['-', 'ไม่มีการระบุรายชื่อกรรมการ', '-', '-']]
                : searchResults.asMap().entries.map((e) => [
                    '${e.key + 1}', e.value.name, 
                    e.value.isMatch ? 'พบประวัติเกี่ยวโยง' : 'ไม่พบรายการที่เกี่ยวข้อง', 
                    e.value.relation ?? '-'
                  ]).toList(),
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              cellStyle: pw.TextStyle(font: fontRegular, fontSize: 10),
              cellAlignment: pw.Alignment.center,
              columnWidths: {0: const pw.FlexColumnWidth(1), 1: const pw.FlexColumnWidth(4), 2: const pw.FlexColumnWidth(3), 3: const pw.FlexColumnWidth(3)},
            ),
            pw.SizedBox(height: 6),

            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('สำหรับสำนักเลขานุการบริษัท ติ๊กตรวจสอบประเภทรายการบุคคลเกี่ยวโยง:', style: pw.TextStyle(fontSize: 10, color: hasRpt ? PdfColors.red900 : PdfColors.green800, fontBold: fontBold)),
                  pw.SizedBox(height: 6),
                  
                  if (!hasRpt) ...[
                    pdfCheckbox('ไม่พบรายการที่เกี่ยวข้อง', isChecked: true, textColor: PdfColors.green800),
                  ] else ...[
                    pw.Row(children: [
                      pw.Expanded(child: pdfCheckbox('พบรายการที่เกี่ยวข้อง', isChecked: true, textColor: PdfColors.red900)),
                      pw.Expanded(child: pdfCheckbox('รายการธุรกิจปกติ')),
                    ]),
                    pw.SizedBox(height: 4),
                    pw.Row(children: [
                      pw.Expanded(child: pdfCheckbox('รายการสนับสนุนธุรกิจปกติ')),
                      pw.Expanded(child: pdfCheckbox('รายการเช่าหรือให้เช่า อสังหาฯไม่เกิน 3 ปี')),
                    ]),
                    pw.SizedBox(height: 4),
                    pw.Row(children: [
                      pw.Expanded(child: pdfCheckbox('รายการเกี่ยวกับทรัพย์สินหรือบริการ')),
                      pw.Expanded(child: pdfCheckbox('รายการให้หรือรับความช่วยเหลือทางการเงิน')),
                    ]),
                  ]
                ]
              )
            ),
            pw.SizedBox(height: 10),

            pw.Text('2. ตารางเกณฑ์คะแนนสรุปการประเมินศักยภาพซัพพลายเออร์ (${evalData.evaluationType})', style: pw.TextStyle(fontSize: 11, color: PdfColors.blue900, fontBold: fontBold)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: ['ข้อ', 'เกณฑ์การประเมินซัพพลายเออร์รายใหม่', 'เต็ม', 'ได้', 'หลักฐาน / บันทึกความเห็น อื่นๆ'],
              data: evalData.evaluationType == 'ร้านค้า' 
              ? [
                ['1', 'Spec สินค้า ข้อกำหนดของผู้ขายสอดคล้องกับข้อกำหนด...', '20', '${evalData.scoreSpec}', evalData.commentSpec],
                ['2', 'เงื่อนไขระยะเวลาการชำระเงิน (Credit Term)', '25', '${evalData.scorePayment}', evalData.commentPayment],
                ['3', 'ระยะเวลาในการส่งมอบสินค้า (Delivery Time)', '20', '${evalData.scoreDelivery}', evalData.commentDelivery],
                ['4', 'ความสนใจในลูกค้า และการอำนวยความสะดวกสบาย', '15', '${evalData.scoreService}', evalData.commentService],
                ['5', 'ระบบบริหารคุณภาพภายในบริษัท (ISO 9001)', '10', '${evalData.scoreIso9001}', evalData.commentIso9001],
                ['6', 'ระบบความปลอดภัยและสิ่งแวดล้อม (ISO 14001/45001)', '10', '${evalData.scoreIso14001}', evalData.commentIso14001],
                ['', 'คะแนนรวมทั้งหมด', '100', '${evalData.totalScore}', ''],
              ]
              : [
                ['1', 'ประสบการณ์และผลงานในอดีต / ปัจจุบัน', '30', '${evalData.scoreExperience}', evalData.commentExperience],
                ['2', 'ความพร้อมที่จะเข้าดำเนินการหลังการสั่งจ้าง', '30', '${evalData.scoreReadiness}', evalData.commentReadiness],
                ['3', 'ความสนใจในลูกค้า และการอำนวยความสะดวกสบาย', '20', '${evalData.scoreService}', evalData.commentService],
                ['4', 'ระบบบริหารคุณภาพภายในบริษัท (ISO 9001)', '10', '${evalData.scoreIso9001}', evalData.commentIso9001],
                ['5', 'ระบบความปลอดภัยและสิ่งแวดล้อม (ISO 14001/45001)', '10', '${evalData.scoreIso14001}', evalData.commentIso14001],
                ['', 'คะแนนรวมทั้งหมด', '100', '${evalData.totalScore}', ''],
              ],
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              cellStyle: pw.TextStyle(font: fontRegular, fontSize: 10),
              cellAlignment: pw.Alignment.center,
              columnWidths: {0: const pw.FlexColumnWidth(1), 1: const pw.FlexColumnWidth(5), 2: const pw.FlexColumnWidth(1), 3: const pw.FlexColumnWidth(1), 4: const pw.FlexColumnWidth(4)},
            ),
            pw.SizedBox(height: 10),

            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('บทสรุปผลการตรวจสอบและประเมินผล:', style: pw.TextStyle(fontSize: 11, fontBold: fontBold)),
                  pw.SizedBox(height: 6),
                  pw.Row(children: [
                    pw.Container(width: 40, padding: const pw.EdgeInsets.all(2), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.green), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))), child: pw.Center(child: pw.Text('PASS', style: pw.TextStyle(color: PdfColors.green, fontSize: 8, fontBold: fontBold)))),
                    pw.SizedBox(width: 10),
                    pw.Text('ด้านคะแนนประเมิน: ${isPassed ? 'ผ่านเกณฑ์มาตรฐาน' : 'ไม่ผ่านเกณฑ์'} (${evalData.totalScore} คะแนน)', style: pw.TextStyle(fontSize: 10, color: isPassed ? PdfColors.green800 : PdfColors.red800)),
                  ]),
                  pw.SizedBox(height: 4),
                  pw.Row(children: [
                    pw.Container(width: 40, padding: const pw.EdgeInsets.all(2), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.orange), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))), child: pw.Center(child: pw.Text('ALERT', style: pw.TextStyle(color: PdfColors.orange, fontSize: 8, fontBold: fontBold)))),
                    pw.SizedBox(width: 10),
                    pw.Text('ด้านประวัติบุคคลเกี่ยวโยง (RPT): ${hasRpt ? 'พบประวัติความเกี่ยวข้อง' : 'ไม่พบประวัติความเกี่ยวข้อง'}', style: pw.TextStyle(fontSize: 10, color: hasRpt ? PdfColors.orange800 : PdfColors.green800)),
                  ]),
                  pw.SizedBox(height: 4),
                  pw.Row(children: [
                    pw.Container(width: 40, padding: const pw.EdgeInsets.all(2), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.red), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))), child: pw.Center(child: pw.Text('ACTION', style: pw.TextStyle(color: PdfColors.red, fontSize: 8, fontBold: fontBold)))),
                    pw.SizedBox(width: 10),
                    pw.Text('สรุปผลลัพธ์: ${hasRpt || !isPassed ? 'ต้องนำเสนอพิจารณาอนุมัติเป็นกรณีพิเศษสายงาน' : 'สามารถอนุมัติตามสายงานปกติได้'}', style: pw.TextStyle(fontSize: 10, color: hasRpt || !isPassed ? PdfColors.red800 : PdfColors.green800)),
                  ]),
                ]
              )
            ),
            pw.SizedBox(height: 25),

            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: getSignatureBlocks().map((block) => pw.Expanded(child: block)).toList(),
            )
          ];
        },
      ),
    );
    return pdf.save();
  }

  // ==========================================
  // UI หน้าจอโทรศัพท์
  // ==========================================
  @override
  Widget build(BuildContext context) {
    bool isPassed = evalData.totalScore >= 70;
    bool hasRpt = searchResults.any((element) => element.isMatch);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('สรุปผลการประเมิน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 10),
            const Text('เตรียมเอกสารเสร็จสมบูรณ์', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('ซัพพลายเออร์: ${evalData.vendorName}', style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPassed ? Colors.green.shade50 : Colors.red.shade50,
                border: Border.all(color: isPassed ? Colors.green.shade300 : Colors.red.shade300),
                borderRadius: BorderRadius.circular(8)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('คะแนนประเมินรวม: ', style: TextStyle(fontSize: 16, color: isPassed ? Colors.green.shade900 : Colors.red.shade900)),
                  Text('${evalData.totalScore} / 100', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isPassed ? Colors.green.shade900 : Colors.red.shade900)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () => _printPdfDocument(context),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('ดูตัวอย่าง และพิมพ์รายงาน PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),

            // 🌟 ปุ่มกระโดดไปหน้าฟอร์มกรอกข้อมูลขอเปิดบัญชี (SAP) เพิ่มเข้ามาตรงนี้!
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VendorRegistrationScreen(
                        userName: userName, // ส่งชื่อพนักงานไป
                        initialVendorName: evalData.vendorName, // ดึงชื่อซัพพลายเออร์ที่เพิ่งประเมินเสร็จไปใส่ฟอร์มให้เลย!
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.app_registration_rounded),
                label: const Text('ขอเปิดหน้าบัญชีร้านค้า (SAP)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.blue.shade900, side: BorderSide(color: Colors.blue.shade900), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.home),
                label: const Text('กลับหน้าหลัก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}