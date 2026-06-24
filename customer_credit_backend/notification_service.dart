import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// ናይ መልእኽቲ መለኣኺ ኣገልግሎት (Telegram + SMS)
class NotificationService {
  // ⚠️ ኣብዚኣ ነታ ካብ @BotFather ዝረኸብካያ Token ብልክዕ ተክኣያ!
  final String botToken;

  NotificationService({
    this.botToken = "YOUR_TELEGRAM_BOT_TOKEN_HERE",
  });

  /// 🤖 📲 ቀንዲ ፈንክሽን መልእኽቲ መለኣኺ (Telegram + SMS Alternative)
  Future<void> send({
    required String message,
    required String phone,
    required String chatId,
  }) async {
    // 1. እቲ ዓሚል Chat ID እንተሃልይዎ ብቴሌግራም ክሰድድ ይፍትን
    if (chatId != "0" && botToken != "YOUR_TELEGRAM_BOT_TOKEN_HERE") {
      final url = Uri.parse(
        "https://api.telegram.org/bot$botToken/sendMessage",
      );
      try {
        final response = await http.post(
          url,
          body: {"chat_id": chatId, "text": message, "parse_mode": "Markdown"},
        );
        if (response.statusCode == 200) {
          debugPrint("Notification sent via Telegram successfully!");
          return; // ብቴሌግራም እንተተላኢኹ ነቲ ናይ SMS ኣማራጺ ይዘሎ
        }
      } catch (e) {
        debugPrint("Telegram Failed, switching to SMS mode... Error: $e");
      }
    }

    // 2. እቲ ዓሚል ቻት ID እንተዘይብሉ ወይ ቴሌግራም እንተዘይሰሪሑ ቀጥታ ናብ መደበኛ SMS ይቕይር
    String cleanMessage = message
        .replaceAll('*', '')
        .replaceAll('✅', '[OK]')
        .replaceAll('🔔', '[ALERT]');
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: <String, String>{'body': cleanMessage},
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      debugPrint("Could not launch SMS application.");
    }
  }
}
