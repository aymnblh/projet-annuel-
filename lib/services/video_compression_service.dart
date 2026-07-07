import 'dart:io';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Service for compressing videos before upload
/// 
/// Reduces video file sizes by 70-80% while maintaining acceptable quality
class VideoCompressionService {
  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB

  /// Compress a video file
  /// 
  /// Returns compressed file or null if compression fails
  /// Callback provides progress (0.0 to 1.0)
  /// 
  /// Throws [VideoCompressionException] with user-friendly messages
  Future<File?> compressVideo({
    required File videoFile,
    VideoQuality quality = VideoQuality.MediumQuality,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Validate input file
      if (!await videoFile.exists()) {
        throw VideoCompressionException(
          'Le fichier vidéo n\'existe pas. Veuillez réessayer.',
          type: VideoCompressionErrorType.fileNotFound,
        );
      }

      final originalSize = await videoFile.length();
      if (originalSize == 0) {
        throw VideoCompressionException(
          'Le fichier vidéo est vide ou corrompu.',
          type: VideoCompressionErrorType.corruptedFile,
        );
      }

      // Subscribe to compression progress
      final subscription = VideoCompress.compressProgress$.subscribe((progress) {
        if (onProgress != null) {
          onProgress(progress / 100.0);
        }
      });

      try {
        // Compress the video
        final info = await VideoCompress.compressVideo(
          videoFile.path,
          quality: quality,
          deleteOrigin: false, // Keep original file
          includeAudio: true,
        );

        // Cancel subscription
        subscription.unsubscribe();

        if (info == null || info.file == null) {
          throw VideoCompressionException(
            'La compression a échoué. Vérifiez que le fichier est une vidéo valide.',
            type: VideoCompressionErrorType.compressionFailed,
          );
        }

        // Check compressed file size
        final compressedSize = await info.file!.length();
        
        if (compressedSize > maxFileSizeBytes) {
          // Still too large, try lower quality
          if (quality != VideoQuality.LowQuality) {
            print('File still too large, trying lower quality...');
            return await compressVideo(
              videoFile: videoFile,
              quality: VideoQuality.LowQuality,
              onProgress: onProgress,
            );
          } else {
            throw VideoCompressionException(
              'La vidéo est trop volumineuse (${_formatFileSize(compressedSize)}). '
              'Maximum: ${_formatFileSize(maxFileSizeBytes)}. '
              'Veuillez choisir une vidéo plus courte.',
              type: VideoCompressionErrorType.fileTooLarge,
            );
          }
        }

        return info.file;
      } finally {
        // Ensure subscription is always cancelled
        subscription.unsubscribe();
      }
    } on VideoCompressionException {
      rethrow;
    } catch (e) {
      print('Error compressing video: $e');
      
      // Provide user-friendly error messages
      if (e.toString().contains('permission')) {
        throw VideoCompressionException(
          'Impossible d\'accéder au fichier. Vérifiez les permissions.',
          type: VideoCompressionErrorType.permissionDenied,
          originalError: e,
        );
      } else if (e.toString().contains('storage') || e.toString().contains('space')) {
        throw VideoCompressionException(
          'Espace de stockage insuffisant. Libérez de l\'espace et réessayez.',
          type: VideoCompressionErrorType.insufficientStorage,
          originalError: e,
        );
      } else {
        throw VideoCompressionException(
          'Une erreur est survenue lors de la compression. Veuillez réessayer.',
          type: VideoCompressionErrorType.unknown,
          originalError: e,
        );
      }
    }
  }

  /// Get video file information
  Future<MediaInfo?> getVideoInfo(String path) async {
    try {
      return await VideoCompress.getMediaInfo(path);
    } catch (e) {
      print('Error getting video info: $e');
      return null;
    }
  }

  /// Get compression statistics
  Future<CompressionStats> getCompressionStats({
    required File originalFile,
    required File compressedFile,
  }) async {
    final originalSize = await originalFile.length();
    final compressedSize = await compressedFile.length();
    final reduction = ((originalSize - compressedSize) / originalSize * 100);

    return CompressionStats(
      originalSize: originalSize,
      compressedSize: compressedSize,
      reductionPercentage: reduction,
      originalSizeFormatted: _formatFileSize(originalSize),
      compressedSizeFormatted: _formatFileSize(compressedSize),
    );
  }

  /// Cancel ongoing compression
  Future<void> cancelCompression() async {
    try {
      await VideoCompress.cancelCompression();
    } catch (e) {
      print('Error canceling compression: $e');
    }
  }

  /// Delete all temporary compressed files
  Future<void> deleteAllCache() async {
    try {
      await VideoCompress.deleteAllCache();
    } catch (e) {
      print('Error deleting cache: $e');
    }
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if video needs compression
  Future<bool> needsCompression(File videoFile) async {
    final size = await videoFile.length();
    return size > 10 * 1024 * 1024; // Compress if >10MB
  }
}

/// Compression statistics
class CompressionStats {
  final int originalSize;
  final int compressedSize;
  final double reductionPercentage;
  final String originalSizeFormatted;
  final String compressedSizeFormatted;

  CompressionStats({
    required this.originalSize,
    required this.compressedSize,
    required this.reductionPercentage,
    required this.originalSizeFormatted,
    required this.compressedSizeFormatted,
  });

  @override
  String toString() {
    return 'Original: $originalSizeFormatted → Compressed: $compressedSizeFormatted '
        '(${reductionPercentage.toStringAsFixed(1)}% reduction)';
  }
}

/// Custom exception for video compression errors
class VideoCompressionException implements Exception {
  final String message;
  final VideoCompressionErrorType type;
  final Object? originalError;

  VideoCompressionException(
    this.message, {
    required this.type,
    this.originalError,
  });

  @override
  String toString() => message;

  /// Whether this error is retryable
  bool get isRetryable {
    return type != VideoCompressionErrorType.fileTooLarge &&
           type != VideoCompressionErrorType.corruptedFile &&
           type != VideoCompressionErrorType.insufficientStorage;
  }
}

/// Types of video compression errors
enum VideoCompressionErrorType {
  fileNotFound,
  corruptedFile,
  fileTooLarge,
  compressionFailed,
  permissionDenied,
  insufficientStorage,
  unknown,
}
