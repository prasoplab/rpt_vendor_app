import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rpt_models.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String scriptUrl =
      "https://script.google.com/macros/s/AKfycbx6GvQzNAHR4wu30XHpNzWgatMhZWUwVxKDN912nZtDqjWbwSKd8tatImuf8tGCQni3/exec";

  // 🌟 ฟังก์ชันตัวกลาง: จัดการปัญหา 302 Redirect พร้อมดักจับ URL ปลายทางและข้อความตอบกลับ
  static Future<http.Response?> _submitToGoogle(
    Map<String, String> body,
  ) async {
    try {
      debugPrint('=========================================');
      debugPrint('กำลังส่งข้อมูลไปที่ Google Apps Script...');
      var client = http.Client();
      var request = http.Request('POST', Uri.parse(scriptUrl))
        ..followRedirects = false
        ..bodyFields = body;

      var streamedResponse = await client.send(request);
      var response = await http.Response.fromStream(streamedResponse);

      // ถ้าเจอ 302 / 301
      if (response.statusCode == 302 || response.statusCode == 301) {
        String? redirectUrl = response.headers['location'];
        debugPrint('🚨 เจอ 302! เป้าหมายที่ Google เตะไปคือ: $redirectUrl');

        if (redirectUrl != null) {
          var redirectedResponse = await http.get(Uri.parse(redirectUrl));
          debugPrint(
            '✅ ข้อมูลจากลิงก์ใหม่ (รหัส ${redirectedResponse.statusCode}): ${redirectedResponse.body}',
          );
          return redirectedResponse;
        }
      } else {
        // ถ้ารหัสอื่นๆ (เช่น 200 สำเร็จ หรือ 500 พัง) ให้โชว์ออกมาเลย
        debugPrint('✅ Google ตอบกลับด้วยรหัส: ${response.statusCode}');
        debugPrint('📦 ข้อมูลที่ตอบกลับมา: ${response.body}');
      }
      debugPrint('=========================================');
      return response;
    } catch (e) {
      debugPrint("❌ HTTP Request Error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>> login(
    String empId,
    String password,
  ) async {
    var response = await _submitToGoogle({
      "action": "login",
      "emp_id": empId,
      "password": password,
    });

    if (response != null && response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {"status": "error"};
  }

  static Future<List<DirectorMatch>> checkRPT(
    List<String> names,
    String vendorName,
    String searchBy,
  ) async {
    var response = await _submitToGoogle({
      "action": "check_rpt",
      "names": json.encode(names),
      "vendor_name": vendorName,
      "search_by": searchBy,
    });

    if (response != null && response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data
          .map(
            (item) => DirectorMatch(
              name: item['name'],
              isMatch: item['isMatch'],
              relation: item['relation'],
              directorId: item['directorId'],
            ),
          )
          .toList();
    }
    return [];
  }

  static Future<bool> addDirector(Map<String, String> data) async {
    data["action"] = "add_director";
    var response = await _submitToGoogle(data);

    if (response != null && response.statusCode == 200) {
      return json.decode(response.body)['status'] == 'success';
    }
    return false;
  }

  static Future<List<String>> scanDocumentOcr(
    List<int> fileBytes,
    String fileName,
  ) async {
    String base64File = base64Encode(fileBytes);

    var response = await _submitToGoogle({
      "action": "ocr_scan",
      "file_name": fileName,
      "file_data": base64File,
    });

    if (response != null) {
      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        if (result['status'] == 'success') {
          return List<String>.from(result['names']);
        }
      }
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getAllDirectors() async {
    var response = await _submitToGoogle({"action": "get_all_directors"});

    if (response != null && response.statusCode == 200) {
      var result = json.decode(response.body);
      if (result['status'] == 'success') {
        return List<Map<String, dynamic>>.from(result['data']);
      }
    }
    return [];
  }

  static Future<bool> editDirector(Map<String, String> data) async {
    data["action"] = "edit_director";
    var response = await _submitToGoogle(data);

    if (response != null && response.statusCode == 200) {
      var result = json.decode(response.body);
      return result['status'] == 'success';
    }
    return false;
  }
}
