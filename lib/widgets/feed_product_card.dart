import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart'; // <--- VIDEO
import 'package:chewie/chewie.dart';           // <--- CHEWIE
import '../models/product.dart';
import '../providers/user_provider.dart';
import '../views/product_details_screen.dart';
import '../views/auth_screen.dart';
import '../widgets/optimized_image.dart';
import '../widgets/rating_stars.dart';
import '../widgets/favorite_button.dart';
import '../utils/app_constants.dart'; // NEW: Design system
import '../utils/app_glassmorphism.dart'; // NEW: Glassmorphism

class FeedProductCard extends StatefulWidget {
  final Product product;
  const FeedProductCard({super.key, required this.product});

  @override
  State<FeedProductCard> createState() => _FeedProductCardState();
}

class _FeedProductCardState extends State<FeedProductCard> {
  int _currentImageIndex = 0;
  List<String> _allMedia = [];
  final Map<int, ChewieController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    // Combine Images + Vidéos
    _allMedia = [...widget.product.imageUrls, ...widget.product.videoUrls];
  }

  @override
  void dispose() {
    for (var controller in _videoControllers.values) {
      controller.videoPlayerController.dispose();
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildMediaItem(int index) {
    if (index < widget.product.imageUrls.length) {
      // C'EST UNE IMAGE
      return GestureDetector(
        onDoubleTap: () {
           final userProvider = Provider.of<UserProvider>(context, listen: false);
           if (FirebaseAuth.instance.currentUser == null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(fromProfile: true)));
              return;
           }
           userProvider.toggleFavorite(widget.product.id);
           // RECOMMANDATION : Liker = Fort intérêt
           userProvider.logInterest(widget.product.category, weight: 5);
        },
        onTap: () {
           final userProvider = Provider.of<UserProvider>(context, listen: false);
           // RECOMMANDATION : Voir détails = Intérêt léger
           userProvider.logInterest(widget.product.category, weight: 1);
           
           Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: widget.product)));
        },
        child: OptimizedImage(
          imageUrl: _allMedia[index],
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else {
      // C'EST UNE VIDÉO
      String videoUrl = _allMedia[index];
      
      // Initialisation Lazy du Controller Vidéo si pas encore fait
      if (!_videoControllers.containsKey(index)) {
        return FutureBuilder(
          future: _initializePlayer(index, videoUrl),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
               return Chewie(controller: _videoControllers[index]!);
            }
            return Container(color: Colors.black, child: const Center(child: CircularProgressIndicator(color: Colors.white)));
          },
        );
      } else {
        return Chewie(controller: _videoControllers[index]!);
      }
    }
  }

  Future<void> _initializePlayer(int index, String url) async {
    final videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
    await videoPlayerController.initialize();
    
    final chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      autoPlay: false,
      looping: true,
      aspectRatio: 1.0, // Carré pour le feed
      showControls: true, 
      placeholder: Container(color: Colors.black),
      errorBuilder: (context, errorMessage) => Center(child: Text("Erreur vidéo: $errorMessage", style: const TextStyle(color: Colors.white))),
    );
    
    if (mounted) {
      setState(() {
        _videoControllers[index] = chewieController;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isLiked = userProvider.isFavorite(widget.product.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER (User info)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0F172A),
                  radius: 18,
                  child: Text(widget.product.sellerId.isNotEmpty ? widget.product.sellerId[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.product.sellerId, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)), 
                      Text(widget.product.wilaya, style: GoogleFonts.cairo(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ],
            ),
          ),

          // 2. MEDIA CAROUSEL (IMAGES + VIDEO)
          AspectRatio(
            aspectRatio: 1.0, 
            child: Stack(
              children: [
                 _allMedia.isNotEmpty 
                 ? PageView.builder(
                     itemCount: _allMedia.length,
                     onPageChanged: (index) => setState(() => _currentImageIndex = index),
                     itemBuilder: (context, index) => Stack(
                       fit: StackFit.expand,
                       children: [
                         _buildMediaItem(index),
                         // Gradient overlay for better text readability
                         Positioned(
                           bottom: 0,
                           left: 0,
                           right: 0,
                           child: Container(
                             height: 100,
                             decoration: BoxDecoration(
                               gradient: LinearGradient(
                                 begin: Alignment.bottomCenter,
                                 end: Alignment.topCenter,
                                 colors: [
                                   Colors.black.withOpacity(0.6),
                                   Colors.transparent,
                                 ],
                               ),
                             ),
                           ),
                         ),
                       ],
                     ),
                   )
                 : Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 50)),
                 
                 // DOT INDICATORS
                 if (_allMedia.length > 1)
                   Positioned(
                     bottom: 10,
                     left: 0,
                     right: 0,
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: List.generate(
                         _allMedia.length,
                         (index) => AnimatedContainer(
                           duration: const Duration(milliseconds: 300),
                           margin: const EdgeInsets.symmetric(horizontal: 3),
                           width: _currentImageIndex == index ? 8 : 6,
                           height: _currentImageIndex == index ? 8 : 6,
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             color: _currentImageIndex == index
                                 ? Colors.white
                                 : Colors.white.withOpacity(0.5),
                             boxShadow: [
                               BoxShadow(
                                 color: Colors.black.withOpacity(0.3),
                                 blurRadius: 2,
                               ),
                             ],
                           ),
                         ),
                       ),
                     ),
                   ),
                 
                 // IMAGE COUNTER
                 if (_allMedia.length > 1)
                   Positioned(
                     top: 10, right: 10,
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(
                         color: Colors.black.withOpacity(0.6),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Text(
                         "${_currentImageIndex + 1}/${_allMedia.length}",
                         style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                       ),
                     ),
                   ),
             
             // NEW: FAVORITE BUTTON (top-right when no counter, or below counter)
             Positioned(
               top: _allMedia.length > 1 ? 50 : 10, // Below counter if exists
               right: 10,
               child: FavoriteButton(
                 productId: widget.product.id,
                 size: 24,
                 showBackground: true,
               ),
             ),
             
            // BADGES (Sponsorisé / Urgent)
            Positioned(
              top: 10, left: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                if (widget.product.isBoosted)
                    GlassBadge(
                      text: "BOOST",
                      icon: Icons.rocket_launch,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                    ),

                  if (widget.product.isUrgent)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 1.0 + (value * 0.1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.6 * value),
                                  blurRadius: 8 * value,
                                  spreadRadius: 2 * value,
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_fire_department, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  "URGENT",
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      onEnd: () {
                        if (mounted) {
                          setState(() {}); // Restart animation
                        }
                      },
                    ),
                    
                  // NEW badge (if posted within last 7 days)
                  if (DateTime.now().difference(widget.product.createdAt).inDays < 7)
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: Text(
                        "NOUVEAU",
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // FLOATING QUICK ACTIONS
            Positioned(
              right: 10,
              bottom: 10,
              child: Column(
                children: [
                  _buildFloatingActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.white,
                    onTap: () {
                      if (FirebaseAuth.instance.currentUser == null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuthScreen(fromProfile: true),
                          ),
                        );
                        return;
                      }
                      userProvider.toggleFavorite(widget.product.id);
                      if (!isLiked) {
                        userProvider.logInterest(widget.product.category, weight: 5);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildFloatingActionButton(
                    icon: Icons.share_outlined,
                    color: Colors.white,
                    onTap: () {
                      // Share functionality
                    },
                  ),
                ],
              ),
            ),
              ],
            ),
          ),

          // 3. ACTIONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Theme.of(context).iconTheme.color, size: 28),
                  onPressed: () {
                    if (FirebaseAuth.instance.currentUser == null) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(fromProfile: true)));
                        return;
                    }
                    userProvider.toggleFavorite(widget.product.id);
                    // RECOMMANDATION
                    if (!isLiked) { // Si on like (pas unlike)
                       userProvider.logInterest(widget.product.category, weight: 5);
                    }
                  },
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 26),
                  onPressed: () { 
                    // Navigation chat (Ã  implémenter)
                    // Navigator.push(...);
                  },
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 26),
                  onPressed: () {},
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                if (widget.product.price > 0)
                  Text(
                    "${widget.product.price.toStringAsFixed(0)} EUR", 
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
                  ),
              ],
            ),
          ),

          // 4. DESCRIPTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.cairo(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14),
                    children: [
                      TextSpan(text: widget.product.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(text: "  "),
                      TextSpan(text: widget.product.description, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Product Rating (if has reviews)
                if (widget.product.reviewCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: RatingDisplay(
                      rating: widget.product.averageRating,
                      reviewCount: widget.product.reviewCount,
                      size: 14,
                    ),
                  ),
                  
                  // Seller Rating (existing)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(widget.product.sellerId).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final rating = (data['rating'] as num?)?.toDouble();
                      final reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
                      
                      if (rating == null || rating == 0) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            Text(" ${rating.toStringAsFixed(1)} ($reviewCount)", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }
                  ),
                const SizedBox(height: 5),
                Text(
                  timeago.format(widget.product.createdAt), 
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          boxShadow: AppShadows.elevated,
        ),
        child: Icon(
          icon,
          color: color,
          size: 22,
        ),
      ),
    );
  }
}

