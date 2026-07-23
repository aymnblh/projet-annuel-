import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service de chatbot IA propulsÃ© par Gemini pour OneClick Cars.
/// GÃ¨re les conversations multi-tours avec contexte automobile algÃ©rien.
class ChatbotService {
  // â”€â”€â”€ Singleton â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static final ChatbotService _instance = ChatbotService._internal();
  factory ChatbotService() => _instance;
  ChatbotService._internal();

  // â”€â”€â”€ Configuration â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€â”€ Historique en mÃ©moire â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final List<Content> _conversationHistory = [];

  List<Content> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  // â”€â”€â”€ Prompt systÃ¨me â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String _systemPrompt = """
Tu es l'assistant IA de OneClick Cars, une marketplace automobile europeenne.
Tu es expert en voitures, achat/vente d'occasion et formalites automobiles en Europe.

TES CONNAISSANCES :

CATEGORIES DE VEHICULES :
- Citadine, Berline, SUV, 4x4, Break, Coupe, Cabriolet, Monospace, Utilitaire, Pick-up, Camion

MARCHES EUROPEENS :
- France, Allemagne, Italie, Espagne, Belgique, Pays-Bas, Portugal, Suisse, Luxembourg, Autriche, Irlande, Pologne, Suede, Danemark, Norvege
- Les prix sont exprimes en euros (EUR), avec des variations selon pays, kilometrage, historique, emissions, fiscalite locale et garantie.

MARQUES COURANTES EN EUROPE :
- Renault, Peugeot, Citroen, Dacia, Volkswagen, Audi, BMW, Mercedes-Benz, Opel, Fiat, Alfa Romeo, Seat, Skoda, Ford, Toyota, Hyundai, Kia, Nissan, Volvo, Tesla, Mini, Porsche

CARBURANTS ET ENERGIES :
- Essence, Diesel, GPL, Hybride, Hybride rechargeable, Electrique
- Attention aux restrictions urbaines selon pays et villes: Crit'Air/ZFE en France, ULEZ au Royaume-Uni, Umweltzone en Allemagne, LEZ en Belgique et autres zones basse emission.

DOCUMENTS ET FORMALITES :
- Carte grise / certificat d'immatriculation
- Certificat de cession ou contrat de vente
- Controle technique selon l'age du vehicule et le pays
- Certificat de conformite europeen (COC) utile pour import/export
- Facture, carnet d'entretien, historique de maintenance, nombre de proprietaires
- Verification VIN, kilometrage, gage/financement, sinistres et rappels constructeur
- Import intra-UE: verifier TVA, quitus fiscal selon pays, immatriculation locale, assurance et plaques temporaires si necessaire

TES MISSIONS :
1. Aider a trouver le bon vehicule selon budget, pays, usage, emissions et cout total de possession
2. Expliquer les documents et demarches de vente/achat en Europe
3. Conseiller sur les risques: kilometrage incoherent, historique incomplet, import, batterie EV, diesel en zones urbaines
4. Suggere des filtres de recherche pertinents sur OneClick Cars
5. Estimer un ordre de prix en euros quand c'est possible, sans inventer de certitude
6. Donner des conseils de negociation, inspection, essai routier et livraison

LANGUES :
- Reponds dans la langue de l'utilisateur quand tu la reconnais.
- Par defaut, reponds en francais clair et concis.

STYLE :
- Sois amical, professionnel et concis.
- Structure tes reponses avec des listes quand c'est utile.
- Quand tu suggeres une recherche, indique les filtres a appliquer: marque, modele, pays/ville, prix max, annee, carburant, boite, kilometrage.
- N'invente jamais de caracteristiques, prix precis ou obligations legales locales si tu n'es pas sur; recommande de verifier les regles du pays concerne.
""";

  // â”€â”€â”€ Envoyer un message â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Envoie un message Ã  l'IA et retourne la rÃ©ponse.
  /// [message] : le texte de l'utilisateur.
  /// [history] : historique optionnel au format [{role, text}] pour
  ///             reconstruire la session si nÃ©cessaire.
  Future<String> sendMessage(
    String message, [
    List<Map<String, String>>? history,
  ]) async {
    try {
      if (_apiKey.isEmpty) {
        return "âŒ Erreur de configuration : clÃ© API Gemini manquante. "
            "Veuillez contacter le support.";
      }

      // Initialiser ou rÃ©utiliser la session de chat
      _chatSession ??= _model.startChat(history: _conversationHistory);

      // Envoyer le message
      final response = await _chatSession!.sendMessage(
        Content.text(message),
      );

      // Mettre Ã  jour l'historique local
      _conversationHistory.add(Content('user', [TextPart(message)]));
      if (response.text != null) {
        _conversationHistory
            .add(Content('model', [TextPart(response.text!)]));
      }

      return response.text?.trim() ??
          "DÃ©solÃ©, je n'ai pas pu gÃ©nÃ©rer une rÃ©ponse. Veuillez rÃ©essayer.";
    } on GenerativeAIException catch (e) {
      return _handleGeminiError(e);
    } catch (e) {
      return "âŒ Une erreur inattendue s'est produite. "
          "Veuillez rÃ©essayer dans quelques instants.\n\nDÃ©tail : $e";
    }
  }

  // â”€â”€â”€ Questions suggÃ©rÃ©es â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Retourne une liste de questions rapides Ã  afficher comme chips.
  /// [isArabic] : si vrai, retourne les suggestions en arabe.
  List<String> getSuggestedQuestions({bool isArabic = false}) {
    if (isArabic) {
      return [
        'Ù†Ø­ÙˆØ³ Ø¹Ù„Ù‰ SUV Ø¹Ø§Ø¦Ù„ÙŠ',
        'ÙƒÙŠÙØ§Ø´ Ù†ØªØ£ÙƒØ¯ Ù…Ù† Ø§Ù„Ø£ÙˆØ±Ø§Ù‚ØŸ',
        'Ø´Ø­Ø§Ù„ ØªØ³ÙˆÙ‰ Ø·ÙˆÙ…ÙˆØ¨ÙŠÙ„ Ø¨Ù€ 20000 EURØŸ',
        'Ø£Ø­Ø³Ù† Ø§Ù„Ù…Ø§Ø±ÙƒØ§Øª Ø§Ù„Ù…ÙˆØ«ÙˆÙ‚Ø©',
        'Ù†ØµØ§Ø¦Ø­ Ø¨Ø§Ø´ Ù†Ø¨ÙŠØ¹ Ø¨Ø³Ø±Ø¹Ø©',
        'Ø§Ù„ÙØ±Ù‚ Ø¨ÙŠÙ† Ø§Ù„Ø¯ÙŠØ²Ù„ ÙˆØ§Ù„Ø¨Ù†Ø²ÙŠÙ†ØŸ',
        'ÙƒÙŠÙØ§Ø´ Ù†Ø¯ÙŠØ± mutationØŸ',
        'Ø³ÙŠØ§Ø±Ø§Øª Ø§Ù‚ØªØµØ§Ø¯ÙŠØ© ÙÙŠ Ø£ÙˆØ±ÙˆØ¨Ø§',
      ];
    }
    return [
      'Trouver un SUV familial',
      'Comment vÃ©rifier les papiers ?',
      'Quelle voiture pour 20 000 euros ?',
      'Les marques les plus fiables',
      'Conseils pour vendre rapidement',
      'Diesel ou essence, que choisir ?',
      'Comment faire une mutation ?',
      'Voitures Ã©conomiques en AlgÃ©rie',
    ];
  }

  // â”€â”€â”€ Effacer l'historique â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// RÃ©initialise la conversation en cours.
  void clearHistory() {
    _conversationHistory.clear();
    _chatSession = null;
  }

  // â”€â”€â”€ Gestion des erreurs Gemini â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String _handleGeminiError(GenerativeAIException e) {
    final errorMessage = e.toString().toLowerCase();

    if (errorMessage.contains('quota') ||
        errorMessage.contains('rate limit')) {
      return "â³ Trop de requÃªtes envoyÃ©es. "
          "Veuillez patienter quelques secondes avant de rÃ©essayer.";
    }
    if (errorMessage.contains('safety') ||
        errorMessage.contains('blocked')) {
      return "âš ï¸ Votre message n'a pas pu Ãªtre traitÃ© pour des raisons "
          "de sÃ©curitÃ©. Veuillez reformuler votre question.";
    }
    if (errorMessage.contains('not found') ||
        errorMessage.contains('model')) {
      return "âŒ Le modÃ¨le IA est temporairement indisponible. "
          "Veuillez rÃ©essayer plus tard.";
    }
    if (errorMessage.contains('api key') ||
        errorMessage.contains('permission')) {
      return "âŒ Erreur d'authentification avec le service IA. "
          "Veuillez contacter le support.";
    }

    return "âŒ Une erreur est survenue avec l'assistant IA : "
        "${e.message}";
  }
}


