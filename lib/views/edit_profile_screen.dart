import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/categories_data.dart';
import '../main.dart'; // Pour languageNotifier

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _coverController; // PRO
  late TextEditingController _whatsappController; // PRO
  
  String? _selectedWilaya;
  List<dynamic> _wilayaList = [];

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadWilayas();
  }

  Future<void> _loadWilayas() async {
    setState(() {
      _wilayaList = CategoriesData.europeanMarkets
          .map((country) => {'nom_fr': country})
          .toList();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final userProvider = Provider.of<UserProvider>(context);
      final data = userProvider.userData;
      
      _nameController = TextEditingController(text: data?['name'] ?? data?['username'] ?? '');
      _phoneController = TextEditingController(text: data?['phone'] ?? '');
      _coverController = TextEditingController(text: data?['coverImageUrl'] ?? '');
      _whatsappController = TextEditingController(text: data?['whatsapp'] ?? '');
      
      // On essaie de trouver la wilaya actuelle
      if (data?['wilaya'] != null) {
        _selectedWilaya = data!['wilaya'];
      }
      
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _coverController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    try {
      await userProvider.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        wilaya: _selectedWilaya,
        coverImageUrl: _coverController.text.trim().isNotEmpty ? _coverController.text.trim() : null,
        whatsapp: _whatsappController.text.trim().isNotEmpty ? _whatsappController.text.trim() : null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil mis à jour ! ✅"), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = languageNotifier.value == 'ar';
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isAr ? "تعديل الملف الشخصي" : "Modifier le profil",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // PHOTO (Statique pour l'instant)
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF0F172A),
                      child: Text(
                        _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : "U",
                        style: const TextStyle(fontSize: 40, color: Colors.white),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.blue,
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          onPressed: () {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Modification photo bientôt disponible !")));
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // NOM
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: isAr ? "الاسم" : "Nom d'utilisateur",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (val) => val!.isEmpty ? (isAr ? "مطلوب" : "Requis") : null,
              ),
              const SizedBox(height: 20),

              // PHONE
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: isAr ? "رقم الهاتف" : "Téléphone",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 20),

              // WILAYA
              DropdownButtonFormField<String>(
                initialValue: _selectedWilaya,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: isAr ? "الدولة" : "Pays",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.map),
                ),
                items: _wilayaList.map((w) {
                  return DropdownMenuItem<String>(
                    value: w['nom_fr'],
                    child: Text(isAr ? (w['nom_ar'] ?? w['nom_fr']) : w['nom_fr']),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedWilaya = val),
              ),

              // --- PRO FIELDS ---
              if (userProvider.isPro) ...[
                const SizedBox(height: 30),
                const Divider(),
                Text("Personnalisation Boutique (PRO)", style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber[800])),
                const SizedBox(height: 15),
                 TextFormField(
                  controller: _coverController,
                  decoration: InputDecoration(
                    labelText: "URL Image de Couverture",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.image),
                    hintText: "https://exemple.com/image.jpg"
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Numéro WhatsApp (avec indicatif)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.chat),
                    hintText: "213550..."
                  ),
                ),
              ],
              
              const SizedBox(height: 40),

              // BOUTON SAVE
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: userProvider.isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: userProvider.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isAr ? "حفظ التغييرات" : "Enregistrer", style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
