
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // 1. Charge la clé
  await dotenv.load(fileName: ".env");
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? ''; 

  print("🔑 Test de la clé API : ${apiKey.substring(0, 5)}...");

  // 2. Modèles à tester
  final models = [
    'gemini-1.5-flash',
    'gemini-1.0-pro',
    'gemini-pro',
  ];

  for (var modelName in models) {
    print("\n------------------------------------------------");
    print("🤖 Test du modèle : $modelName");
    try {
      final model = GenerativeModel(model: modelName, apiKey: apiKey);
      final content = [Content.text('Test')];
      final response = await model.generateContent(content);
      print("✅ SUCCÈS ! Le modèle $modelName est DISPONIBLE.");
      print("   Réponse: ${response.text}");
    } catch (e) {
      print("❌ ÉCHEC pour $modelName");
      if (e.toString().contains('404')) {
        print("   -> Modèle non trouvé ou non activé.");
      } else if (e.toString().contains('403')) {
        print("   -> Accès refusé (Clé API ou Pays).");
      } else {
        print("   -> ${e.toString().replaceAll('\n', ' ')}");
      }
    }
  }
}
