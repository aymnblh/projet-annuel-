import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../utils/categories_data.dart';
import 'home_screen.dart'; 

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  
  String _phone = "";
  
  // Données JSON
  List<dynamic> _wilayaList = [];
  List<dynamic> _communeList = [];
  List<dynamic> _filteredCommunes = [];

  // Sélections
  int? _selectedWilayaId;
  String? _selectedWilayaName;
  String? _selectedCommuneName;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    setState(() {
      _wilayaList = CategoriesData.europeanMarkets
          .map((country) => {'nom_fr': country})
          .toList();
      _communeList = CategoriesData.europeanCitiesByCountry.entries
          .expand(
            (entry) => entry.value.map(
              (city) => {
                'country': entry.key,
                'nom_fr': city,
              },
            ),
          )
          .toList();
    });
  }

  void _onWilayaChanged(int? wilayaId) {
    if (wilayaId == null) return;
    setState(() {
      _selectedWilayaId = wilayaId;
      _selectedCommuneName = null;
      _selectedWilayaName = _wilayaList[wilayaId - 1]['nom_fr'];
      _filteredCommunes = _communeList.where((c) => c['country'] == _selectedWilayaName).toList();
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && _selectedWilayaId != null) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        await _authService.completeProfile(
          phone: _phone,
          wilaya: _selectedWilayaName!,
          commune: _selectedCommuneName ?? "",
        );

        if (mounted) {
          // Redirection vers l'accueil en effaçant l'historique de nav
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
        }
      }
    } else if (_selectedWilayaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez selectionner un pays")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Finaliser l'inscription", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                "Bienvenue ! 👋",
                style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Pour faciliter vos achats et ventes, nous avons besoin de votre localisation et contact.",
                style: GoogleFonts.cairo(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              // Champ Téléphone
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Numéro de téléphone",
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: "05 50 12 34 56"
                ),
                keyboardType: TextInputType.phone,
                validator: (val) => (val == null || val.length < 9) ? "Numéro invalide" : null,
                onSaved: (val) => _phone = val!,
              ),
              const SizedBox(height: 20),

              // Pays
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: "Pays", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                initialValue: _selectedWilayaId,
                items: _wilayaList.asMap().entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key + 1, // ID commence Ã  1
                    child: Text(entry.value['nom_fr']),
                  );
                }).toList(),
                onChanged: _onWilayaChanged,
              ),
              const SizedBox(height: 20),

              // Ville (optionnel ou obligatoire selon votre choix, ici activé si wilaya ok)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: "Ville (optionnel)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                initialValue: _selectedCommuneName,
                items: _filteredCommunes.map((c) {
                  return DropdownMenuItem<String>(
                    value: c['nom_fr'],
                    child: Text(c['nom_fr']),
                  );
                }).toList(),
                onChanged: _selectedWilayaId == null ? null : (val) => setState(() => _selectedCommuneName = val),
              ),

              const SizedBox(height: 40),

              // Bouton Valider
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("TERMINER", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

