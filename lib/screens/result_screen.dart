import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:rpt_vendor_app/models/rpt_models.dart'; 

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

  // ฟังก์ชันตัวช่วย: วาดกล่อง Checkbox เวกเตอร์สี่เหลี่ยมจัตุรัสแบบเนี๊ยบ
  pw.Widget _buildPdfCheckbox({required bool isChecked}) {
    return pw.Container(
      width: 9,
      height: 9,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey700, width: 0.8),
        borderRadius: pw.BorderRadius.circular(1),
      ),
      child: isChecked
          ? pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2.5),
                child: pw.Text('/', style: pw.TextStyle(font: pw.Font.courierBold(), fontSize: 8, color: PdfColors.green800)),
              ),
            )
          : pw.SizedBox(),
    );
  }

  // ฟังก์ชันตัวช่วย: เปลี่ยนวงกลมแข็งๆ เป็นป้ายสถานะ (Badge) สไตล์โมเดิร์น สะอาดตา
  pw.Widget _buildStatusBadge({required bool isPass, required String text}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: pw.BoxDecoration(
        color: isPass ? PdfColors.green50 : PdfColors.red50,
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(color: isPass ? PdfColors.green200 : PdfColors.red200, width: 0.5),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8, 
          color: isPass ? PdfColors.green800 : PdfColors.red800,
        ),
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load('assets/fonts/THSarabunNew.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/THSarabunNew Bold.ttf');
    
    final fontRegular = pw.Font.ttf(fontData);
    final fontBold = pw.Font.ttf(fontBoldData);

    final mainTheme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);
    final String printDate = '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
    final bool isRptMatch = evalData.rptStatus == 'MATCH';
    final bool isScorePassed = evalData.totalScore >= 70;
    
    // ดักเงื่อนไขสายงานอนุมัติปลายทาง
    final bool needHighestApproval = !isScorePassed || isRptMatch;

    final List<List<String>> rptTableData = [
      ['ลำดับ', 'รายชื่อกรรมการที่ตรวจสอบ', 'ผลการตรวจสอบ RPT', 'ความสัมพันธ์ / ตำแหน่ง']
    ];
    for (int i = 0; i < searchResults.length; i++) {
      final res = searchResults[i];
      rptTableData.add([
        '${i + 1}',
        res.name,
        res.isMatch ? 'พบความเกี่ยวข้อง (RPT)' : 'ไม่พบความเกี่ยวข้อง',
        res.isMatch ? (res.relation ?? '-') : '-', 
      ]);
    }

    final List<List<String>> evalTableData = [
      ['ข้อ', 'เกณฑ์การประเมินซัพพลายเออร์รายใหม่', 'เต็ม', 'ได้', 'หลักฐาน / บันทึกความเห็นอื่นๆ'],
      ['1', 'Spec สินค้า ข้อกำหนดของผู้ขายสอดคล้องกับที่ต้องการ', '20', '${evalData.scoreSpec}', evalData.commentSpec],
      ['2', 'เงื่อนไขระยะเวลาการชำระเงิน (Credit Term)', '25', '${evalData.scorePayment}', evalData.commentPayment],
      ['3', 'ระยะเวลาในการส่งมอบสินค้า (Delivery Time)', '20', '${evalData.scoreDelivery}', evalData.commentDelivery],
      ['4', 'ความสนใจในลูกค้า และการอำนวยความสะดวกสบาย', '15', '${evalData.scoreService}', evalData.commentService],
      ['5', 'ระบบบริหารคุณภาพภายในบริษัท (ISO 9001)', '10', '${evalData.scoreIso9001}', evalData.commentIso9001],
      ['6', 'ระบบความปลอดภัยและสิ่งแวดล้อม (ISO 14001)', '10', '${evalData.scoreIso14001}', evalData.commentIso14001],
      ['', 'คะแนนรวมทั้งหมด', '100', '${evalData.totalScore}', '']
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        theme: mainTheme,
        margin: const pw.EdgeInsets.only(top: 25, bottom: 35, left: 30, right: 30),
        
        // บล็อกหัวกระดาษแสดงข้อมูลคู่ค้าในทุกหน้า
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('แบบฟอร์มการประเมินซัพพลายเออร์รายใหม่ และตรวจสอบบุคคลเกี่ยวโยง', style: pw.TextStyle(font: fontBold, fontSize: 13))),
              pw.SizedBox(height: 5),
              
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.5)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [
                      pw.Expanded(child: pw.Text('ชื่อผู้ขาย: ${evalData.vendorName}', style: pw.TextStyle(font: fontBold, fontSize: 10.5))),
                      pw.Expanded(child: pw.Text('ชื่อผู้ติดต่อ: ${evalData.contactPerson}', style: pw.TextStyle(font: fontRegular, fontSize: 10.5))),
                    ]),
                    pw.SizedBox(height: 2),
                    pw.Row(children: [
                      pw.Expanded(child: pw.Text('ประเภทสินค้า: ${evalData.productType}', style: pw.TextStyle(font: fontRegular, fontSize: 10.5))),
                      pw.Expanded(child: pw.Text('โทรศัพท์: ${evalData.phone}', style: pw.TextStyle(font: fontRegular, fontSize: 10.5))),
                    ]),
                    pw.SizedBox(height: 2),
                    pw.Text('ที่อยู่: ${evalData.address}', style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
              pw.SizedBox(height: 4),
            ],
          );
        },

        // 🌟 แก้ไขจัดระเบียบ Footer ใหม่: แทรกโค้ดควบคุม FM-AD-02_REV01_25671016 ไว้ซ้ายสุดเสมอกันทุกหน้า
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'FM-AD-02_REV01_25671016',
                  style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey700),
                ),
                pw.Text(
                  'หน้า ${context.pageNumber} / ${context.pagesCount}',
                  style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },

        build: (pw.Context context) {
          return [
            pw.Text('1. รายงานผลการตรวจสอบบุคคลเกี่ยวโยง (Related Party Transaction)', style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue900)),
            pw.SizedBox(height: 3),
            pw.TableHelper.fromTextArray(
              context: context,
              data: rptTableData,
              cellStyle: pw.TextStyle(font: fontRegular, fontSize: 9.5),
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              columnWidths: {0: const pw.FixedColumnWidth(25), 1: const pw.FlexColumnWidth(3), 2: const pw.FlexColumnWidth(2.5), 3: const pw.FlexColumnWidth(2.5)},
            ),
            pw.SizedBox(height: 10),

            // กล่องเช็คลิสต์ประเภทรายการ RPT ของสำนักเลขานุการบริษัท
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5), borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('สำหรับสำนักเลขานุการบริษัท ติ๊กตรวจสอบประเภทรายการบุคคลเกี่ยวโยง:', style: pw.TextStyle(font: fontBold, fontSize: 10.5, color: PdfColors.purple900)),
                  pw.SizedBox(height: 6),
                  
                  pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1.0), 
                      1: const pw.FlexColumnWidth(1.0), 
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3),
                            child: pw.Row(
                              children: [
                                _buildPdfCheckbox(isChecked: !isRptMatch),
                                pw.SizedBox(width: 5),
                                pw.Text('ไม่พบรายการที่เกี่ยวข้อง', style: pw.TextStyle(font: fontBold, fontSize: 10, color: !isRptMatch ? PdfColors.green800 : PdfColors.black)),
                              ]
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3),
                            child: pw.Row(
                              children: [
                                _buildPdfCheckbox(isChecked: false),
                                pw.SizedBox(width: 5),
                                pw.Text('รายการธุรกิจปกติ', style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                              ]
                            ),
                          ),
                        ]
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3),
                            child: pw.Row(
                              children: [
                                _buildPdfCheckbox(isChecked: false),
                                pw.SizedBox(width: 5),
                                pw.Text('รายการสนับสนุนธุรกิจปกติ', style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                              ]
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3),
                            child: pw.Row(
                              children: [
                                _buildPdfCheckbox(isChecked: false),
                                pw.SizedBox(width: 5),
                                pw.Text('รายการเช่าหรือให้เช่า อสังหาริมทรัพย์ไม่เกิน 3 ปี', style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                              ]
                            ),
                          ),
                        ]
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3),
                            child: pw.Row(
                              children: [
                                _buildPdfCheckbox(isChecked: false),
                                pw.SizedBox(width: 5),
                                pw.Text('รายการเกี่ยวกับทรัพย์สินหรือบริการ', style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                              ]
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 3),
                            child: pw.Row(
                              children: [
                                _buildPdfCheckbox(isChecked: false),
                                pw.SizedBox(width: 5),
                                pw.Text('รายการให้หรือรับความช่วยเหลือทางการเงิน', style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                              ]
                            ),
                          ),
                        ]
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            pw.Text('2. ตารางเกณฑ์คะแนนสรุปการประเมินศักยภาพซัพพลายเออร์', style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue900)),
            pw.SizedBox(height: 3),
            pw.TableHelper.fromTextArray(
              context: context,
              data: evalTableData,
              cellStyle: pw.TextStyle(font: fontRegular, fontSize: 9), 
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              columnWidths: {0: const pw.FixedColumnWidth(18), 1: const pw.FlexColumnWidth(3.5), 2: const pw.FixedColumnWidth(22), 3: const pw.FixedColumnWidth(22), 4: const pw.FlexColumnWidth(3.5)},
            ),
            pw.SizedBox(height: 8),

            // กล่องบทสรุปผลประเมินตัวเนี๊ยบ
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(color: PdfColors.grey50, border: pw.Border.all(color: PdfColors.grey300, width: 0.5), borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('บทสรุปผลการตรวจสอบและประเมินผล:', style: pw.TextStyle(font: fontBold, fontSize: 10.5, color: PdfColors.black)),
                  pw.SizedBox(height: 6),
                  
                  pw.Table(
                    columnWidths: {
                      0: const pw.FixedColumnWidth(40), 
                      1: const pw.FlexColumnWidth(1.0), 
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: _buildStatusBadge(isPass: isScorePassed, text: isScorePassed ? 'PASS' : 'ALERT'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2, left: 6),
                            child: pw.Text(
                              'ด้านคะแนนประเมิน: ${isScorePassed ? "ผ่านเกณฑ์มาตรฐาน" : "ต่ำกว่าเกณฑ์มาตรฐาน"} (${evalData.totalScore} คะแนน)',
                              style: pw.TextStyle(font: fontBold, fontSize: 10, color: isScorePassed ? PdfColors.green800 : PdfColors.red800)
                            ),
                          ),
                        ]
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: _buildStatusBadge(isPass: !isRptMatch, text: !isRptMatch ? 'PASS' : 'ALERT'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2, left: 6),
                            child: pw.Text(
                              'ด้านประวัติบุคคลเกี่ยวโยง (RPT): ${!isRptMatch ? "ไม่พบความเกี่ยวข้อง" : "พบประวัติความเกี่ยวข้อง"}',
                              style: pw.TextStyle(font: fontBold, fontSize: 10, color: !isRptMatch ? PdfColors.green800 : PdfColors.purple800)
                            ),
                          ),
                        ]
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 4),
                            child: _buildStatusBadge(isPass: (isScorePassed && !isRptMatch), text: (isScorePassed && !isRptMatch) ? 'RESULT' : 'ACTION'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 4, left: 6),
                            child: pw.Text(
                              'สรุปผลลัพธ์: ${(isScorePassed && !isRptMatch) ? "อนุมัติผลอัตโนมัติ (เสนอลงนามตามขั้นตอนจัดซื้อปกติ)" : "ต้องนำเสนอพิจารณาอนุมัติเป็นกรณีพิเศษตามสายงาน"}',
                              style: pw.TextStyle(font: fontBold, fontSize: 10.5, color: (isScorePassed && !isRptMatch) ? PdfColors.blue900 : PdfColors.red900)
                            ),
                          ),
                        ]
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 25), 

            // ตารางกระจายระยะบล็อกลงนามท้ายฟอร์ม
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 140,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('ผู้จัดทำรายการประเมิน', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900)),
                      pw.SizedBox(height: 16), 
                      pw.Container(
                        width: 125,
                        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.5))),
                        child: pw.Center(child: pw.Text(userName, style: pw.TextStyle(font: fontRegular, fontSize: 9.5))),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('วันที่: $printDate', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                ),
                
                pw.Spacer(), 

                if (isRptMatch) ...[
                  pw.Container(
                    width: 140,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('สำนักเลขานุการบริษัท', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.purple900)),
                        pw.SizedBox(height: 16), 
                        pw.Container(
                          width: 125,
                          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.5))),
                          child: pw.Center(child: pw.Text('(..................................................)', style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey400))),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('สถานะ: ตรวจสอบประวัติ RPT', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.purple800)),
                        pw.Text('วันที่อนุมัติ: ...... / ...... / ......', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Spacer(), 
                ],

                pw.Container(
                  width: 140,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(needHighestApproval ? 'ผู้ตรวจสอบ (จัดซื้อ)' : 'ผู้อนุมัติผลการคัดเลือก', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blue900)),
                      pw.SizedBox(height: 16), 
                      pw.Container(
                        width: 125,
                        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.5))),
                        child: pw.Center(child: pw.Text('(..................................................)', style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey400))),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('ตำแหน่ง: ผู้จัดการแผนกจัดซื้อ', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey800)),
                      pw.SizedBox(height: 2),
                      pw.Text('วันที่อนุมัติ: ...... / ...... / ......', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                ),

                if (needHighestApproval) ...[
                  pw.Spacer(),
                  pw.Container(
                    width: 140,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('ผู้อนุมัติกรณีพิเศษ', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.red900)),
                        pw.SizedBox(height: 16), 
                        pw.Container(
                          width: 125,
                          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.5))),
                          child: pw.Center(child: pw.Text('(..................................................)', style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey400))),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('ตำแหน่ง: ประธานเจ้าหน้าที่สายงานบริหารงานทั่วไป', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.grey800)),
                        pw.SizedBox(height: 2),
                        pw.Text('วันที่อนุมัติ: ...... / ...... / ......', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สรุปผลการประเมินซัพพลายเออร์', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, size: 26),
            tooltip: 'พิมพ์ใบอนุมัติรวม PDF',
            onPressed: () async {
              await Printing.layoutPdf(
                onLayout: (PdfPageFormat format) async => _generatePdf(format),
                name: 'Evaluation_Report_${evalData.vendorName}.pdf',
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Card(
              color: (evalData.isAutoApproved && evalData.rptStatus != 'MATCH') ? Colors.green.shade50 : Colors.orange.shade50,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      (evalData.isAutoApproved && evalData.rptStatus != 'MATCH') ? Icons.verified_user_rounded : Icons.assignment_late_rounded,
                      size: 44,
                      color: (evalData.isAutoApproved && evalData.rptStatus != 'MATCH') ? Colors.green.shade800 : Colors.orange.shade900,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          Text(evalData.vendorName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('คะแนนรวม: ${evalData.totalScore} / 100 คะแนน  |  สถานะ RPT: ${evalData.rptStatus}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                            evalData.rptStatus == 'MATCH'
                                ? '⚠️ สายงานอนุมัติ: ผ่านสำนักเลขาฯ ➡️ จัดซื้อ ➡️ ประธานเจ้าหน้าที่สายงานฯ'
                                : (evalData.isAutoApproved ? '✅ สายงานอนุมัติ: ผู้จัดการแผนกจัดซื้ออนุมัติ' : '⚠️ สายงานอนุมัติ: จัดซื้อ ➡️ ประธานเจ้าหน้าที่สายงานบริหารทั่วไป'),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: evalData.rptStatus == 'MATCH' ? Colors.purple.shade900 : (evalData.isAutoApproved ? Colors.green.shade900 : Colors.red.shade900)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 14),
            const Text('รายละเอียดคะแนนและบันทึกความเห็น:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: ListView(
                  children: [
                    _buildAppGridRow('1. ด้าน Spec คุณภาพสินค้า', '${evalData.scoreSpec} คะแนน', evalData.commentSpec),
                    _buildAppGridRow('2. เงื่อนไขระยะเวลาชำระเงิน', '${evalData.scorePayment} คะแนน', evalData.commentPayment),
                    _buildAppGridRow('3. ระยะเวลาการส่งมอบสินค้า', '${evalData.scoreDelivery} คะแนน', evalData.commentDelivery),
                    _buildAppGridRow('4. ด้านการบริการดูแลลูกค้า', '${evalData.scoreService} คะแนน', evalData.commentService),
                    _buildAppGridRow('5. ระบบมาตรฐาน ISO 9001', '${evalData.scoreIso9001} คะแนน', evalData.commentIso9001),
                    _buildAppGridRow('6. ระบบความปลอดภัย ISO 14001', '${evalData.scoreIso14001} คะแนน', evalData.commentIso14001),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: evalData.rptStatus == 'MATCH' ? Colors.purple.shade900 : (evalData.isAutoApproved ? Colors.blue.shade900 : Colors.deepOrange.shade900),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  await Printing.layoutPdf(
                    onLayout: (PdfPageFormat format) async => _generatePdf(format),
                    name: 'Evaluation_Report_${evalData.vendorName}.pdf',
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: Text(
                  evalData.rptStatus == 'MATCH' ? 'ออกใบพิมพ์อนุมัติผ่านสำนักเลขาฯ (PDF)' : 'ออกใบพิมพ์รายงานอนุมัติมาตรฐาน (PDF)', 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppGridRow(String criteriaName, String scoreValue, String comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(criteriaName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Text(scoreValue, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
            ],
          ),
          const SizedBox(height: 1),
          Text('บันทึกความเห็น: $comment', style: TextStyle(fontSize: 11.5, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
          const Divider(height: 12),
        ],
      ),
    );
  }
}