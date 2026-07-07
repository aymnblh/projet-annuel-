import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/review.dart';
import '../services/review_service.dart';
import '../widgets/rating_stars.dart';

class ReviewCard extends StatefulWidget {
  final Review review;
  final bool isSellerView; // If seller is viewing their product's reviews
  final VoidCallback? onUpdated; // Callback after actions

  const ReviewCard({
    super.key,
    required this.review,
    this.isSellerView = false,
    this.onUpdated,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _isSubmittingResponse = false;
  final TextEditingController _responseController = TextEditingController();

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _markHelpful() async {
    final success = await ReviewService.markReviewHelpful(widget.review.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci pour votre retour !')),
      );
      widget.onUpdated?.call();
    }
  }

  Future<void> _flagReview() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _FlagReviewDialog(),
    );

    if (reason != null && reason.isNotEmpty) {
      final success = await ReviewService.flagReview(widget.review.id, reason);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avis signalé à l\'admin')),
        );
        widget.onUpdated?.call();
      }
    }
  }

  Future<void> _submitResponse() async {
    if (_responseController.text.trim().isEmpty) return;

    setState(() => _isSubmittingResponse = true);

    final success = await ReviewService.addSellerResponse(
      widget.review.id,
      _responseController.text.trim(),
    );

    setState(() => _isSubmittingResponse = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réponse publiée !')),
      );
      _responseController.clear();
      widget.onUpdated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isSeller = currentUser?.uid == widget.review.sellerId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info + Rating
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.review.userPhoto != null
                      ? NetworkImage(widget.review.userPhoto!)
                      : null,
                  child: widget.review.userPhoto == null
                      ? Text(widget.review.userName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),

                // Name + Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.review.userName,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        timeago.format(widget.review.createdAt, locale: 'fr'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Rating
                RatingStars(rating: widget.review.rating.toDouble(), size: 18),
              ],
            ),

            const SizedBox(height: 12),

            // Comment
            Text(
              widget.review.comment,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),

            // Photos
            if (widget.review.photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.review.photos.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRectImage(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.review.photos[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                // Helpful button
                TextButton.icon(
                  onPressed: _markHelpful,
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: Text(
                    'Utile (${widget.review.helpfulCount})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),

                const SizedBox(width: 8),

                // Flag button (for sellers)
                if (isSeller && !widget.review.isFlagged)
                  TextButton.icon(
                    onPressed: _flagReview,
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    label: const Text(
                      'Signaler',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),

                if (widget.review.isFlagged)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag, size: 14, color: Colors.orange[800]),
                        const SizedBox(width: 4),
                        Text(
                          'Signalé',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Seller Response Section
            if (widget.review.sellerResponse != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Réponse du vendeur',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.blue[700],
                          ),
                        ),
                        const Spacer(),
                        if (widget.review.sellerResponseDate != null)
                          Text(
                            timeago.format(widget.review.sellerResponseDate!, locale: 'fr'),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.review.sellerResponse!,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],

            // Add Response (for seller, if no response yet)
            if (isSeller && widget.review.sellerResponse == null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _responseController,
                decoration: InputDecoration(
                  hintText: 'Répondre à cet avis...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: _isSubmittingResponse
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _submitResponse,
                        ),
                ),
                maxLines: 3,
                minLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Flag Review Dialog
class _FlagReviewDialog extends StatefulWidget {
  @override
  State<_FlagReviewDialog> createState() => _FlagReviewDialogState();
}

class _FlagReviewDialogState extends State<_FlagReviewDialog> {
  String? _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();

  final List<String> _reasons = [
    'Contenu inapproprié',
    'Langage offensant',
    'Spam',
    'Faux avis',
    'Hors sujet',
    'Autre',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Signaler cet avis'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Pourquoi signalez-vous cet avis ?'),
          const SizedBox(height: 16),
          ...List.generate(_reasons.length, (index) {
            final reason = _reasons[index];
            return RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) => setState(() => _selectedReason = value),
            );
          }),
          if (_selectedReason == 'Autre') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _customReasonController,
              decoration: const InputDecoration(
                hintText: 'Précisez la raison...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = _selectedReason == 'Autre'
                ? _customReasonController.text.trim()
                : _selectedReason;
            Navigator.pop(context, reason);
          },
          child: const Text('Signaler'),
        ),
      ],
    );
  }
}

// Helper widget for ClipRRect
class ClipRRectImage extends StatelessWidget {
  final BorderRadius borderRadius;
  final Widget child;

  const ClipRRectImage({
    super.key,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: child,
    );
  }
}
