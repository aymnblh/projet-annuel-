import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_translations.dart';
import '../models/product.dart';
import '../utils/categories_data.dart';
import '../services/analytics_service.dart';
import 'dart:async';
import '../main.dart';
import 'compare_screen.dart';
import 'price_estimation_screen.dart';
import 'showroom_dashboard_screen.dart';
import '../widgets/filter_sheet.dart';
import '../providers/user_provider.dart';
import 'alerts_screen.dart';
import '../services/recently_viewed_service.dart';
import 'product_details_screen.dart';
import '../widgets/recently_viewed_section.dart';
import '../widgets/search_autocomplete.dart';
import '../widgets/optimized_image.dart';
import 'product_card.dart';
import '../services/search_history_service.dart';
import 'about_screen.dart';
import 'contact_screen.dart';
import '../widgets/nlp_search_bar.dart';
import '../widgets/personalized_section.dart';
import 'visual_search_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- ÉTATS ACCUEIL ---
  String _searchQuery = "";
  String _selectedCategory = "Tout";
  
  // FILTERS
  String? _filterWilaya;
  double? _minPrice;
  double? _maxPrice;
  
  // CAR SPECIFIC FILTERS
  String? _filterBrand;
  String? _filterFuel;
  String? _filterGearbox;
  String? _filterVehicleType;
  String? _filterColor;
  int? _minYear;
  int? _maxYear;
  int? _minKm;
  int? _maxKm;
  bool _isAiSearchEnabled = false;

  bool _isLocating = false;
  List<dynamic> _wilayaList = [];
  
  // Search controller - FIX: Create once instead of on every build
  late final TextEditingController _searchController;

  String t(String key) => AppTranslations.get(languageNotifier.value, key);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _searchQuery);
    _loadWilayas();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _loadWilayas() async {
    setState(() {
      _wilayaList = CategoriesData.europeanMarkets
          .map((country) => {'nom_fr': country})
          .toList();
    });
  }

  // --- FILTRES AVANCÉS ---
  int _sortIndex = 0; // 0: Récent, 1: Prix Asc, 2: Prix Desc
  int _limit = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose(); // FIX: Dispose search controller
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_limit < 500) setState(() => _limit += 20);
    }
  }

  String? _cleanString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  String? _normalizeFromList(dynamic value, List<String> options) {
    final text = _cleanString(value);
    if (text == null) return null;
    final lower = text.toLowerCase();
    for (final option in options) {
      if (option.toLowerCase() == lower) return option;
    }
    return null;
  }

  double? _toDoubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    final text = _cleanString(value);
    if (text == null) return null;
    final normalized = text
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.]'), '');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  int? _toIntValue(dynamic value) {
    if (value is num) return value.toInt();
    final number = _toDoubleValue(value);
    return number?.round();
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    final text = _cleanString(value);
    return text == null ? [] : [text];
  }

  String? _normalizeFuel(dynamic value) {
    final text = _cleanString(value);
    if (text == null) return null;
    final lower = text.toLowerCase();
    if (lower.contains('essence')) return 'Essence';
    if (lower.contains('diesel')) return 'Diesel';
    if (lower.contains('gpl')) return 'GPL';
    if (lower.contains('hybr')) return 'Hybride';
    if (lower.contains('lect')) return 'Electrique';
    return _normalizeFromList(text, CategoriesData.fuelTypes);
  }

  String? _normalizeGearbox(dynamic value) {
    final text = _cleanString(value);
    if (text == null) return null;
    final lower = text.toLowerCase();
    if (lower.contains('semi')) return 'Semi-Automatique';
    if (lower.contains('auto')) return 'Automatique';
    if (lower.contains('man')) return 'Manuelle';
    return _normalizeFromList(text, CategoriesData.gearboxes);
  }

  String? _normalizeVehicleType(dynamic value) {
    final text = _cleanString(value);
    if (text == null) return null;
    final lower = text.toLowerCase();
    if (lower.contains('suv') || lower.contains('4x4')) return 'SUV / 4x4';
    if (lower.contains('mono') || lower.contains('van')) return 'Monospace / Van';
    return _normalizeFromList(text, CategoriesData.vehicleTypes);
  }

  void _applyAiFilters(Map<String, dynamic> filters) {
    final keywords = <String>[];
    final rawBrand = _cleanString(filters['brand']);
    final normalizedBrand = _normalizeFromList(rawBrand, CategoriesData.carBrands);
    final model = _cleanString(filters['model']);
    final yearRange = _cleanString(filters['yearRange']);

    if (rawBrand != null && normalizedBrand == null) keywords.add(rawBrand);
    if (model != null) keywords.add(model);
    keywords.addAll(_toStringList(filters['keywords']));
    keywords.addAll(_toStringList(filters['features']));

    int? minYear = _toIntValue(filters['minYear']);
    int? maxYear = _toIntValue(filters['maxYear']);
    if (yearRange != null && (minYear == null || maxYear == null)) {
      final years = RegExp(r'\d{4}')
          .allMatches(yearRange)
          .map((match) => int.tryParse(match.group(0)!))
          .whereType<int>()
          .toList();
      if (years.isNotEmpty) {
        minYear ??= years.first;
        maxYear ??= years.last;
      }
    }

    setState(() {
      _isAiSearchEnabled = true;
      _selectedCategory = 'Tout';
      _filterWilaya = _cleanString(filters['wilaya']);
      _filterBrand = normalizedBrand;
      _filterFuel = _normalizeFuel(filters['fuel']);
      _filterGearbox = _normalizeGearbox(filters['gearbox']);
      _filterVehicleType = _normalizeVehicleType(filters['vehicleType']);
      _filterColor = _normalizeFromList(filters['color'], CategoriesData.colors) ??
          _cleanString(filters['color']);
      _minPrice = _toDoubleValue(filters['minPrice']);
      _maxPrice = _toDoubleValue(filters['maxPrice']);
      _minYear = minYear;
      _maxYear = maxYear;
      _minKm = _toIntValue(filters['minKm']);
      _maxKm = _toIntValue(filters['maxKm']);
      _searchQuery = keywords.join(' ').trim();
      _searchController.text = _searchQuery;
      _limit = 20;
    });

    if (_scrollController.hasClients) _scrollController.jumpTo(0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtres IA appliques'),
        backgroundColor: Color(0xFF0F172A),
      ),
    );
  }

  Future<void> _openVisualSearch() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const VisualSearchScreen()),
    );

    if (!mounted || result == null) return;
    _applyAiFilters(result);
  }

  void _openChatbot() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatbotScreen()),
    );
  }

  void _runClassicSearch(String query) {
    setState(() {
      _searchQuery = query;
      _searchController.text = query;
      _limit = 20;
    });
    if (query.length > 2) {
      AnalyticsService.logSearch(query);
      SearchHistoryService().addSearch(
        query: query,
        resultCount: 0,
      );
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FilterSheet(
          initialFilters: {
            'wilaya': _filterWilaya,
            'category': _selectedCategory,
            'minPrice': _minPrice,
            'maxPrice': _maxPrice,
            'minYear': _minYear,
            'maxYear': _maxYear,
            'minKm': _minKm,
            'maxKm': _maxKm,
            'brand': _filterBrand,
            'fuel': _filterFuel,
            'gearbox': _filterGearbox,
            'sortIndex': _sortIndex,
          },
          onApply: (filters) {
            setState(() {
              _filterWilaya = filters['wilaya'];
              _selectedCategory = filters['category'];
              _minPrice = filters['minPrice'];
              _maxPrice = filters['maxPrice'];
              _minYear = filters['minYear'];
              _maxYear = filters['maxYear'];
              _minKm = filters['minKm'];
              _maxKm = filters['maxKm'];
              _filterBrand = filters['brand'];
              _filterFuel = filters['fuel'];
              _filterGearbox = filters['gearbox'];
              _filterVehicleType = null;
              _filterColor = null;
              _sortIndex = filters['sortIndex'];
              _limit = 20; 
            });
            if (_scrollController.hasClients) _scrollController.jumpTo(0);
          },
        );
      },
    );
  }

  void _showSaveAlertDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    // Auto-generate name based on filters
    List<String> parts = [];
    if (_filterBrand != null) parts.add(_filterBrand!);
    if (_filterFuel != null) parts.add(_filterFuel!);
    if (_maxPrice != null) parts.add("< ${_maxPrice!.toInt()}");
    nameCtrl.text = parts.isNotEmpty ? parts.join(" - ") : "Nouvelle Recherche";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Créer une alerte"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Soyez notifié quand une voiture correspondant Ã  ces critères est publiée."),
            const SizedBox(height: 10),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nom de l'alerte", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              
              // Construct Filters Map
              Map<String, dynamic> filters = {
                'brand': _filterBrand,
                'fuel': _filterFuel,
                'gearbox': _filterGearbox,
                'minYear': _minYear,
                'maxYear': _maxYear,
                'minPrice': _minPrice,
                'maxPrice': _maxPrice,
                'wilaya': _filterWilaya,
                'vehicleType': _filterVehicleType,
                'color': _filterColor,
              };
              // Remove nulls
              filters.removeWhere((key, value) => value == null);

              Provider.of<UserProvider>(context, listen: false).saveSearchAlert(filters, nameCtrl.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alerte créée avec succès ! ðŸ””"), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            child: const Text("Créer"),
          )
        ],
      ),
    );
  }

  Widget _buildHomeContent(bool isAr) {
    var screenWidth = MediaQuery.of(context).size.width;
    double itemHeight = 280;
    double itemWidth = (screenWidth - 48) / 2;
    double dynamicAspectRatio = itemWidth / itemHeight;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          // 1. HEADER MODERNE
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            color: theme.scaffoldBackgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     IconButton(icon: Icon(Icons.menu, color: theme.iconTheme.color), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
                     Text("AutoStore", style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w900, color: theme.textTheme.bodyLarge?.color)),
                     CircleAvatar(
                       radius: 18,
                       backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                       child: IconButton(
                         icon: Icon(
                           Icons.notifications_none,
                           color: isDark ? Colors.white : Colors.black,
                           size: 20,
                         ),
                         onPressed: () => Navigator.push(
                           context,
                           MaterialPageRoute(builder: (_) => const AlertsScreen()),
                         ),
                       ),
                     )
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.search),
                            label: Text('Classique'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.auto_awesome),
                            label: Text('Recherche IA'),
                          ),
                        ],
                        selected: {_isAiSearchEnabled},
                        showSelectedIcon: false,
                        onSelectionChanged: (values) {
                          setState(() => _isAiSearchEnabled = values.first);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Recherche visuelle',
                      icon: const Icon(Icons.camera_alt_outlined),
                      onPressed: _openVisualSearch,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isAiSearchEnabled)
                  NlpSearchBar(
                    onFiltersExtracted: _applyAiFilters,
                    onFallbackSearch: _runClassicSearch,
                    onVisualSearch: _openVisualSearch,
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: SearchAutocomplete(
                          controller: _searchController,
                          onSearch: _runClassicSearch,
                          hintText: t('search_hint') + " (ex: Golf 7)",
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.tune),
                        onPressed: _showFilterSheet,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // 2. CATEGORIES (Pill Tabs)
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: ["Tout", ...CategoriesData.categoryTranslations.keys].map((cat) {
                 // Use categoryTranslations keys which match subCategories keys now but cleaner
                final isSelected = _selectedCategory == cat;
                String label = cat;
                if (cat == 'Tout') {
                  label = 'Tout';
                } else if (isAr && CategoriesData.categoryTranslations.containsKey(cat)) label = CategoriesData.categoryTranslations[cat]!;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => setState(() {
                        _selectedCategory = cat;
                        _limit = 20; 
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primary : (isDark ? const Color(0xFF1E1E1E) : Colors.transparent),
                        borderRadius: BorderRadius.circular(30),
                        border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? theme.colorScheme.onPrimary : (isDark ? Colors.grey[300] : Colors.grey[600]), // FIX: Use onPrimary for contrast
                            fontWeight: FontWeight.bold,
                            fontFamily: GoogleFonts.cairo().fontFamily
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 10),

          // 3. RECENTLY VIEWED SECTION
          _buildRecentlyViewedSection(),

           // 4. ACTIVE FILTERS & SAVE ALERT
          if (_filterWilaya != null || _filterBrand != null || _filterFuel != null || _filterGearbox != null || _filterVehicleType != null || _filterColor != null || _minPrice != null || _maxPrice != null || _minYear != null || _maxYear != null || _minKm != null || _maxKm != null || _searchQuery.isNotEmpty)
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 SingleChildScrollView(
                   scrollDirection: Axis.horizontal,
                   padding: const EdgeInsets.symmetric(horizontal: 20),
                   child: Row(
                   children: [
                     if (_searchQuery.isNotEmpty) _buildFilterChip("Recherche: $_searchQuery", () => setState(() {
                       _searchQuery = "";
                       _searchController.clear();
                     })),
                     if (_filterWilaya != null) _buildFilterChip(_filterWilaya!, () => setState(() => _filterWilaya = null)),
                     if (_filterBrand != null) _buildFilterChip(_filterBrand!, () => setState(() => _filterBrand = null)),
                     if (_filterFuel != null) _buildFilterChip(_filterFuel!, () => setState(() => _filterFuel = null)),
                     if (_filterGearbox != null) _buildFilterChip(_filterGearbox!, () => setState(() => _filterGearbox = null)),
                     if (_filterVehicleType != null) _buildFilterChip(_filterVehicleType!, () => setState(() => _filterVehicleType = null)),
                     if (_filterColor != null) _buildFilterChip(_filterColor!, () => setState(() => _filterColor = null)),
                     if (_minPrice != null) _buildFilterChip("> ${_minPrice!.toInt()} EUR", () => setState(() => _minPrice = null)),
                     if (_maxPrice != null) _buildFilterChip("< ${_maxPrice!.toInt()} EUR", () => setState(() => _maxPrice = null)),
                     if (_minYear != null) _buildFilterChip(">= $_minYear", () => setState(() => _minYear = null)),
                     if (_maxYear != null) _buildFilterChip("<= $_maxYear", () => setState(() => _maxYear = null)),
                     if (_minKm != null) _buildFilterChip("> $_minKm km", () => setState(() => _minKm = null)),
                     if (_maxKm != null) _buildFilterChip("< $_maxKm km", () => setState(() => _maxKm = null)),
                     
                     // SAVE ALERT BUTTON
                     const SizedBox(width: 5),
                     ActionChip(
                       avatar: const Icon(Icons.notifications_active, size: 16, color: Colors.white),
                       label: Text("M'alerter", style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                       backgroundColor: const Color(0xFF0F172A),
                       onPressed: _showSaveAlertDialog,
                     )
                   ],
                 )),
                 const SizedBox(height: 10),
               ],
             ),

          // NEW: RECENTLY VIEWED SECTION
          const RecentlyViewedSection(),

          const PersonalizedSection(),

          // 4. GRID PRODUCTS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: () {
                Query q = FirebaseFirestore.instance.collection('products');
                // Server-side Basic Filters
                if (_selectedCategory != "Tout") {
                   q = q.where('category', isEqualTo: _selectedCategory);
                }
                if (_filterWilaya != null) {
                   q = q.where('wilaya', isEqualTo: _filterWilaya);
                }
                if (_filterBrand != null) {
                  q = q.where('brand', isEqualTo: _filterBrand);
                }
                  q = q.where('isApproved', isEqualTo: true) // MODERATION
                       .orderBy('isBoosted', descending: true) // TRI PAR BOOST
                       .orderBy('createdAt', descending: true);
                return q.limit(_limit).snapshots();
              }(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // LOG ERROR to see if it's an index issue
                  debugPrint("HOME STREAM ERROR: ${snapshot.error}");
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 40),
                          const SizedBox(height: 10),
                          Text(t('error_occurred'), style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                          const SizedBox(height: 5),
                          Text(
                            "${snapshot.error}", 
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 12)
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text("Réessayer")
                          )
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                List<Product> products = snapshot.data!.docs.map((d) => Product.fromFirestore(d)).where((p) {
                   // Client-side Advanced Filtering
                   
                   // Search Query
                   if (_searchQuery.isNotEmpty) {
                     final q = _searchQuery.toLowerCase();
                     final terms = q
                         .split(RegExp(r'\s+'))
                         .where((term) => term.trim().isNotEmpty)
                         .toList();
                     final haystack = [
                       p.title,
                       p.description,
                       p.model ?? '',
                       p.brand ?? '',
                       ...p.detectedEquipments,
                     ].join(' ').toLowerCase();
                     if (terms.isNotEmpty &&
                         !terms.every((term) => haystack.contains(term))) {
                       return false;
                     }
                   }

                   // Price
                   if (_minPrice != null && p.price < _minPrice!) return false;
                   if (_maxPrice != null && p.price > _maxPrice!) return false;
                   
                   // Car Specifics
                   if (_filterFuel != null && p.fuel != _filterFuel) return false;
                   if (_filterGearbox != null && p.gearbox != _filterGearbox) return false;
                   if (_filterVehicleType != null &&
                       (p.vehicleType == null ||
                        p.vehicleType!.toLowerCase() != _filterVehicleType!.toLowerCase())) {
                     return false;
                   }
                   if (_filterColor != null &&
                       (p.color == null ||
                        p.color!.toLowerCase() != _filterColor!.toLowerCase())) {
                     return false;
                   }
                   
                   if (_minYear != null && p.year != null) {
                      int? y = int.tryParse(p.year!);
                      if (y != null && y < _minYear!) return false;
                   }
                   if (_maxYear != null && p.year != null) {
                      int? y = int.tryParse(p.year!);
                      if (y != null && y > _maxYear!) return false;
                   }

                   if (_minKm != null && p.km != null) {
                      int? k = int.tryParse(p.km!);
                      if (k != null && k < _minKm!) return false;
                   }
                   if (_maxKm != null && p.km != null) {
                      int? k = int.tryParse(p.km!);
                      if (k != null && k > _maxKm!) return false;
                   }

                   return !p.isSold;
                }).toList();

                if (_sortIndex == 0) { // Recent
                   // Already sorted by query
                } else if (_sortIndex == 1) {
                  products.sort((a, b) => a.price.compareTo(b.price));
                } else if (_sortIndex == 2) {
                  products.sort((a, b) => b.price.compareTo(a.price));
                }

                if (products.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, size: 50, color: Colors.grey[300]), const SizedBox(height: 10), Text(t('no_products'), style: TextStyle(color: Colors.grey[500]))]));

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    childAspectRatio: dynamicAspectRatio,
                    mainAxisSpacing: 20, 
                    crossAxisSpacing: 20
                  ), 
                  itemCount: products.length, 
                  controller: _scrollController,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final isSelected = _selectedProductIds.contains(product.id);
                    return ProductCard(
                      product: product,
                      isSelected: isSelected,
                      onLongPress: () => _toggleSelection(product),
                    );
                  }
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 10),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12, color: Colors.blue)),
        backgroundColor: Colors.blue.withOpacity(0.1),
        deleteIcon: const Icon(Icons.close, size: 14, color: Colors.blue),
        onDeleted: onDeleted,
        side: BorderSide.none,
      ),
    );
  }

  // --- SELECTION COMPARATEUR ---
  final Set<String> _selectedProductIds = {};
  final List<Product> _selectedProducts = [];

  void _toggleSelection(Product product) {
    setState(() {
      if (_selectedProductIds.contains(product.id)) {
        _selectedProductIds.remove(product.id);
        _selectedProducts.removeWhere((p) => p.id == product.id);
      } else {
        if (_selectedProductIds.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maximum 3 véhicules Ã  comparer")));
          return;
        }
        _selectedProductIds.add(product.id);
        _selectedProducts.add(product);
      }
    });
  }

  // --- DRAWER ---
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0F172A)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.directions_car, color: Colors.amber, size: 40),
                const SizedBox(height: 10),
                Text("OneClick Cars", style: GoogleFonts.cairo(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text("Europe", style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.price_change),
            title: Text("La Côte (Argus)"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PriceEstimationScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: Text("Mes Alertes"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())),
          ),
           // SHOWROOM LINK (SaaS)
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.blueAccent),
            title: Text("Mon Showroom (Pro)"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShowroomDashboardScreen())),
          ),
          if (_selectedProductIds.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.compare_arrows),
              title: Text("Comparateur"),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CompareScreen(products: _selectedProducts))),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text("Mon Profil"),
            onTap: () {}, 
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text("À propos"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.contact_support),
            title: Text("Contactez-nous"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactScreen())),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // KEY ADDED
      drawer: _buildDrawer(), // DRAWER ADDED
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: _selectedProductIds.isEmpty
          ? FloatingActionButton.extended(
              onPressed: _openChatbot,
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text('Assistant IA'),
            )
          : null,
      body: Stack(
        children: [
          _buildHomeContent(isAr),
          
          // BOUTON COMPARER FLOTTANT
          if (_selectedProductIds.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CompareScreen(products: _selectedProducts)));
                  // On pourrait reset la sélection après retour, ou laisser le choix
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5
                ),
                icon: const Icon(Icons.compare_arrows),
                label: Text(
                  "Comparer (${_selectedProducts.length})",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Recently Viewed Section
  Widget _buildRecentlyViewedSection() {
    final isAr = languageNotifier.value == 'ar';
    final theme = Theme.of(context);

    return StreamBuilder<List<String>>(
      stream: RecentlyViewedService.getRecentlyViewed(),
      builder: (context, snapshot) {
        // Don't show section if no data yet or empty
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final productIds = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.history, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Vus récemment',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      await RecentlyViewedService.clearHistory();
                    },
                    child: Text(
                      'Effacer',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Scrollable List
            SizedBox(
              height: 220,
              child: FutureBuilder<List<Product>>(
                future: _fetchRecentlyViewedProducts(productIds),
                builder: (context, productSnapshot) {
                  if (!productSnapshot.hasData) {
                    // Loading skeletons
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: HorizontalCardSkeleton(),
                        );
                      },
                    );
                  }

                  final products = productSnapshot.data!;

                  if (products.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildRecentlyViewedCard(product);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildRecentlyViewedCard(Product product) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: OptimizedImage(
                imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls[0] : '',
                width: 160,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Price
                  Text(
                    '${product.price.toStringAsFixed(0)} EUR',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 10, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product.wilaya,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Product>> _fetchRecentlyViewedProducts(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    try {
      final products = <Product>[];
      
      // Fetch products in batches (Firestore 'in' query limit is 10)
      for (var i = 0; i < productIds.length; i += 10) {
        final batch = productIds.skip(i).take(10).toList();
        
        final snapshot = await FirebaseFirestore.instance
            .collection('products')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        products.addAll(
          snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
        );
      }

      // Sort by the order in productIds (most recent first)
      products.sort((a, b) {
        final indexA = productIds.indexOf(a.id);
        final indexB = productIds.indexOf(b.id);
        return indexA.compareTo(indexB);
      });

      return products;
    } catch (e) {
      debugPrint('Error fetching recently viewed products: $e');
      return [];
    }
  }
}
