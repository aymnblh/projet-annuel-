import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/user_provider.dart';

class VerificationRequestScreen extends StatefulWidget {
  const VerificationRequestScreen({super.key});

  @override
  State<VerificationRequestScreen> createState() => _VerificationRequestScreenState();
}

class _VerificationRequestScreenState extends State<VerificationRequestScreen> {
  XFile? _idFile;
  XFile? _selfieFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isId) async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (photo != null) {
      setState(() {
        if (isId) {
          _idFile = photo;
        } else {
          _selfieFile = photo;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Image sélectionnée !")));
    }
  }

  Future<String?> _uploadFile(XFile file, String name) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      
      final ref = FirebaseStorage.instance.ref().child('verification_docs').child(user.uid).child(name);
      await ref.putFile(File(file.path));
      return await ref.getDownloadURL();
    } catch (e) {
      print("Erreur upload: $e");
      return null;
    }
  }

  void _submit() async {
    if (_idFile == null || _selfieFile == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez uploader les deux documents.")));
       return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Upload Images
      final idUrl = await _uploadFile(_idFile!, 'id_card.jpg');
      final selfieUrl = await _uploadFile(_selfieFile!, 'selfie.jpg');

      if (idUrl == null || selfieUrl == null) {
        throw Exception("Échec de l'envoi des images.");
      }

      // 2. Update Firestore
      await Provider.of<UserProvider>(context, listen: false).requestVerification(idUrl, selfieUrl);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Demande envoyée ! Examen en cours... ⏳")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Vérification d'identité", style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.verified_user, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              "Obtenez le Badge Bleu 🛡️",
              style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Confirmez votre identité pour rassurer vos clients et augmenter vos ventes. Ce processus est sécurisé.",
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            
            _buildUploadButton("Photo CI / Permis", Icons.credit_card, _idFile != null, () => _pickImage(true)),
            const SizedBox(height: 20),
            _buildUploadButton("Selfie avec la pièce", Icons.face, _selfieFile != null, () => _pickImage(false)),
            
            const SizedBox(height: 50),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16)
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text("ENVOYER LA DEMANDE", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(String label, IconData icon, bool isUploaded, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: isUploaded ? Colors.green : Colors.grey.shade600, width: 2), // Visibility fix
          borderRadius: BorderRadius.circular(12),
          color: isUploaded ? Colors.green.withOpacity(0.1) : Theme.of(context).cardColor, // Theme aware
        ),
        child: Row(
          children: [
            Icon(isUploaded ? Icons.check_circle : icon, color: isUploaded ? Colors.green : Theme.of(context).iconTheme.color, size: 30), // Icon color fix
            const SizedBox(width: 20),
            Expanded(child: Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16))),
            if (!isUploaded) Icon(Icons.upload_file, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
