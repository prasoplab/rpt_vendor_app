class SupplierEvaluation {
  String vendorName = '';
  String productType = '';
  String address = '';
  String contactPerson = '';
  String phone = '';
  
  // คะแนนแยกแต่ละข้อ
  int scoreSpec = 0;
  int scorePayment = 0;
  int scoreDelivery = 0;
  int scoreService = 0;
  int scoreIso9001 = 0;
  int scoreIso14001 = 0;

  // 🌟 บังคับประกาศตัวแปรเก็บข้อความบันทึกความเห็นแยกแต่ละข้อให้ระบบรู้จักชัดเจน
  String commentSpec = '';
  String commentPayment = '';
  String commentDelivery = '';
  String commentService = '';
  String commentIso9001 = '';
  String commentIso14001 = '';
  
  String rptStatus = 'CLEAR'; 

  int get totalScore => scoreSpec + scorePayment + scoreDelivery + scoreService + scoreIso9001 + scoreIso14001;

  // เงื่อนไขผ่านอัตโนมัติ (>= 70 คะแนน และ RPT ต้อง CLEAR)
  bool get isAutoApproved => totalScore >= 70 && rptStatus == 'CLEAR';
}

class DirectorMatch {
  final String? directorId; 
  final String name;
  final bool isMatch;
  final String? relation;

  DirectorMatch({
    this.directorId, 
    required this.name,
    required this.isMatch,
    this.relation,
  });
}