
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  try {
    print("Direct file check for .env: ${File('.env').existsSync()}");
    await dotenv.load(fileName: ".env");
    print("GEMINI_API_KEY: ${dotenv.env['GEMINI_API_KEY']?.substring(0, 5)}...");
  } catch (e) {
    print("Error loading .env: $e");
  }
}
