import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';
import '../main.dart';

/// Full-screen visual search: take a photo or pick from gallery,
/// AI identifies the car, then navigate back with structured results.
class VisualSearchScreen extends StatefulWidget {
  const VisualSearchScreen({super.key});

  @override
  State<VisualSearchScreen> createState() => _VisualSearchScreenState();
}

class _VisualSearchScreenState extends State<VisualSearchScreen>
    with TickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  Map<String, dynamic>? _result;
  bool _isAnalyzing = false;
  String? _errorMessage;

  // ── Scanning animation ───────────────────────────────────────────
  late AnimationController _scanController;
  late Animation<double> _scanPosition;

  // ── Result card fade ─────────────────────────────────────────────
  late AnimationController _resultController;
  late Animation<double> _resultFade;
  late Animation<Offset> _resultSlide;

  bool get _isArabic => languageNotifier.value == 'ar';

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scanPosition = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resultFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.easeOut),
    );
    _resultSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _resultController, curve: Curves.easeOutCubic));
  }

  // ── Image Selection ──────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _selectedImage = File(picked.path);
          _result = null;
          _errorMessage = null;
        });
        _analyzeImage();
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = _isArabic
              ? 'خطأ في اختيار الصورة'
              : 'Erreur lors de la sélection de l\'image';
        });
      }
    }
  }

  // ── AI Analysis ──────────────────────────────────────────────────
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _result = null;
      _errorMessage = null;
    });
    _scanController.repeat();
    _resultController.reset();

    try {
      final result = await AIService().identifyCarFromPhoto(_selectedImage!);

      if (!mounted) return;

      if (result != null && result['error'] == null) {
        setState(() {
          _result = result;
          _isAnalyzing = false;
        });
        _scanController.stop();
        _scanController.reset();
        _resultController.forward();
      } else {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = result?['error'] as String? ??
              (_isArabic
                  ? 'لم يتم التعرف على السيارة'
                  : 'Impossible d\'identifier le véhicule');
        });
        _scanController.stop();
        _scanController.reset();
      }
    } catch (e) {
      debugPrint('Visual search error: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = _isArabic
              ? 'خطأ في التحليل. حاول مرة أخرى'
              : 'Erreur d\'analyse. Réessayez';
        });
        _scanController.stop();
        _scanController.reset();
      }
    }
  }

  void _retry() {
    setState(() {
      _selectedImage = null;
      _result = null;
      _errorMessage = null;
    });
  }

  void _viewSimilarListings() {
    if (_result == null) return;
    Navigator.pop(context, {
      'brand': _result!['brand'],
      'model': _result!['model'],
      'yearRange': _result!['yearRange'],
      'vehicleType': _result!['vehicleType'],
      'color': _result!['color'],
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isArabic ? 'البحث المرئي' : 'Recherche Visuelle',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.camera_alt,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0A0A0A), const Color(0xFF1A1A2E)]
                : [const Color(0xFFF8F9FA), const Color(0xFFE8EAF6)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_selectedImage == null && _result == null)
                  _buildHeroSection(isDark),
                if (_selectedImage != null) _buildImagePreview(isDark),
                if (_result != null) _buildResultCard(isDark),
                if (_errorMessage != null) _buildErrorState(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero Section (initial state) ─────────────────────────────────
  Widget _buildHeroSection(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 30),
        // Large camera illustration
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF8B5CF6).withOpacity(0.15),
                const Color(0xFF3B82F6).withOpacity(0.15),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.25),
                    const Color(0xFF3B82F6).withOpacity(0.25),
                  ],
                ),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 56,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          _isArabic
              ? 'التقط صورة لسيارة للتعرف عليها'
              : 'Prenez en photo une voiture\npour l\'identifier',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isArabic
              ? 'الذكاء الاصطناعي سيحدد الماركة والموديل'
              : 'L\'IA identifiera la marque, le modèle\net la génération du véhicule',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            height: 1.3,
          ),
        ),
        const SizedBox(height: 40),

        // ── Action Buttons ───────────────────────────────────────
        _buildActionButton(
          icon: Icons.camera_alt_rounded,
          emoji: '📸',
          label: _isArabic ? 'التقط صورة' : 'Prendre une photo',
          gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          onTap: () => _pickImage(ImageSource.camera),
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        _buildActionButton(
          icon: Icons.photo_library_rounded,
          emoji: '🖼️',
          label: _isArabic ? 'اختر من المعرض' : 'Choisir depuis la galerie',
          gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          onTap: () => _pickImage(ImageSource.gallery),
          isDark: isDark,
        ),
        const SizedBox(height: 30),

        // ── Tips ─────────────────────────────────────────────────
        _buildTipsSection(isDark),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String emoji,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection(bool isDark) {
    final tips = _isArabic
        ? [
            'التقط صورة واضحة للسيارة بالكامل',
            'تأكد من إضاءة جيدة',
            'تجنب الصور الضبابية أو البعيدة جداً',
          ]
        : [
            'Prenez une photo claire de la voiture entière',
            'Assurez un bon éclairage',
            'Évitez les photos floues ou trop éloignées',
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.amber[600],
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                _isArabic ? 'نصائح للحصول على نتائج أفضل' : 'Conseils pour de meilleurs résultats',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ',
                        style: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[600])),
                    Expanded(
                      child: Text(
                        tip,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Image Preview + Scanning ─────────────────────────────────────
  Widget _buildImagePreview(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 10),
        // Image with scanning overlay
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Selected image
              Image.file(
                _selectedImage!,
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
              ),

              // Scanning animation overlay
              if (_isAnalyzing)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _scanPosition,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          // Semi-transparent overlay
                          Container(
                            color: Colors.black.withOpacity(0.3),
                          ),
                          // Scanning line
                          Positioned(
                            top: _scanPosition.value * 280 - 2,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    const Color(0xFF8B5CF6),
                                    const Color(0xFF3B82F6),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.6),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Corner markers
                          _buildCornerMarker(top: 12, left: 12),
                          _buildCornerMarker(top: 12, right: 12, rotated: true),
                          _buildCornerMarker(bottom: 12, left: 12, rotated: true),
                          _buildCornerMarker(bottom: 12, right: 12),
                        ],
                      );
                    },
                  ),
                ),

              // Dark overlay at bottom for text
              if (_isAnalyzing)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isArabic ? 'جاري التحليل...' : 'Analyse en cours...',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Retake / Choose another
        if (!_isAnalyzing && _result == null && _errorMessage == null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: Text(
                      _isArabic ? 'إعادة التقاط' : 'Reprendre',
                      style: GoogleFonts.cairo(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: Text(
                      _isArabic ? 'صورة أخرى' : 'Autre image',
                      style: GoogleFonts.cairo(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCornerMarker({
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool rotated = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: rotated ? 1.5708 : 0, // 90 degrees
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFF8B5CF6), width: 3),
              left: BorderSide(color: Color(0xFF8B5CF6), width: 3),
            ),
          ),
        ),
      ),
    );
  }

  // ── Result Card ──────────────────────────────────────────────────
  Widget _buildResultCard(bool isDark) {
    final brand = _result!['brand'] ?? '—';
    final model = _result!['model'] ?? '—';
    final generation = _result!['generation'] ?? '';
    final yearRange = _result!['yearRange'] ?? '';
    final vehicleType = _result!['vehicleType'] ?? '';
    final color = _result!['color'] ?? '';
    final description = _result!['description'] ?? '';
    final confidence = (_result!['confidence'] is num)
        ? (_result!['confidence'] as num).toDouble()
        : 0.0;
    final confidencePercent = (confidence * 100).toInt();

    return SlideTransition(
      position: _resultSlide,
      child: FadeTransition(
        opacity: _resultFade,
        child: Container(
          margin: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.4)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey.withOpacity(0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header with confidence ──────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withOpacity(0.1),
                      const Color(0xFF3B82F6).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    // AI icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isArabic ? 'تم التعرف على السيارة' : 'Véhicule identifié',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            _isArabic ? 'بواسطة الذكاء الاصطناعي' : 'Propulsé par l\'IA',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Confidence badge
                    _buildConfidenceBadge(confidencePercent, isDark),
                  ],
                ),
              ),

              // ── Car details ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  '$brand $model',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (generation.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    generation,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: const Color(0xFF8B5CF6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // ── Info chips ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (yearRange.isNotEmpty)
                      _buildInfoTag(Icons.calendar_today, yearRange, isDark),
                    if (vehicleType.isNotEmpty)
                      _buildInfoTag(Icons.category, vehicleType, isDark),
                    if (color.isNotEmpty)
                      _buildInfoTag(Icons.palette, color, isDark),
                  ],
                ),
              ),

              // ── Description ────────────────────────────────────
              if (description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Text(
                    description,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // ── CTA Button ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _viewSimilarListings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 6,
                      shadowColor: const Color(0xFF8B5CF6).withOpacity(0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          _isArabic
                              ? 'عرض الإعلانات المشابهة'
                              : 'Voir les annonces similaires',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Try another
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(
                      _isArabic ? 'تجربة صورة أخرى' : 'Essayer une autre photo',
                      style: GoogleFonts.cairo(fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(int percent, bool isDark) {
    Color badgeColor;
    if (percent >= 80) {
      badgeColor = const Color(0xFF4CAF50);
    } else if (percent >= 50) {
      badgeColor = const Color(0xFFFF9800);
    } else {
      badgeColor = const Color(0xFFF44336);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            percent >= 80
                ? Icons.verified
                : (percent >= 50 ? Icons.help_outline : Icons.warning_amber),
            color: badgeColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$percent%',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600]),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // ── Error State ──────────────────────────────────────────────────
  Widget _buildErrorState(bool isDark) {
    return AnimatedOpacity(
      opacity: _errorMessage != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: Colors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isArabic ? 'لم يتم التعرف' : 'Non identifié',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: Text(
                      _isArabic ? 'إعادة المحاولة' : 'Réessayer',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: Text(
                      _isArabic ? 'صورة أخرى' : 'Autre photo',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
