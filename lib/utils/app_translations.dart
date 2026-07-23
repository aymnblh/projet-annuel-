class AppTranslations {
  static final Map<String, Map<String, String>> _translations = {
    'fr': {
      'app_title': '1Click',
      'home': 'Accueil',
      'favorites': 'Favoris',
      'profile': 'Profil',
      'sell': 'VENDRE',
      'search_hint': 'Rechercher (ex: 208 2023)...',
      'login_required': 'Veuillez vous connecter.',
      'login_title': 'Connexion',
      'login_btn': 'SE CONNECTER',
      'signup_btn': 'S\'INSCRIRE',
      'phone_btn': 'Téléphone',
      'google_btn': 'Continuer avec Google',
      'email_label': 'Email',
      'pass_label': 'Mot de passe',
      'name_label': 'Nom complet',
      'phone_hint': 'Numéro (ex: +213...)',
      'send_sms': 'Envoyer SMS',
      'verify': 'Vérifier',
      'cancel': 'Annuler',
      'logout': 'Se déconnecter',
      'my_ads': 'Mes Annonces',
      'change_lang': 'Changer la langue',
      'delete_account': 'Supprimer le compte',
      'welcome_guest': 'Bienvenue !',
      'guest_desc': 'Connectez-vous pour vendre et gérer vos favoris.',
      'price_da': 'EUR',
      'price_da': 'EUR',
      'description': 'Description',
      'features': 'Caractéristiques',
      'location': 'Localisation',
      'sponsored': 'Sponsorisé',
      'urgent': 'URGENT',
      'top': 'TOP',
      'boosted': 'BOOSTÉ',
      'out_of_stock': 'Rupture de stock',
      'in_stock': 'En stock',
      'few_left': 'Il n\'en reste que quelques-uns',
      'discover': 'Découvrir',
      'options': 'Variantes',
      'sold_by': 'Vendu par',
      'total_price': 'Prix total',
      'contact_seller': 'Contacter le vendeur',
      'call': 'Appeler',
      'message': 'Message',
      'view_more': '...Voir plus',
      'view_less': 'Voir moins',
      'views': 'vues',
      'no_products': 'Aucun produit trouvé',
      'email_taken': 'Cet email a déjà un compte. Veuillez vous connecter.',
      'weak_password': 'Le mot de passe est trop faible.',
      'invalid_email': 'L\'adresse email est invalide.',
      'unknown_error': 'Une erreur est survenue.',
      
      // NEW: Social Sharing
      'share_product': 'Partager',
      'share_via': 'Partager via',
      'link_copied': 'Lien copié',
      'copy_link': 'Copier le lien',
      
      // NEW: Recently Viewed
      'recently_viewed': 'Récemment vus',
      'view_all': 'Voir tout',
      'recently_viewed_clear': 'Effacer',
      'recently_viewed_clear_confirm_title': 'Effacer l\'historique ?',
      'recently_viewed_clear_confirm_message': 'Tous les produits récemment vus seront supprimés.',
      'recently_viewed_cleared': 'Historique effacé',
      
      // NEW: Similar Cars
      'similar_cars': 'Voitures similaires',
      'similar_products': 'Produits similaires',
      
      // NEW: Video Compression
      'video_compression_title': 'Compression vidéo',
      'video_compression_preparing': 'Préparation...',
      'video_compression_in_progress': 'Compression en cours...',
      'video_compression_done': 'Terminé !',
      'video_compression_cancel': 'Annuler',
      'video_compression_error_title': 'Erreur de compression',
      'video_compression_retry': 'Réessayer',
      'video_compression_original': 'Original',
      'video_compression_compressed': 'Compressé',
      
      // NEW: Advanced Search
      'search_suggestions': 'Suggestions',
      'search_history': 'Historique',
      'clear_history': 'Effacer l\'historique',
      'no_suggestions': 'Aucune suggestion',
      'search_no_results': 'Aucun résultat',
      'search_type_to_search': 'Tapez pour rechercher',
      
      // NEW: Deep Linking
      'deep_link_loading': 'Chargement...',
      'deep_link_error_title': 'Erreur',
      
      // NEW: Error Messages
      'error_video_compression_failed': 'La compression vidéo a échoué',
      'error_video_file_not_found': 'Fichier vidéo introuvable',
      'error_video_invalid_format': 'Format vidéo non valide',
      'error_search_failed': 'La recherche a échoué',
      'error_network': 'Erreur réseau. Vérifiez votre connexion.',
      'error_try_again': 'Veuillez réessayer',
      'error_deep_link_invalid': 'Lien invalide',
      'error_product_not_found': 'Produit introuvable',
      'error_loading': 'Erreur de chargement',
      
      // NEW: Notifications (Future)
      'notifications': 'Notifications',
      'new_message': 'Nouveau message',
      'price_drop': 'Baisse de prix',

    },
    };

  static String get(String code, String key) {
    // Toujours utiliser le francais
    if (_translations.containsKey('fr') && _translations['fr']!.containsKey(key)) {
      return _translations['fr']![key]!;
    }
    return key;
  }
}
