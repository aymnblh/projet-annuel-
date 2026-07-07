import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/favorites_service.dart';

/// Animated favorite button widget
/// 
/// Shows heart icon that toggles between outline and filled states
/// with smooth animation and haptic feedback
class FavoriteButton extends StatefulWidget {
  final String productId;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showBackground;
  
  const FavoriteButton({
    super.key,
    required this.productId,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
    this.showBackground = true,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> with SingleTickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService();
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Setup animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    // Check initial favorite status
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await _favoritesService.isFavorite(widget.productId);
    if (mounted) {
      setState(() => _isFavorite = isFav);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();
      
      // Animate
      await _controller.forward();
      
      // Toggle favorite
      await _favoritesService.toggleFavorite(widget.productId);
      
      // Update state
      setState(() => _isFavorite = !_isFavorite);
      
      // Reverse animation
      await _controller.reverse();
      
      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite 
                ? '❤️ Ajouté aux favoris' 
                : 'Retiré des favoris',
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
          ),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? Colors.red;
    final inactiveColor = widget.inactiveColor ?? Colors.white;
    
    return GestureDetector(
      onTap: _toggleFavorite,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: widget.showBackground 
                ? const EdgeInsets.all(8) 
                : EdgeInsets.zero,
              decoration: widget.showBackground
                ? BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  )
                : null,
              child: _isLoading
                ? SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                    ),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? activeColor : inactiveColor,
                    size: widget.size,
                  ),
            ),
          );
        },
      ),
    );
  }
}

/// Simplified favorite button for use in lists
class SimpleFavoriteButton extends StatelessWidget {
  final String productId;
  final double size;
  
  const SimpleFavoriteButton({
    super.key,
    required this.productId,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return FavoriteButton(
      productId: productId,
      size: size,
      showBackground: false,
    );
  }
}
