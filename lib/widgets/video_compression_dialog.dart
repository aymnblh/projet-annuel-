import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/video_compression_service.dart';
import '../services/analytics_service.dart';
import '../utils/app_translations.dart';
import '../main.dart';

/// Dialog that shows video compression progress with stats and cancel option
class VideoCompressionDialog extends StatefulWidget {
  final File videoFile;
  final Function(File? compressedFile) onComplete;
  final VoidCallback? onCancel;

  const VideoCompressionDialog({
    super.key,
    required this.videoFile,
    required this.onComplete,
    this.onCancel,
  });

  @override
  State<VideoCompressionDialog> createState() => _VideoCompressionDialogState();
}

class _VideoCompressionDialogState extends State<VideoCompressionDialog> {
  String t(String key) => AppTranslations.get(languageNotifier.value, key);
  
  final VideoCompressionService _compressionService = VideoCompressionService();
  double _progress = 0.0;
  String _status = 'Préparation...';
  bool _isCancelled = false;
  String? _originalSize;
  String? _estimatedSize;
  DateTime? _startTime; // Track compression duration

  @override
  void initState() {
    super.initState();
    _startCompression();
  }

  Future<void> _startCompression() async {
    try {
      // Get original file size
      final originalBytes = await widget.videoFile.length();
      setState(() {
        _originalSize = _formatFileSize(originalBytes);
        _status = 'Compression en cours...';
        _startTime = DateTime.now();
      });
      
      // Track compression start
      await AnalyticsService.logVideoCompressionStarted(
        originalSizeMB: originalBytes / (1024 * 1024),
      );

      // Compress with progress callback
      final compressedFile = await _compressionService.compressVideo(
        videoFile: widget.videoFile,
        onProgress: (progress) {
          if (!_isCancelled && mounted) {
            setState(() {
              _progress = progress;
              // Estimate compressed size based on typical 70-80% reduction
              final estimatedBytes = (originalBytes * (1 - 0.75 * progress)).toInt();
              _estimatedSize = _formatFileSize(estimatedBytes);
            });
          }
        },
      );

      if (_isCancelled) {
        // Cleanup if cancelled
        if (compressedFile != null) {
          try {
            await compressedFile.delete();
          } catch (e) {
            debugPrint('Error deleting cancelled file: $e');
          }
        }
        return;
      }

      if (mounted) {
        // Get final stats
        if (compressedFile != null) {
          final stats = await _compressionService.getCompressionStats(
            originalFile: widget.videoFile,
            compressedFile: compressedFile,
          );
          
          setState(() {
            _status = 'Terminé !';
            _estimatedSize = stats.compressedSizeFormatted;
          });
          
          // Track compression success
          final duration = _startTime != null 
              ? DateTime.now().difference(_startTime!).inSeconds 
              : 0;
          await AnalyticsService.logVideoCompressionSuccess(
            originalSizeMB: stats.originalSize / (1024 * 1024),
            compressedSizeMB: stats.compressedSize / (1024 * 1024),
            reductionPercentage: stats.reductionPercentage,
            durationSeconds: duration,
          );

          // Wait a moment to show success
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // Close dialog and return result
        if (mounted) {
          Navigator.of(context).pop();
          widget.onComplete(compressedFile);
        }
      }
    } on VideoCompressionException catch (e) {
      // Track compression error
      await AnalyticsService.logVideoCompressionError(
        errorType: e.type.toString(),
        errorMessage: e.message,
      );
      
      if (mounted && !_isCancelled) {
        Navigator.of(context).pop();
        _showErrorDialog(e.message, e.isRetryable);
      }
    } catch (e) {
      if (mounted && !_isCancelled) {
        Navigator.of(context).pop();
        _showErrorDialog('Une erreur est survenue: $e', true);
      }
    }
  }

  void _showErrorDialog(String message, bool canRetry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur de compression'),
        content: Text(message),
        actions: [
          if (canRetry)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _progress = 0.0;
                  _status = 'Nouvelle tentative...';
                });
                _startCompression();
              },
              child: const Text('Réessayer'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onComplete(null);
            },
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancel() async {
    setState(() => _isCancelled = true);
    
    try {
      await _compressionService.cancelCompression();
      
      // Track cancellation
      await AnalyticsService.logVideoCompressionCancelled(
        progress: _progress,
      );
    } catch (e) {
      debugPrint('Error cancelling compression: $e');
    }

    if (mounted) {
      Navigator.of(context).pop();
      if (widget.onCancel != null) {
        widget.onCancel!();
      } else {
        widget.onComplete(null);
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return WillPopScope(
      onWillPop: () async {
        // Prevent dismissing by tapping outside
        return false;
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.video_file,
                  size: 48,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                t('video_compression_title'),
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Status
              Text(
                _status,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                ),
              ),
              const SizedBox(height: 8),

              // Progress percentage
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 24),

              // Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Original size
                    Column(
                      children: [
                        Text(
                          t('video_compression_original'),
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _originalSize ?? '...',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Arrow
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.grey[400],
                    ),

                    // Compressed size
                    Column(
                      children: [
                        Text(
                          t('video_compression_compressed'),
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _estimatedSize ?? '...',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isCancelled ? null : _handleCancel,
                  icon: const Icon(Icons.close),
                  label: Text(
                    t('video_compression_cancel'),
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_isCancelled) {
      _compressionService.cancelCompression();
    }
    super.dispose();
  }
}

/// Helper function to show the compression dialog
Future<File?> showVideoCompressionDialog({
  required BuildContext context,
  required File videoFile,
  VoidCallback? onCancel,
}) async {
  File? result;
  
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => VideoCompressionDialog(
      videoFile: videoFile,
      onComplete: (compressedFile) {
        result = compressedFile;
      },
      onCancel: onCancel,
    ),
  );
  
  return result;
}
