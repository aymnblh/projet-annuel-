import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service de chatbot IA propulsé par Gemini pour OneClick Cars.
/// Gère les conversations multi-tours avec contexte automobile algérien.
class ChatbotService {
  // ─── Singleton ───────────────────────────────────────────────────
  static final ChatbotService _instance = ChatbotService._internal();
  factory ChatbotService() => _instance;
  ChatbotService._internal();

  // ─── Configuration ───────────────────────────────────────────────
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  late final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: _apiKey,
    generationConfig: GenerationConfig(
      temperature: 0.7,
      maxOutputTokens: 1024,
    ),
    systemInstruction: Content.system(_systemPrompt),
  );

  ChatSession? _chatSession;

  // ─── Historique en mémoire ───────────────────────────────────────
  final List<Content> _conversationHistory = [];

  List<Content> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  // ─── Prompt système ──────────────────────────────────────────────
  static const String _systemPrompt = """
Tu es l'assistant IA de OneClick Cars, la marketplace automobile n°1 en Algérie. 
Tu es expert en voitures et en marché automobile algérien.

🚗 TES CONNAISSANCES :

CATÉGORIES DE VÉHICULES :
- Citadine, Berline, SUV, 4x4, Break, Coupé, Cabriolet, Monospace, Utilitaire, Pick-up, Camion

MARQUES POPULAIRES EN ALGÉRIE :
- Européennes : Renault (Symbol, Clio, Mégane), Peugeot (208, 301, 3008, 5008), Volkswagen (Golf, Polo, Tiguan), Dacia (Logan, Sandero, Duster), Citroën, SEAT, Skoda, Fiat
- Asiatiques : Hyundai (Accent, Tucson, Creta, i10, i20), Kia (Picanto, Rio, Sportage, Seltos), Toyota (Corolla, Hilux, Yaris, Land Cruiser), Suzuki (Swift, Dzire, Vitara), Chery (Tiggo), Geely, BAIC, Changan, JAC
- Américaines/Autres : Ford, Chevrolet

CARBURANTS :
- Essence, Diesel, GPL (Sirgas très répandu en Algérie), Hybride, Électrique

WILAYAS PRINCIPALES :
- Alger, Oran, Constantine, Annaba, Sétif, Blida, Tizi Ouzou, Béjaïa, Batna, Tlemcen, Djelfa, M'sila, Chlef, Mostaganem, Biskra, Ouargla, Ghardaia, Tiaret, Jijel, Skikda, et les 58 wilayas

⚖️ RÉGLEMENTATION ALGÉRIENNE :
- Importation de véhicules de moins de 3 ans (loi d'importation)
- Documents obligatoires : Carte grise, Carte jaune (assurance), Contrôle technique, Certificat de conformité
- Dédouanement et droits de douane
- Transfert de propriété (mutation) à la daïra
- Assurance obligatoire (RC minimum)
- Contrôle technique tous les 2 ans pour les véhicules de plus de 5 ans
- Plaques d'immatriculation par wilaya (ex: 16 = Alger, 31 = Oran)

💰 PRIX ET MARCHÉ :
- Les prix en Algérie sont souvent exprimés en "millions" (centimes). 200 millions = 2 000 000 DA
- 1 EUR ≈ 270 DZD (change officiel), marché parallèle plus élevé
- Le marché de l'occasion est très actif, les véhicules gardent bien leur valeur
- Les prix varient selon la wilaya (Alger est plus cher)
- Le GPL (Sirgas) réduit les coûts de carburant significativement

🎯 TES MISSIONS :
1. Répondre aux questions sur les voitures (caractéristiques, comparaisons, avis)
2. Aider à trouver le bon véhicule selon le budget et les besoins
3. Expliquer les procédures administratives (mutation, assurance, contrôle technique)
4. Donner des conseils d'achat et de vente
5. Suggérer des filtres de recherche pertinents sur OneClick
6. Estimer des prix de marché
7. Conseiller sur l'entretien et les réparations

🗣️ LANGUES :
- Tu parles couramment le Français, l'Arabe classique, et le Darija (dialecte algérien)
- Adapte ta langue à celle de l'utilisateur
- Si l'utilisateur parle en Darija, réponds en Darija
- Si l'utilisateur parle en arabe, réponds en arabe
- Par défaut, réponds en français

📝 STYLE :
- Sois amical, professionnel et concis
- Utilise des emojis avec modération pour rendre la conversation agréable
- Structure tes réponses avec des listes quand c'est pertinent
- Quand tu suggères une recherche, indique les filtres à appliquer sur OneClick
- N'invente jamais de prix ou de caractéristiques que tu ne connais pas
- Si tu n'es pas sûr, dis-le honnêtement
""";

  // ─── Envoyer un message ──────────────────────────────────────────
  /// Envoie un message à l'IA et retourne la réponse.
  /// [message] : le texte de l'utilisateur.
  /// [history] : historique optionnel au format [{role, text}] pour
  ///             reconstruire la session si nécessaire.
  Future<String> sendMessage(
    String message, [
    List<Map<String, String>>? history,
  ]) async {
    try {
      if (_apiKey.isEmpty) {
        return "❌ Erreur de configuration : clé API Gemini manquante. "
            "Veuillez contacter le support.";
      }

      // Initialiser ou réutiliser la session de chat
      _chatSession ??= _model.startChat(history: _conversationHistory);

      // Envoyer le message
      final response = await _chatSession!.sendMessage(
        Content.text(message),
      );

      // Mettre à jour l'historique local
      _conversationHistory.add(Content('user', [TextPart(message)]));
      if (response.text != null) {
        _conversationHistory
            .add(Content('model', [TextPart(response.text!)]));
      }

      return response.text?.trim() ??
          "Désolé, je n'ai pas pu générer une réponse. Veuillez réessayer.";
    } on GenerativeAIException catch (e) {
      return _handleGeminiError(e);
    } catch (e) {
      return "❌ Une erreur inattendue s'est produite. "
          "Veuillez réessayer dans quelques instants.\n\nDétail : $e";
    }
  }

  // ─── Questions suggérées ─────────────────────────────────────────
  /// Retourne une liste de questions rapides à afficher comme chips.
  /// [isArabic] : si vrai, retourne les suggestions en arabe.
  List<String> getSuggestedQuestions({bool isArabic = false}) {
    if (isArabic) {
      return [
        'نحوس على SUV عائلي',
        'كيفاش نتأكد من الأوراق؟',
        'شحال تسوى طوموبيل بـ 200 مليون؟',
        'أحسن الماركات الموثوقة',
        'نصائح باش نبيع بسرعة',
        'الفرق بين الديزل والبنزين؟',
        'كيفاش ندير mutation؟',
        'سيارات اقتصادية في الجزائر',
      ];
    }
    return [
      'Trouver un SUV familial',
      'Comment vérifier les papiers ?',
      'Quelle voiture pour 200 millions ?',
      'Les marques les plus fiables',
      'Conseils pour vendre rapidement',
      'Diesel ou essence, que choisir ?',
      'Comment faire une mutation ?',
      'Voitures économiques en Algérie',
    ];
  }

  // ─── Effacer l'historique ────────────────────────────────────────
  /// Réinitialise la conversation en cours.
  void clearHistory() {
    _conversationHistory.clear();
    _chatSession = null;
  }

  // ─── Gestion des erreurs Gemini ──────────────────────────────────
  String _handleGeminiError(GenerativeAIException e) {
    final errorMessage = e.toString().toLowerCase();

    if (errorMessage.contains('quota') ||
        errorMessage.contains('rate limit')) {
      return "⏳ Trop de requêtes envoyées. "
          "Veuillez patienter quelques secondes avant de réessayer.";
    }
    if (errorMessage.contains('safety') ||
        errorMessage.contains('blocked')) {
      return "⚠️ Votre message n'a pas pu être traité pour des raisons "
          "de sécurité. Veuillez reformuler votre question.";
    }
    if (errorMessage.contains('not found') ||
        errorMessage.contains('model')) {
      return "❌ Le modèle IA est temporairement indisponible. "
          "Veuillez réessayer plus tard.";
    }
    if (errorMessage.contains('api key') ||
        errorMessage.contains('permission')) {
      return "❌ Erreur d'authentification avec le service IA. "
          "Veuillez contacter le support.";
    }

    return "❌ Une erreur est survenue avec l'assistant IA : "
        "${e.message}";
  }
}
