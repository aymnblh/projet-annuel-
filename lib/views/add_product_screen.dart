import 'dart:io';
import 'dart:convert';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../utils/app_translations.dart';
import '../utils/categories_data.dart';
import '../widgets/add_product/product_media_picker.dart';
import '../services/video_compression_service.dart'; // NEW: Video compression
import '../services/ai_service.dart'; // NEW: AI enriched analysis
import '../services/image_moderation_service.dart'; // NEW: Image moderation (blur faces/plates)
import '../services/kyc_fraud_service.dart';
import '../main.dart';
import '../utils/button_utils.dart';

class AddProductScreen extends StatefulWidget {
  /// Pass 'rent' from RentalMobileLayout to pre-select the listing type.
  final String initialListingType;

  /// Callback appelé après publication réussie (pour revenir à l'accueil depuis la BottomNav).
  final VoidCallback? onSuccess;

  const AddProductScreen({
    super.key,
    this.initialListingType = 'sale',
    this.onSuccess,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isAnalyzing = false;
  bool _isLocating = false;
  bool _isCompressingVideo = false; // NEW: Video compression state
  double _compressionProgress = 0.0; // NEW: Compression progress
  bool _isGeneratingDescription = false; // NEW: Description generation state
  bool _isModeratingImages = false; // NEW: Image moderation state
  int _moderationProgress = 0; // NEW: Current image being moderated
  List<String> _detectedEquipments = []; // NEW: AI-detected equipments
  bool _imagesModerated = false; // NEW: Track if images were moderated

  List<XFile> _images = [];
  List<XFile> _videos = [];

  // --- LOCATION ---
  List<dynamic> _wilayaList = [];
  List<dynamic> _communeList = [];
  List<dynamic> _filteredCommunes = [];
  int? _selectedWilayaId;
  String? _selectedWilayaName;
  String? _selectedCommuneName;

  // --- CONTROLLERS ---
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _kmController = TextEditingController();
  final _yearController = TextEditingController(); // Nouveau controller
  final _modelController = TextEditingController(); // Free text for model
  final _engineController = TextEditingController(); // Free text for engine
  final _simpleStockController = TextEditingController(text: '1');

  // --- DROPDOWNS ---
  String _selectedCategory = "Voitures Occasion";
  String _etat = "Bon Ã©tat";
  String? _selectedFuel;
  String? _selectedGearbox;
  String? _selectedBrand;
  String? _selectedPaper;
  String? _selectedColor;
  bool _exchangeAccepted = false;

  // --- SELLER LOCATION ---
  String _sellerCountry = 'France';

  // --- LISTING TYPE ---
  late String _listingType; // 'sale' | 'rent' | 'both'

  List<Map<String, dynamic>> _variants = [];
  bool _hasVariants = false;

  final Map<String, String> _etatMap = {
    'Neuf': 'Ø¬Ø¯ÙŠØ¯', 'Excellent Ã©tat': 'Ø­Ø§Ù„Ø© Ù…Ù…ØªØ§Ø²Ø©', 'Bon Ã©tat': 'Ø­Ø§Ù„Ø© Ø¬ÙŠØ¯Ø©', 'Ã‰tat moyen': 'Ø­Ø§Ù„Ø© Ù…ØªÙˆØ³Ø·Ø©', 'Pour piÃ¨ces': 'Ù‚Ø·Ø¹Ø© ØºÙŠØ§Ø±'
  };

  // Liste annÃ©es supprimÃ©e car saisie libre
  // final List<String> _years = List.generate(47, (index) => (2026 - index).toString());

  String t(String key) => AppTranslations.get(languageNotifier.value, key);

  @override
  void initState() {
    super.initState();
    _listingType = widget.initialListingType;
    _checkDraft();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    setState(() {
      _wilayaList = CategoriesData.europeanMarkets
          .map((country) => {'nom_fr': country})
          .toList();
      _communeList = CategoriesData.europeanCitiesByCountry.entries
          .expand(
            (entry) => entry.value.map(
              (city) => {
                'country': entry.key,
                'nom_fr': city,
              },
            ),
          )
          .toList();
    });
    // FIX 1: Pré-sélectionner automatiquement le premier pays
    if (_wilayaList.isNotEmpty && _selectedWilayaId == null) {
      _onWilayaChanged(1);
    }
  }

  // --- GEMINI AI (ENRICHED) ---
  Future<void> _analyzeImageWithAI(XFile image) async {
    setState(() => _isAnalyzing = true);
    try {
      final aiService = AIService();
      final data = await aiService.analyzeImageEnriched(File(image.path));
      
      if (data != null) {
        setState(() {
          _titleController.text = data['title'] ?? "";
          _descController.text = data['description'] ?? "";
          if (data['price'] != null) _priceController.text = data['price'].toString();
          if (CategoriesData.carBrands.contains(data['brand'])) _selectedBrand = data['brand'];
          _modelController.text = data['model'] ?? "";
          _yearController.text = data['year']?.toString() ?? "";
          if (CategoriesData.colors.contains(data['color'])) _selectedColor = data['color'];
          
          // NEW: Detected equipments
          if (data['detectedEquipments'] != null) {
            _detectedEquipments = List<String>.from(data['detectedEquipments']);
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Auto-rempli ! âœ¨ ${_detectedEquipments.length} Ã©quipements dÃ©tectÃ©s"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      String errorMsg = "Analyse IA Ã©chouÃ©e";
      if (e.toString().contains('API_KEY')) {
        errorMsg = "Erreur: ClÃ© API invalide";
      } else if (e.toString().contains('quota') || e.toString().contains('RESOURCE_EXHAUSTED')) {
        errorMsg = "Erreur: Quota API dÃ©passÃ©. RÃ©essayez plus tard.";
      } else if (e.toString().contains('network') || e.toString().contains('SocketException')) {
        errorMsg = "Erreur: Pas de connexion Internet";
      } else {
        errorMsg = "Analyse IA Ã©chouÃ©e: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}";
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.orange, duration: const Duration(seconds: 5)),
        );
      }
      print("AI Analysis Error: $e");
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  // --- GENERATE MARKETING DESCRIPTION ---
  Future<void> _generateMarketingDescription() async {
    if (_titleController.text.isEmpty || _selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Remplissez d'abord le titre et la marque")),
      );
      return;
    }
    setState(() => _isGeneratingDescription = true);
    try {
      final aiService = AIService();
      final description = await aiService.generateSellerDescription(
        title: _titleController.text,
        brand: _selectedBrand ?? '',
        model: _modelController.text,
        year: _yearController.text,
        km: _kmController.text,
        fuel: _selectedFuel,
        gearbox: _selectedGearbox,
        color: _selectedColor,
        engine: _engineController.text,
        condition: _etat,
        equipments: _detectedEquipments,
      );
      if (description != null && mounted) {
        setState(() => _descController.text = description);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Description gÃ©nÃ©rÃ©e ! âœï¸"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur gÃ©nÃ©ration: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingDescription = false);
    }
  }

  // --- IMAGE MODERATION (blur faces & plates) ---
  Future<List<File>> _moderateImages(List<XFile> images) async {
    if (images.isEmpty) return [];
    setState(() {
      _isModeratingImages = true;
      _moderationProgress = 0;
    });
    
    try {
      final moderationService = ImageModerationService();
      final files = images.map((x) => File(x.path)).toList();
      final result = await moderationService.moderateAllImages(
        files,
        onProgress: (current, total) {
          if (mounted) setState(() => _moderationProgress = current + 1);
        },
      );
      
      if (mounted && result.hadModifications) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ðŸ”’ ModÃ©ration: ${result.facesBlurred} visage(s) et '
              '${result.platesBlurred} plaque(s) floutÃ©s',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _imagesModerated = true);
      }
      
      return result.moderatedFiles;
    } catch (e) {
      debugPrint('Moderation error: $e');
      // Return original files on error
      return images.map((x) => File(x.path)).toList();
    } finally {
      if (mounted) setState(() => _isModeratingImages = false);
    }
  }

  // --- SUBMIT ---
  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty && _videos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ajoutez au moins une photo")));
      return;
    }
    if (_selectedWilayaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selectionnez le pays")));
      return;
    }
    // Validation spÃ©cifique Voitures
    if ((_selectedCategory.contains("Voiture") || _selectedCategory == "Camions & Engins") && (_selectedBrand == null || _yearController.text.isEmpty || _selectedFuel == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir les informations du vÃ©hicule (Marque, AnnÃ©e, Carburant)")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur: Vous n'êtes pas connecté."), backgroundColor: Colors.red));
        }
        return;
      }
      
      List<String> imageUrls = [];
      try {
        final moderatedFiles = await _moderateImages(_images);
        for (int i = 0; i < moderatedFiles.length; i++) {
          final fileName = "cars/${DateTime.now().millisecondsSinceEpoch}_img_$i.jpg";
          final ref = FirebaseStorage.instance.ref().child(fileName);
          await ref.putFile(moderatedFiles[i]);
          imageUrls.add(await ref.getDownloadURL());
        }
      } catch (e) {
        debugPrint('Image upload error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ Les images n’ont pas pu être traitées, la publication continue avec les fichiers disponibles.'), backgroundColor: Colors.orange),
          );
        }
      }

      // Upload Videos with Compression
      List<String> videoUrls = [];
      final compressionService = VideoCompressionService();
      
      for (int i = 0; i < _videos.length; i++) {
        final video = _videos[i];
        
        // Show compression UI
        if (mounted) {
          setState(() {
            _isCompressingVideo = true;
            _compressionProgress = 0.0;
          });
        }
        
        try {
          // Compress video with progress tracking
          final compressedVideo = await compressionService.compressVideo(
            videoFile: File(video.path),
            onProgress: (progress) {
              if (mounted) {
                setState(() => _compressionProgress = progress);
              }
            },
          );
          
          if (compressedVideo == null) {
            throw Exception('Compression failed for video ${i + 1}');
          }
          
          // Get compression stats for user feedback
          final stats = await compressionService.getCompressionStats(
            originalFile: File(video.path),
            compressedFile: compressedVideo,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'VidÃ©o ${i + 1} compressÃ©e: ${stats.originalSizeFormatted} â†’ '
                  '${stats.compressedSizeFormatted} (-${stats.reductionPercentage.toStringAsFixed(0)}%)',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          
          // Upload compressed video
          String fileName = "cars_vid/${DateTime.now().millisecondsSinceEpoch}_compressed_${video.name}";
          Reference ref = FirebaseStorage.instance.ref().child(fileName);
          await ref.putFile(compressedVideo);
          videoUrls.add(await ref.getDownloadURL());
          
          // Clean up compressed file
          try {
            await compressedVideo.delete();
          } catch (e) {
            debugPrint('Error deleting temp file: $e');
          }
          
          
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur compression vidÃ©o ${i + 1}: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          // Continue with original video if compression fails
          String fileName = "cars_vid/${DateTime.now().millisecondsSinceEpoch}_${video.name}";
          Reference ref = FirebaseStorage.instance.ref().child(fileName);
          await ref.putFile(File(video.path));
          videoUrls.add(await ref.getDownloadURL());
        }
      }
      
      // Hide compression UI
      if (mounted) {
        setState(() {
          _isCompressingVideo = false;
          _compressionProgress = 0.0;
        });
      }

      Map<String, dynamic> productData = {
        'sellerId': user.uid,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'category': _selectedCategory,
        'wilaya': _selectedWilayaName,
        'commune': _selectedCommuneName,
        'imageUrls': imageUrls,
        'videoUrls': videoUrls,
        'phone': _phoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'isSold': false,
        'condition': _etat,
        'listingType': _listingType,
        'sellerCountry': _sellerCountry,
        
        // CAR FIELDS
        'brand': _selectedBrand,
        'model': _modelController.text.trim(),
        'year': _yearController.text.trim(),
        'km': _kmController.text.trim(),
        'fuel': _selectedFuel,
        'gearbox': _selectedGearbox,
        'engine': _engineController.text.trim(),
        'color': _selectedColor,
        'papers': _selectedPaper,
        'exchange': _exchangeAccepted,
        'detectedEquipments': _detectedEquipments, // NEW: AI-detected equipment
        
        'viewCount': 0,
        'isApproved': false, // Moderation: Default false
        'fraudRiskScore': 0,
        'fraudRiskLevel': 'low',
        'fraudRiskReasons': [],
        'fraudRecommendation': 'manual_review',
      };

      final fraudResult = await KycFraudService().evaluateProductFraud(productData, sellerData: {
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName,
      });

      if (fraudResult != null) {
        productData['fraudRiskScore'] = fraudResult['fraudRiskScore'];
        productData['fraudRiskLevel'] = fraudResult['fraudRiskLevel'];
        productData['fraudRiskReasons'] = fraudResult['fraudRiskReasons'];
        productData['fraudRecommendation'] = fraudResult['recommendation'];
      }

      await FirebaseFirestore.instance.collection('products').add(productData);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Annonce publiée ! 🚀"), backgroundColor: Colors.green),
        );
        // FIX écran noir : si on est dans la BottomNav (pas pushé), utiliser le callback.
        // Sinon, tenter un pop normal.
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // FIX 3: Messages d'erreur clairs selon le type d'exception Firebase
        String errorMsg;
        if (e is FirebaseException) {
          switch (e.code) {
            case 'permission-denied':
              errorMsg = '🔒 Accès refusé. Vérifiez que vous êtes bien connecté.';
              break;
            case 'unavailable':
            case 'network-request-failed':
              errorMsg = '📶 Pas de connexion Internet. Vérifiez votre réseau et réessayez.';
              break;
            case 'unauthenticated':
              errorMsg = '🔑 Session expirée. Veuillez vous reconnecter.';
              break;
            case 'storage/unauthorized':
              errorMsg = '🖼️ Erreur de téléchargement des photos. Réessayez.';
              break;
            default:
              errorMsg = 'Erreur Firebase (${e.code}): ${e.message}';
          }
        } else {
          errorMsg = 'Erreur: ${e.toString()}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg, maxLines: 5),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
          )
        );
      }
    }
  }

  // --- UI BUILDERS ---
  
  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged, {Map<String, String>? translations}) {
    bool isAr = languageNotifier.value == 'ar';
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      value: value,
      items: items.map((e) {
        String displayText = e;
        if (isAr && translations != null && translations.containsKey(e)) {
          displayText = translations[e]!;
        }
        return DropdownMenuItem(value: e, child: Text(displayText));
      }).toList(),
      onChanged: onChanged,
      validator: (val) => val == null && label.contains("*") ? "Requis" : null,
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, {bool isNumber = false, int lines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: lines,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (val) => val!.isEmpty ? "Requis" : null,
    );
  }

  // --- LOCATION ---
  void _onWilayaChanged(int? wilayaId) {
    if (wilayaId == null) return;
    setState(() {
      _selectedWilayaId = wilayaId;
      _selectedCommuneName = null;
      _selectedWilayaName = _wilayaList[wilayaId - 1]['nom_fr'];
      _sellerCountry = _selectedWilayaName ?? _sellerCountry;
      _filteredCommunes = _communeList
          .where((c) => c['country'] == _selectedWilayaName)
          .toList();
    });
  }

  Future<void> _detectLocation() async {
     // Simplified for brevity - assumes permissions are handled similarly to previous
     setState(() => _isLocating = true);
     // ... (Keep existing logic or simplify)
     await Future.delayed(const Duration(seconds: 1)); // Mock
     setState(() => _isLocating = false);
  }

  // --- DRAFTS ---
  Future<void> _checkDraft() async {} // Placeholder
  Future<void> _saveDraft() async {} // Placeholder

  Widget _buildListingTypeSelector(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'Ù†ÙˆØ¹ Ø§Ù„Ø¥Ø¹Ù„Ø§Ù†' : 'Type d\'annonce',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'sale',
              label: Text(isAr ? 'Ù„Ù„Ø¨ÙŠØ¹' : 'Ã€ Vendre'),
              icon: const Icon(Icons.sell_rounded),
            ),
            ButtonSegment(
              value: 'rent',
              label: Text(isAr ? 'Ù„Ù„Ø¥ÙŠØ¬Ø§Ø±' : 'Ã€ Louer'),
              icon: const Icon(Icons.vpn_key_rounded),
            ),
            ButtonSegment(
              value: 'both',
              label: Text(isAr ? 'ÙƒÙ„Ø§Ù‡Ù…Ø§' : 'Les deux'),
              icon: const Icon(Icons.compare_arrows_rounded),
            ),
          ],
          selected: {_listingType},
          onSelectionChanged: (s) => setState(() => _listingType = s.first),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF0F172A);
              }
              return null;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSellerCountryPicker(bool isAr) {
    final bool isImport = _sellerCountry == 'Autre';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown(
          isAr ? 'Ø¯ÙˆÙ„Ø© Ø§Ù„Ø¨Ø§Ø¦Ø¹' : 'Pays du vendeur',
          CategoriesData.sellerCountries,
          _sellerCountry,
          (v) => setState(() => _sellerCountry = v ?? 'France'),
          translations: CategoriesData.countryTranslations,
        ),
        if (isImport) ...
          [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAr
                        ? 'ØªÙ†Ø¨ÙŠÙ‡ Ø§Ø³ØªÙŠØ±Ø§Ø¯: Ø§Ù„Ø³ÙŠØ§Ø±Ø© ÙŠØ¬Ø¨ Ø£Ù† ØªÙƒÙˆÙ† Ø£Ù‚Ù„ Ù…Ù† 3 Ø³Ù†ÙˆØ§Øª (${DateTime.now().year - 2} Ø£Ùˆ Ø£Ø­Ø¯Ø«).'
                        : 'Vente transfrontaliere : verifiez COC, TVA/quitus fiscal, immatriculation et assurance selon le pays.',
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = languageNotifier.value == 'ar';
    bool isVehicle = _selectedCategory.contains("Voiture") || _selectedCategory == "Camions & Engins" || _selectedCategory == "Motos";

    return Scaffold(
      appBar: AppBar(title: Text(isAr ? "Ø¥Ø¶Ø§ÙØ© Ø¥Ø¹Ù„Ø§Ù†" : "Publier une annonce"), actions: [
        IconButton(onPressed: _saveDraft, icon: const Icon(Icons.save_outlined))
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProductMediaPicker(
                isAr: isAr, 
                isAnalyzing: _isAnalyzing, 
                onImagesChanged: (i) => _images = i, 
                onVideosChanged: (v) => _videos = v, 
                onRequestAnalysis: (i) => _analyzeImageWithAI(i)
              ),
              const SizedBox(height: 20),

              // LISTING TYPE SELECTOR
              _buildListingTypeSelector(isAr),
              const SizedBox(height: 15),

              // SELLER COUNTRY
              _buildSellerCountryPicker(isAr),
              const SizedBox(height: 15),

              _buildDropdown(isAr ? "الفئة" : "Catégorie *", CategoriesData.categoryTranslations.keys.toList(), _selectedCategory, (v) => setState(() => _selectedCategory = v!), translations: CategoriesData.categoryTranslations),
              const SizedBox(height: 15),

              _buildTextField(_titleController, isAr ? "العنوان" : "Titre de l'annonce"),
              const SizedBox(height: 15),
              _buildTextField(_priceController, isAr ? "السعر" : "Prix (EUR)", isNumber: true),
              const SizedBox(height: 15),

              if (isVehicle) ...[
                const Divider(),
                Text(isAr ? "مواصفات المركبة" : "Spécifications du véhicule", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                
                Row(children: [
                  Expanded(child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          return CategoriesData.carBrands.where((String option) {
                            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (String selection) {
                          setState(() => _selectedBrand = selection);
                        },
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          // Allow pre-filling if _selectedBrand is set (e.g. by AI)
                          if (_selectedBrand != null && textEditingController.text.isEmpty) {
                             textEditingController.text = _selectedBrand!;
                          }
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: isAr ? "الماركة" : "Marque *",
                              border: const OutlineInputBorder(),
                            ),
                            // FIX 2: Capturer la marque même si l'utilisateur saisit manuellement
                            onChanged: (val) {
                              _selectedBrand = val.isNotEmpty ? val : null;
                            },
                            validator: (val) {
                               if (val == null || val.isEmpty) return "Requis";
                               _selectedBrand = val;
                               return null;
                            },
                          );
                        },
                      );
                    }
                  )),

                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_modelController, isAr ? "الموديل" : "Modèle *")),
                ]),
                const SizedBox(height: 10),
                
                Row(children: [
                  Expanded(child: _buildTextField(_yearController, isAr ? "السنة" : "Année (ex: 2023)", isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_kmController, isAr ? "المسافة (كم)" : "Kilométrage", isNumber: true)),
                ]),
                const SizedBox(height: 10),

                Row(children: [
                  Expanded(child: _buildDropdown(isAr ? "الوقود" : "Carburant *", CategoriesData.fuelTypes, _selectedFuel, (v) => setState(() => _selectedFuel = v), translations: CategoriesData.fuelTranslations)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildDropdown(isAr ? "ناقل الحركة" : "Boîte", CategoriesData.gearboxes, _selectedGearbox, (v) => setState(() => _selectedGearbox = v), translations: CategoriesData.gearboxTranslations)),
                ]),
                const SizedBox(height: 10),

                Row(children: [
                  Expanded(child: _buildDropdown(isAr ? "اللون" : "Couleur", CategoriesData.colors, _selectedColor, (v) => setState(() => _selectedColor = v), translations: CategoriesData.colorTranslations)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_engineController, isAr ? "المحرك" : "Moteur (ex: 1.6 HDI)")),
                ]),
                const SizedBox(height: 10),

                _buildDropdown(isAr ? "الأوراق" : "Papiers", CategoriesData.papers, _selectedPaper, (v) => setState(() => _selectedPaper = v), translations: CategoriesData.papersTranslations),
                
                CheckboxListTile(
                  value: _exchangeAccepted, 
                  onChanged: (v) => setState(() => _exchangeAccepted = v!),
                  title: Text(isAr ? "أقبل التبادل" : "J'accepte l'échange"),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
              ],

              // --- AI-DETECTED EQUIPMENTS ---
              if (_detectedEquipments.isNotEmpty) ...[
                Text(
                  isAr ? "المميزات المكتشفة بالذكاء الاصطناعي" : "Équipements détectés par l'IA ✨",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _detectedEquipments.map((eq) {
                    return Chip(
                      label: Text(eq, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setState(() => _detectedEquipments.remove(eq)),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 15),
              ],

              _buildTextField(_descController, isAr ? "الوصف" : "Description", lines: 4),
              const SizedBox(height: 8),
              
              // --- GENERATE MARKETING DESCRIPTION BUTTON ---
              OutlinedButton.icon(
                onPressed: _isGeneratingDescription ? null : _generateMarketingDescription,
                icon: _isGeneratingDescription
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, color: Colors.purple),
                label: Text(
                  _isGeneratingDescription
                      ? (isAr ? "جاري التوليد..." : "Génération en cours...")
                      : (isAr ? "✨ توليد وصف بيع احترافي" : "✨ Générer une description vendeuse"),
                  style: TextStyle(color: _isGeneratingDescription ? Colors.grey : Colors.purple),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.purple),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),
              
              // --- IMAGE MODERATION STATUS ---
              if (_isModeratingImages)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Text(
                        '🛡️ Modération image $_moderationProgress/${_images.length}...',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              if (_imagesModerated)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('✅ Images modérées (visages/plaques floutés)', style: TextStyle(fontSize: 13, color: Colors.green)),
                    ],
                  ),
                ),

              // Location
               Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true, 
                      value: _selectedWilayaId,
                      decoration: InputDecoration(labelText: isAr ? "الولاية" : "Pays", border: const OutlineInputBorder()),
                      items: _wilayaList.asMap().entries.map((entry) => DropdownMenuItem<int>(
                        value: entry.key + 1,
                        child: Text(entry.value['nom_fr'], overflow: TextOverflow.ellipsis)
                      )).toList(),
                      onChanged: _onWilayaChanged
                    )
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true, 
                      value: _selectedCommuneName,
                      decoration: InputDecoration(labelText: isAr ? "المدينة" : "Ville", border: const OutlineInputBorder()),
                      items: _filteredCommunes.map((c) => DropdownMenuItem<String>(
                        value: c['nom_fr'],
                        child: Text(c['nom_fr'], overflow: TextOverflow.ellipsis)
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedCommuneName = val)
                    )
                  )
                ]
              ),
              const SizedBox(height: 15),
              _buildTextField(_phoneController, isAr ? "الهاتف" : "Téléphone", isNumber: true),

              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.all(15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check, color: Colors.white),
                label: Text(
                  isAr ? "نشر الإعلان" : "PUBLIER",
                  style: TextStyle(
                    color: getContrastTextColor(const Color(0xFF0F172A)),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

