import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../utils/firebase_test.dart';
import 'admin/pending_reviews_screen.dart';
import 'admin/flagged_reviews_screen.dart';
// pour languageNotifier

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this); // UPDATED to 7 (added reviews)
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- ADMIN ---

  // 1. Supprimer n'importe quel produit
  Future<void> _forceDeleteProduct(String productId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ADMIN: Supprimer ?"),
        content: const Text("Vous allez supprimer cette annonce définitivement."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("SUPPRIMER", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('products').doc(productId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produit supprimé par l'Admin.")));
    }
  }

  // 2. Bannir / Débannir un utilisateur
  Future<void> _toggleUserBan(String userId, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isBanned': !currentStatus
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(currentStatus ? "Utilisateur débanni" : "Utilisateur BANNI ðŸš«")));
  }

  // 3. Valider une annonce
  Future<void> _approveProduct(String productId) async {
    await FirebaseFirestore.instance.collection('products').doc(productId).update({
      'isApproved': true
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Annonce validée ! âœ…"), backgroundColor: Colors.green));
  }

  // --- ONGLET 4 : À VALIDER ---
  Widget _buildToValidate() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').where('isApproved', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) return const Center(child: Text("Aucune annonce en attente", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final p = Product.fromFirestore(docs[index]);
            return Card(
              margin: const EdgeInsets.all(10),
              // REMOVED: color: Colors.orange.shade50
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.orange.withOpacity(0.5), width: 1), // Add border to indicate status
              ),
              child: Column(
                children: [
                   ListTile(
                    leading: Image.network(p.imageUrls.isNotEmpty ? p.imageUrls[0] : '', width: 50, height: 50, fit: BoxFit.cover),
                    title: Text(p.title),
                    subtitle: Text("${p.price} EUR • ${p.wilaya}"),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  ButtonBar(
                    alignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text("REFUSER", style: TextStyle(color: Colors.red)),
                        onPressed: () => _forceDeleteProduct(p.id),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text("VALIDER"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () => _approveProduct(p.id),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- ONGLET : SPONSORING REQUESTS ---
  Widget _buildSponsorships() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sponsorship_requests').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) return const Center(child: Text("Aucune demande de sponsoring", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final reqId = docs[index].id;
            final status = data['status'] ?? 'pending';
            final platforms = (data['platforms'] as List<dynamic>?)?.join(', ') ?? 'Meta';
            final budget = data['budget'] ?? 0;
            final duration = data['durationDays'] ?? 0;

            Color statusColor = Colors.orange;
            if (status == 'active') statusColor = Colors.green;
            if (status == 'completed') statusColor = Colors.blue;
            if (status == 'rejected') statusColor = Colors.red;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              // REMOVED card color to use Theme default
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(Icons.campaign, color: statusColor),
                ),
                title: Text("Sponsoring Meta ($platforms)"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Budget: ${budget} EUR pour $duration jours"),
                    Text("Status: $status", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (val) {
                    FirebaseFirestore.instance.collection('sponsorship_requests').doc(reqId).update({'status': val});
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'pending', child: Text("En attente")),
                    const PopupMenuItem(value: 'active', child: Text("Actif (Lancé)")),
                    const PopupMenuItem(value: 'completed', child: Text("Terminé")),
                    const PopupMenuItem(value: 'rejected', child: Text("Refusé")),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Panel Administrateur", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.red[900], 
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: "Stats"),
            Tab(icon: Icon(Icons.new_releases), text: "À Valider"),
            Tab(icon: Icon(Icons.campaign), text: "Sponsoring"), // ADDED
            Tab(icon: Icon(Icons.shopping_bag), text: "Annonces"),
            Tab(icon: Icon(Icons.people), text: "Utilisateurs"),
            Tab(icon: Icon(Icons.rate_review), text: "Reviews"), // NEW
            Tab(icon: Icon(Icons.flag), text: "Signalés"), // NEW
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboard(),
          _buildToValidate(),
          _buildSponsorships(), // ADDED
          _buildAllProducts(),
          _buildAllUsers(),
          const PendingReviewsScreen(), // NEW
          const FlaggedReviewsScreen(), // NEW
        ],
      ),
    );
  }

  // --- ONGLET 1 : EURSHBOARD ---
  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          _buildStatCard("Utilisateurs", FirebaseFirestore.instance.collection('users'), Icons.people, Colors.blue),
          const SizedBox(height: 20),
          _buildStatCard("Annonces", FirebaseFirestore.instance.collection('products'), Icons.shopping_cart, Colors.green),
          const SizedBox(height: 20),
          _buildStatCard("Messages échangés", FirebaseFirestore.instance.collection('chats'), Icons.chat, Colors.orange),
          const SizedBox(height: 30),
          // Firebase Test Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FirebaseTestScreen()),
                );
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Test Firebase Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, CollectionReference col, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.2), radius: 30, child: Icon(icon, color: color, size: 30)),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey)),
                StreamBuilder<QuerySnapshot>(
                  stream: col.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Text("...");
                    return Text("${snapshot.data!.docs.length}", style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- ONGLET 2 : TOUS LES PRODUITS ---
  Widget _buildAllProducts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final p = Product.fromFirestore(docs[index]);
            return ListTile(
              leading: Image.network(p.imageUrls.isNotEmpty ? p.imageUrls[0] : '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,o,s)=>const Icon(Icons.image)),
              title: Text(p.title, maxLines: 1),
              subtitle: Text("${p.price} EUR - ${p.wilaya}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed: () => _forceDeleteProduct(p.id),
              ),
            );
          },
        );
      },
    );
  }

  // --- ONGLET 3 : UTILISATEURS ---
  Widget _buildAllUsers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final userId = docs[index].id;
            final isBanned = data['isBanned'] ?? false;
            final email = data['email'] ?? "Pas d'email";
            final name = data['name'] ?? "Inconnu";

            return Card(
              // REMOVED: color: isBanned ? Colors.red.shade50 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isBanned ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isBanned ? Colors.red : Colors.blue,
                  child: Icon(isBanned ? Icons.block : Icons.person, color: Colors.white),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(email),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: isBanned ? Colors.green : Colors.red),
                  onPressed: () => _toggleUserBan(userId, isBanned),
                  child: Text(isBanned ? "Débannir" : "Bannir", style: const TextStyle(color: Colors.white)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
