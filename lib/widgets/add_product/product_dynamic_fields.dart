import 'package:flutter/material.dart';
import '../../utils/categories_data.dart';
// Pour languageNotifier si besoin, mais on passe isAr

class ProductDynamicFields extends StatefulWidget {
  final bool isAr;
  final String selectedCategory;
  
  // Controllers
  final TextEditingController yearController;
  final TextEditingController kmController;
  final TextEditingController surfaceController;
  final TextEditingController sizeController;
  final TextEditingController brandController;

  // State Values
  final String fuelType;
  final String immoType;
  final String? selectedSubType;
  final String? selectedGender;

  // Callbacks
  final Function(String?) onSubTypeChanged;
  final Function(String?) onGenderChanged;
  final Function(String?) onFuelChanged;
  final Function(String?) onImmoTypeChanged;

  const ProductDynamicFields({
    super.key,
    required this.isAr,
    required this.selectedCategory,
    required this.yearController,
    required this.kmController,
    required this.surfaceController,
    required this.sizeController,
    required this.brandController,
    required this.fuelType,
    required this.immoType,
    this.selectedSubType,
    this.selectedGender,
    required this.onSubTypeChanged,
    required this.onGenderChanged,
    required this.onFuelChanged,
    required this.onImmoTypeChanged,
  });

  @override
  State<ProductDynamicFields> createState() => _ProductDynamicFieldsState();
}

class _ProductDynamicFieldsState extends State<ProductDynamicFields> {

  // DICTIONNAIRES LOCAUX
  final Map<String, String> _fuelMap = {
    'Essence': 'بنزين', 'Diesel': 'مازوت', 'GPL': 'غاز (GPL)', 'Hybride': 'هجين', 'Électrique': 'كهربائي'
  };

  final Map<String, String> _immoMap = {
    'Vente': 'بيع', 'Location': 'كراء', 'Location Vacances': 'كراء للعطل', 'Échange': 'تبادل'
  };

  String _trDisplay(String val, Map<String, String> map) {
    if (!widget.isAr) return val;
    return map[val] ?? val;
  }

  Widget _buildTextField(TextEditingController ctrl, String label, {bool isNumber = false, int lines = 1, bool isOptional = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: lines,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (val) {
        if (isOptional) return null;
        return val!.isEmpty ? (widget.isAr ? "مطلوب" : "Requis") : null;
      },
    );
  }

  Widget _buildDropdown({required String? value, required String label, required List<String> items, required Map<String, String> map, required Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(_trDisplay(e, map), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    bool isAr = widget.isAr;

    // 1. SOUS-CATÉGORIE
    if (CategoriesData.subCategories.containsKey(widget.selectedCategory) && CategoriesData.subCategories[widget.selectedCategory]!.isNotEmpty) {
      children.add(_buildDropdown(
        value: widget.selectedSubType,
        label: isAr ? "النوع الفرعي" : "Sous-catégorie",
        items: CategoriesData.subCategories[widget.selectedCategory]!,
        map: CategoriesData.subCategoryTranslations,
        onChanged: widget.onSubTypeChanged,
      ));
      children.add(const SizedBox(height: 10));
    }

    // 2. VÉHICULES
    if (widget.selectedCategory == 'Véhicules') {
      children.addAll([
        Row(children: [
          Expanded(child: _buildTextField(widget.yearController, isAr ? "السنة (اختياري)" : "Année (Optionnel)", isNumber: true, isOptional: true)),
          const SizedBox(width: 10),
          Expanded(child: _buildTextField(widget.kmController, isAr ? "المسافة (كم) (اختياري)" : "Kilométrage (Optionnel)", isNumber: true, isOptional: true)),
        ]),
        const SizedBox(height: 10),
        _buildDropdown(
          value: widget.fuelType, 
          label: isAr ? "الوقود" : "Carburant", 
          items: _fuelMap.keys.toList(), 
          map: _fuelMap, 
          onChanged: widget.onFuelChanged
        ),
      ]);
    }
    
    // 3. IMMOBILIER
    else if (widget.selectedCategory == 'Immobilier') {
      children.addAll([
        _buildDropdown(
          value: widget.immoType, 
          label: isAr ? "نوع المعاملة" : "Type de transaction", 
          items: _immoMap.keys.toList(), 
          map: _immoMap, 
          onChanged: widget.onImmoTypeChanged
        ),
        const SizedBox(height: 10),
        _buildTextField(widget.surfaceController, isAr ? "المساحة (م²) (اختياري)" : "Surface (m²) (Optionnel)", isNumber: true, isOptional: true),
      ]);
    }
    
    // 4. MODE & VÊTEMENTS
    else if (widget.selectedCategory == 'Vêtements & Mode') {
      String sizeLabel = isAr ? "المقاس" : "Taille (S, M, L...)";
      if (widget.selectedSubType == 'Chaussures') {
        sizeLabel = isAr ? "مقاس الحذاء" : "Pointure (38, 40, 42...)";
      }
      
      children.addAll([
        _buildTextField(widget.sizeController, sizeLabel),
        const SizedBox(height: 10),
        _buildTextField(widget.brandController, isAr ? "العلامة التجارية" : "Marque"),
        const SizedBox(height: 10),
        _buildDropdown(
          value: widget.selectedGender,
          label: isAr ? "الجنس" : "Genre",
          items: ['Homme', 'Femme', 'Enfant', 'Unisexe'],
          map: {'Homme': 'رجل', 'Femme': 'امرأة', 'Enfant': 'طفل', 'Unisexe': 'للجنسين'},
          onChanged: widget.onGenderChanged
        ),
      ]);
    }
    
    // 5. TECH
    else if (['Téléphones & Tablettes', 'Informatique'].contains(widget.selectedCategory)) {
       children.add(_buildTextField(widget.brandController, isAr ? "العلامة التجارية" : "Marque"));
    }

    return Column(children: children);
  }
}
