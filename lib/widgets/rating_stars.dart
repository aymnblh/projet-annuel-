import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int starCount;
  final double size;
  final Color color;
  final Color emptyColor;
  final bool allowHalfStars;
  final Function(int)? onRatingChanged; // For input mode

  const RatingStars({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 20,
    this.color = Colors.amber,
    this.emptyColor = Colors.grey,
    this.allowHalfStars = true,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Input mode (tappable)
    if (onRatingChanged != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(starCount, (index) {
          return GestureDetector(
            onTap: () => onRatingChanged!(index + 1),
            child: Icon(
              Icons.star,
              size: size,
              color: index < rating ? color : emptyColor,
            ),
          );
        }),
      );
    }

    // Display mode (non-interactive)
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        IconData icon;
        Color starColor;

        if (index < rating.floor()) {
          // Full star
          icon = Icons.star;
          starColor = color;
        } else if (allowHalfStars && index < rating) {
          // Half star
          icon = Icons.star_half;
          starColor = color;
        } else {
          // Empty star
          icon = Icons.star_border;
          starColor = emptyColor;
        }

        return Icon(icon, size: size, color: starColor);
      }),
    );
  }
}

/// Compact rating display with number
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double size;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount = 0,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (rating == 0 && reviewCount == 0) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: size, color: Colors.amber),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size * 0.9,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (reviewCount > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: size * 0.8,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}
