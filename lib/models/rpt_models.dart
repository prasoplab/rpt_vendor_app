class SupplierEvaluation {
  String? evalId; // 🌟 เพิ่มไอดีไว้ใช้อ้างอิงตอนแก้ไข
  String? timestamp;

  String vendorName = '';
  String productType = '';
  String address = '';
  String contactPerson = '';
  String phone = '';
  
  String evaluationType = 'ร้านค้า';

  int scoreSpec = 0;
  int scorePayment = 0;
  int scoreDelivery = 0;
  int scoreService = 0;
  int scoreIso9001 = 0;
  int scoreIso14001 = 0;

  String commentSpec = '';
  String commentPayment = '';
  String commentDelivery = '';
  String commentService = '';
  String commentIso9001 = '';
  String commentIso14001 = '';
  
  int scoreExperience = 0; 
  int scoreReadiness = 0;  

  String commentExperience = '';
  String commentReadiness = '';

  String rptStatus = 'CLEAR'; 
SupplierEvaluation();
  int get totalScore {
    if (evaluationType == 'ผู้รับเหมา') {
      return scoreExperience + scoreReadiness + scoreService + scoreIso9001 + scoreIso14001;
    } else {
      return scoreSpec + scorePayment + scoreDelivery + scoreService + scoreIso9001 + scoreIso14001;
    }
  }

  bool get isAutoApproved => totalScore >= 70;

  // 🌟 ฟังก์ชันแปลงข้อมูลจาก Google Sheet กลับมาเป็น Object
  factory SupplierEvaluation.fromJson(Map<String, dynamic> json) {
    SupplierEvaluation eval = SupplierEvaluation();
    eval.evalId = json['evalId']?.toString();
    eval.timestamp = json['timestamp']?.toString();
    eval.vendorName = json['vendorName']?.toString() ?? '';
    eval.productType = json['productType']?.toString() ?? '';
    eval.address = json['address']?.toString() ?? '';
    eval.contactPerson = json['contactPerson']?.toString() ?? '';
    eval.phone = json['phone']?.toString() ?? '';
    eval.evaluationType = json['evaluationType']?.toString() ?? 'ร้านค้า';
    eval.rptStatus = json['rptStatus']?.toString() ?? 'CLEAR';

    eval.scoreSpec = int.tryParse(json['scoreSpec']?.toString() ?? '0') ?? 0;
    eval.scorePayment = int.tryParse(json['scorePayment']?.toString() ?? '0') ?? 0;
    eval.scoreDelivery = int.tryParse(json['scoreDelivery']?.toString() ?? '0') ?? 0;
    eval.scoreService = int.tryParse(json['scoreService']?.toString() ?? '0') ?? 0;
    eval.scoreIso9001 = int.tryParse(json['scoreIso9001']?.toString() ?? '0') ?? 0;
    eval.scoreIso14001 = int.tryParse(json['scoreIso14001']?.toString() ?? '0') ?? 0;
    eval.scoreExperience = int.tryParse(json['scoreExperience']?.toString() ?? '0') ?? 0;
    eval.scoreReadiness = int.tryParse(json['scoreReadiness']?.toString() ?? '0') ?? 0;

    eval.commentSpec = json['commentSpec']?.toString() ?? '';
    eval.commentPayment = json['commentPayment']?.toString() ?? '';
    eval.commentDelivery = json['commentDelivery']?.toString() ?? '';
    eval.commentService = json['commentService']?.toString() ?? '';
    eval.commentIso9001 = json['commentIso9001']?.toString() ?? '';
    eval.commentIso14001 = json['commentIso14001']?.toString() ?? '';
    eval.commentExperience = json['commentExperience']?.toString() ?? '';
    eval.commentReadiness = json['commentReadiness']?.toString() ?? '';

    return eval;
  }
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