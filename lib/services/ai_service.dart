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
      You are an expert seller assistant for the European secondhand market. 
      Analyze the image and return ONLY a raw JSON object (no markdown, no backticks).
      Fields required:
      - 'title': Short title in French.
      - 'category': Choose strictly one: 'VÃªtements', 'Ã‰lectronique', 'Maison', 'VÃ©hicules', 'Autre'.
      - 'description': Attractive description in French.
      - 'price': An integer estimate in Euro (EUR).
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
    String? historyContext, // Ex: "User asked: Price? Seller said: 5000 EUR"
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7, // Un peu plus crÃ©atif pour le chat
        ),
      );

      final prompt = """
      You are an European seller assistant on 'OneClick'. You speak clear, polite French or the buyer language.
      
      Context:
      - Product: $productTitle
      - Description: $productDescription
      - Price: $price
      
      Conversation History:
      ${historyContext ?? 'New conversation'}
      
      Last Message from Buyer: "$lastUserMessage"
      
      Task: Generate a short, polite, and helpful reply (2-3 sentences max) to the buyer.
      Examples:
      - If asked "Where is it?" -> "The car is available in the location shown on the listing."
      - If asked "Price?" -> "The listed price is $price. A reasonable offer can be discussed."
      - If asked generic -> "Hello, yes, it is still available."
      
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
      You are an expert market analyst for Europe.
      Product: "$productTitle"
      Category: "$category"
      Current Price: $currentPrice EUR
      
      Task: Suggest a slight discount strategy (5-15%) to sell this item faster.
      Return ONLY a short string in French, e.g.: "Conseil : Baissez le prix Ã  X EUR pour vendre 2x plus vite !"
      """;

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      return response.text?.trim();
    } catch (e) {
      print("Gemini Price Suggest Error: $e");
      return null;
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // NOUVEAU : Recherche NLP â€” langage naturel â†’ filtres structurÃ©s
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Future<Map<String, dynamic>?> parseNaturalLanguageSearch(String query) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(temperature: 0.2),
      );

      const prompt = """
      Tu es un assistant de recherche pour une marketplace de voitures en Europe.
      L'utilisateur decrit ce qu'il cherche en langage naturel (francais, anglais, espagnol, allemand, italien ou autre langue europeenne).
      
      Extrais les filtres de recherche structurÃ©s Ã  partir de la requÃªte.
      Retourne UNIQUEMENT un objet JSON brut (pas de markdown, pas de backticks).
      
      Champs possibles (n'inclure que ceux mentionnÃ©s ou clairement impliquÃ©s) :
      - "brand": String (marque, ex: "Renault", "Peugeot", "Toyota")
      - "model": String (modÃ¨le, ex: "Golf", "Clio", "Corolla")
      - "vehicleType": String parmi ["Citadine", "Berline", "SUV", "4x4", "Break", "CoupÃ©", "Cabriolet", "Monospace", "Utilitaire", "Pick-up", "Camion"]
      - "fuel": String parmi ["Essence", "Diesel", "GPL", "Hybride", "Ã‰lectrique"]
      - "gearbox": String parmi ["Manuelle", "Automatique", "Semi-automatique"]
      - "minPrice": int (en euros EUR)
      - "maxPrice": int (en euros EUR)
      - "minYear": int (annÃ©e minimum)
      - "maxYear": int (annÃ©e maximum)
      - "maxKm": int (kilomÃ©trage max)
      - "wilaya": String (pays, region ou grande ville europeenne; ex: "France", "Allemagne", "Paris")
      - "color": String
      - "keywords": List<String> (mots-clÃ©s additionnels non capturÃ©s par les filtres)
      - "features": List<String> (Ã©quipements demandÃ©s: "toit ouvrant", "GPS", "cuir", etc.)
      
      Exemples :
      - "SUV hybride budget 25000 euros" -> {"vehicleType": "SUV", "fuel": "Hybride", "maxPrice": 25000}
      - "Golf 7 diesel Paris moins de 100000 km" -> {"brand": "Volkswagen", "model": "Golf", "fuel": "Diesel", "wilaya": "France", "keywords": ["Paris"], "maxKm": 100000}
      - "voiture familiale automatique pas chere" -> {"vehicleType": "Monospace", "gearbox": "Automatique", "maxPrice": 15000, "keywords": ["familiale"]}
      - "diesel break 2020 en Allemagne" -> {"fuel": "Diesel", "vehicleType": "Break", "minYear": 2020, "wilaya": "Allemagne"}
      
      IMPORTANT: Les prix sont en euros. Si l'utilisateur mentionne 25k, 25 000, 25.000 ou 25000 euros, retourne 25000. Ne convertis pas vers une autre devise.
      """;

      final content = [
        Content.multi([
          TextPart(prompt),
          TextPart("RequÃªte utilisateur: \"$query\""),
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

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // NOUVEAU : Recherche visuelle â€” photo â†’ identification voiture
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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
      en concession, ou n'importe oÃ¹) et identifie le vÃ©hicule.
      
      Retourne UNIQUEMENT un objet JSON brut (pas de markdown, pas de backticks) :
      {
        "brand": "Marque (ex: Volkswagen)",
        "model": "ModÃ¨le (ex: Golf)",
        "generation": "GÃ©nÃ©ration (ex: Golf 7, Phase 2)",
        "yearRange": "Fourchette d'annÃ©es (ex: 2017-2020)",
        "vehicleType": "Type parmi: Citadine, Berline, SUV, 4x4, Break, CoupÃ©, Cabriolet, Monospace, Utilitaire, Pick-up",
        "color": "Couleur principale",
        "confidence": 0.85,
        "description": "Description courte en franÃ§ais du vÃ©hicule identifiÃ©"
      }
      
      Si tu ne peux pas identifier la voiture, retourne:
      {"error": "Impossible d'identifier le vÃ©hicule", "confidence": 0.0}
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

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // NOUVEAU : Analyse enrichie â€” dÃ©tecte marque + Ã©quipements visibles
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Future<Map<String, dynamic>?> analyzeImageEnriched(File imageFile) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(temperature: 0.4),
      );

      final imageBytes = await imageFile.readAsBytes();

      const prompt = """
      Tu es un expert vendeur automobile pour le marchÃ© algÃ©rien de l'occasion.
      Analyse cette photo de voiture et retourne UNIQUEMENT un objet JSON brut (pas de markdown, pas de backticks).
      
      {
        "title": "Titre court et vendeur (ex: Peugeot 3008 GT Line 2019)",
        "brand": "Marque",
        "model": "ModÃ¨le",
        "year": "AnnÃ©e estimÃ©e (String)",
        "category": "CatÃ©gorie",
        "color": "Couleur",
        "vehicleType": "Citadine/Berline/SUV/4x4/Break/CoupÃ©/Cabriolet/Monospace/Utilitaire/Pick-up",
        "price": 25000,
        "description": "Description technique et vendeuse (moteur, Ã©tat visible, points forts)",
        "detectedEquipments": ["Toit ouvrant", "Jantes alliage", "Feux LED", "SiÃ¨ges cuir", "GPS", "CamÃ©ra de recul", "Climatisation auto", "Radar de stationnement", "Barres de toit", "Vitres teintÃ©es", "RÃ©troviseurs Ã©lectriques", "Airbags", "ABS", "ESP"],
        "condition": "Neuf/Excellent Ã©tat/Bon Ã©tat/Ã‰tat moyen/Pour piÃ¨ces"
      }
      
      Pour "detectedEquipments", liste UNIQUEMENT les Ã©quipements que tu peux voir ou dÃ©duire de la photo.
      Pour le prix, estime en euros (EUR) pour le marche europeen de l'occasion.
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

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // NOUVEAU : GÃ©nÃ©ration de description vendeuse marketing
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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

      final equipmentStr = equipments?.join(', ') ?? 'Non spÃ©cifiÃ©';

      final prompt = """
      Tu es un rÃ©dacteur professionnel d'annonces automobiles pour le marchÃ© algÃ©rien.
      RÃ©dige une description VENDEUSE, engageante et sans fautes pour cette annonce.
      
      VÃ©hicule :
      - Titre : $title
      - Marque : $brand | ModÃ¨le : $model
      - AnnÃ©e : ${year ?? 'Non spÃ©cifiÃ©'} | KilomÃ©trage : ${km ?? 'Non spÃ©cifiÃ©'} km
      - Carburant : ${fuel ?? 'Non spÃ©cifiÃ©'} | BoÃ®te : ${gearbox ?? 'Non spÃ©cifiÃ©'}
      - Couleur : ${color ?? 'Non spÃ©cifiÃ©'} | Moteur : ${engine ?? 'Non spÃ©cifiÃ©'}
      - Ã‰tat : ${condition ?? 'Non spÃ©cifiÃ©'}
      - Ã‰quipements dÃ©tectÃ©s : $equipmentStr
      
      RÃ¨gles :
      1. Ã‰cris en franÃ§ais avec un ton professionnel mais chaleureux
      2. Mets en avant les points forts et les Ã©quipements
      3. 4-6 phrases maximum, structurÃ©es avec des emojis discrets
      4. Mentionne l'Ã©tat et les avantages clÃ©s
      5. Termine par un appel Ã  l'action
      6. N'invente PAS de caractÃ©ristiques non mentionnÃ©es
      
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

