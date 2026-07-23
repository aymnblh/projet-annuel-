import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_mode_provider.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _buyPressController;
  late AnimationController _rentPressController;

  late Animation<double> _logoFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _footerFade;

  late Animation<double> _buyScale;
  late Animation<double> _rentScale;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _buyPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _rentPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _logoFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));
    _cardFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
    );
    _footerFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    _buyScale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _buyPressController, curve: Curves.easeOut),
    );
    _rentScale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _rentPressController, curve: Curves.easeOut),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _buyPressController.dispose();
    _rentPressController.dispose();
    super.dispose();
  }

  Future<void> _selectMode(String mode) async {
    final ctrl = mode == 'sale' ? _buyPressController : _rentPressController;
    await ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    Provider.of<AppModeProvider>(context, listen: false).setMode(mode);
    // AppModeProvider notifies listeners → AuthWrapper auto-rebuilds to correct layout
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF06080F), Color(0xFF0D1421), Color(0xFF0F172A)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // ── LOGO ──
                FadeTransition(
                  opacity: _logoFade,
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: Color(0xFFF59E0B),
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '1Click',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Comment souhaitez-vous utiliser l\'application ?',
                        style: GoogleFonts.cairo(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── CARDS ──
                SlideTransition(
                  position: _cardSlide,
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: Column(
                      children: [
                        // BUY CARD
                        ScaleTransition(
                          scale: _buyScale,
                          child: GestureDetector(
                            onTapDown: (_) => _buyPressController.forward(),
                            onTapCancel: () => _buyPressController.reverse(),
                            onTapUp: (_) async {
                              await _buyPressController.reverse();
                              _selectMode('sale');
                            },
                            child: _ModeCard(
                              icon: Icons.directions_car_rounded,
                              title: 'Acheter',
                              titleAr: 'شراء',
                              subtitle:
                                  'Des milliers de vehicules d\'occasion et neufs partout en Europe',
                              gradientColors: const [
                                Color(0xFF1B4332),
                                Color(0xFF1E3A5F),
                              ],
                              accentColor: const Color(0xFF4ECDC4),
                              badgeLabel: 'Vente',
                              badgeIcon: Icons.storefront_rounded,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // RENT CARD
                        ScaleTransition(
                          scale: _rentScale,
                          child: GestureDetector(
                            onTapDown: (_) => _rentPressController.forward(),
                            onTapCancel: () => _rentPressController.reverse(),
                            onTapUp: (_) async {
                              await _rentPressController.reverse();
                              _selectMode('rent');
                            },
                            child: _ModeCard(
                              icon: Icons.vpn_key_rounded,
                              title: 'Louer',
                              titleAr: 'استئجار',
                              subtitle:
                                  'Louez une voiture pour un jour, une semaine ou plus',
                              gradientColors: const [
                                Color(0xFF4C1D95),
                                Color(0xFF831843),
                              ],
                              accentColor: const Color(0xFFF59E0B),
                              badgeLabel: 'Location',
                              badgeIcon: Icons.calendar_month_rounded,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // ── FOOTER ──
                FadeTransition(
                  opacity: _footerFade,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Vous pouvez changer de mode à tout moment',
                      style: GoogleFonts.cairo(
                        color: Colors.white24,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String titleAr;
  final String subtitle;
  final List<Color> gradientColors;
  final Color accentColor;
  final String badgeLabel;
  final IconData badgeIcon;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.titleAr,
    required this.subtitle,
    required this.gradientColors,
    required this.accentColor,
    required this.badgeLabel,
    required this.badgeIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withOpacity(0.4)),
            ),
            child: Icon(icon, color: accentColor, size: 32),
          ),
          const SizedBox(width: 18),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: accentColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 11, color: accentColor),
                          const SizedBox(width: 3),
                          Text(
                            badgeLabel,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded,
              color: accentColor.withOpacity(0.6), size: 16),
        ],
      ),
    );
  }
}
