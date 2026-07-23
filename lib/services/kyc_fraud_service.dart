import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class KycFraudService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  GenerativeModel get _model {
    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(temperature: 0.25),
    );
  }

  String _cleanJson(String raw) {
    final cleaned = raw.replaceAll('```json', '').replaceAll('```', '').trim();
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1) return '{}';
    return cleaned.substring(start, end + 1);
  }

  Future<Map<String, dynamic>?> _parseJson(String raw) async {
    try {
      final jsonString = _cleanJson(raw);
      final jsonResult = json.decode(jsonString);
      if (jsonResult is Map<String, dynamic>) {
        return jsonResult;
      }
      return null;
    } catch (e) {
      print('KycFraudService JSON parse error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzeIdDocument(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      const prompt = '''
You are a KYC/OCR expert for an online marketplace. Analyze the provided identity document image and extract the following fields.
Return ONLY a raw JSON object, with no markdown or backticks.

{
  "documentType": "Type de document (ex: Carte d'identité, Passeport, Permis de conduire)",
  "fullName": "Nom complet tel qu'il apparaît sur le document",
  "documentNumber": "Numéro de document",
  "dateOfBirth": "YYYY-MM-DD",
  "expirationDate": "YYYY-MM-DD",
  "issuingCountry": "Pays émetteur",
  "documentAuthentic": true,
  "confidence": 0.0,
  "extractedFields": {
    "firstName": "",
    "lastName": "",
    "address": "",
    "nationality": ""
  }
}

If the document cannot be read, return documentAuthentic: false and confidence: 0.0.
''';

      final response = await _model.generateContent([
        Content.multi([TextPart(prompt), DataPart('image/jpeg', bytes)])
      ]);
      if (response.text == null) return null;
      return await _parseJson(response.text!);
    } catch (e) {
      print('KycFraudService analyzeIdDocument error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> compareSelfieToId(File idImage, File selfieImage) async {
    try {
      final idBytes = await idImage.readAsBytes();
      final selfieBytes = await selfieImage.readAsBytes();
      const prompt = '''
You are an identity verification specialist. Compare the first image (identity document photo) with the second image (selfie) and determine whether they belong to the same person.
Return ONLY a JSON object with no markdown or code fences.

{
  "faceMatchScore": 0.0,
  "similarityLabel": "Très élevé / Élevé / Moyen / Faible / Non similaire",
  "match": true,
  "confidence": 0.0,
  "recommendation": "accept / manual_review / reject"
}
''';

      final response = await _model.generateContent([
        Content.multi([TextPart(prompt), DataPart('image/jpeg', idBytes), DataPart('image/jpeg', selfieBytes)])
      ]);
      if (response.text == null) return null;
      return await _parseJson(response.text!);
    } catch (e) {
      print('KycFraudService compareSelfieToId error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzeVerificationDocuments(XFile idFile, XFile selfieFile) async {
    try {
      final idResult = await analyzeIdDocument(File(idFile.path));
      final selfieResult = await compareSelfieToId(File(idFile.path), File(selfieFile.path));

      final faceMatchScore = (selfieResult?['faceMatchScore'] as num?)?.toDouble() ?? 0.0;
      final documentAuthentic = (idResult?['documentAuthentic'] == true);
      final kycScore = ((faceMatchScore * 100) * 0.65 + (documentAuthentic ? 35.0 : 0.0)).clamp(0, 100).round();
      final kycLevel = kycScore >= 80 ? 'low' : kycScore >= 50 ? 'medium' : 'high';

      return {
        'idAnalysis': idResult ?? {},
        'selfieMatch': selfieResult ?? {},
        'kycScore': kycScore,
        'kycLevel': kycLevel,
        'risk': {
          'score': 100 - kycScore,
          'level': kycLevel == 'low' ? 'low' : kycLevel == 'medium' ? 'medium' : 'high',
        }
      };
    } catch (e) {
      print('KycFraudService analyzeVerificationDocuments error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzeVerificationDocumentsFromUrls(String idUrl, String selfieUrl) async {
    try {
      final idResponse = await http.get(Uri.parse(idUrl));
      final selfieResponse = await http.get(Uri.parse(selfieUrl));
      if (idResponse.statusCode != 200 || selfieResponse.statusCode != 200) {
        return null;
      }
      final tempId = File('${Directory.systemTemp.path}/kyc_id_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final tempSelfie = File('${Directory.systemTemp.path}/kyc_selfie_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempId.writeAsBytes(idResponse.bodyBytes);
      await tempSelfie.writeAsBytes(selfieResponse.bodyBytes);
      return await analyzeVerificationDocuments(XFile(tempId.path), XFile(tempSelfie.path));
    } catch (e) {
      print('KycFraudService analyzeVerificationDocumentsFromUrls error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> evaluateProductFraud(
    Map<String, dynamic> productData, {
    Map<String, dynamic>? sellerData,
  }) async {
    try {
      final summary = json.encode({
        'product': productData,
        'seller': sellerData ?? {},
      });
      final prompt = '''
You are an expert fraud analyst for a European automobile marketplace.
Analyze the listing data below and return a fraud risk evaluation.
Return ONLY a raw JSON object with no markdown or backticks.

{
  "fraudRiskScore": 0,
  "fraudRiskLevel": "low / medium / high",
  "reasons": ["..."],
  "recommendation": "approve / manual_review / reject"
}

Listing data:
$summary
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      if (response.text == null) return null;
      final result = await _parseJson(response.text!);
      if (result == null) return null;

      final score = (result['fraudRiskScore'] as num?)?.toInt() ?? 0;
      final level = (result['fraudRiskLevel'] as String?)?.toLowerCase() ?? 'low';
      final reasons = (result['reasons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

      return {
        'fraudRiskScore': score.clamp(0, 100),
        'fraudRiskLevel': level,
        'fraudRiskReasons': reasons,
        'recommendation': result['recommendation'] ?? 'manual_review',
      };
    } catch (e) {
      print('KycFraudService evaluateProductFraud error: $e');
      return null;
    }
  }
}
