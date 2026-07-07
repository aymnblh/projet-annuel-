import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import '../services/ai_service.dart';
import '../main.dart';

/// NLP-powered search bar that converts natural language queries
/// into structured car-search filters via Gemini AI.
class NlpSearchBar extends StatefulWidget {
  /// Called with structured filters after AI successfully parses the query.
  final Function(Map<String, dynamic> filters)? onFiltersExtracted;

  /// Fallback when AI parsing fails — receives the raw text query.
  final Function(String query)? onFallbackSearch;

  /// Opens the camera / visual-search screen.
  final VoidCallback? onVisualSearch;

  const NlpSearchBar({
    super.key,
    this.onFiltersExtracted,
    this.onFallbackSearch,
    this.onVisualSearch,
  });

  @override
  State<NlpSearchBar> createState() => _NlpSearchBarState();
}

class _NlpSearchBarState extends State<NlpSearchBar>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // ── AI State ─────────────────────────────────────────────────────
  bool _isProcessing = false;
  Map<String, dynamic>? _extractedFilters;
  String? _errorMessage;

  // ── Voice State ──────────────────────────────────────────────────
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  // ── Animations ───────────────────────────────────────────────────
  late AnimationController _sparkleController;
  late AnimationController _chipController;
  late Animation<double> _sparkleRotation;
  late Animation<double> _chipSlide;

  // ── Filter label / color map ─────────────────────────────────────
  static const Map<String, _ChipStyle> _chipStyles = {
    'brand': _ChipStyle(Icons.directions_car, Color(0xFF2196F3), 'Marque', 'الماركة'),
    'model': _ChipStyle(Icons.car_repair, Color(0xFF1976D2), 'Modèle', 'الموديل'),
    'vehicleType': _ChipStyle(Icons.category, Color(0xFF0288D1), 'Type', 'النوع'),
    'fuel': _ChipStyle(Icons.local_gas_station, Color(0xFFFF9800), 'Carburant', 'الوقود'),
    'gearbox': _ChipStyle(Icons.settings, Color(0xFF9C27B0), 'Boîte', 'ناقل الحركة'),
    'minPrice': _ChipStyle(Icons.arrow_upward, Color(0xFF4CAF50), 'Prix min', 'أدنى سعر'),
    'maxPrice': _ChipStyle(Icons.arrow_downward, Color(0xFF4CAF50), 'Prix max', 'أقصى سعر'),
    'minYear': _ChipStyle(Icons.calendar_today, Color(0xFF795548), 'Année min', 'أقل سنة'),
    'maxYear': _ChipStyle(Icons.event, Color(0xFF795548), 'Année max', 'أقصى سنة'),
    'maxKm': _ChipStyle(Icons.speed, Color(0xFFE91E63), 'Km max', 'أقصى كم'),
    'wilaya': _ChipStyle(Icons.location_on, Color(0xFFF44336), 'Wilaya', 'الولاية'),
    'color': _ChipStyle(Icons.palette, Color(0xFF607D8B), 'Couleur', 'اللون'),
  };

  // ── Helpers ──────────────────────────────────────────────────────
  bool get _isArabic => languageNotifier.value == 'ar';

  @override
  void initState() {
    super.initState();
    _initSpeech();

    // Sparkle icon rotation while processing
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _sparkleRotation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.linear),
    );

    // Chip slide-in animation
    _chipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _chipSlide = CurvedAnimation(parent: _chipController, curve: Curves.easeOutCubic);
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech error: $error');
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  // ── Voice Input ──────────────────────────────────────────────────
  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic
                  ? 'يرجى السماح باستخدام الميكروفون'
                  : 'Permission microphone requise',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic
                  ? 'البحث الصوتي غير متاح'
                  : 'Recherche vocale non disponible',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          });
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _stopListeningAndSearch();
          }
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: _isArabic ? 'ar_DZ' : 'fr_FR',
    );
  }

  Future<void> _stopListeningAndSearch() async {
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
      if (_controller.text.trim().isNotEmpty) {
        _submitSearch(_controller.text.trim());
      }
    }
  }

  // ── AI Search ────────────────────────────────────────────────────
  Future<void> _submitSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _extractedFilters = null;
      _errorMessage = null;
    });
    _sparkleController.repeat();

    try {
      final filters = await AIService().parseNaturalLanguageSearch(query);

      if (!mounted) return;

      if (filters != null && filters.isNotEmpty) {
        setState(() {
          _extractedFilters = filters;
          _isProcessing = false;
        });
        _sparkleController.stop();
        _sparkleController.reset();
        _chipController.forward(from: 0);
      } else {
        // AI returned nothing → fallback
        setState(() {
          _isProcessing = false;
          _errorMessage = _isArabic
              ? 'لم يتم استخراج فلاتر. بحث عادي...'
              : 'Aucun filtre extrait. Recherche classique...';
        });
        _sparkleController.stop();
        _sparkleController.reset();
        widget.onFallbackSearch?.call(query);
      }
    } catch (e) {
      debugPrint('NLP search error: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = _isArabic
              ? 'خطأ في التحليل. بحث عادي...'
              : 'Erreur d\'analyse. Recherche classique...';
        });
        _sparkleController.stop();
        _sparkleController.reset();
        widget.onFallbackSearch?.call(query);
      }
    }
  }

  void _removeFilter(String key) {
    setState(() {
      _extractedFilters?.remove(key);
      if (_extractedFilters?.isEmpty ?? true) {
        _extractedFilters = null;
      }
    });
  }

  void _applyFilters() {
    if (_extractedFilters != null && _extractedFilters!.isNotEmpty) {
      widget.onFiltersExtracted?.call(Map.from(_extractedFilters!));
    }
  }

  void _clearAll() {
    setState(() {
      _controller.clear();
      _extractedFilters = null;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _sparkleController.dispose();
    _chipController.dispose();
    _speech.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Search Field ───────────────────────────────────────────
        _buildSearchField(isDark),

        // ── Shimmer Loading ────────────────────────────────────────
        if (_isProcessing) _buildShimmerLoader(isDark),

        // ── Error Message ──────────────────────────────────────────
        if (_errorMessage != null) _buildErrorBanner(),

        // ── Filter Chips ───────────────────────────────────────────
        if (_extractedFilters != null && _extractedFilters!.isNotEmpty)
          _buildFilterChips(isDark),
      ],
    );
  }

  // ── Search Field ─────────────────────────────────────────────────
  Widget _buildSearchField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF7C3AED), const Color(0xFF2563EB)]
              : [const Color(0xFF8B5CF6), const Color(0xFF3B82F6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2), // Gradient border thickness
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
          style: GoogleFonts.cairo(
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: _isArabic
                ? 'صف سيارة أحلامك...'
                : 'Décrivez la voiture de vos rêves...',
            hintStyle: GoogleFonts.cairo(
              color: isDark ? Colors.grey[500] : Colors.grey[400],
              fontSize: 14,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            // Sparkle prefix icon
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: AnimatedBuilder(
                animation: _sparkleRotation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _isProcessing ? _sparkleRotation.value * 6.28 : 0,
                    child: Icon(
                      Icons.auto_awesome,
                      color: _isProcessing
                          ? const Color(0xFF8B5CF6)
                          : (isDark ? Colors.grey[400] : Colors.grey[500]),
                      size: 22,
                    ),
                  );
                },
              ),
            ),
            // Suffix: mic + camera
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Microphone
                if (_speechAvailable)
                  GestureDetector(
                    onTap: _isProcessing ? null : _toggleListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? Colors.red.withOpacity(0.15)
                            : Colors.transparent,
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none_rounded,
                        color: _isListening
                            ? Colors.red
                            : (isDark ? Colors.grey[400] : Colors.grey[500]),
                        size: 22,
                      ),
                    ),
                  ),
                // Camera (visual search)
                if (widget.onVisualSearch != null)
                  GestureDetector(
                    onTap: _isProcessing ? null : widget.onVisualSearch,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8, left: 4),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                        size: 22,
                      ),
                    ),
                  ),
                // Clear button (when text present)
                if (_controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: _clearAll,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, left: 4),
                      child: Icon(
                        Icons.close,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          onSubmitted: (text) {
            if (text.trim().isNotEmpty) _submitSearch(text.trim());
          },
          onChanged: (_) => setState(() {}), // Rebuild for clear button
        ),
      ),
    );
  }

  // ── Shimmer Loader ───────────────────────────────────────────────
  Widget _buildShimmerLoader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
        child: Column(
          children: [
            // Fake chip row
            Row(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 80 + (i * 20),
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Processing text
            Container(
              width: 180,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error Banner ─────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return AnimatedOpacity(
      opacity: _errorMessage != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.orange[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter Chips ─────────────────────────────────────────────────
  Widget _buildFilterChips(bool isDark) {
    final filters = _extractedFilters!;
    // Exclude non-displayable keys like 'keywords' and 'features'
    final displayKeys = filters.keys
        .where((k) => _chipStyles.containsKey(k) || k == 'keywords' || k == 'features')
        .toList();

    return AnimatedBuilder(
      animation: _chipSlide,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _chipSlide.value)),
          child: Opacity(
            opacity: _chipSlide.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        _isArabic ? 'فلاتر مستخرجة بالذكاء الاصطناعي' : 'Filtres IA extraits',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _clearAll,
                  child: Text(
                    _isArabic ? 'مسح الكل' : 'Tout effacer',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: Colors.grey,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: displayKeys.map((key) {
                final value = filters[key];
                if (key == 'keywords' && value is List) {
                  return _buildListChip(
                    icon: Icons.label_outline,
                    label: value.join(', '),
                    color: const Color(0xFF9E9E9E),
                    filterKey: key,
                    isDark: isDark,
                  );
                }
                if (key == 'features' && value is List) {
                  return _buildListChip(
                    icon: Icons.star_outline,
                    label: value.join(', '),
                    color: const Color(0xFFFFB300),
                    filterKey: key,
                    isDark: isDark,
                  );
                }

                final style = _chipStyles[key];
                if (style == null) return const SizedBox.shrink();

                String displayValue;
                if (value is int || value is double) {
                  // Format price with spaces
                  if (key.contains('Price')) {
                    displayValue = _formatPrice(value);
                  } else {
                    displayValue = value.toString();
                  }
                } else {
                  displayValue = value.toString();
                }

                final label = _isArabic ? style.labelAr : style.labelFr;

                return _buildFilterChip(
                  icon: style.icon,
                  label: '$label: $displayValue',
                  color: style.color,
                  filterKey: key,
                  isDark: isDark,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _applyFilters,
                icon: const Icon(Icons.search, size: 20),
                label: Text(
                  _isArabic ? 'بحث بهذه الفلاتر' : 'Rechercher',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF8B5CF6).withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required Color color,
    required String filterKey,
    required bool isDark,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Chip(
        avatar: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: color.withOpacity(isDark ? 0.2 : 0.1),
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        deleteIcon: Icon(Icons.close, size: 16, color: color),
        onDeleted: () => _removeFilter(filterKey),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildListChip({
    required IconData icon,
    required String label,
    required Color color,
    required String filterKey,
    required bool isDark,
  }) {
    return _buildFilterChip(
      icon: icon,
      label: label,
      color: color,
      filterKey: filterKey,
      isDark: isDark,
    );
  }

  String _formatPrice(dynamic value) {
    final number = (value is double) ? value.toInt() : value as int;
    final str = number.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) buffer.write(' ');
    }
    return '${buffer.toString().split('').reversed.join()} DA';
  }
}

// ══════════════════════════════════════════════════════════════════════
//  Chip styling helper
// ══════════════════════════════════════════════════════════════════════
class _ChipStyle {
  final IconData icon;
  final Color color;
  final String labelFr;
  final String labelAr;

  const _ChipStyle(this.icon, this.color, this.labelFr, this.labelAr);
}
