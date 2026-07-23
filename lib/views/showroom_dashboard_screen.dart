import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../utils/app_translations.dart';
import '../main.dart';
import 'add_product_screen.dart';
import 'product_details_screen.dart';

class ShowroomDashboardScreen extends StatefulWidget {
  const ShowroomDashboardScreen({super.key});

  @override
  State<ShowroomDashboardScreen> createState() =>
      _ShowroomDashboardScreenState();
}

class _ShowroomDashboardScreenState extends State<ShowroomDashboardScreen> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late Future<Map<String, int>> _statsFuture;

  String t(String key) => AppTranslations.get(languageNotifier.value, key);

  @override
  void initState() {
    super.initState();
    _statsFuture = DatabaseService().fetchSellerStats(_userId);
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = DatabaseService().fetchSellerStats(_userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Tableau de Bord',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshStats,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshStats(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€ WELCOME â”€â”€
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.store_rounded,
                          color: Color(0xFFF59E0B), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenue !',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Votre tableau de bord',
                          style: GoogleFonts.cairo(
                              color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // â”€â”€ REAL STATS CARDS â”€â”€
              Text(
                'Performance des annonces',
                style: GoogleFonts.cairo(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              FutureBuilder<Map<String, int>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ));
                  }
                  final stats = snapshot.data!;
                  return Column(
                    children: [
                      Row(
                        children: [
                          _StatCard(
                            title: 'Vues totales',
                            value: _fmt(stats['views'] ?? 0),
                            icon: Icons.visibility_rounded,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            title: 'Appels reçus',
                            value: _fmt(stats['calls'] ?? 0),
                            icon: Icons.phone_rounded,
                            color: const Color(0xFF16A34A),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatCard(
                            title: 'WhatsApp',
                            value: _fmt(stats['whatsapps'] ?? 0),
                            icon: Icons.chat_rounded,
                            color: const Color(0xFF25D366),
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            title: 'Annonces',
                            value: _fmt(stats['listings'] ?? 0),
                            icon: Icons.directions_car_rounded,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Lead conversion hint
                      if ((stats['views'] ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF16A34A).withOpacity(0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.trending_up_rounded,
                                  color: Color(0xFF16A34A), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Taux de conversion : ${_conversionRate(stats)} % des vues ont généré un appel ou WhatsApp.',
                                  style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: const Color(0xFF16A34A)),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // â”€â”€ INVENTORY â”€â”€
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mes annonces',
                    style: GoogleFonts.cairo(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddProductScreen()),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text('Ajouter'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('sellerId', isEqualTo: _userId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.directions_car_outlined,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune annonce pour le moment',
                              style: GoogleFonts.cairo(
                                  color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (ctx, index) {
                      final prod =
                          Product.fromFirestore(snapshot.data!.docs[index]);
                      return _InventoryTile(product: prod, isAr: isAr);
                    },
                  );
                },
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  String _conversionRate(Map<String, int> stats) {
    final views = stats['views'] ?? 0;
    final leads = (stats['calls'] ?? 0) + (stats['whatsapps'] ?? 0);
    if (views == 0) return '0';
    return ((leads / views) * 100).toStringAsFixed(1);
  }
}

// â”€â”€ STAT CARD â”€â”€

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ INVENTORY TILE â”€â”€

class _InventoryTile extends StatelessWidget {
  final Product product;
  final bool isAr;

  const _InventoryTile({required this.product, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrls.isNotEmpty
                    ? Image.network(
                        product.imageUrls[0],
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image),
                        ),
                      )
                    : Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey[200],
                        child: const Icon(Icons.directions_car),
                      ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.price.toStringAsFixed(0)} EUR',
                      style: GoogleFonts.cairo(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    // Lead mini-stats
                    Row(
                      children: [
                        _LeadBadge(
                          icon: Icons.visibility_rounded,
                          value: '${product.viewCount}',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        _LeadBadge(
                          icon: Icons.phone_rounded,
                          value: '${product.callCount}',
                          color: const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 6),
                        _LeadBadge(
                          icon: Icons.chat_rounded,
                          value: '${product.whatsappCount}',
                          color: const Color(0xFF25D366),
                        ),
                        if (product.isBoosted) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.rocket_launch_rounded,
                              color: Colors.amber, size: 14),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Status badge
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: product.isApproved
                          ? const Color(0xFF16A34A).withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.isApproved
                          ? ('Actif')
                          : ('En attente'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: product.isApproved
                            ? const Color(0xFF16A34A)
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _LeadBadge(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

