import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/payment_service.dart';
import '../services/ai_service.dart'; // AJOUT
import 'package:firebase_auth/firebase_auth.dart'; // AJOUT
import '../main.dart'; // Pour languageNotifier

class BoostAdScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final double currentPrice; // AJOUT
  final String category; // AJOUT

  const BoostAdScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.currentPrice,
    required this.category,
  });

  @override
  State<BoostAdScreen> createState() => _BoostAdScreenState();
}

class _BoostAdScreenState extends State<BoostAdScreen> {
  final PaymentService _paymentService = PaymentService();
  final AIService _aiService = AIService(); // AJOUT
  final _formKey = GlobalKey<FormState>();

  String? _aiAdvice;
  bool _loadingAdvice = true;

  @override
  void initState() {
    super.initState();
    _fetchAIAdvice();
  }

  Future<void> _fetchAIAdvice() async {
    // Simulation d'un petit dÃ©lai pour l'effet "AI Thinking"
    await Future.delayed(const Duration(milliseconds: 500));
    final advice = await _aiService.suggestOptimalPrice(
      productTitle: widget.productName, 
      currentPrice: widget.currentPrice, 
      category: widget.category
    );
    if (mounted) {
      setState(() {
        _aiAdvice = advice;
        _loadingAdvice = false;
      });
    }
  }

  String _promoType = 'boost'; // 'boost', 'urgent', 'meta'
  int _selectedDuration = 1; 
  double _price = 200.0;
  List<String> _selectedPlatforms = ['facebook']; // ['facebook', 'instagram']

  String _selectedMethod = 'edahabia';
  
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isLoading = false;

  void _updatePrice() {
    setState(() {
      if (_promoType == 'urgent') {
        _price = 100.0; // Prix fixe Urgent
      } else if (_promoType == 'meta') {
        // META ADS BUDGETS
        if (_selectedDuration == 3) _price = 3000.0; // 3 Jours
        else if (_selectedDuration == 7) _price = 6000.0; // 7 Jours
        else if (_selectedDuration == 15) _price = 12000.0; // 15 Jours
        else _price = 3000.0; // Default
      } else {
        // Boost Interne
        if (_selectedDuration == 1) {
          _price = 200.0;
        } else if (_selectedDuration == 3) _price = 500.0;
        else if (_selectedDuration == 7) _price = 1000.0;
      }
    });
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Process Paiement
      await _paymentService.processPayment(
        amount: _price,
        method: _selectedMethod,
        cardNumber: _cardNumberController.text.trim(),
        expiryDate: _expiryController.text.trim(),
        cvv: _cvvController.text.trim(),
      );

      // 2. Appliquer Promotion
      // 2. Appliquer Promotion / Sponsoring
      if (_promoType == 'urgent') {
        await _paymentService.makeUrgent(productId: widget.productId);
      } else if (_promoType == 'meta') {
        await _paymentService.requestMetaSponsorship(
          productId: widget.productId, 
          uid: FirebaseAuth.instance.currentUser!.uid,
          budget: _price, 
          durationdays: _selectedDuration, 
          platforms: _selectedPlatforms
        );
      } else {
        await _paymentService.boostProduct(productId: widget.productId, days: _selectedDuration);
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Paiement RÃ©ussi ! ðŸŽ‰"),
            content: Text(_promoType == 'urgent' ? "Le badge URGENT a Ã©tÃ© ajoutÃ©." : (_promoType == 'meta' ? "Votre demande de sponsoring est envoyÃ©e !" : "Votre annonce est boostÃ©e !")),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); 
                  Navigator.pop(context); 
                },
                child: const Text("GÃ©nial !"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = languageNotifier.value == 'ar';
    
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? "ØªØ±ÙˆÙŠØ¬ Ø§Ù„Ø¥Ø¹Ù„Ø§Ù†" : "Promouvoir l'annonce")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- AI ADVICE CARD ---
              if (_loadingAdvice)
                 const Padding(padding: EdgeInsets.only(bottom: 20), child: Center(child: LinearProgressIndicator(color: Colors.purple)))
              else if (_aiAdvice != null)
                 Container(
                   margin: const EdgeInsets.only(bottom: 25),
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
                     borderRadius: BorderRadius.circular(16),
                     boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                   ),
                   child: Row(
                     children: [
                       const Icon(Icons.auto_awesome, color: Colors.amber, size: 30),
                       const SizedBox(width: 15),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text("Conseil IA OneClick ðŸ§ ", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                             const SizedBox(height: 5),
                             Text(_aiAdvice!, style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                           ],
                         ),
                       )
                     ],
                   ),
                 ),

              // CHOIX DU TYPE DE PROMO

              const SizedBox(height: 15),
              // META OPTION
              GestureDetector(
                onTap: () { setState(() { _promoType = 'meta'; _selectedDuration = 3; _updatePrice(); }); },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: _promoType == 'meta' ? Colors.blue[900]!.withOpacity(0.1) : Colors.white,
                    border: Border.all(color: _promoType == 'meta' ? Colors.blue[900]! : Colors.grey[300]!, width: 2),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.public, color: Colors.blue[900], size: 30),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isAr ? "Ø¥Ø¹Ù„Ø§Ù† Ù…Ù…ÙˆÙ„ (ÙÙŠØ³Ø¨ÙˆÙƒ/Ø£Ù†Ø³ØªØºØ±Ø§Ù…)" : "SponsorisÃ© sur Meta", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(isAr ? "Ø§Ù„ÙˆØµÙˆÙ„ Ø¥Ù„Ù‰ Ø¢Ù„Ø§Ù Ø§Ù„Ø£Ø´Ø®Ø§Øµ" : "Touchez des milliers de personnes", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // DURATION SELECTION (Seulement pour Boost)
              if (_promoType == 'boost') ...[
                Text(isAr ? "Ù…Ø¯Ø© Ø§Ù„ØªØ±ÙˆÙŠØ¬" : "DurÃ©e du boost", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _durationCard(1, "200 EUR", isAr ? "ÙŠÙˆÙ…" : "1 Jour"),
                    _durationCard(3, "500 EUR", isAr ? "3 Ø£ÙŠØ§Ù…" : "3 Jours"),
                    _durationCard(7, "1000 EUR", isAr ? "Ø£Ø³Ø¨ÙˆØ¹" : "7 Jours"),
                  ],
                ),
                const SizedBox(height: 30),
              ] else if (_promoType == 'meta') ...[
                 Text(isAr ? "Ø§Ù„Ù…Ù†ØµØ§Øª" : "Plateformes", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
                 const SizedBox(height: 10),
                 Row(
                   children: [
                     FilterChip(
                       label: const Text("Facebook"),
                       selected: _selectedPlatforms.contains('facebook'),
                       onSelected: (val) => setState(() {
                         if(val) _selectedPlatforms.add('facebook'); else _selectedPlatforms.remove('facebook');
                       }),
                     ),
                     const SizedBox(width: 10),
                     FilterChip(
                       label: const Text("Instagram"),
                       selected: _selectedPlatforms.contains('instagram'),
                       onSelected: (val) => setState(() {
                         if(val) _selectedPlatforms.add('instagram'); else _selectedPlatforms.remove('instagram');
                       }),
                     ),
                   ],
                 ),
                 const SizedBox(height: 20),
                 Text(isAr ? "Ø§Ù„Ù…ÙŠØ²Ø§Ù†ÙŠØ© Ø§Ù„Ø¥Ø¬Ù…Ø§Ù„ÙŠØ© (Ø´Ø§Ù…Ù„ Ø§Ù„Ø±Ø³ÙˆÙ…)" : "Budget Total (Frais inclus)", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
                 const SizedBox(height: 15),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     _durationCard(3, "3000 EUR", isAr ? "3 Ø£ÙŠØ§Ù…" : "3 Jours"),
                     _durationCard(7, "6000 EUR", isAr ? "7 Ø£ÙŠØ§Ù…" : "7 Jours"),
                     _durationCard(15, "12000 EUR", isAr ? "15 ÙŠÙˆÙ…" : "15 Jours"),
                   ],
                 ),
                 const SizedBox(height: 15),
                 Text(
                   isAr ? "Ù‡Ø°Ø§ Ø§Ù„Ù…Ø¨Ù„Øº ÙŠØºØ·ÙŠ ØªÙƒØ§Ù„ÙŠÙ Ø¥Ø¹Ù„Ø§Ù†Ø§Øª Ù…ÙŠØªØ§ ÙˆØ±Ø³ÙˆÙ… Ø§Ù„Ø®Ø¯Ù…Ø©." : "Ce montant couvre les frais publicitaires Meta et nos frais de gestion.",
                   style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                 ),
                 const SizedBox(height: 30),
              ] else ...[
                 Container(
                   width: double.infinity,
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10)),
                   child: Row(children: [
                     const Icon(Icons.info_outline, color: Colors.red),
                     const SizedBox(width: 10),
                     Expanded(child: Text("Le badge URGENT est permanent jusqu'Ã  la vente.", style: GoogleFonts.cairo(color: Colors.red[800])))
                   ]),
                 ),
                 const SizedBox(height: 30),
              ],

              // PAYMENT METHOD
              Text(isAr ? "Ø·Ø±ÙŠÙ‚Ø© Ø§Ù„Ø¯ÙØ¹" : "Moyen de paiement", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _methodCard('edahabia', "Edahabia", Colors.orange)),
                  const SizedBox(width: 10),
                  Expanded(child: _methodCard('cib', "CIB", Colors.blue)),
                ],
              ),
              const SizedBox(height: 30),

              // CARD DETAILS
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? "Ø±Ù‚Ù… Ø§Ù„Ø¨Ø·Ø§Ù‚Ø©" : "NumÃ©ro de la carte",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.credit_card),
                ),
                validator: (v) => (v == null || v.length < 16) ? "Invalide" : null,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        labelText: "MM/YY",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      validator: (v) => v!.isEmpty ? "Requis" : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "CVV",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      validator: (v) => v!.length < 3 ? "Invalide" : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              
              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "${isAr ? "Ø¯ÙØ¹ " : "Payer "}${_price.toStringAsFixed(0)} EUR", 
                        style: GoogleFonts.cairo(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text("ðŸ”’ ${isAr ? "Ø¯ÙØ¹ Ø¢Ù…Ù† 100%" : "Paiement 100% SÃ©curisÃ©"}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _durationCard(int days, String price, String label) {
    bool selected = _selectedDuration == days;
    return GestureDetector(
      onTap: () { setState(() => _selectedDuration = days); _updatePrice(); },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? Colors.blue[50] : Colors.white,
          border: Border.all(color: selected ? Colors.blue : Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: selected ? Colors.blue : Colors.black)),
            const SizedBox(height: 5),
            Text(price, style: TextStyle(color: selected ? Colors.blue[800] : Colors.grey[600], fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _methodCard(String id, String label, Color color) {
    bool selected = _selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(color: selected ? color : Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card, color: selected ? color : Colors.grey),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: selected ? color : Colors.black)),
          ],
        ),
      ),
    );
  }
}

