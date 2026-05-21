// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/email_model.dart';

// class EmailStorageService {
//   static const String _key = 'sent_emails';

//   static Future<void> save(EmailModel email) async {
//     final prefs = await SharedPreferences.getInstance();
//     final emails = await getAll();
//     emails.insert(0, email);
//     final jsonList = emails.map((e) => jsonEncode(e.toJson())).toList();
//     await prefs.setStringList(_key, jsonList);
//   }

//   static Future<List<EmailModel>> getAll() async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonList = prefs.getStringList(_key) ?? [];
//     return jsonList
//         .map((json) => EmailModel.fromJson(jsonDecode(json) as Map<String, dynamic>))
//         .toList();
//   }

//   static Future<void> delete(String id) async {
//     final prefs = await SharedPreferences.getInstance();
//     final emails = await getAll();
//     emails.removeWhere((e) => e.id == id);
//     final jsonList = emails.map((e) => jsonEncode(e.toJson())).toList();
//     await prefs.setStringList(_key, jsonList);
//   }
// }
