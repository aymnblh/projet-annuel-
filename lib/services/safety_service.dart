import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';

class SafetyService {
  static GenerativeModel? _model;

  static void _init() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      print("⚠️ SafetyService: GEMINI_API_KEY manquant.");
      return;
    }
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  /// Retourne true si l'image est SÛRE, false si elle est NSFW/Dangereuse.
  static Future<bool> analyzeImageSafety(XFile imageFile) async {
    if (_model == null) _init();
    if (_model == null) return true; // Fail safe: on laisse passer si pas de clé (ou false selon politique)

    try {
      final imageBytes = await imageFile.readAsBytes();
      final prompt = Content.text(
        "Analyze this image. Is it safe for a public e-commerce app? "
        "Check for nudity, violence, weapons, or gore. "
        "Answer ONLY with a JSON object: {\"safe\": boolean, \"reason\": \"short reason\"}."
      );
      
      final imagePart = DataPart('image/jpeg', imageBytes); // On assume jpeg/png
      final response = await _model!.generateContent([
        Content.multi([prompt.parts.first, imagePart])
      ]);

      final text = response.text;
      if (text == null) return true;

      // Nettoyage Markdown éventuel
      final cleanText = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final jsonResponse = json.decode(cleanText);
      
      bool isSafe = jsonResponse['safe'] ?? false;
      if (!isSafe) {
        print("🚨 Image bloquée par SafetyService: ${jsonResponse['reason']}");
      }
      return isSafe;

    } catch (e) {
      print("SafetyService Error: $e");
      return true; // En cas d'erreur API, on laisse passer (ou on bloque, au choix)
    }
  }
}
