import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/user_provider.dart';
import '../../services/payment_service.dart';
import '../../main.dart'; // Pour languageNotifier, etc.

class CreateStoreScreen extends StatefulWidget {
  const CreateStoreScreen({super.key});

  @override
  State<CreateStoreScreen> createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends State<CreateStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  
  File? _logoFile;
  bool _isLoading = false;
  bool _isLocating = false;
  GeoPoint? _storeLocation;

  final ImagePicker _picker = ImagePicker();

  // Pick Logo
  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _logoFile = File(image.path));
  }

  // Geolocate
  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _storeLocation = GeoPoint(position.latitude, position.longitude);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ðŸ“ Position du Showroom enregistrée !"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur GPS: $e")));
    } finally {
      setState(() => _isLocating = false);
    }
  }

  // Submit
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_logoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez ajouter un logo")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Paiement (Simulation)
      // On simule une carte pour l'API
      await PaymentService().processPayment(
          amount: 5000, // Prix plus élevé pour un showroom automobile
          method: 'cib', 
          cardNumber: '1111222233334444', 
          expiryDate: '12/26', 
          cvv: '123'
      );

      // 2. Upload Logo
      String fileName = "logo_${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = FirebaseStorage.instance.ref().child('logos/$fileName');
      await ref.putFile(_logoFile!);
      String logoUrl = await ref.getDownloadURL();

      // 3. Update User
      final storeData = {
        'storeName': _nameController.text.trim(),
        'storeDescription': _descController.text.trim(),
        'storeAddress': _addressController.text.trim(),
        'storeLocation': _storeLocation, // Peut être null si pas cliqué
        'logoUrl': logoUrl,
        'storeCreatedAt': FieldValue.serverTimestamp(),
      };

      await Provider.of<UserProvider>(context, listen: false).upgradeToPro(storeData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Félicitations ! Votre Showroom est actif ! 🎉"), backgroundColor: Colors.green));
        Navigator.pop(context); // Retour au profil
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Créer mon Showroom")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // LOGO UPLOAD
              GestureDetector(
                onTap: _pickLogo,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _logoFile != null ? FileImage(_logoFile!) : null,
                  child: _logoFile == null ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey) : null,
                ),
              ),
              const SizedBox(height: 10),
              Text("Logo du Showroom", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Nom du Showroom",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.store),
                ),
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Description (Marques, Spécialité...)",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                ),
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: "Adresse physique",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.map), 
                ),
              ),
              const SizedBox(height: 10),

              // BOUTON LOCALISATION
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLocating ? null : _detectLocation,
                  icon: _isLocating 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : Icon(Icons.my_location, color: _storeLocation != null ? Colors.green : Colors.blue),
                  label: Text(
                    _storeLocation != null 
                        ? ("Position du Showroom enregistrée âœ“") 
                        : ("Localiser le Showroom sur Google Maps"),
                  ),
                ),
              ),
              if (_storeLocation != null)
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Text("Les clients pourront vous trouver via GPS.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),

              const SizedBox(height: 40),

              // PRIX ET VALIDATION
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.shade200)),
                child: Column(
                  children: [
                    Text("Abonnement Showroom", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    const Text("5000 EUR", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(height: 10),
                    const Text("Status Showroom • Visibilité Max • Gestion Pro", textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text("PAYER ET ACTIVER", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

