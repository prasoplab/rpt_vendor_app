import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🌟 ใส่ URL ของ Google Apps Script ของพี่ต้นตรงนี้
  static const String scriptUrl = 'https://script.google.com/macros/s/AKfycbxl01N5r_wjweW_AMlA8kE-P3vkDKU86kxSWNF3UmwlTdy1O16XnktaH1wYMgEScONJ/exec';

// ==========================================
  // ดึงข้อมูลกรรมการทั้งหมด (เวอร์ชันฟ้อง Error ออกหน้าจอ)
  // ==========================================
  static Future<List<Map<String, dynamic>>> getAllDirectors() async {
    try {
      final response = await http.post(Uri.parse(scriptUrl), body: {"action": "get_directors"});
      
      if (response.statusCode == 200 || response.statusCode == 302) {
        try {
          final result = jsonDecode(response.body);
          if (result['status'] == 'success') {
            List<dynamic> rawData = result['data'];
            return rawData.map((e) => {
              "director_id": e['id'],
              "first_name": e['firstName'],
              "last_name": e['lastName'],
              "relationship": e['relation'],
              "dob": e['dob'],
              "age_status": e['ageStatus'],
              "marital_status": e['maritalStatus'],
              "active_status": e['activeStatus'],
              "end_date": e['endDate']
            }).toList();
          } else {
            // 🌟 ฟ้อง Error จากฝั่ง Google Script
            return [{"first_name": "❌ GAS Error:", "last_name": result['message'], "active_status": "พ้นสภาพ"}];
          }
        } catch (e) {
          // 🌟 ฟ้อง Error กรณี Google ไม่ยอมส่ง JSON มาให้ (มักเกิดจากลืมทำ Anyone)
          return [{"first_name": "❌ ไม่ใช่ JSON", "last_name": "กรุณาเช็คการ Deploy", "active_status": "พ้นสภาพ"}];
        }
      }
      return [{"first_name": "❌ HTTP Error:", "last_name": response.statusCode.toString(), "active_status": "พ้นสภาพ"}];
    } catch (e) {
      return [{"first_name": "❌ Network Error:", "last_name": e.toString(), "active_status": "พ้นสภาพ"}];
    }
  }

  // ==========================================
  // แก้ไขข้อมูลกรรมการ
  // ==========================================
  static Future<bool> editDirector(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        body: {
          "action": "update_director",
          "directorId": data['director_id']?.toString() ?? "",
          "fullName": "${data['first_name']} ${data['last_name']}",
          "firstName": data['first_name']?.toString() ?? "",
          "lastName": data['last_name']?.toString() ?? "",
          "relation": data['relationship']?.toString() ?? "",
          "dob": data['dob']?.toString() ?? "",
          "ageStatus": data['age_status']?.toString() ?? "",
          "maritalStatus": data['marital_status']?.toString() ?? "",
          "activeStatus": data['active_status']?.toString() ?? "",
          "endDate": data['end_date']?.toString() ?? "-",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        final result = jsonDecode(response.body);
        return result['status'] == 'success';
      }
      return false;
    } catch (e) {
      print("Error editDirector: $e");
      return false;
    }
  }
  
  // (ถ้ามีฟังก์ชัน addDirector เดิมอยู่แล้ว ก็ปล่อยไว้ได้เลยครับ)
}