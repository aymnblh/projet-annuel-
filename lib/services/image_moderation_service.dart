import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ModerationResult — résultat agrégé de la modération d'un lot d'images
// ═══════════════════════════════════════════════════════════════════════════════

class ModerationResult {
  final List<File> moderatedFiles;
  final int facesBlurred;
  final int platesBlurred;
  final bool hadModifications;

  const ModerationResult({
    required this.moderatedFiles,
    required this.facesBlurred,
    required this.platesBlurred,
    required this.hadModifications,
  });

  @override
  String toString() =>
      'ModerationResult(files: ${moderatedFiles.length}, '
      'faces: $facesBlurred, plates: $platesBlurred, '
      'modified: $hadModifications)';
}

// ═══════════════════════════════════════════════════════════════════════════════
// ImageModerationService — Floutage automatique des visages et plaques
// ═══════════════════════════════════════════════════════════════════════════════

class ImageModerationService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // ---------------------------------------------------------------------------
  // PUBLIC — Point d'entrée principal : modérer une seule image
  // ---------------------------------------------------------------------------

  /// Detects faces and license plates in [imageFile], blurs them, and returns
  /// the moderated file. Returns `null` if no faces or plates were found
  /// (i.e. no modification was needed).
  Future<File?> moderateImage(File imageFile) async {
    try {
      // 1. Detect faces
      List<Rect> faceRegions = [];
      try {
        faceRegions = await detectFaces(imageFile);
        debugPrint('🔍 ImageModeration: ${faceRegions.length} face(s) detected');
      } catch (e) {
        debugPrint('⚠️ ImageModeration: Face detection failed — $e');
      }

      // 2. Detect license plates
      List<Rect> plateRegions = [];
      try {
        plateRegions = await detectLicensePlates(imageFile);
        debugPrint('🔍 ImageModeration: ${plateRegions.length} plate(s) detected');
      } catch (e) {
        debugPrint('⚠️ ImageModeration: Plate detection failed — $e');
      }

      // 3. Combine all regions
      final allRegions = [...faceRegions, ...plateRegions];

      if (allRegions.isEmpty) {
        debugPrint('✅ ImageModeration: No sensitive regions found — image is clean');
        return null;
      }

      // 4. Apply blur to all detected regions
      final moderatedFile = await applyBlur(imageFile, allRegions);
      debugPrint(
        '✅ ImageModeration: Blurred ${faceRegions.length} face(s) '
        'and ${plateRegions.length} plate(s)',
      );
      return moderatedFile;
    } catch (e) {
      debugPrint('❌ ImageModeration: Unexpected error — $e');
      // Never break the upload flow: return null (caller keeps original)
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // PUBLIC — Modérer un lot d'images avec callback de progression
  // ---------------------------------------------------------------------------

  /// Processes a list of [images] sequentially. Reports progress via the
  /// optional [onProgress] callback (currentIndex, totalCount).
  Future<ModerationResult> moderateAllImages(
    List<File> images, {
    Function(int current, int total)? onProgress,
  }) async {
    final List<File> resultFiles = [];
    int totalFaces = 0;
    int totalPlates = 0;
    bool anyModified = false;

    for (int i = 0; i < images.length; i++) {
      onProgress?.call(i + 1, images.length);

      try {
        // Detect independently so we can count them
        List<Rect> faces = [];
        List<Rect> plates = [];

        try {
          faces = await detectFaces(images[i]);
        } catch (e) {
          debugPrint('⚠️ ImageModeration[batch $i]: Face detection failed — $e');
        }

        try {
          plates = await detectLicensePlates(images[i]);
        } catch (e) {
          debugPrint('⚠️ ImageModeration[batch $i]: Plate detection failed — $e');
        }

        final allRegions = [...faces, ...plates];

        if (allRegions.isNotEmpty) {
          final moderated = await applyBlur(images[i], allRegions);
          resultFiles.add(moderated);
          totalFaces += faces.length;
          totalPlates += plates.length;
          anyModified = true;
        } else {
          resultFiles.add(images[i]); // keep original
        }
      } catch (e) {
        debugPrint('❌ ImageModeration[batch $i]: Error — $e');
        resultFiles.add(images[i]); // keep original on error
      }
    }

    debugPrint(
      '✅ ImageModeration batch complete: '
      '${images.length} images, $totalFaces faces, $totalPlates plates',
    );

    return ModerationResult(
      moderatedFiles: resultFiles,
      facesBlurred: totalFaces,
      platesBlurred: totalPlates,
      hadModifications: anyModified,
    );
  }

  // ---------------------------------------------------------------------------
  // FACE DETECTION — Google ML Kit
  // ---------------------------------------------------------------------------

  /// Uses Google ML Kit [FaceDetector] to locate faces in [imageFile].
  /// Returns a list of [Rect] bounding boxes in pixel coordinates.
  Future<List<Rect>> detectFaces(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableClassification: false,
        enableLandmarks: false,
        enableTracking: false,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.1, // detect small faces too
      ),
    );

    try {
      final faces = await faceDetector.processImage(inputImage);

      return faces.map((face) {
        final bb = face.boundingBox;
        // Add a small padding around the face for better coverage
        const padding = 10.0;
        return Rect.fromLTRB(
          max(0, bb.left - padding),
          max(0, bb.top - padding),
          bb.right + padding,
          bb.bottom + padding,
        );
      }).toList();
    } finally {
      // Always release the detector to free native resources
      await faceDetector.close();
    }
  }

  // ---------------------------------------------------------------------------
  // LICENSE PLATE DETECTION — Gemini Vision API
  // ---------------------------------------------------------------------------

  /// Uses Gemini Vision to locate license plates in [imageFile].
  /// Returns a list of [Rect] bounding boxes in pixel coordinates.
  Future<List<Rect>> detectLicensePlates(File imageFile) async {
    if (_apiKey.isEmpty) {
      debugPrint('⚠️ ImageModeration: GEMINI_API_KEY not set — skipping plate detection');
      return [];
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(temperature: 0.1),
    );

    final imageBytes = await imageFile.readAsBytes();

    // Decode image to get its dimensions for coordinate conversion
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) {
      debugPrint('⚠️ ImageModeration: Could not decode image for dimensions');
      return [];
    }
    final imageWidth = decodedImage.width.toDouble();
    final imageHeight = decodedImage.height.toDouble();

    const prompt = """
You are a license plate detection system. Analyze the image and locate ALL visible 
license plates (car plates, motorcycle plates, any vehicle registration plates).

If license plates are found, return ONLY a raw JSON array (no markdown, no backticks) 
with bounding box coordinates normalized to 0-1 relative to image dimensions:

[{"x": 0.1, "y": 0.8, "width": 0.15, "height": 0.05}]

Where:
- "x" = left edge of the plate as a fraction of image width (0 = left, 1 = right)
- "y" = top edge of the plate as a fraction of image height (0 = top, 1 = bottom)
- "width" = plate width as a fraction of image width
- "height" = plate height as a fraction of image height

If NO license plates are visible, return exactly: []

Return ONLY the JSON array, nothing else.
""";

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]),
    ];

    final response = await model.generateContent(content);

    if (response.text == null || response.text!.trim().isEmpty) {
      return [];
    }

    try {
      String cleanText = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Find the JSON array boundaries
      final startIndex = cleanText.indexOf('[');
      final endIndex = cleanText.lastIndexOf(']');

      if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
        return [];
      }

      cleanText = cleanText.substring(startIndex, endIndex + 1);
      final List<dynamic> parsed = jsonDecode(cleanText);

      if (parsed.isEmpty) return [];

      final List<Rect> rects = [];

      for (final item in parsed) {
        if (item is Map<String, dynamic>) {
          final double nx = (item['x'] as num?)?.toDouble() ?? 0;
          final double ny = (item['y'] as num?)?.toDouble() ?? 0;
          final double nw = (item['width'] as num?)?.toDouble() ?? 0;
          final double nh = (item['height'] as num?)?.toDouble() ?? 0;

          // Validate normalized coordinates are within 0-1 range
          if (nx < 0 || nx > 1 || ny < 0 || ny > 1 ||
              nw <= 0 || nw > 1 || nh <= 0 || nh > 1) {
            debugPrint('⚠️ ImageModeration: Skipping invalid plate bbox: $item');
            continue;
          }

          // Convert normalized → pixel coordinates with padding
          const padding = 5.0;
          rects.add(Rect.fromLTWH(
            max(0, (nx * imageWidth) - padding),
            max(0, (ny * imageHeight) - padding),
            min((nw * imageWidth) + (padding * 2), imageWidth),
            min((nh * imageHeight) + (padding * 2), imageHeight),
          ));
        }
      }

      return rects;
    } catch (e) {
      debugPrint('⚠️ ImageModeration: Failed to parse Gemini plate response — $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // BLUR APPLICATION — `image` package pixel manipulation
  // ---------------------------------------------------------------------------

  /// Reads [imageFile], applies a gaussian blur (radius 20) to each [regions],
  /// and saves the result to a temp directory with a '_moderated' suffix.
  Future<File> applyBlur(File imageFile, List<Rect> regions) async {
    final imageBytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(imageBytes);

    if (decoded == null) {
      debugPrint('⚠️ ImageModeration: Could not decode image for blur — returning original');
      return imageFile;
    }

    // Work on a mutable copy
    img.Image image = decoded;

    for (final region in regions) {
      image = _applyGaussianBlurToRegion(image, region, radius: 20);
    }

    // Save to temp directory
    final tempDir = await getTemporaryDirectory();
    final originalName = imageFile.uri.pathSegments.last;
    final extension = originalName.contains('.')
        ? originalName.substring(originalName.lastIndexOf('.'))
        : '.jpg';
    final baseName = originalName.contains('.')
        ? originalName.substring(0, originalName.lastIndexOf('.'))
        : originalName;
    final moderatedPath = '${tempDir.path}/${baseName}_moderated$extension';

    // Encode based on original format
    List<int> encodedBytes;
    if (extension.toLowerCase() == '.png') {
      encodedBytes = img.encodePng(image);
    } else {
      encodedBytes = img.encodeJpg(image, quality: 92);
    }

    final moderatedFile = File(moderatedPath);
    await moderatedFile.writeAsBytes(encodedBytes);

    debugPrint('✅ ImageModeration: Saved moderated image → $moderatedPath');
    return moderatedFile;
  }

  // ---------------------------------------------------------------------------
  // PRIVATE — Gaussian blur on a rectangular sub-region
  // ---------------------------------------------------------------------------

  /// Applies a box-blur approximation of gaussian blur to a rectangular region
  /// of [image]. The [radius] controls blur intensity. We apply 3 passes of
  /// box blur to approximate a true gaussian.
  img.Image _applyGaussianBlurToRegion(
    img.Image image,
    Rect region, {
    int radius = 20,
  }) {
    // Clamp region to image bounds
    final int x1 = max(0, region.left.toInt());
    final int y1 = max(0, region.top.toInt());
    final int x2 = min(image.width - 1, region.right.toInt());
    final int y2 = min(image.height - 1, region.bottom.toInt());

    if (x1 >= x2 || y1 >= y2) return image;

    final regionWidth = x2 - x1 + 1;
    final regionHeight = y2 - y1 + 1;

    // Extract the sub-region into a separate image
    final subImage = img.copyCrop(
      image,
      x: x1,
      y: y1,
      width: regionWidth,
      height: regionHeight,
    );

    // Apply gaussian blur using the image package's built-in filter
    final blurred = img.gaussianBlur(subImage, radius: radius);

    // Copy blurred pixels back into the original image
    for (int dy = 0; dy < regionHeight; dy++) {
      for (int dx = 0; dx < regionWidth; dx++) {
        final pixel = blurred.getPixel(dx, dy);
        image.setPixel(x1 + dx, y1 + dy, pixel);
      }
    }

    return image;
  }
}
