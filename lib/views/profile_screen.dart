import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // AJOUT
import '../models/product.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart'; // AJOUT
import '../utils/app_translations.dart';
import '../main.dart';
import 'auth_screen.dart';
import 'product_card.dart';
import 'edit_profile_screen.dart';
import 'boost_ad_screen.dart';
import 'pro/create_store_screen.dart'; // AJOUT
import 'pro/dashboard_screen.dart'; 
import 'pro/verification_request_screen.dart'; // AJOUT
import '../providers/theme_provider.dart'; // AJOUT
import 'admin/admin_verification_screen.dart'; // ADMIN IMPORT

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  User? user;

  // <--- AJOUT : LISTE DES ADMINS
  // Remplacez par votre vrai email connectÃ© (Google ou Email/Password)
  final List<String> _admins = [
    'aymenboulahia63@gmail.com', 
    'admin@soukdzair.com'
  ];

  String t(String key) => AppTranslations.get(languageNotifier.value, key);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((u) {
      if (mounted) setState(() => user = u);
    });
  }

  String _getInitials() {
    if (user?.displayName == null || user!.displayName!.trim().isEmpty) return "U";
    try { return user!.displayName!.trim()[0].toUpperCase(); } catch (e) { return "U"; }
  }

  // --- ACTIONS PROPRIÃ‰TAIRE ---
  
  // 1. Marquer comme Vendu
  Future<void> _markAsSold(String productId, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('products').doc(productId).update({
      'isSold': !currentStatus // On inverse l'Ã©tat
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(currentStatus ? "Annonce remise en vente" : "FÃ©licitations pour la vente ! ðŸŽ‰")));
  }

  // 2. Supprimer l'annonce
  Future<void> _deleteProduct(String productId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer ?"),
        content: const Text("Cette action est irrÃ©versible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('products').doc(productId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Annonce supprimÃ©e.")));
    }
  }

  // --- VUES ---

  Widget _buildGuestView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(t('welcome_guest'), style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(t('guest_desc'), textAlign: TextAlign.center, style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(fromProfile: true))),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            child: Text(t('login_btn')),
          ),
          const SizedBox(height: 40),
          _buildLanguageSwitcher(),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitcher() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.language, color: Colors.grey),
        const SizedBox(width: 10),
        DropdownButton<String>(
          value: languageNotifier.value,
          underline: Container(),
          items: const [DropdownMenuItem(value: 'fr', child: Text("FranÃ§ais ðŸ‡«ðŸ‡·")), DropdownMenuItem(value: 'ar', child: Text("Ø§Ù„Ø¹Ø±Ø¨ÙŠØ© ðŸ‡©ðŸ‡¿"))],
          onChanged: (val) { if (val != null) setState(() => languageNotifier.value = val); },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return Scaffold(body: _buildGuestView());
    bool isAr = languageNotifier.value == 'ar';
    final userProvider = Provider.of<UserProvider>(context);

    // <--- AJOUT : VÃ©rification si l'utilisateur est Admin
    bool isAdmin = user!.email != null && _admins.contains(user!.email);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Utilisation du thÃ¨me
      appBar: AppBar(
        title: Text(t('profile'), style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () => _authService.signOut())],
      ),
      body: Column(
        children: [
          // Header & Options
          Container(
             color: Theme.of(context).cardColor, // THÃˆME
             padding: const EdgeInsets.all(20),
             child: Column(
               children: [
                 // ... (Header User Info restÃ© le mÃªme) ...
                 Row(
                  children: [
                    CircleAvatar(radius: 30, backgroundColor: Theme.of(context).primaryColor, child: Text(_getInitials(), style: const TextStyle(color: Colors.white, fontSize: 24))),
                    const SizedBox(width: 15),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(
                        children: [
                          Text(user!.displayName ?? "Utilisateur", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                          if (userProvider.isVerified) ...[const SizedBox(width: 5), const Icon(Icons.verified, color: Colors.blue, size: 20)],
                        ],
                      ),
                      Text(user!.email ?? user!.phoneNumber ?? "", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
                      if (!userProvider.isVerified && userProvider.verificationStatus != 'pending')
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationRequestScreen())),
                          child: const Text("Obtenir le badge vÃ©rifiÃ© ðŸ›¡ï¸", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                        )
                      else if (userProvider.verificationStatus == 'pending')
                        const Text("VÃ©rification en cours... â³", style: TextStyle(color: Colors.orange, fontSize: 12)),
                    ])),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                    ),
                    const SizedBox(width: 5),
                    _buildLanguageSwitcher(),
                  ],
                ),
                 
                 const SizedBox(height: 20),
                 
                 // SWITCH THEME SOMBRE
                 Consumer<ThemeProvider>(
                   builder: (context, themeProvider, _) {
                     return SwitchListTile(
                       title: Text(isAr ? "Ø§Ù„ÙˆØ¶Ø¹ Ø§Ù„Ù„ÙŠÙ„ÙŠ" : "Mode Sombre", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                       secondary: Icon(Icons.dark_mode, color: themeProvider.isDarkMode ? Colors.amber : Colors.grey),
                       value: themeProvider.isDarkMode,
                       onChanged: (val) => themeProvider.toggleTheme(val),
                       activeThumbColor: Colors.amber,
                       contentPadding: EdgeInsets.zero,
                     );
                   }
                 ),

                 // ... (Suite de la banniÃ¨re Pro) ...

                // BANNIÃˆRE PRO
                if (userProvider.isPro) 
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF334155)]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.blueAccent, size: 30),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userProvider.userData?['storeName'] ?? "Showroom", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const Text("Compte Showroom Actif", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else 
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateStoreScreen())),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront, color: Colors.white, size: 30),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isAr ? "Ø£Ù†Ø´Ø¦ Ù…Ø¹Ø±Ø¶Ùƒ Ø§Ù„Ø¢Ù†" : "Ouvrir un Showroom", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(isAr ? "ÙƒÙ† Ø¨Ø§Ø¦Ø¹Ù‹Ø§ Ù…Ø­ØªØ±ÙÙ‹Ø§ ÙˆØ²Ø¯ Ù…Ø¨ÙŠØ¹Ø§ØªÙƒ" : "CrÃ©ez votre vitrine digitale professionnelle", style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                
                // <--- AJOUT : BOUTON ADMIN (VISIBLE SEULEMENT SI ADMIN)
                if (userProvider.isAdmin) // Use getter
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminVerificationScreen())),
                        icon: const Icon(Icons.security, color: Colors.white),
                        label: const Text("PANEL ADMIN Verif", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900], foregroundColor: Colors.white),
                      ),
                    ),
                  )
              ],
            ),
          ),
          
          Container(
            color: Theme.of(context).cardColor, // UTILISATION DU THEME (plus de blanc forcÃ©)
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SizedBox(
               width: double.infinity,
               child: OutlinedButton.icon(
                 onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardScreen())), 
                 // Force visible colors regarding theme
                 icon: Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary), 
                 label: Text(
                   isAr ? "Ù„ÙˆØ­Ø© Ø§Ù„ØªØ­Ù„ÙŠÙ„Ø§Øª" : "Voir mon Dashboard", 
                   style: TextStyle(
                     fontWeight: FontWeight.bold,
                     color: Theme.of(context).colorScheme.primary // Adapts to theme
                   )
                 ),
                 style: OutlinedButton.styleFrom(
                   side: BorderSide(color: Theme.of(context).colorScheme.primary),
                 ),
               ),
            ),
          ),
          
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor, 
              indicatorColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              tabs: [Tab(text: t('my_ads')), Tab(text: t('favorites'))],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. MES ANNONCES (Avec gestion)
                _buildMyAdsList(),
                // 2. FAVORIS
                _buildFavoritesList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Liste spÃ©ciale pour "Mes Annonces" avec boutons de gestion
  Widget _buildMyAdsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').where('sellerId', isEqualTo: user!.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text(t('no_products')));
        final products = snapshot.data!.docs.map((d) => Product.fromFirestore(d)).toList();
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            bool isAr = languageNotifier.value == 'ar';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  // On rÃ©utilise pas ProductCard ici car on veut un design "Gestion"
                  ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(p.imageUrls.isNotEmpty ? p.imageUrls[0] : '', width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c,o,s) => const Icon(Icons.image)),
                    ),
                    title: Text(p.title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    subtitle: Text("${p.price.toStringAsFixed(0)} EUR â€¢ ${p.isSold ? (isAr ? 'Ù…Ø¨Ø§Ø¹' : 'Vendu') : (isAr ? 'Ù†Ø´Ø·' : 'Actif')}", 
                      style: TextStyle(color: p.isSold ? Colors.red : Colors.green)),
                  ),
                  const Divider(height: 1),
                  Row(
                    children: [
                      // BOUTON VENDU
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _markAsSold(p.id, p.isSold),
                          icon: Icon(p.isSold ? Icons.refresh : Icons.check_circle, color: p.isSold ? Colors.orange : Colors.green, size: 20),
                          label: Text(
                            p.isSold ? (isAr ? "Ø¥Ø¹Ø§Ø¯Ø©" : "Relancer") : (isAr ? "Ø¨ÙŠØ¹Øª" : "Vendu"), 
                            style: GoogleFonts.cairo(color: p.isSold ? Colors.orange : Colors.green, fontSize: 13)
                          ),
                        ),
                      ),
                      Container(width: 1, height: 30, color: Colors.grey[200]),
                      
                      // BOUTON BOOST ðŸš€
                      Expanded(
                        child: TextButton.icon(
                          onPressed: (p.isBoosted && p.boostExpiresAt != null && p.boostExpiresAt!.isAfter(DateTime.now()))
                            ? null // DÃ©jÃ  boostÃ©
                            : () => Navigator.push(context, MaterialPageRoute(builder: (_) => BoostAdScreen(productId: p.id, productName: p.title, category: p.category, currentPrice: p.price))),
                          icon: Icon(Icons.rocket_launch, color: (p.isBoosted && p.boostExpiresAt != null && p.boostExpiresAt!.isAfter(DateTime.now())) ? Colors.purple : Colors.blue, size: 20),
                          label: Text(
                            (p.isBoosted && p.boostExpiresAt != null && p.boostExpiresAt!.isAfter(DateTime.now())) ? (isAr ? "Ù…Ø±ÙˆØ¬" : "BoostÃ©") : (isAr ? "ØªØ±ÙˆÙŠØ¬" : "Booster"), 
                            style: GoogleFonts.cairo(color: (p.isBoosted && p.boostExpiresAt != null && p.boostExpiresAt!.isAfter(DateTime.now())) ? Colors.purple : Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)
                          ),
                        ),

                      ),

                      Container(width: 1, height: 30, color: Colors.grey[200]),
                      
                      // BOUTON SUPPRIMER
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _deleteProduct(p.id),
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          label: Text(isAr ? "Ø­Ø°Ù" : "Suppr.", style: GoogleFonts.cairo(color: Colors.red, fontSize: 13)),
                        ),
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

  Widget _buildFavoritesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('favorites').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text(t('no_products')));
        List<String> favIds = snapshot.data!.docs.map((d) => d.id).toList();
        if (favIds.isEmpty) return Center(child: Text(t('no_products')));

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').where(FieldPath.documentId, whereIn: favIds).snapshots(),
          builder: (context, snapProd) {
            if (!snapProd.hasData) return const Center(child: CircularProgressIndicator());
            final products = snapProd.data!.docs.map((d) => Product.fromFirestore(d)).toList();
            if (products.isEmpty) return Center(child: Text(t('no_products')));

            return GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, mainAxisSpacing: 10, crossAxisSpacing: 10),
              itemCount: products.length,
              itemBuilder: (context, index) => ProductCard(product: products[index]),
            );
          },
        );
      },
    );
  }
}
