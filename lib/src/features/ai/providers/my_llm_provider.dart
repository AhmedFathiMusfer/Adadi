// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
// import 'package:firebase_ai/firebase_ai.dart';

// class MyLlmProvider extends ChangeNotifier implements LlmProvider {
//   MyLlmProvider({
//     required GenerativeModel model,
//     Iterable<ChatMessage>? history,
//   })  : _model = model,
//         _history = history?.toList() ?? [] {
//     _chat = _startChat(_history);
//   }

//   final GenerativeModel _model;
//   final List<ChatMessage> _history;
//   Chat? _chat;

//   static Part _partFrom(Attachment attachment) {
//     if (attachment is FileAttachment) {
//       return DataPart(attachment.mimeType, attachment.bytes);
//     } else if (attachment is LinkAttachment) {
//       return FilePart(attachment.url);
//     }
//     throw UnsupportedError('Unsupported attachment type');
//   }

//   static Content _contentFrom(ChatMessage message) => Content(
//         message.origin.isUser ? 'user' : 'model',
//         [
//           TextPart(message.text ?? ''),
//           ...message.attachments.map(_partFrom),
//         ],
//       );

//   Chat _startChat(Iterable<ChatMessage> history) {
//     // If the underlying SDK supports starting a chat with existing history,
//     // map history to the SDK type here. For now start a fresh chat.
//     return _model.startChat();
//   }

//   @override
//   Stream<String> generateStream(
//     String prompt, {
//     Iterable<Attachment> attachments = const [],
//   }) =>
//       _generateStream(
//         prompt: prompt,
//         attachments: attachments,
//         contentStreamGenerator: (c) => _model.generateContentStream([c]),
//       );

//   @override
//   Stream<String> sendMessageStream(
//     String prompt, {
//     Iterable<Attachment> attachments = const [],
//   }) async* {
//     final userMessage = ChatMessage.user(prompt, attachments);
//     final llmMessage = ChatMessage.llm();
//     _history.addAll([userMessage, llmMessage]);

//     final response = _generateStream(
//       prompt: prompt,
//       attachments: attachments,
//       contentStreamGenerator: _chat!.sendMessageStream,
//     );

//     yield* response.map((chunk) {
//       llmMessage.append(chunk);
//       return chunk;
//     });

//     notifyListeners();
//   }

//   Stream<String> _generateStream({
//     required String prompt,
//     required Iterable<Attachment> attachments,
//     required Stream<GenerateContentResponse> Function(Content)
//         contentStreamGenerator,
//   }) async* {
//     final content = Content('user', [
//       TextPart(prompt),
//       ...attachments.map(_partFrom),
//     ]);

//     final response = contentStreamGenerator(content);
//     yield* response
//         .map((chunk) => chunk.text)
//         .where((text) => text != null)
//         .cast<String>();
//   }

//   @override
//   Iterable<ChatMessage> get history => List.unmodifiable(_history);

//   @override
//   set history(Iterable<ChatMessage> history) {
//     _history
//       ..clear()
//       ..addAll(history);
//     _chat = _startChat(_history);
//     notifyListeners();
//   }
// }
