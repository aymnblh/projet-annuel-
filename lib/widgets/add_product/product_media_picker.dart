import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:flutter/services.dart';
import '../../services/safety_service.dart';
import '../../services/image_service.dart';
import '../../services/video_compression_service.dart';
import '../video_compression_dialog.dart';

class ProductMediaPicker extends StatefulWidget {
  final bool isAr;
  final Function(List<XFile>) onImagesChanged;
  final Function(List<XFile>) onVideosChanged;
  final Function(XFile) onRequestAnalysis; // Callback pour l'IA
  final bool isAnalyzing;

  const ProductMediaPicker({
    super.key,
    required this.isAr,
    required this.onImagesChanged,
    required this.onVideosChanged,
    required this.onRequestAnalysis,
    this.isAnalyzing = false,
  });

  @override
  State<ProductMediaPicker> createState() => _ProductMediaPickerState();
}

class _ProductMediaPickerState extends State<ProductMediaPicker> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];
  final List<XFile> _videos = [];
  bool _isRemovingBg = false;

  // --- ACTIONS ---
  Future<void> _pickFromGallery() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    
    if (pickedFiles.isEmpty) return;
    
    // Show compression dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Optimisation des images...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      // Safety Check & Compression
      final List<XFile> processedFiles = [];
      double totalOriginalSize = 0;
      double totalCompressedSize = 0;
      
      for (var file in pickedFiles) {
        // Safety check first
        bool isSafe = await SafetyService.analyzeImageSafety(file);
        if (!isSafe) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Une image a été bloquée (Contenu inapproprié) 🛡️"),
                backgroundColor: Colors.red,
              ),
            );
          }
          continue;
        }
        
        // Compress image
        final originalFile = File(file.path);
        final originalSize = await ImageService.getFileSizeMB(originalFile);
        totalOriginalSize += originalSize;
        
        final compressed = await ImageService.compressImage(originalFile);
        if (compressed != null) {
          final compressedSize = await ImageService.getFileSizeMB(compressed);
          totalCompressedSize += compressedSize;
          processedFiles.add(XFile(compressed.path));
        } else {
          // If compression fails, use original
          processedFiles.add(file);
          totalCompressedSize += originalSize;
        }
      }
      
      if (mounted) Navigator.pop(context); // Close loading dialog
      
      if (processedFiles.isNotEmpty) {
        setState(() => _images.addAll(processedFiles));
        widget.onImagesChanged(_images);
        
        // Show success message with stats
        if (mounted && totalOriginalSize > 0) {
          final saved = ((totalOriginalSize - totalCompressedSize) / totalOriginalSize * 100).toInt();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✨ Images optimisées ! Économie: $saved% (${totalOriginalSize.toStringAsFixed(1)}MB → ${totalCompressedSize.toStringAsFixed(1)}MB)',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _takePhotoWithCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;
    
    // Show compression dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Optimisation...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      // Safety check
      bool isSafe = await SafetyService.analyzeImageSafety(photo);
      if (!isSafe) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Photo bloquée (Contenu inapproprié) 🛡️"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Compress
      final originalFile = File(photo.path);
      final compressed = await ImageService.compressImage(originalFile);
      
      if (mounted) Navigator.pop(context);
      
      if (compressed != null) {
        setState(() => _images.add(XFile(compressed.path)));
        widget.onImagesChanged(_images);
        
        // Show compression stats
        if (mounted) {
          final ratio = await ImageService.getCompressionRatio(originalFile, compressed);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✨ Photo optimisée ! Économie: $ratio%'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Use original if compression fails
        setState(() => _images.add(photo));
        widget.onImagesChanged(_images);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    
    // Check if video needs compression
    final videoFile = File(video.path);
    final compressionService = VideoCompressionService();
    final needsCompression = await compressionService.needsCompression(videoFile);
    
    if (needsCompression && mounted) {
      // Show compression dialog
      final compressedFile = await showVideoCompressionDialog(
        context: context,
        videoFile: videoFile,
        onCancel: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Compression annulée'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
      );
      
      if (compressedFile != null) {
        setState(() => _videos.add(XFile(compressedFile.path)));
        widget.onVideosChanged(_videos);
        
        // Show success message
        if (mounted) {
          final stats = await compressionService.getCompressionStats(
            originalFile: videoFile,
            compressedFile: compressedFile,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✨ Vidéo compressée ! ${stats.originalSizeFormatted} → '
                '${stats.compressedSizeFormatted} (-${stats.reductionPercentage.toStringAsFixed(0)}%)',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      // Video is small enough, use as-is
      setState(() => _videos.add(video));
      widget.onVideosChanged(_videos);
      
      if (mounted && !needsCompression) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Vidéo ajoutée (compression non nécessaire)'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // --- BACKGROUND REMOVAL ---
  Future<void> _removeBackground(XFile image) async {
    setState(() => _isRemovingBg = true);
    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final segmenter = SubjectSegmenter(options: SubjectSegmenterOptions(
        enableForegroundBitmap: true,
        enableForegroundConfidenceMask: false,
        enableMultipleSubjects: SubjectResultOptions(
          enableConfidenceMask: false,
          enableSubjectBitmap: false,
        ),
      ));

      final result = await segmenter.processImage(inputImage);
      Uint8List? pngBytes = result.foregroundBitmap;

      if (pngBytes != null) {
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/bg_removed_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(pngBytes);

        setState(() {
          int idx = _images.indexOf(image);
          if (idx != -1) {
            _images[idx] = XFile(file.path);
          }
        });
        widget.onImagesChanged(_images);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Arrière-plan supprimé ! ✨"), backgroundColor: Colors.blue));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible de traiter l'image.")));
      }
      segmenter.close();
    } catch (e) {
      print("Erreur BG Remove: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur technique lors du détourage."), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isRemovingBg = false);
    }
  }

  void _showImageSourceSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(widget.isAr ? 'التقاط صورة' : 'Prendre une photo', style: GoogleFonts.cairo()),
                onTap: () { Navigator.of(context).pop(); _takePhotoWithCamera(); },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: Text(widget.isAr ? 'إضافة فيديو' : 'Ajouter une vidéo', style: GoogleFonts.cairo()),
                onTap: () { Navigator.of(context).pop(); _pickVideo(); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(widget.isAr ? 'اختيار صور من المعرض' : 'Choisir photos depuis galerie', style: GoogleFonts.cairo()),
                onTap: () { Navigator.of(context).pop(); _pickFromGallery(); },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // BOUTON AJOUT
              GestureDetector(
                onTap: () => _showImageSourceSelection(context),
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                  child: const Icon(Icons.add_a_photo, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 10),

              // LISTE IMAGES
              ..._images.map((img) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Stack(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(img.path), width: 100, height: 100, fit: BoxFit.cover)),
                    // DELETE BTN
                    Positioned(top: 0, right: 0, child: GestureDetector(
                      onTap: () {
                        setState(() => _images.remove(img));
                        widget.onImagesChanged(_images);
                      },
                      child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white))
                    )),
                    // MAGIC WAND BTN
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: () => _removeBackground(img),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.only(topLeft: Radius.circular(8))),
                          child: _isRemovingBg 
                            ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                            : const Icon(Icons.auto_fix_high, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              )),

              // LISTE VIDEOS
              ..._videos.map((vid) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Stack(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                      child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40)),
                    ),
                    Positioned(top: 0, right: 0, child: GestureDetector(
                      onTap: () {
                        setState(() => _videos.remove(vid));
                        widget.onVideosChanged(_videos);
                      },
                      child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white))
                    )),
                  ],
                ),
              )),
            ],
          ),
        ),

        // BOUTON IA
        if (_images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.isAnalyzing ? null : () => widget.onRequestAnalysis(_images.first),
                icon: widget.isAnalyzing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(widget.isAr ? "ملء تلقائي بالذكاء الاصطناعي" : "Remplir avec l'IA", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
