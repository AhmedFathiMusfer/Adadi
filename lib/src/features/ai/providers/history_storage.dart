// import 'dart:convert';

// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

// class HistoryStorage {
//   static const _kKey = 'llm_history_v1';

//   static Future<void> saveHistory(Iterable<ChatMessage> history) async {
//     final prefs = await SharedPreferences.getInstance();
//     final list = history
//         .map((m) => {
//               'origin': m.origin.isUser ? 'user' : 'model',
//               'text': m.text ?? '',
//             })
//         .toList();
//     await prefs.setString(_kKey, jsonEncode(list));
//   }

//   static Future<List<ChatMessage>> loadHistory() async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonStr = prefs.getString(_kKey);
//     if (jsonStr == null) return [];
//     final parsed = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
//     return parsed.map((m) {
//       final origin = m['origin'] as String? ?? 'user';
//       final text = m['text'] as String? ?? '';
//       if (origin == 'user') {
//         return ChatMessage.user(text);
//       } else {
//         final msg = ChatMessage.llm();
//         if (text.isNotEmpty) msg.append(text);
//         return msg;
//       }
//     }).toList();
//   }
// }
