
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Petit GIF 1x1 base64 pour test
final Uint8List _testImage = Uint8List.fromList([
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00, 0x00, 0xFF, 0xFF, 0xFF,
  0x00, 0x00, 0x00, 0x21, 0xF9, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x2C, 0x00, 0x00, 0x00, 0x00,
  0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3B
]);

void main() async {
  await dotenv.load(fileName: ".env");
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  print("🔑 Test VISION avec clé : ${apiKey.substring(0, 5)}...");

  final models = [
    'gemini-1.5-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-pro', 
    'gemini-pro-vision',  // Deprecated mais peut marcher
    'models/gemini-1.5-flash',
  ];

  for (var modelName in models) {
    print("\n------------------------------------------------");
    print("📷 Test VISION sur : $modelName");
    try {
      final model = GenerativeModel(model: modelName, apiKey: apiKey);
      final content = [
        Content.multi([
          TextPart('Describe this image in 1 word'),
          DataPart('image/gif', _testImage)
        ])
      ];
      
      final response = await model.generateContent(content);
      print("✅ SUCCÈS VISION ! Le modèle $modelName supporte les images.");
      print("   Réponse: ${response.text}");
    } catch (e) {
      print("❌ ÉCHEC VISION pour $modelName");
      String err = e.toString().replaceAll('\n', ' ');
      if (err.length > 150) err = err.substring(0, 150) + "...";
      print("   -> $err");
    }
  }
}
