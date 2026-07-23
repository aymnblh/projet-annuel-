
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:readmore/readmore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/product.dart';
import '../utils/app_translations.dart';
import '../utils/categories_data.dart'; // ADDED
import '../main.dart'; // Pour languageNotifier
import '../services/chat_service.dart';
import '../services/database_service.dart';
import '../services/analytics_service.dart';
import '../services/share_service.dart';
import '../services/recently_viewed_service.dart';
import '../services/recommendation_service.dart';
import '../widgets/optimized_image.dart';
import 'chat_room_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'public_profile_screen.dart';
import 'product_card.dart';
import '../widgets/similar_products_section.dart'; // NEW: Similar products section
import '../services/social_sharing_service.dart'; // NEW: Social sharing
import '../services/behavior_tracking_service.dart'; // NEW: ML behavior tracking

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String t(String key) => AppTranslations.get(languageNotifier.value, key);
  
  int _currentImageIndex = 0;
  List<String> _allMedia = [];
  final Map<int, ChewieController> _videoControllers = {};
  
  // --- ML Behavior Tracking ---
  final DateTime _viewStartTime = DateTime.now();
  int _photoSwipeCount = 0;

  @override
  void initState() {
    super.initState();
    _allMedia = [...widget.product.imageUrls, ...widget.product.videoUrls];
    
    // Track recently viewed
    RecentlyViewedService.trackView(widget.product.id);
    
    // Track product view with analytics
    AnalyticsService.logProductView(
      productId: widget.product.id,
      productTitle: widget.product.title,
      category: widget.product.category,
      source: 'product_details',
    );
    
    // Track behavior for ML recommendations
    BehaviorTrackingService().trackProductView(
      widget.product.id,
      widget.product.brand ?? '',
      widget.product.category,
      widget.product.price,
      widget.product.fuel,
      widget.product.vehicleType,
    );
    
    // Incrémenter la vue
    if (FirebaseAuth.instance.currentUser?.uid != widget.product.sellerId) {
      DatabaseService().incrementViewCount(widget.product.id);
      AnalyticsService.logViewItem(widget.product);
    }
  }

  @override
  void dispose() {
    // Track view duration for ML
    final viewDuration = DateTime.now().difference(_viewStartTime).inSeconds;
    BehaviorTrackingService().trackViewDuration(widget.product.id, viewDuration);
    if (_photoSwipeCount > 0) {
      BehaviorTrackingService().trackPhotoSwipe(widget.product.id, _photoSwipeCount);
    }
    
    for (var c in _videoControllers.values) {
      c.videoPlayerController.dispose();
      c.dispose();
    }
    super.dispose();
  }

  void _contactSeller(String sellerName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(fromProfile: true)));
      return;
    }
    if (user.uid == widget.product.sellerId) {
       // Si c'est notre produit, on peut le booster
       _showBoostOptions();
      return;
    }
    BehaviorTrackingService().trackContact(
      widget.product.id,
      widget.product.brand ?? '',
      'chat',
    );
    final chatService = ChatService();
    String chatId = await chatService.startChat(
      otherUserId: widget.product.sellerId,
      productId: widget.product.id,
      productName: widget.product.title, 
      productImage: widget.product.imageUrls.isNotEmpty ? widget.product.imageUrls[0] : '',
    );
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(chatId: chatId, otherUserName: sellerName, productName: widget.product.title)));
    }
  }

  void _openSellerProfile(String sellerName) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: widget.product.sellerId, userName: sellerName)));
  }

  // â”€â”€ LEAD: APPELER â”€â”€
  Future<void> _callSeller() async {
    final phone = widget.product.phone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pas de numéro disponible')));
      return;
    }
    // Track lead first (fire-and-forget)
    DatabaseService().incrementLeadCount(widget.product.id, 'call');
    BehaviorTrackingService().trackContact(
      widget.product.id,
      widget.product.brand ?? '',
      'call',
    );

    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de lancer l\'appel')));
      }
    }
  }

  // â”€â”€ LEAD: WHATSAPP â”€â”€
  Future<void> _openWhatsApp() async {
    final phone = widget.product.phone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pas de numéro disponible')));
      return;
    }
    // Track lead first (fire-and-forget)
    DatabaseService().incrementLeadCount(widget.product.id, 'whatsapp');
    BehaviorTrackingService().trackContact(
      widget.product.id,
      widget.product.brand ?? '',
      'whatsapp',
    );

    final p = widget.product;
    final msg = Uri.encodeComponent(
      'Bonjour, je suis intéressé(e) par votre annonce "«${p.title}»" '
      '(${p.price.toStringAsFixed(0)} EUR) sur 1Click. '
      'Est-elle toujours disponible ?',
    );
    String cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp non disponible')));
      }
    }
  }

  // â”€â”€ REPORT LISTING â”€â”€
  void _showReportSheet() {
    final reasons = [
      'Prix incorrect',
      'Voiture déjÃ  vendue',
      'Annonce frauduleuse',
      'Photos trompeuses',
      'Autre',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'Signaler l\'annonce âš‘' : 'Signaler l\'annonce âš‘',
                style: GoogleFonts.cairo(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Pour quelle raison signalez-vous cette annonceÂ ?',
                style: GoogleFonts.cairo(
                    fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ...reasons.map((r) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.flag_rounded, color: Colors.red),
                    title: Text(r, style: GoogleFonts.cairo(fontSize: 14)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) return;
                      await DatabaseService().reportListing(
                        productId: widget.product.id,
                        reporterId: uid,
                        reason: r,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Signalement envoyé. MerciÂ !'),
                          backgroundColor: Colors.green,
                        ));
                      }
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // --- BOOST LOGIC ---
  void _showBoostOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("🚀 Booster mon annonce", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              Text("Obtenez jusqu'Ã  10x plus de vues en apparaissant en tête de liste.", textAlign: TextAlign.center),
              const SizedBox(height: 20),
              
              _buildBoostOption(
                title: "24 Heures",
                price: "200 EUR",
                color: Colors.blue.shade100,
                onTap: () => _processBoostPayment(1),
              ),
              const SizedBox(height: 10),
              _buildBoostOption(
                title: "7 Jours (Populaire)",
                price: "1000 EUR",
                color: Colors.amber.shade100,
                isPopular: true,
                onTap: () => _processBoostPayment(7),
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        );
      }
    );
  }

  Widget _buildBoostOption({required String title, required String price, required Color color, required VoidCallback onTap, bool isPopular = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: isPopular ? Border.all(color: Colors.orange, width: 2) : null,
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                if (isPopular) Text("Top Deal ðŸ”¥", style: TextStyle(fontSize: 10, color: Colors.orange[800], fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            Text(price, style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  void _processBoostPayment(int days) async {
    Navigator.pop(context); // Close sheet
    
    // Simulate Payment Flow
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Traitement du paiement...")));
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Update Firestore
      final expiresAt = DateTime.now().add(Duration(days: days));
      await FirebaseFirestore.instance.collection('products').doc(widget.product.id).update({
        'isBoosted': true,
        'boostExpiresAt': expiresAt,
        'boostedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Annonce Boostée avec succès ! 🚀"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  Widget _buildSpecChip(IconData icon, String label) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  // WIDGET MEDIA
  Widget _buildMediaItem(int index) {
    if (index < widget.product.imageUrls.length) {
      final imageWidget = CachedNetworkImage(
        imageUrl: _allMedia[index], 
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Container(color: Colors.grey[200]),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );

      if (index == 0) return Hero(tag: widget.product.id, child: imageWidget);
      return imageWidget;
    } else {
      String videoUrl = _allMedia[index];
      if (!_videoControllers.containsKey(index)) {
        return FutureBuilder(
          future: _initVideo(index, videoUrl),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.done) {
               return Chewie(controller: _videoControllers[index]!);
            }
            return const Center(child: CircularProgressIndicator());
          }
        );
      }
      return Chewie(controller: _videoControllers[index]!);
    }
  }

  Future<void> _initVideo(int index, String url) async {
    final vCtrl = VideoPlayerController.networkUrl(Uri.parse(url));
    await vCtrl.initialize();
    final cCtrl = ChewieController(
       videoPlayerController: vCtrl,
       autoPlay: false, looping: true, aspectRatio: vCtrl.value.aspectRatio,
       errorBuilder: (ctx, err) => const Center(child: Icon(Icons.error, color: Colors.white)),
    );
    if (mounted) setState(() => _videoControllers[index] = cCtrl);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formattedDate = timeago.format(p.createdAt, locale: 'fr');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 350, 
                backgroundColor: theme.scaffoldBackgroundColor,
                pinned: true,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.share,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () async {
                        try {
                          await SocialSharingService.shareProduct(p);
                          
                          // Track share event
                          await AnalyticsService.logProductShare(
                            productId: p.id,
                            productTitle: p.title,
                          );
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('âœ… Produit partagé !'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('âŒ Erreur: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                action: SnackBarAction(
                                  label: 'Réessayer',
                                  textColor: Colors.white,
                                  onPressed: () async {
                                    await SocialSharingService.shareProduct(p);
                                  },
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseAuth.instance.currentUser != null 
                        ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).collection('favorites').doc(p.id).snapshots()
                        : null,
                      builder: (context, snapshot) {
                        bool isFav = snapshot.hasData && snapshot.data!.exists;
                        return IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : (isDark ? Colors.white : Colors.black),
                          ),
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AuthScreen(fromProfile: true),
                                ),
                              );
                              return;
                            }

                            final ref = FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('favorites')
                                .doc(p.id);

                            if (isFav) {
                              await ref.delete();
                            } else {
                              await ref.set({
                                'productId': p.id,
                                'addedAt': FieldValue.serverTimestamp(),
                              });
                              BehaviorTrackingService().trackFavorite(
                                p.id,
                                p.brand ?? '',
                                p.category,
                                p.price,
                              );
                            }
                          },
                        );
                      }
                    ), 
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                       PageView.builder(
                         itemCount: _allMedia.length,
                         onPageChanged: (index) {
                           setState(() => _currentImageIndex = index);
                           _photoSwipeCount++; // Track for ML
                         },
                         itemBuilder: (ctx, i) => _buildMediaItem(i),
                       ),
                       if (_allMedia.length > 1)
                         Positioned(
                           bottom: 20, left: 0, right: 0,
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: List.generate(_allMedia.length, (index) {
                               return AnimatedContainer(
                                 duration: const Duration(milliseconds: 300),
                                 margin: const EdgeInsets.symmetric(horizontal: 4),
                                 width: _currentImageIndex == index ? 20 : 8,
                                 height: 8,
                                 decoration: BoxDecoration(color: _currentImageIndex == index ? Colors.white : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(4)),
                               );
                             }),
                           ),
                         ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  transform: Matrix4.translationValues(0, -20, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITRE & PRIX
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (p.brand != null)
                                  Text(p.brand!.toUpperCase(), style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                                Text(p.title, style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w900, color: theme.textTheme.bodyLarge?.color, height: 1.2)),
                              ],
                            )
                          ),
                          const SizedBox(width: 10),
                          Text("${p.price.toStringAsFixed(0)} EUR", style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      // METADATA
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text("${p.wilaya}, ${p.commune ?? ''}", style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 13)),
                          const Spacer(),
                          Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(formattedDate, style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                      
                      const SizedBox(height: 25),
                      const Divider(),
                      const SizedBox(height: 20),

                      // --- CAR SPECS ---
                      Text("Caractéristiques", style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Wrap(
                        spacing: 10, runSpacing: 10,
                        children: [
                          if (p.year != null) _buildSpecChip(Icons.calendar_today, "${p.year}"),
                          if (p.km != null) _buildSpecChip(Icons.speed, "${p.km} km"),
                          if (p.fuel != null) _buildSpecChip(Icons.local_gas_station, CategoriesData.tSpecies(p.fuel!, 'fr')),
                          if (p.gearbox != null) _buildSpecChip(Icons.settings, CategoriesData.tSpecies(p.gearbox!, 'fr')),
                          if (p.color != null) _buildSpecChip(Icons.palette, CategoriesData.tSpecies(p.color!, 'fr')),
                          if (p.engine != null && p.engine!.isNotEmpty) _buildSpecChip(Icons.engineering, "${p.engine}"),
                          if (p.exchange == true) _buildSpecChip(Icons.sync_alt, "Échange"),
                          if (p.papers != null) _buildSpecChip(Icons.article, CategoriesData.tSpecies(p.papers!, 'fr')),
                        ],
                      ),

                      if (p.detectedEquipments.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          "Equipements detectes",
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: p.detectedEquipments
                              .map(
                                (equipment) => Chip(
                                  avatar: const Icon(
                                    Icons.auto_awesome,
                                    size: 16,
                                  ),
                                  label: Text(
                                    equipment,
                                    style: GoogleFonts.cairo(fontSize: 12),
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                              .toList(),
                        ),
                      ],

                      const SizedBox(height: 25),
                      Text("Description", style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ReadMoreText(
                        p.description,
                        trimLines: 4,
                        colorClickableText: theme.colorScheme.primary,
                        trimMode: TrimMode.Line,
                        trimCollapsedText: '...Voir plus',
                        trimExpandedText: ' Voir moins',
                        style: GoogleFonts.cairo(fontSize: 15, height: 1.6),
                      ),
                      
                      const SizedBox(height: 30),

                      // SELLER INFO
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.canvasColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.5))
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24, 
                              backgroundColor: theme.colorScheme.primary, 
                              child: Text(p.sellerId.substring(0,1).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Vendeur", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                                FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection('users').doc(p.sellerId).get(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) return const Text("...");
                                    var data = snapshot.data!.data() as Map<String, dynamic>?;
                                    return Text(
                                      data?['name'] ?? data?['username'] ?? 'User', 
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)
                                    );
                                  }
                                ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(onPressed: () => _openSellerProfile("Seller"), icon: const Icon(Icons.arrow_forward_ios, size: 16))
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),

                      // SIMILAR CARS SECTION
                      Text(
                        "Voitures similaires",
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      
                      FutureBuilder<List<Product>>(
                        future: RecommendationService.getSimilarCars(p, limit: 5),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            // Loading state
                            return SizedBox(
                              height: 220,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 5,
                                itemBuilder: (context, index) {
                                  return const HorizontalCardSkeleton();
                                },
                              ),
                            );
                          }

                          final similarCars = snapshot.data!;

                          if (similarCars.isEmpty) {
                            // Empty state
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.canvasColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.dividerColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.grey[400],
                                    size: 32,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      "Aucune voiture similaire pour le moment",
                                      style: GoogleFonts.cairo(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Display similar cars
                          return SizedBox(
                            height: 220,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: similarCars.length,
                              itemBuilder: (context, index) {
                                final car = similarCars[index];
                                return Container(
                                  width: 160,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: GestureDetector(
                                    onTap: () {
                                      // Track similar product click
                                      AnalyticsService.logSimilarProductClick(
                                        sourceProductId: p.id,
                                        clickedProductId: car.id,
                                        position: index,
                                      );
                                      
                                      // Navigate to product details
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailsScreen(
                                            product: car,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Image
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                              child: OptimizedImage(
                                                imageUrl: car.imageUrls.isNotEmpty
                                                    ? car.imageUrls[0]
                                                    : '',
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
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
                                                  car.title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                // Price
                                                Text(
                                                  "${car.price.toStringAsFixed(0)} EUR",
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
                                                    Icon(
                                                      Icons.location_on,
                                                      size: 10,
                                                      color: Colors.grey[500],
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Expanded(
                                                      child: Text(
                                                        car.wilaya,
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
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      
                      // SIMILAR PRODUCTS SECTION
                      const SizedBox(height: 20),
                      SimilarProductsSection(product: widget.product),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
           // BOTTOM BAR
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: (FirebaseAuth.instance.currentUser?.uid == widget.product.sellerId)
              ? SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showBoostOptions,
                  icon: const Icon(Icons.rocket_launch),
                  label: Text("Booster mon annonce", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.amber[800],
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // â”€â”€ PRIMARY CTA: APPELER â”€â”€
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: _callSeller,
                            icon: const Icon(Icons.phone_rounded, size: 20),
                            label: Text(
                              'Appeler',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // â”€â”€ SECONDARY CTA: WHATSAPP â”€â”€
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: _openWhatsApp,
                            icon: const Icon(Icons.chat_rounded, size: 20),
                            label: Text(
                              'WhatsApp',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // â”€â”€ IN-APP CHAT â”€â”€
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: theme.dividerColor, width: 1.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            onPressed: () => _contactSeller('Seller'),
                            icon: const Icon(
                                Icons.chat_bubble_outline_rounded),
                            tooltip: 'Chat in-app',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // â”€â”€ REPORT LINK â”€â”€
                    GestureDetector(
                      onTap: _showReportSheet,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flag_outlined,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Signaler cette annonce',
                            style: GoogleFonts.cairo(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ),
          ),
        ],
      ),
    );
  }
}

