import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../utils/categories_data.dart';
import '../../main.dart';
import '../../utils/app_translations.dart';
import '../../providers/app_mode_provider.dart';
import '../product_details_screen.dart';
import '../add_product_screen.dart';
import '../../widgets/optimized_image.dart';

class RentalHomeScreen extends StatefulWidget {
  const RentalHomeScreen({super.key});

  @override
  State<RentalHomeScreen> createState() => _RentalHomeScreenState();
}

class _RentalHomeScreenState extends State<RentalHomeScreen> {
  // â”€â”€ FILTERS â”€â”€
  String? _filterWilaya;
  String? _filterGearbox;       // Manuelle / Automatique
  String? _filterVehicleType;   // Citadine, SUVâ€¦
  double _maxPricePerDay = 20000;
  double _currentMaxPrice = 20000;
  DateTime? _startDate;
  DateTime? _endDate;

  String _searchQuery = '';
  int _limit = 20;
  final ScrollController _scrollController = ScrollController();

  // Wilayas loaded for filter dropdown
  final List<String> _popularWilayas = [
    'Alger', 'Oran', 'Constantine', 'Annaba', 'Blida',
    'Tlemcen', 'SÃ©tif', 'Batna', 'BÃ©jaÃ¯a', 'Tizi Ouzou',
  ];

  String t(String key) => AppTranslations.get(languageNotifier.value, key);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (_limit < 200) setState(() => _limit += 20);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // â”€â”€ EURTE PICKER â”€â”€
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF7C3AED),
            onPrimary: Colors.white,
            surface: Color(0xFF1E1E2E),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  // â”€â”€ QUERY â”€â”€
  Stream<QuerySnapshot> _buildQuery() {
    Query q = FirebaseFirestore.instance
        .collection('products')
        .where('listingType', whereIn: ['rent', 'both'])
        .where('isApproved', isEqualTo: true)
        .where('isAvailableForRent', isEqualTo: true);

    if (_filterWilaya != null) {
      q = q.where('wilaya', isEqualTo: _filterWilaya);
    }
    if (_filterGearbox != null) {
      q = q.where('gearbox', isEqualTo: _filterGearbox);
    }
    if (_filterVehicleType != null) {
      q = q.where('vehicleType', isEqualTo: _filterVehicleType);
    }

    return q
        .orderBy('isBoosted', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(_limit)
        .snapshots();
  }

  // â”€â”€ FILTER PRODUCTS CLIENT-SIDE â”€â”€
  List<Product> _filter(List<Product> all) {
    return all.where((p) {
      // Price/day
      if (p.pricePerDay != null && p.pricePerDay! > _currentMaxPrice) {
        return false;
      }
      // Search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = p.title.toLowerCase().contains(q) ||
            (p.brand?.toLowerCase().contains(q) ?? false) ||
            (p.model?.toLowerCase().contains(q) ?? false);
        if (!match) return false;
      }
      // Date availability â€” exclude if any blocked date falls in range
      if (_startDate != null && _endDate != null && p.blockedDates.isNotEmpty) {
        for (final blocked in p.blockedDates) {
          if (!blocked.isBefore(_startDate!) && !blocked.isAfter(_endDate!)) {
            return false;
          }
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = languageNotifier.value == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ HEADER â”€â”€
            _buildHeader(isAr, theme),

            // â”€â”€ INLINE FILTERS â”€â”€
            _buildFilterRow(isAr, theme),

            // â”€â”€ PRICE SLIDER â”€â”€
            _buildPriceSlider(theme),

            // â”€â”€ RESULTS â”€â”€
            Expanded(child: _buildResults(isAr, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isAr, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.vpn_key_rounded,
                          color: Color(0xFF7C3AED), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isAr ? 'ØªØ£Ø¬ÙŠØ± Ø§Ù„Ø³ÙŠØ§Ø±Ø§Øª' : 'Location de Voitures',
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    isAr ? 'Ø§Ø®ØªØ± ÙˆØªÙ†Ù‚Ù„ Ø¨Ø±Ø§Ø­Ø©' : 'Choisissez, rÃ©servez et roulez',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              // Switch to Buy mode
              GestureDetector(
                onTap: () => Provider.of<AppModeProvider>(context, listen: false)
                    .setMode('sale'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_car_rounded,
                          size: 14, color: Color(0xFF4ECDC4)),
                      const SizedBox(width: 4),
                      Text(
                        isAr ? 'Ø´Ø±Ø§Ø¡' : 'Acheter',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search bar
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: isAr
                  ? 'Ø§Ø¨Ø­Ø« Ø¹Ù† Ø³ÙŠØ§Ø±Ø© (Ù…Ø«Ø§Ù„: Golf, Clio...)'
                  : 'Rechercher (ex: Golf, Clioâ€¦)',
              hintStyle: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
              prefixIcon:
                  const Icon(Icons.search, color: Color(0xFF7C3AED)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF7C3AED), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(bool isAr, ThemeData theme) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Wilaya
          _FilterChip(
            icon: Icons.location_on_rounded,
            label: _filterWilaya ?? (isAr ? 'Ø§Ù„ÙˆÙ„Ø§ÙŠØ©' : 'Wilaya'),
            isActive: _filterWilaya != null,
            accentColor: const Color(0xFF7C3AED),
            onTap: () => _showWilayaPicker(isAr),
          ),
          const SizedBox(width: 8),
          // Dates
          _FilterChip(
            icon: Icons.calendar_month_rounded,
            label: _startDate != null
                ? '${_startDate!.day}/${_startDate!.month} â†’ ${_endDate!.day}/${_endDate!.month}'
                : (isAr ? 'Ø§Ù„ØªÙˆØ§Ø±ÙŠØ®' : 'Dates'),
            isActive: _startDate != null,
            accentColor: const Color(0xFF7C3AED),
            onTap: _pickDateRange,
          ),
          const SizedBox(width: 8),
          // Gearbox
          _FilterChip(
            icon: Icons.settings_rounded,
            label: _filterGearbox ?? (isAr ? 'Ø¹Ù„Ø¨Ø© Ø§Ù„Ø³Ø±Ø¹Ø©' : 'BoÃ®te'),
            isActive: _filterGearbox != null,
            accentColor: const Color(0xFF7C3AED),
            onTap: () => _showGearboxPicker(isAr),
          ),
          const SizedBox(width: 8),
          // Vehicle type
          _FilterChip(
            icon: Icons.directions_car_rounded,
            label: _filterVehicleType ?? (isAr ? 'Ù†ÙˆØ¹ Ø§Ù„Ø³ÙŠØ§Ø±Ø©' : 'Type'),
            isActive: _filterVehicleType != null,
            accentColor: const Color(0xFF7C3AED),
            onTap: () => _showVehicleTypePicker(isAr),
          ),
          if (_filterWilaya != null ||
              _filterGearbox != null ||
              _filterVehicleType != null ||
              _startDate != null) ...[
            const SizedBox(width: 8),
            _FilterChip(
              icon: Icons.close_rounded,
              label: isAr ? 'Ù…Ø³Ø­' : 'Effacer',
              isActive: false,
              accentColor: Colors.red,
              onTap: () => setState(() {
                _filterWilaya = null;
                _filterGearbox = null;
                _filterVehicleType = null;
                _startDate = null;
                _endDate = null;
                _currentMaxPrice = _maxPricePerDay;
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceSlider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text(
            'Max/jour: ',
            style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[600]),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF7C3AED),
                thumbColor: const Color(0xFF7C3AED),
                inactiveTrackColor: Colors.grey.shade300,
                overlayColor: const Color(0xFF7C3AED).withOpacity(0.12),
              ),
              child: Slider(
                value: _currentMaxPrice,
                min: 1000,
                max: _maxPricePerDay,
                divisions: 19,
                label: '${_currentMaxPrice.toInt()} EUR',
                onChanged: (v) => setState(() => _currentMaxPrice = v),
              ),
            ),
          ),
          Text(
            '${_currentMaxPrice.toInt()} EUR',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: const Color(0xFF7C3AED),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(bool isAr, ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
        }

        final products =
            _filter(snapshot.data!.docs.map((d) => Product.fromFirestore(d)).toList());

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.vpn_key_off_rounded, size: 56, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  isAr
                      ? 'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø³ÙŠØ§Ø±Ø§Øª Ù„Ù„Ø¥ÙŠØ¬Ø§Ø±'
                      : 'Aucune voiture disponible Ã  la location',
                  style:
                      GoogleFonts.cairo(color: Colors.grey[500], fontSize: 15),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) =>
              _RentalCard(product: products[index]),
        );
      },
    );
  }

  // â”€â”€ PICKERS â”€â”€

  void _showWilayaPicker(bool isAr) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: [
          ListTile(
            title: Text(isAr ? 'ÙƒÙ„ Ø§Ù„ÙˆÙ„Ø§ÙŠØ§Øª' : 'Toutes les wilayas'),
            onTap: () {
              setState(() => _filterWilaya = null);
              Navigator.pop(context);
            },
          ),
          ..._popularWilayas.map((w) => ListTile(
                title: Text(w),
                selected: _filterWilaya == w,
                selectedColor: const Color(0xFF7C3AED),
                onTap: () {
                  setState(() => _filterWilaya = w);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }

  void _showGearboxPicker(bool isAr) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text(isAr ? 'Ø§Ù„ÙƒÙ„' : 'Toutes'),
            onTap: () {
              setState(() => _filterGearbox = null);
              Navigator.pop(context);
            },
          ),
          ...CategoriesData.gearboxes.map((g) => ListTile(
                title: Text(isAr ? (CategoriesData.gearboxTranslations[g] ?? g) : g),
                selected: _filterGearbox == g,
                selectedColor: const Color(0xFF7C3AED),
                onTap: () {
                  setState(() => _filterGearbox = g);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }

  void _showVehicleTypePicker(bool isAr) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text(isAr ? 'Ø§Ù„ÙƒÙ„' : 'Tous les types'),
            onTap: () {
              setState(() => _filterVehicleType = null);
              Navigator.pop(context);
            },
          ),
          ...CategoriesData.vehicleTypes.map((v) => ListTile(
                title: Text(
                    isAr ? (CategoriesData.vehicleTypeTranslations[v] ?? v) : v),
                selected: _filterVehicleType == v,
                selectedColor: const Color(0xFF7C3AED),
                onTap: () {
                  setState(() => _filterVehicleType = v);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }
}

// â”€â”€ RENTAL CARD â”€â”€

class _RentalCard extends StatelessWidget {
  final Product product;

  const _RentalCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(
                children: [
                  OptimizedImage(
                    imageUrl: product.imageUrls.isNotEmpty
                        ? product.imageUrls[0]
                        : '',
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                  // Availability badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.isAvailableForRent
                            ? const Color(0xFF059669)
                            : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.isAvailableForRent ? 'Disponible' : 'Indispo',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Gearbox badge
                  if (product.gearbox != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.gearbox == 'Automatique' ? 'Auto' : 'Manu',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Price per day
                  if (product.pricePerDay != null)
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${product.pricePerDay!.toInt()} EUR',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                          TextSpan(
                            text: '/jour',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Location + year
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${product.wilaya}${product.year != null ? ' Â· ${product.year}' : ''}',
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: Colors.grey[500]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (product.vehicleType != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.vehicleType!,
                        style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ FILTER CHIP â”€â”€

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? accentColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isActive ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

