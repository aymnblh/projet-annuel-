class CategoriesData {
  // --- SELLER COUNTRIES ---
  static const List<String> sellerCountries = [
    'Algérie',
    'France',
    'Allemagne',
    'Italie',
    'Espagne',
    'Belgique',
    'Pays-Bas',
    'Turquie',
    'Émirats Arabes Unis',
    'Arabie Saoudite',
    'Qatar',
    'Maroc',
    'Tunisie',
    'Chine',
    'Autre',
  ];

  static const Map<String, String> countryTranslations = {
    'Algérie': 'الجزائر',
    'France': 'فرنسا',
    'Allemagne': 'ألمانيا',
    'Italie': 'إيطاليا',
    'Espagne': 'إسبانيا',
    'Belgique': 'بلجيكا',
    'Pays-Bas': 'هولندا',
    'Turquie': 'تركيا',
    'Émirats Arabes Unis': 'الإمارات',
    'Arabie Saoudite': 'السعودية',
    'Qatar': 'قطر',
    'Maroc': 'المغرب',
    'Tunisie': 'تونس',
    'Chine': 'الصين',
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
    'Citadine': 'سيارة صغيرة',
    'Berline': 'برلين',
    'Break': 'بريك',
    'SUV / 4x4': 'دفع رباعي',
    'Coupé': 'كوبيه',
    'Monospace / Van': 'فان',
    'Utilitaire': 'مركبة خدمة',
    'Pick-up': 'بيك أب',
  };

  // --- DELIVERY OPTIONS ---
  static const List<String> deliveryOptions = [
    'Sur place',
    'Livraison',
    'Les deux',
  ];

  static const Map<String, String> deliveryTranslations = {
    'Sur place': 'في المكان',
    'Livraison': 'توصيل',
    'Les deux': 'كلاهما',
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
    'Voitures Occasion': 'سيارات مستعملة',
    'Voitures Neuves': 'سيارات جديدة',
    'Location Véhicules': 'كراء سيارات',
    'Motos': 'دراجات نارية',
    'Camions & Engins': 'شاحنات وآليات',
    'Pièces & Accessoires': 'قطع غيار ولواحق',
    'Bateaux': 'قوارب',
  };

  static const Map<String, String> subCategoryTranslations = {
    'Voiture': 'سيارة',
    'Moto': 'دراجة',
    'Camion': 'شاحنة',
    'Bus': 'حافلة',
    'Engin': 'آلية',
    'Scooter': 'سكوتر',
    'Quad': 'كواد',
    'Semi-remorque': 'نصف مقطورة',
    'Engin de chantier': 'آليات أشغال',
    'Tracteur': 'جرار',
    'Carrosserie': 'هيكل',
    'Moteur': 'محرك',
    'Intérieur': 'داخلي',
    'Roues': 'عجلات',
    'Accessoires': 'لواحق',
    'Huiles & Entretien': 'زيوت وصيانة',
    'Pedalo': 'بيدالو',
    'Zodiac': 'زودياك',
    'Yacht': 'يخت',
    'Jet Ski': 'جات سكي',
    'Moteur Marin': 'محرك بحري',
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
    'Carte Grise (Safia)', 'Carte Jaune', 'Licence Moudjahid', 'Papiers Bloqués', 'Sans Papiers'
  ];
  
  static const List<String> colors = [
    'Blanc', 'Noir', 'Gris Argent', 'Gris Souris', 'Bleu', 'Rouge', 'Vert', 'Beige', 'Marron', 'Jaune', 'Orange', 'Autre'
  ];
  static const Map<String, String> fuelTranslations = {
    'Essence': 'بنزين', 'Diesel': 'ديزل', 'GPL': 'غاز (سيرغاز)', 'Hybride': 'هجين', 'Electrique': 'كهربائي'
  };

  static const Map<String, String> gearboxTranslations = {
    'Manuelle': 'يدوي', 'Automatique': 'أوتوماتيك', 'Semi-Automatique': 'نصف أوتوماتيك'
  };

  static const Map<String, String> papersTranslations = {
    'Carte Grise (Safia)': 'بطاقة رمادية (صافية)',
    'Carte Jaune': 'بطاقة صفراء',
    'Licence Moudjahid': 'رخصة مجاهد',
    'Papiers Bloqués': 'وثائق محجوزة',
    'Sans Papiers': 'بدون وثائق'
  };

  static const Map<String, String> colorTranslations = {
    'Blanc': 'أبيض', 'Noir': 'أسود', 'Gris Argent': 'رمادي فضي', 'Gris Souris': 'رمادي غامق', 
    'Bleu': 'أزرق', 'Rouge': 'أحمر', 'Vert': 'أخضر', 'Beige': 'بيج', 'Marron': 'بني', 
    'Jaune': 'أصفر', 'Orange': 'برتقالي', 'Autre': 'آخر'
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
