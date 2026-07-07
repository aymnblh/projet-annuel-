import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StockManager extends StatefulWidget {
  final bool isAr;
  final bool hasVariants;
  final Function(bool) onHasVariantsChanged;
  
  final TextEditingController simpleStockController;
  final List<Map<String, dynamic>> variants;
  final Function(List<Map<String, dynamic>>) onVariantsChanged;

  const StockManager({
    super.key,
    required this.isAr,
    required this.hasVariants,
    required this.onHasVariantsChanged,
    required this.simpleStockController,
    required this.variants,
    required this.onVariantsChanged,
  });

  @override
  State<StockManager> createState() => _StockManagerState();
}

class _StockManagerState extends State<StockManager> {
  // Controllers internes pour l'ajout
  final _variantNameController = TextEditingController();
  final _variantQtyController = TextEditingController();

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

  void _addVariant() {
    if (_variantNameController.text.isNotEmpty && _variantQtyController.text.isNotEmpty) {
      List<Map<String, dynamic>> updatedList = List.from(widget.variants);
      updatedList.add({
        'name': _variantNameController.text.trim(),
        'qty': int.tryParse(_variantQtyController.text) ?? 0
      });
      
      widget.onVariantsChanged(updatedList);
      
      _variantNameController.clear();
      _variantQtyController.clear();
      setState(() {}); // Refresh local UI for text fields if needed
    }
  }

  void _removeVariant(Map<String, dynamic> v) {
    List<Map<String, dynamic>> updatedList = List.from(widget.variants);
    updatedList.remove(v);
    widget.onVariantsChanged(updatedList);
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = widget.isAr;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.2))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isAr ? "إدارة المخزون" : "Gestion de Stock", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.orange[800])),
              Switch(
                value: widget.hasVariants, 
                onChanged: widget.onHasVariantsChanged,
                activeThumbColor: Colors.orange,
              )
            ],
          ),
          Text(
            widget.hasVariants 
              ? (isAr ? "هذا المنتج لديه خيارات (مقاسات، ألوان...)" : "Ce produit a des variantes (Tailles, Couleurs...)")
              : (isAr ? "منتج بسيط (بدون خيارات)" : "Produit simple (Pas de variantes)"),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),

          if (!widget.hasVariants)
            _buildTextField(widget.simpleStockController, isAr ? "الكمية المتوفرة" : "Quantité disponible", isNumber: true),

          if (widget.hasVariants) ...[
            Row(
              children: [
                Expanded(flex: 2, child: _buildTextField(_variantNameController, isAr ? "اسم الخيار (مثال: أحمر، XL)" : "Variante (ex: XL, Rouge)")),
                const SizedBox(width: 10),
                Expanded(flex: 1, child: _buildTextField(_variantQtyController, isAr ? "الكمية" : "Qté", isNumber: true)),
                IconButton(
                  onPressed: _addVariant,
                  icon: const Icon(Icons.add_circle, color: Colors.orange, size: 30),
                )
              ],
            ),
            const SizedBox(height: 10),
            if (widget.variants.isEmpty)
              Text(isAr ? "لا توجد خيارات مضافة" : "Aucune variante ajoutée", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            
            ...widget.variants.map((v) => Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.grey.shade300)),
              child: Row(
                children: [
                  Expanded(child: Text("${v['name']}  (Qté: ${v['qty']})", style: const TextStyle(fontWeight: FontWeight.bold))),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _removeVariant(v),
                  )
                ],
              ),
            )),
          ]
        ],
      ),
    );
  }
}
