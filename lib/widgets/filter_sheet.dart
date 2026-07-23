import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/categories_data.dart';
import '../utils/app_translations.dart';
import '../main.dart'; // Pour languageNotifier

class FilterSheet extends StatefulWidget {
  final Function(Map<String, dynamic> filters) onApply;
  final Map<String, dynamic> initialFilters;

  const FilterSheet({
    super.key,
    required this.onApply,
    required this.initialFilters,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  final List<String> _wilayas = CategoriesData.europeanMarkets;

  late String _selectedCategory;
  String? _selectedWilaya;
  String? _selectedFuel;
  String? _selectedGearbox;
  String? _selectedBrand;

  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _minYearController;
  late TextEditingController _maxYearController;
  late TextEditingController _minKmController;
  late TextEditingController _maxKmController;

  int _sortIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialFilters['category'] ?? 'Tout';
    _selectedWilaya = widget.initialFilters['wilaya'];
    _selectedFuel = widget.initialFilters['fuel'];
    _selectedGearbox = widget.initialFilters['gearbox'];
    _selectedBrand = widget.initialFilters['brand'];

    _minPriceController = TextEditingController(text: widget.initialFilters['minPrice']?.toString() ?? '');
    _maxPriceController = TextEditingController(text: widget.initialFilters['maxPrice']?.toString() ?? '');
    _minYearController = TextEditingController(text: widget.initialFilters['minYear']?.toString() ?? '');
    _maxYearController = TextEditingController(text: widget.initialFilters['maxYear']?.toString() ?? '');
    _minKmController = TextEditingController(text: widget.initialFilters['minKm']?.toString() ?? '');
    _maxKmController = TextEditingController(text: widget.initialFilters['maxKm']?.toString() ?? '');
    
    _sortIndex = widget.initialFilters['sortIndex'] ?? 0;
  }

  String t(String key) => AppTranslations.get(languageNotifier.value, key);

  void _apply() {
    widget.onApply({
      'category': _selectedCategory,
      'wilaya': _selectedWilaya,
      'fuel': _selectedFuel,
      'gearbox': _selectedGearbox,
      'brand': _selectedBrand,
      'minPrice': double.tryParse(_minPriceController.text),
      'maxPrice': double.tryParse(_maxPriceController.text),
      'minYear': int.tryParse(_minYearController.text),
      'maxYear': int.tryParse(_maxYearController.text),
      'minKm': int.tryParse(_minKmController.text),
      'maxKm': int.tryParse(_maxKmController.text),
      'sortIndex': _sortIndex,
    });
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _selectedCategory = 'Tout';
      _selectedWilaya = null;
      _selectedFuel = null;
      _selectedGearbox = null;
      _selectedBrand = null;
      _minPriceController.clear();
      _maxPriceController.clear();
      _minYearController.clear();
      _maxYearController.clear();
      _minKmController.clear();
      _maxKmController.clear();
      _sortIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white, // Dark Blue background in Dark Mode
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Filtres & Tri", style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                TextButton(
                  onPressed: _reset,
                  child: Text("Réinitialiser", style: GoogleFonts.cairo(color: Colors.red)),
                )
              ],
            ),
          ),
          const Divider(),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionTitle("Trier par", isDark),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    _buildSortChip("Plus récent", 0, isDark),
                    _buildSortChip("Prix croissant", 1, isDark),
                    _buildSortChip("Prix décroissant", 2, isDark),
                  ],
                ),
                const SizedBox(height: 25),

                _buildSectionTitle("Région / département", isDark),
                DropdownButtonFormField<String>(
                  value: _selectedWilaya,
                  decoration: _inputDecoration("Région / département", isDark),
                  dropdownColor: isDark ? const Color(0xFF334155) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  items: [DropdownMenuItem(value: null, child: Text("Tout")), ..._wilayas.map((w) => DropdownMenuItem(value: w, child: Text(w)))],
                  onChanged: (v) => setState(() => _selectedWilaya = v),
                ),
                const SizedBox(height: 25),

                _buildSectionTitle("Catégorie", isDark),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: _inputDecoration("", isDark),
                  dropdownColor: isDark ? const Color(0xFF334155) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  items: [DropdownMenuItem(value: 'Tout', child: Text('Tout')), ...CategoriesData.subCategories.keys.map((c) => DropdownMenuItem(value: c, child: Text(c)))],
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
                const SizedBox(height: 25),
                
                 _buildSectionTitle("Marque", isDark),
                DropdownButtonFormField<String>(
                  value: _selectedBrand,
                  decoration: _inputDecoration("", isDark),
                  dropdownColor: isDark ? const Color(0xFF334155) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  items: [DropdownMenuItem(value: null, child: Text('Tout')), ...CategoriesData.carBrands.map((c) => DropdownMenuItem(value: c, child: Text(c)))],
                  onChanged: (v) => setState(() => _selectedBrand = v),
                ),
                const SizedBox(height: 25),

                _buildSectionTitle("Prix (EUR)", isDark),
                Row(children: [
                  Expanded(child: TextField(controller: _minPriceController, keyboardType: TextInputType.number, style: TextStyle(color: isDark ? Colors.white : Colors.black), decoration: _inputDecoration("Min", isDark))),
                  const SizedBox(width: 15),
                  Expanded(child: TextField(controller: _maxPriceController, keyboardType: TextInputType.number, style: TextStyle(color: isDark ? Colors.white : Colors.black), decoration: _inputDecoration("Max", isDark))),
                ]),
                const SizedBox(height: 25),

                // VEHICLE SPECIFIC
                _buildSectionTitle("Année", isDark),
                Row(children: [
                  Expanded(child: TextField(controller: _minYearController, keyboardType: TextInputType.number, style: TextStyle(color: isDark ? Colors.white : Colors.black), decoration: _inputDecoration("Min", isDark))),
                  const SizedBox(width: 15),
                  Expanded(child: TextField(controller: _maxYearController, keyboardType: TextInputType.number, style: TextStyle(color: isDark ? Colors.white : Colors.black), decoration: _inputDecoration("Max", isDark))),
                ]),
                const SizedBox(height: 25),

                _buildSectionTitle("Kilométrage", isDark),
                Row(children: [
                  Expanded(child: TextField(controller: _minKmController, keyboardType: TextInputType.number, style: TextStyle(color: isDark ? Colors.white : Colors.black), decoration: _inputDecoration("Min", isDark))),
                  const SizedBox(width: 15),
                  Expanded(child: TextField(controller: _maxKmController, keyboardType: TextInputType.number, style: TextStyle(color: isDark ? Colors.white : Colors.black), decoration: _inputDecoration("Max", isDark))),
                ]),
                const SizedBox(height: 25),

                _buildSectionTitle("Carburant", isDark),
                DropdownButtonFormField<String>(
                  value: _selectedFuel,
                  decoration: _inputDecoration("", isDark),
                  dropdownColor: isDark ? const Color(0xFF334155) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  items: [DropdownMenuItem(value: null, child: Text('Tout')), ...CategoriesData.fuelTypes.map((c) => DropdownMenuItem(value: c, child: Text(c)))],
                  onChanged: (v) => setState(() => _selectedFuel = v),
                ),
                const SizedBox(height: 25),

                 _buildSectionTitle("Boîte", isDark),
                DropdownButtonFormField<String>(
                  value: _selectedGearbox,
                  decoration: _inputDecoration("", isDark),
                  dropdownColor: isDark ? const Color(0xFF334155) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  items: [DropdownMenuItem(value: null, child: Text('Tout')), ...CategoriesData.gearboxes.map((c) => DropdownMenuItem(value: c, child: Text(c)))],
                  onChanged: (v) => setState(() => _selectedGearbox = v),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
                child: Text("Voir résultats", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)));
  }

  Widget _buildSortChip(String label, int index, bool isDark) {
    bool isSelected = _sortIndex == index;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.cairo(color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black))),
      selected: isSelected,
      onSelected: (bool selected) => setState(() => _sortIndex = index),
      selectedColor: const Color(0xFF0F172A),
      backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey.shade300)),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint, 
      hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
      filled: true, 
      fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

