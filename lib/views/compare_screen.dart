import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../utils/app_translations.dart';
import '../main.dart';

class CompareScreen extends StatelessWidget {
  final List<Product> products;

  const CompareScreen({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    bool isAr = languageNotifier.value == 'ar';
    
    // Safety check
    if (products.isEmpty) return const Scaffold(body: Center(child: Text("Aucun vÃ©hicule Ã  comparer")));

    return Scaffold(
      appBar: AppBar(title: Text(isAr ? "Ù…Ù‚Ø§Ø±Ù†Ø© Ø§Ù„Ù…Ø±ÙƒØ¨Ø§Øª" : "Comparateur")),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            horizontalMargin: 10,
            headingRowHeight: 180, // Height for images
            dataRowMinHeight: 50,
            columns: [
              // Colonne des Ã©tiquettes (vide en header)
              const DataColumn(label: SizedBox(width: 80, child: Text(""))), // Label column
              ...products.map((p) => DataColumn(
                label: SizedBox(
                  width: 140,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: p.imageUrls.isNotEmpty ? p.imageUrls[0] : '',
                          height: 100,
                          width: 140,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.car_crash)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text("${p.price.toStringAsFixed(0)} EUR", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ))
            ],
            rows: [
              _buildRow(isAr ? "Ø§Ù„Ù…Ø§Ø±ÙƒØ©" : "Marque", (p) => p.brand ?? "-"),
              _buildRow(isAr ? "Ø§Ù„Ù…ÙˆØ¯ÙŠÙ„" : "ModÃ¨le", (p) => p.model ?? "-"),
              _buildRow(isAr ? "Ø§Ù„Ø³Ù†Ø©" : "AnnÃ©e", (p) => p.year ?? "-"),
              _buildRow(isAr ? "Ø§Ù„Ø¹Ø¯Ø§Ø¯" : "Km", (p) => "${p.km ?? '-'} km"),
              _buildRow(isAr ? "Ø§Ù„Ø·Ø§Ù‚Ø©" : "Carburant", (p) => p.fuel ?? "-"),
              _buildRow(isAr ? "Ø§Ù„Ø¹Ù„Ø¨Ø©" : "BoÃ®te", (p) => p.gearbox ?? "-"),
              _buildRow(isAr ? "Ø§Ù„Ù…Ø­Ø±Ùƒ" : "Moteur", (p) => p.engine ?? "-"),
              _buildRow(isAr ? "Ø§Ù„Ù„ÙˆÙ†" : "Couleur", (p) => p.color ?? "-"),
              _buildRow(isAr ? "Ø§Ù„ÙˆØ«Ø§Ø¦Ù‚" : "Papiers", (p) => p.papers ?? "-"),

              _buildRow(isAr ? "Ø§Ù„ØªØ¨Ø§Ø¯Ù„" : "Echange", (p) => p.exchange ? "Oui / Ù†Ø¹Ù…" : "Non / Ù„Ø§"),
              _buildRow(isAr ? "Ø§Ù„ÙˆÙ„Ø§ÙŠØ©" : "Région / département", (p) => p.wilaya),
              // _buildRow(isAr ? "Ø§Ù„Ù‡Ø§ØªÙ" : "Tel", (p) => p.phone ?? "-"),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(String label, String Function(Product) extractor) {
    return DataRow(
      cells: [
        DataCell(Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
        ...products.map((p) => DataCell(
          Container(
            width: 140,
            alignment: Alignment.center, // Center content
            child: Text(extractor(p), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          )
        ))
      ],
    );
  }
}

