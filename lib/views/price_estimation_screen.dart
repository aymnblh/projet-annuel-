import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/categories_data.dart';
import '../utils/app_translations.dart';
import '../main.dart';

class PriceEstimationScreen extends StatefulWidget {
  const PriceEstimationScreen({super.key});

  @override
  State<PriceEstimationScreen> createState() => _PriceEstimationScreenState();
}

class _PriceEstimationScreenState extends State<PriceEstimationScreen> {
  String? _selectedBrand;
  String? _selectedModel; // Pour simplifier, on fera un textfield ou dropdown statique
  String? _selectedYear;
  String? _selectedFuel;
  
  double? _estimatedMin;
  double? _estimatedMax;
  bool _calculating = false;

  final List<String> _years = List.generate(20, (index) => (2025 - index).toString());

  // Simulation de calcul
  void _calculatePrice() async {
    if (_selectedBrand == null || _selectedYear == null || _selectedFuel == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir tous les champs !")));
      return;
    }

    setState(() => _calculating = true);
    
    // 1. TENTATIVE : Données Réelles (Firestore)
    // On cherche des véhicules similaires (Même Marque, Même Modèle si précisé, +/- 1 an)
    double? realMarketAverage;
    int matchingCount = 0;

    try {
      // Note: Pour une vraie prod, il faudrait un index composite sur Firestore
      // Ici on fait une requête simple et on filtre côté client si besoin pour l'exemple
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('brand', isEqualTo: _selectedBrand)
          .where('fuel', isEqualTo: _selectedFuel)
          .get(); // On prend tout la marque/carburant et on affine

      int targetYear = int.parse(_selectedYear!);
      double total = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Filtre Année (+/- 1 an)
        int? docYear = int.tryParse(data['year']?.toString() ?? "0");
        if (docYear != null && (docYear >= targetYear - 1 && docYear <= targetYear + 1)) {
             // Filtre Modèle (si saisi) - contient le texte
             if (_selectedModel != null && _selectedModel!.isNotEmpty) {
               if (!(data['model']?.toString().toLowerCase().contains(_selectedModel!.toLowerCase()) ?? false)) {
                 continue; // Pas le bon modèle
               }
             }
             
             double price = (data['price'] as num).toDouble();
             if (price > 100000) { // Ignorer prix absurdes (ex: 1 EUR)
               total += price;
               matchingCount++;
             }
        }
      }

      if (matchingCount > 0) {
        realMarketAverage = total / matchingCount;
      }

    } catch (e) {
      debugPrint("Erreur Estim Firestore: $e");
    }

    // 2. LOGIQUE DU PRIX (Hybrid)
    double finalEstimation = 0;
    bool isTheoretical = false;

    if (realMarketAverage != null) {
      finalEstimation = realMarketAverage;
    } else {
      isTheoretical = true;
      // Fallback Heuristique (Approximatif pour le démarrage)
      double basePrice = 2500000; // 250M par défaut
      
      // Ajustement Marque
      if (_selectedBrand == 'Renault') basePrice = 1800000;
      if (_selectedBrand == 'Peugeot') basePrice = 1900000;
      if (_selectedBrand == 'Volkswagen') basePrice = 2800000;
      if (_selectedBrand == 'Mercedes-Benz') basePrice = 5000000;
      if (_selectedBrand == 'Audi') basePrice = 4500000;
      if (_selectedBrand == 'Dacia') basePrice = 1500000;
      if (_selectedBrand == 'Hyundai') basePrice = 1700000;
      if (_selectedBrand == 'Kia') basePrice = 1700000;
      if (_selectedBrand == 'Toyota') basePrice = 2200000;

      // Ajustement Année
      int year = int.parse(_selectedYear!);
      int currentYear = DateTime.now().year;
      int age = currentYear - year;
      basePrice -= (age * 120000); // Décote 12M/an

      // Ajustement Carburant
      if (_selectedFuel == 'Diesel') basePrice += 250000; // Diesel + cher
      if (_selectedFuel == 'Electrique') basePrice += 500000;

      finalEstimation = basePrice;
    }
    
    // Empêcher prix négatif
    if (finalEstimation < 500000) finalEstimation = 500000;

    if (mounted) {
      setState(() {
        // Fourchette +/- 5% si réel, +/- 10% si théorique
        double margin = isTheoretical ? 0.10 : 0.05;
        _estimatedMin = finalEstimation * (1 - margin);
        _estimatedMax = finalEstimation * (1 + margin);
        _calculating = false;
      });
      
      if (isTheoretical) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Estimation théorique (manque de données réelles)"), backgroundColor: Colors.orange));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Basé sur $matchingCount véhicule(s) similaire(s) !"), backgroundColor: Colors.green));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("La Côte Auto (Argus)")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(15)
              ),
              child: Column(
                children: [
                   const Icon(Icons.price_change, color: Colors.amber, size: 50),
                   const SizedBox(height: 10),
                   Text(
                     "Combien vaut votre voiture ?",
                     style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 5),
                   Text(
                     "Obtenez une estimation basée sur le marché actuel.",
                     textAlign: TextAlign.center,
                     style: const TextStyle(color: Colors.grey),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Form
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: "Marque", border: const OutlineInputBorder()),
              value: _selectedBrand,
              items: CategoriesData.carBrands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (v) => setState(() => _selectedBrand = v),
            ),
            const SizedBox(height: 15),
            
            // Model (Simplified as Text for now or we can use Autocomplete)
            TextFormField(
              decoration: InputDecoration(labelText: "Modèle (ex: Clio)", border: const OutlineInputBorder()),
              onChanged: (v) => _selectedModel = v,
            ),
            const SizedBox(height: 15),

            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: "Année", border: const OutlineInputBorder()),
                  value: _selectedYear,
                  items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                  onChanged: (v) => setState(() => _selectedYear = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: "Carburant", border: const OutlineInputBorder()),
                  value: _selectedFuel,
                  items: CategoriesData.fuelTypes.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setState(() => _selectedFuel = v),
                ),
              ),
            ]),
            
            const SizedBox(height: 30),
            
             SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _calculating ? null : _calculatePrice,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[800], foregroundColor: Colors.white),
                  child: _calculating 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text("ESTIMER LE PRIX", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 30),

              // RESULT
              if (_estimatedMin != null && _estimatedMax != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text("Estimation du Marché", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                        "${(_estimatedMin! / 10000).toStringAsFixed(0)} - ${(_estimatedMax! / 10000).toStringAsFixed(0)} Millions",
                        style: GoogleFonts.cairo(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green[800]),
                      ),
                      const SizedBox(height: 5),
                      Text("Le prix peut varier selon l'état, la région, le département et la ville.", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),

          ],
        ),
      ),
    );
  }
}

