import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/categories_data.dart';
import '../main.dart'; // Pour languageNotifier

class EditProductScreen extends StatefulWidget {
  final Product product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late String _selectedWilaya;
  String? _selectedCommune;

  final List<String> _categories = [
    'Tout', 'Véhicules', 'Immobilier', 'Téléphones & Tablettes', 'Informatique',
    'Électroménager', 'Vêtements & Mode', 'Montres & Bijoux', 'Beauté & Santé',
    'Bébé & Enfant', 'Maison & Déco', 'Bricolage & Jardin', 'Sport & Loisirs',
    'Jeux Vidéo & Consoles', 'Livres & Culture', 'Animaux', 'Emploi & Services', 'Autre'
  ];

  final List<String> _wilayas = CategoriesData.europeanMarkets;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product.title);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _descriptionController = TextEditingController(text: widget.product.description);
    
    _selectedCategory = _categories.contains(widget.product.category) ? widget.product.category : 'Autre';
    _selectedWilaya = _wilayas.contains(widget.product.wilaya) ? widget.product.wilaya : _wilayas.first;
    _selectedCommune = widget.product.commune;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Fermer le clavier
    FocusScope.of(context).unfocus();

    // Map des données Ã  mettre Ã  jour
    Map<String, dynamic> updateData = {
      'title': _titleController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'description': _descriptionController.text.trim(),
      'category': _selectedCategory,
      'wilaya': _selectedWilaya,
      'commune': _selectedCommune ?? "",
      'updatedAt': DateTime.now(), // Firestore le convertira si on passe par le provider, sinon FieldValue.serverTimestamp()
    };

    try {
      await context.read<ProductProvider>().updateProduct(widget.product.id, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Annonce mise Ã  jour avec succès !"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Retour
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: ${e.toString()}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = languageNotifier.value == 'ar';
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isAr ? "ØªØ¹Ø¯ÙŠÙ„ Ø§Ù„Ø¥Ø¹Ù„Ø§Ù†" : "Modifier l'annonce", 
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IMAGE PREVIEW (Non modifiable ici pour simplifier, ou Ã  ajouter plus tard)
                  if (widget.product.imageUrls.isNotEmpty)
                    Container(
                      height: 150,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: NetworkImage(widget.product.imageUrls.first),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  _buildSectionTitle("Informations Principales"),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    label: "Titre de l'annonce", 
                    controller: _titleController,
                    icon: Icons.title,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    label: "Prix (EUR)", 
                    controller: _priceController,
                    isNumber: true,
                    icon: Icons.attach_money,
                    suffix: "EUR",
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle("Détails"),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: _inputDecoration("Catégorie", Icons.category),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.cairo()))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedWilaya,
                    decoration: _inputDecoration("Région / département", Icons.location_on),
                    items: _wilayas.map((w) => DropdownMenuItem(value: w, child: Text(w, style: GoogleFonts.cairo()))).toList(),
                    onChanged: (val) => setState(() => _selectedWilaya = val!),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle("Description"),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    label: "Description détaillée...", 
                    controller: _descriptionController,
                    maxLines: 6,
                    icon: Icons.description,
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: productProvider.isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: productProvider.isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "ENREGISTRER",
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Overlay si chargement (pour bloquer les clics)
          if (productProvider.isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey[500],
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {String? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
      suffixText: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5)),
      labelStyle: GoogleFonts.cairo(color: Colors.grey[600]),
    );
  }

  Widget _buildTextField({
    required String label, 
    required TextEditingController controller, 
    IconData? icon, 
    bool isNumber = false, 
    int maxLines = 1,
    String? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: GoogleFonts.cairo(color: const Color(0xFF0F172A)),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Ce champ est requis';
        if (isNumber) {
          if (double.tryParse(val) == null) return 'Prix invalide';
          if (double.parse(val) <= 0) return 'Le prix doit être positif';
        }
        return null;
      },
      decoration: _inputDecoration(label, icon ?? Icons.edit, suffix: suffix).copyWith(
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}

