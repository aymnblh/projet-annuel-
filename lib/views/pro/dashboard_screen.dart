import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/product.dart';
import '../../main.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    bool isAr = languageNotifier.value == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? "Ù„ÙˆØ­Ø© Ø§Ù„Ù‚ÙŠØ§Ø¯Ø©" : "Tableau de Bord", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('sellerId', isEqualTo: _uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(isAr ? "Ù„ÙŠØ³ Ù„Ø¯ÙŠÙƒ Ù…Ù†ØªØ¬Ø§Øª Ø¨Ø¹Ø¯" : "Aucun produit pour l'instant"));
          }

          final products = snapshot.data!.docs.map((d) => Product.fromFirestore(d)).toList();
          
          // CALCUL DES STATS
          int totalProducts = products.length;
          int totalViews = products.fold(0, (sum, p) => sum + p.viewCount);
          int totalSold = products.where((p) => p.isSold).length;
          double totalRevenue = products.where((p) => p.isSold).fold(0.0, (sum, p) => sum + p.price);
          


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. STAT CARDS
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: [
                    _buildStatCard(
                      icon: Icons.visibility, 
                      title: isAr ? "Ø§Ù„Ù…Ø´Ø§Ù‡Ø¯Ø§Øª" : "Vues Totales", 
                      value: "$totalViews", 
                      gradient: const LinearGradient(colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)])
                    ),
                    _buildStatCard(
                      icon: Icons.shopping_bag, 
                      title: isAr ? "Ø§Ù„Ù…Ø¨ÙŠØ¹Ø§Øª" : "Ventes", 
                      value: "$totalSold", 
                      gradient: const LinearGradient(colors: [Color(0xFF11998e), Color(0xFF38ef7d)])
                    ),
                    _buildStatCard(
                      icon: Icons.inventory, 
                      title: isAr ? "Ø§Ù„Ù…Ù†ØªØ¬Ø§Øª" : "Produits", 
                      value: "$totalProducts", 
                      gradient: const LinearGradient(colors: [Color(0xFFf12711), Color(0xFFf5af19)])
                    ),
                    _buildStatCard(
                      icon: Icons.attach_money, 
                      title: isAr ? "Ø§Ù„Ø£Ø±Ø¨Ø§Ø­" : "Revenus", 
                      value: "${totalRevenue.toStringAsFixed(0)} EUR", 
                      gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)])
                    ),
                  ],
                ),
                
                const SizedBox(height: 25),
                
                // 2. CHART (Simulation Views vs Sales)
                Text(isAr ? "ØªØ­Ù„ÙŠÙ„ Ø§Ù„Ø£Ø¯Ø§Ø¡" : "Performance", style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Container(
                  height: 220,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(20), 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) => Text("J-${val.toInt()}", style: const TextStyle(color: Colors.grey, fontSize: 10)))),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0, maxX: 6, minY: 0, maxY: 10,
                      lineBarsData: [
                         LineChartBarData(
                           spots: [
                             const FlSpot(0, 2), const FlSpot(1, 3.5), const FlSpot(2, 2.8), 
                             const FlSpot(3, 4.5), const FlSpot(4, 3.2), const FlSpot(5, 7), const FlSpot(6, 8.5),
                           ],
                           isCurved: true,
                           gradient: const LinearGradient(colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)]),
                           barWidth: 4,
                           isStrokeCapRound: true,
                           dotData: const FlDotData(show: false),
                           belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [const Color(0xFF2193b0).withOpacity(0.3), const Color(0xFF6dd5ed).withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                         )
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 25),
                

              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value, required Gradient gradient}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(title, style: GoogleFonts.cairo(fontSize: 12, color: Colors.white.withOpacity(0.8))),
            ],
          )
        ],
      ),
    );
  }
}

