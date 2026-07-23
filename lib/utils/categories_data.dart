class CategoriesData {
  // --- EUROPEAN MARKET ---
  static const List<String> sellerCountries = [
    'France',
    'Allemagne',
    'Italie',
    'Espagne',
    'Belgique',
    'Pays-Bas',
    'Portugal',
    'Suisse',
    'Luxembourg',
    'Autriche',
    'Irlande',
    'Pologne',
    'Suede',
    'Danemark',
    'Norvege',
    'Turquie',
    'Autre',
  ];

  static const List<String> europeanMarkets = [
    'France',
    'Allemagne',
    'Italie',
    'Espagne',
    'Belgique',
    'Pays-Bas',
    'Portugal',
    'Suisse',
    'Luxembourg',
    'Autriche',
    'Irlande',
    'Pologne',
    'Suede',
    'Danemark',
    'Norvege',
  ];

  static const Map<String, List<String>> europeanCitiesByCountry = {
    'France': ['Paris', 'Lyon', 'Marseille', 'Toulouse', 'Nice', 'Nantes', 'Lille', 'Bordeaux', 'Strasbourg'],
    'Allemagne': ['Berlin', 'Hambourg', 'Munich', 'Cologne', 'Francfort', 'Stuttgart', 'Dusseldorf'],
    'Italie': ['Rome', 'Milan', 'Naples', 'Turin', 'Bologne', 'Florence', 'Venise'],
    'Espagne': ['Madrid', 'Barcelone', 'Valence', 'Seville', 'Bilbao', 'Malaga'],
    'Belgique': ['Bruxelles', 'Anvers', 'Gand', 'Liege', 'Bruges'],
    'Pays-Bas': ['Amsterdam', 'Rotterdam', 'La Haye', 'Utrecht', 'Eindhoven'],
    'Portugal': ['Lisbonne', 'Porto', 'Braga', 'Coimbra', 'Faro'],
    'Suisse': ['Zurich', 'Geneve', 'Bale', 'Lausanne', 'Berne'],
    'Luxembourg': ['Luxembourg', 'Esch-sur-Alzette'],
    'Autriche': ['Vienne', 'Graz', 'Linz', 'Salzbourg'],
    'Irlande': ['Dublin', 'Cork', 'Galway', 'Limerick'],
    'Pologne': ['Varsovie', 'Cracovie', 'Wroclaw', 'Gdansk'],
    'Suede': ['Stockholm', 'Goteborg', 'Malmo', 'Uppsala'],
    'Danemark': ['Copenhague', 'Aarhus', 'Odense', 'Aalborg'],
    'Norvege': ['Oslo', 'Bergen', 'Trondheim', 'Stavanger'],
  };

  static const Map<String, String> countryTranslations = {
    'France': 'فرنسا',
    'Allemagne': 'ألمانيا',
    'Italie': 'إيطاليا',
    'Espagne': 'إسبانيا',
    'Belgique': 'بلجيكا',
    'Pays-Bas': 'هولندا',
    'Portugal': 'البرتغال',
    'Suisse': 'سويسرا',
    'Luxembourg': 'لوكسمبورغ',
    'Autriche': 'النمسا',
    'Irlande': 'إيرلندا',
    'Pologne': 'بولندا',
    'Suede': 'السويد',
    'Danemark': 'الدنمارك',
    'Norvege': 'النرويج',
    'Turquie': 'تركيا',
    'Autre': 'أخرى',
  };
  // --- VEHICLE TYPES (for rental filtering) ---
  static const List<String> vehicleTypes = [
    'Citadine',
    'Berline',
    'Break',
    'SUV / 4x4',
    'Coupé',
    'Monospace / Van',
    'Utilitaire',
    'Pick-up',
  ];

  static const Map<String, String> vehicleTypeTranslations = {
    'Citadine': 'Ø³ÙŠØ§Ø±Ø© ØµØºÙŠØ±Ø©',
    'Berline': 'Ø¨Ø±Ù„ÙŠÙ†',
    'Break': 'Ø¨Ø±ÙŠÙƒ',
    'SUV / 4x4': 'Ø¯ÙØ¹ Ø±Ø¨Ø§Ø¹ÙŠ',
    'Coupé': 'ÙƒÙˆØ¨ÙŠÙ‡',
    'Monospace / Van': 'ÙØ§Ù†',
    'Utilitaire': 'Ù…Ø±ÙƒØ¨Ø© Ø®Ø¯Ù…Ø©',
    'Pick-up': 'Ø¨ÙŠÙƒ Ø£Ø¨',
  };

  // --- DELIVERY OPTIONS ---
  static const List<String> deliveryOptions = [
    'Sur place',
    'Livraison',
    'Les deux',
  ];

  static const Map<String, String> deliveryTranslations = {
    'Sur place': 'ÙÙŠ Ø§Ù„Ù…ÙƒØ§Ù†',
    'Livraison': 'ØªÙˆØµÙŠÙ„',
    'Les deux': 'ÙƒÙ„Ø§Ù‡Ù…Ø§',
  };
  static const Map<String, List<String>> subCategories = {
    'Voitures Occasion': [],
    'Voitures Neuves': [],
    'Location Véhicules': ['Voiture', 'Camion', 'Moto', 'Bus', 'Engin'],
    'Motos': ['Scooter', 'Moto', 'Quad'],
    'Camions & Engins': ['Camion', 'Semi-remorque', 'Bus', 'Engin de chantier', 'Tracteur'],
    'Pièces & Accessoires': ['Carrosserie', 'Moteur', 'Intérieur', 'Roues', 'Accessoires', 'Huiles & Entretien'],
    'Bateaux': ['Pedalo', 'Zodiac', 'Yacht', 'Jet Ski', 'Moteur Marin'],
  };

  static const Map<String, String> categoryTranslations = {
    'Voitures Occasion': 'Ø³ÙŠØ§Ø±Ø§Øª Ù…Ø³ØªØ¹Ù…Ù„Ø©',
    'Voitures Neuves': 'Ø³ÙŠØ§Ø±Ø§Øª Ø¬Ø¯ÙŠØ¯Ø©',
    'Location Véhicules': 'ÙƒØ±Ø§Ø¡ Ø³ÙŠØ§Ø±Ø§Øª',
    'Motos': 'Ø¯Ø±Ø§Ø¬Ø§Øª Ù†Ø§Ø±ÙŠØ©',
    'Camions & Engins': 'Ø´Ø§Ø­Ù†Ø§Øª ÙˆØ¢Ù„ÙŠØ§Øª',
    'Pièces & Accessoires': 'Ù‚Ø·Ø¹ ØºÙŠØ§Ø± ÙˆÙ„ÙˆØ§Ø­Ù‚',
    'Bateaux': 'Ù‚ÙˆØ§Ø±Ø¨',
  };

  static const Map<String, String> subCategoryTranslations = {
    'Voiture': 'Ø³ÙŠØ§Ø±Ø©',
    'Moto': 'Ø¯Ø±Ø§Ø¬Ø©',
    'Camion': 'Ø´Ø§Ø­Ù†Ø©',
    'Bus': 'Ø­Ø§ÙÙ„Ø©',
    'Engin': 'Ø¢Ù„ÙŠØ©',
    'Scooter': 'Ø³ÙƒÙˆØªØ±',
    'Quad': 'ÙƒÙˆØ§Ø¯',
    'Semi-remorque': 'Ù†ØµÙ Ù…Ù‚Ø·ÙˆØ±Ø©',
    'Engin de chantier': 'Ø¢Ù„ÙŠØ§Øª Ø£Ø´ØºØ§Ù„',
    'Tracteur': 'Ø¬Ø±Ø§Ø±',
    'Carrosserie': 'Ù‡ÙŠÙƒÙ„',
    'Moteur': 'Ù…Ø­Ø±Ùƒ',
    'Intérieur': 'Ø¯Ø§Ø®Ù„ÙŠ',
    'Roues': 'Ø¹Ø¬Ù„Ø§Øª',
    'Accessoires': 'Ù„ÙˆØ§Ø­Ù‚',
    'Huiles & Entretien': 'Ø²ÙŠÙˆØª ÙˆØµÙŠØ§Ù†Ø©',
    'Pedalo': 'Ø¨ÙŠØ¯Ø§Ù„Ùˆ',
    'Zodiac': 'Ø²ÙˆØ¯ÙŠØ§Ùƒ',
    'Yacht': 'ÙŠØ®Øª',
    'Jet Ski': 'Ø¬Ø§Øª Ø³ÙƒÙŠ',
    'Moteur Marin': 'Ù…Ø­Ø±Ùƒ Ø¨Ø­Ø±ÙŠ',
  };

  static const List<String> carBrands = [
    'Abarth', 'Alfa Romeo', 'Audi', 'BAIC', 'BMW', 'Chery', 'Chevrolet', 'Chrysler', 'Citroën', 
    'Dacia', 'Daewoo', 'DFSK', 'Dodge', 'DS', 'Fiat', 'Ford', 'Geely', 'Great Wall', 'Haval', 
    'Honda', 'Hyundai', 'Infiniti', 'Isuzu', 'JAC', 'Jaguar', 'Jeep', 'Jetour', 'Kia', 
    'Land Rover', 'Lexus', 'Mahindra', 'Mazda', 'Mercedes-Benz', 'MG', 'Mini', 'Mitsubishi', 
    'Nissan', 'Opel', 'Peugeot', 'Porsche', 'Renault', 'Seat', 'Skoda', 'SsangYong', 'Subaru', 
    'Suzuki', 'Toyota', 'Volkswagen', 'Volvo', 'Zotye', 'Autre'
  ];
  
  static const List<String> fuelTypes = [
    'Essence', 'Diesel', 'GPL', 'Hybride', 'Electrique'
  ];

  static const List<String> gearboxes = [
    'Manuelle', 'Automatique', 'Semi-Automatique'
  ];
  
  static const List<String> papers = [
    'Carte grise', 'Certificat de cession', 'Controle technique', 'Carnet d entretien', 'Facture d achat', 'Certificat de conformite'
  ];
  
  static const List<String> colors = [
    'Blanc', 'Noir', 'Gris Argent', 'Gris Souris', 'Bleu', 'Rouge', 'Vert', 'Beige', 'Marron', 'Jaune', 'Orange', 'Autre'
  ];
  static const Map<String, String> fuelTranslations = {
    'Essence': 'Ø¨Ù†Ø²ÙŠÙ†', 'Diesel': 'Ø¯ÙŠØ²Ù„', 'GPL': 'ØºØ§Ø² (Ø³ÙŠØ±ØºØ§Ø²)', 'Hybride': 'Ù‡Ø¬ÙŠÙ†', 'Electrique': 'ÙƒÙ‡Ø±Ø¨Ø§Ø¦ÙŠ'
  };

  static const Map<String, String> gearboxTranslations = {
    'Manuelle': 'ÙŠØ¯ÙˆÙŠ', 'Automatique': 'Ø£ÙˆØªÙˆÙ…Ø§ØªÙŠÙƒ', 'Semi-Automatique': 'Ù†ØµÙ Ø£ÙˆØªÙˆÙ…Ø§ØªÙŠÙƒ'
  };

  static const Map<String, String> papersTranslations = {
    'Carte grise': 'بطاقة تسجيل',
    'Certificat de cession': 'شهادة التنازل',
    'Controle technique': 'فحص تقني',
    'Carnet d entretien': 'دفتر الصيانة',
    'Facture d achat': 'فاتورة الشراء',
    'Certificat de conformite': 'شهادة المطابقة'
  };

  static const Map<String, String> colorTranslations = {
    'Blanc': 'Ø£Ø¨ÙŠØ¶', 'Noir': 'Ø£Ø³ÙˆØ¯', 'Gris Argent': 'Ø±Ù…Ø§Ø¯ÙŠ ÙØ¶ÙŠ', 'Gris Souris': 'Ø±Ù…Ø§Ø¯ÙŠ ØºØ§Ù…Ù‚', 
    'Bleu': 'Ø£Ø²Ø±Ù‚', 'Rouge': 'Ø£Ø­Ù…Ø±', 'Vert': 'Ø£Ø®Ø¶Ø±', 'Beige': 'Ø¨ÙŠØ¬', 'Marron': 'Ø¨Ù†ÙŠ', 
    'Jaune': 'Ø£ØµÙØ±', 'Orange': 'Ø¨Ø±ØªÙ‚Ø§Ù„ÙŠ', 'Autre': 'Ø¢Ø®Ø±'
  };

  static String tSpecies(String val, String langCode) {
    if (langCode != 'ar') return val;
    if (fuelTranslations.containsKey(val)) return fuelTranslations[val]!;
    if (gearboxTranslations.containsKey(val)) return gearboxTranslations[val]!;
    if (papersTranslations.containsKey(val)) return papersTranslations[val]!;
    if (colorTranslations.containsKey(val)) return colorTranslations[val]!;
    if (subCategoryTranslations.containsKey(val)) return subCategoryTranslations[val]!;
    if (vehicleTypeTranslations.containsKey(val)) return vehicleTypeTranslations[val]!;
    if (countryTranslations.containsKey(val)) return countryTranslations[val]!;
    if (deliveryTranslations.containsKey(val)) return deliveryTranslations[val]!;
    return val;
  }
}

