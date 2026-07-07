import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<Map<String, dynamic>?> analyzeImage(File imageFile) async {
    try {
      // 1. Setup Gemini
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.4,
        ),
      );

      // 2. Prepare the Image
      final imageBytes = await imageFile.readAsBytes();
      
      // 3. Prompt (On insiste sur le JSON ici)
      const prompt = """
      You are an expert seller assistant for the Algerian secondhand market. 
      Analyze the image and return ONLY a raw JSON object (no markdown, no backticks).
      Fields required:
      - 'title': Short title in French.
      - 'category': Choose strictly one: 'Vêtements', 'Électronique', 'Maison', 'Véhicules', 'Autre'.
      - 'description': Attractive description in French.
      - 'price': An integer estimate in Algerian Dinar (DZD) which is valued at 1 EUR = 270 DZD.
      """;

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      // 4. Generate
      final response = await model.generateContent(content);
      
      // 5. Clean & Parse
      if (response.text != null) {
        String cleanText = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
            
        int startIndex = cleanText.indexOf('{');
        int endIndex = cleanText.lastIndexOf('}');
        
        if (startIndex != -1 && endIndex != -1) {
          cleanText = cleanText.substring(startIndex, endIndex + 1);
          return jsonDecode(cleanText) as Map<String, dynamic>;
        }
      }
      return null;
      
    } catch (e) {
      print("Gemini Error: $e");
      return null;
    }
  }

  // NOUVEAU : Smart Reply (RAG)
  Future<String?> generateSmartReply({
    required String productTitle,
    required String productDescription,
    required String price,
    required String lastUserMessage,
    String? historyContext, // Ex: "User asked: Price? Seller said: 5000DA"
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7, // Un peu plus créatif pour le chat
        ),
      );

      final prompt = """
      You are an Algerian seller assistant on 'OneClick'. You speak Algerian Dialect (Darija) mixed with French.
      
      Context:
      - Product: $productTitle
      - Description: $productDescription
      - Price: $price
      
      Conversation History:
      ${historyContext ?? 'New conversation'}
      
      Last Message from Buyer: "$lastUserMessage"
      
      Task: Generate a short, polite, and helpful reply (2-3 sentences max) to the buyer.
      Examples:
      - If asked "Win jay?" -> "Rani f Alger centre khouya, marhba bik."
      - If asked "Prix?" -> "Sawmouna $price DA, chhal t3tina?"
      - If asked generic -> "Salam, oui disponible."
      
      Reply directly in the requested style (Darija/French).
      """;

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      return response.text?.trim();
    } catch (e) {
      print("Gemini Smart Reply Error: $e");
      return null;
    }
  }
  // NOUVEAU : Smart Price Suggestion (Boost)
  Future<String?> suggestOptimalPrice({
    required String productTitle,
    required double currentPrice,
    required String category,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(temperature: 0.3),
      );

      final prompt = """
      You are an expert market analyst for Algeria.
      Product: "$productTitle"
      Category: "$category"
      Current Price: $currentPrice DZD
      
      Task: Suggest a slight discount strategy (5-15%) to sell this item faster.
      Return ONLY a short string in French, e.g.: "Conseil : Baissez le prix à X DA pour vendre 2x plus vite !"
      """;

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      return response.text?.trim();
    } catch (e) {
      print("Gemini Price Suggest Error: $e");
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // NOUVEAU : Recherche NLP — langage naturel → filtres structurés
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> parseNaturalLanguageSearch(String query) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(temperature: 0.2),
      );

      const prompt = """
      Tu es un assistant de recherche pour une marketplace de voitures en Algérie.
      L'utilisateur décrit ce qu'il cherche en langage naturel (français, arabe, darija).
      
      Extrais les filtres de recherche structurés à partir de la requête.
      Retourne UNIQUEMENT un objet JSON brut (pas de markdown, pas de backticks).
      
      Champs possibles (n'inclure que ceux mentionnés ou clairement impliqués) :
      - "brand": String (marque, ex: "Renault", "Peugeot", "Toyota")
      - "model": String (modèle, ex: "Golf", "Clio", "Corolla")
      - "vehicleType": String parmi ["Citadine", "Berline", "SUV", "4x4", "Break", "Coupé", "Cabriolet", "Monospace", "Utilitaire", "Pick-up", "Camion"]
      - "fuel": String parmi ["Essence", "Diesel", "GPL", "Hybride", "Électrique"]
      - "gearbox": String parmi ["Manuelle", "Automatique", "Semi-automatique"]
      - "minPrice": int (en Dinars Algériens, 1 EUR ≈ 270 DZD, 1M DA = 1000000)
      - "maxPrice": int (en Dinars Algériens)
      - "minYear": int (année minimum)
      - "maxYear": int (année maximum)
      - "maxKm": int (kilométrage max)
      - "wilaya": String (ville/wilaya algérienne)
      - "color": String
      - "keywords": List<String> (mots-clés additionnels non capturés par les filtres)
      - "features": List<String> (équipements demandés: "toit ouvrant", "GPS", "cuir", etc.)
      
      Exemples :
      - "SUV hybride budget 250 millions" → {"vehicleType": "SUV", "fuel": "Hybride", "maxPrice": 2500000}
      - "Golf 7 diesel Alger moins de 100000 km" → {"brand": "Volkswagen", "model": "Golf", "fuel": "Diesel", "wilaya": "Alger", "maxKm": 100000}
      - "voiture familiale automatique pas chère" → {"vehicleType": "Monospace", "gearbox": "Automatique", "maxPrice": 2000000, "keywords": ["familiale"]}
      - "kayen chi tomobil diesel dyal 2020" → {"fuel": "Diesel", "minYear": 2020}
      
      IMPORTANT: Les prix en Algérie sont en millions de DA. "250 millions" = 2500000 DA. "25 millions" = 250000 DA. Quand l'utilisateur dit "budget 200" il veut dire 200 millions centimes = 2000000 DA.
      Si l'utilisateur mentionne des euros, convertis en DA (1€ ≈ 270 DA).
      """;

      final content = [
        Content.multi([
          TextPart(prompt),
          TextPart("Requête utilisateur: \"$query\""),
        ])
      ];

      final response = await model.generateContent(content);

      if (response.text != null) {
        String cleanText = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        int startIndex = cleanText.indexOf('{');
        int endIndex = cleanText.lastIndexOf('}');

        if (startIndex != -1 && endIndex != -1) {
          cleanText = cleanText.substring(startIndex, endIndex + 1);
          return jsonDecode(cleanText) as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print("Gemini NLP Search Error: $e");
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // NOUVEAU : Recherche visuelle — photo → identification voiture
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> identifyCarFromPhoto(File imageFile) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(temperature: 0.3),
      );

      final imageBytes = await imageFile.readAsBytes();

      const prompt = """
      Tu es un expert automobile. Analyse cette photo d'une voiture (prise dans la rue, 
      en concession, ou n'importe où) et identifie le véhicule.
      
      Retourne UNIQUEMENT un objet JSON brut (pas de markdown, pas de backticks) :
      {
        "brand": "Marque (ex: Volkswagen)",
        "model": "Modèle (ex: Golf)",
        "generation": "Génération (ex: Golf 7, Phase 2)",
        "yearRange": "Fourchette d'années (ex: 2017-2020)",
        "vehicleType": "Type parmi: Citadine, Berline, SUV, 4x4, Break, Coupé, Cabriolet, Monospace, Utilitaire, Pick-up",
        "color": "Couleur principale",
        "confidence": 0.85,
        "description": "Description courte en français du véhicule identifié"
      }
      
      Si tu ne peux pas identifier la voiture, retourne:
      {"error": "Impossible d'identifier le véhicule", "confidence": 0.0}
      """;

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);

      if (response.text != null) {
        String cleanText = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        int startIndex = cleanText.indexOf('{');
        int endIndex = cleanText.lastIndexOf('}');

        if (startIndex != -1 && endIndex != -1) {
          cleanText = cleanText.substring(startIndex, endIndex + 1);
          return jsonDecode(cleanText) as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print("Gemini Visual Search Error: $e");
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // NOUVEAU : Analyse enrichie — détecte marque + équipements visibles
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> analyzeImageEnriched(File imageFile) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(temperature: 0.4),
      );

      final imageBytes = await imageFile.readAsBytes();

      const prompt = """
      Tu es un expert vendeur automobile pour le marché algérien de l'occasion.
      Analyse cette photo de voiture et retourne UNIQUEMENT un objet JSON brut (pas de markdown, pas de backticks).
      
      {
        "title": "Titre court et vendeur (ex: Peugeot 3008 GT Line 2019)",
        "brand": "Marque",
        "model": "Modèle",
        "year": "Année estimée (String)",
        "category": "Catégorie",
        "color": "Couleur",
        "vehicleType": "Citadine/Berline/SUV/4x4/Break/Coupé/Cabriolet/Monospace/Utilitaire/Pick-up",
        "price": 2500000,
        "description": "Description technique et vendeuse (moteur, état visible, points forts)",
        "detectedEquipments": ["Toit ouvrant", "Jantes alliage", "Feux LED", "Sièges cuir", "GPS", "Caméra de recul", "Climatisation auto", "Radar de stationnement", "Barres de toit", "Vitres teintées", "Rétroviseurs électriques", "Airbags", "ABS", "ESP"],
        "condition": "Neuf/Excellent état/Bon état/État moyen/Pour pièces"
      }
      
      Pour "detectedEquipments", liste UNIQUEMENT les équipements que tu peux voir ou déduire de la photo.
      Pour le prix, estime en Dinars Algériens (DZD) pour le marché algérien de l'occasion.
      """;

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);

      if (response.text != null) {
        String cleanText = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        int startIndex = cleanText.indexOf('{');
        int endIndex = cleanText.lastIndexOf('}');

        if (startIndex != -1 && endIndex != -1) {
          cleanText = cleanText.substring(startIndex, endIndex + 1);
          return jsonDecode(cleanText) as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print("Gemini Enriched Analysis Error: $e");
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // NOUVEAU : Génération de description vendeuse marketing
  // ═══════════════════════════════════════════════════════════════════
  Future<String?> generateSellerDescription({
    required String title,
    required String brand,
    required String model,
    String? year,
    String? km,
    String? fuel,
    String? gearbox,
    String? color,
    String? engine,
    String? condition,
    List<String>? equipments,
  }) async {
    try {
      final model_ = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(temperature: 0.7),
      );

      final equipmentStr = equipments?.join(', ') ?? 'Non spécifié';

      final prompt = """
      Tu es un rédacteur professionnel d'annonces automobiles pour le marché algérien.
      Rédige une description VENDEUSE, engageante et sans fautes pour cette annonce.
      
      Véhicule :
      - Titre : $title
      - Marque : $brand | Modèle : $model
      - Année : ${year ?? 'Non spécifié'} | Kilométrage : ${km ?? 'Non spécifié'} km
      - Carburant : ${fuel ?? 'Non spécifié'} | Boîte : ${gearbox ?? 'Non spécifié'}
      - Couleur : ${color ?? 'Non spécifié'} | Moteur : ${engine ?? 'Non spécifié'}
      - État : ${condition ?? 'Non spécifié'}
      - Équipements détectés : $equipmentStr
      
      Règles :
      1. Écris en français avec un ton professionnel mais chaleureux
      2. Mets en avant les points forts et les équipements
      3. 4-6 phrases maximum, structurées avec des emojis discrets
      4. Mentionne l'état et les avantages clés
      5. Termine par un appel à l'action
      6. N'invente PAS de caractéristiques non mentionnées
      
      Retourne UNIQUEMENT le texte de la description (pas de JSON, pas de guillemets).
      """;

      final content = [Content.text(prompt)];
      final response = await model_.generateContent(content);

      return response.text?.trim();
    } catch (e) {
      print("Gemini Description Generation Error: $e");
      return null;
    }
  }
}