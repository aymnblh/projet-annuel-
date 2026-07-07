import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; 
import '../services/auth_service.dart';
import '../utils/app_translations.dart';
import '../main.dart'; 

class AuthScreen extends StatefulWidget {
  final bool fromProfile; 
  const AuthScreen({super.key, this.fromProfile = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs de texte
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); 
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLogin = true; 
  bool _isLoading = false;
  bool _obscurePassword = true;

  String t(String key) => AppTranslations.get(languageNotifier.value, key);

  // --- 1. CONNEXION / INSCRIPTION EMAIL ---
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    String? error; 

    if (_isLogin) {
      error = await _authService.signIn(
        email: _emailController.text.trim(), 
        password: _passwordController.text.trim()
      );
    } else {
      error = await _authService.signUp(
        email: _emailController.text.trim(), 
        password: _passwordController.text.trim()
      );
      if (error == null && _nameController.text.isNotEmpty) {
         final user = _authService.currentUser;
         if (user != null) { 
           await user.updateDisplayName(_nameController.text.trim()); 
           await user.reload(); 
         }
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        _showError(error);
      } else if (widget.fromProfile) {
        Navigator.pop(context); 
      }
    }
  }

  // --- 2. CONNEXION GOOGLE ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final user = await _authService.signInWithGoogle();
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (user != null && widget.fromProfile) {
        Navigator.pop(context);
      }
    }
  }

  // --- 3. CONNEXION TÉLÉPHONE ---
  void _startPhoneAuth() {
    _phoneController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(t('phone_btn')),
        content: TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: t('phone_hint'),
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t('cancel'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); 
              if (_phoneController.text.isNotEmpty) {
                _verifyPhoneNumber(_phoneController.text.trim());
              }
            },
            child: Text(t('send_sms')),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPhoneNumber(String phone) async {
    setState(() => _isLoading = true);
    await _authService.verifyPhoneNumber(
      phoneNumber: phone,
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showOtpDialog(verificationId);
        }
      },
      onVerificationFailed: (errorMsg) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError(errorMsg);
        }
      },
      onAutoVerifySuccess: () {
        if (mounted) {
          setState(() => _isLoading = false);
          if (widget.fromProfile) Navigator.pop(context);
        }
      },
    );
  }

  void _showOtpDialog(String verifId) {
    _otpController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(t('verify')),
        content: TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(letterSpacing: 8, fontSize: 20),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t('cancel'))),
          ElevatedButton(
            onPressed: () async {
              String? error = await _authService.signInWithOTP(
                verificationId: verifId, 
                smsCode: _otpController.text.trim()
              );

              if (mounted) {
                if (error == null) {
                  Navigator.pop(context);
                  if (widget.fromProfile) Navigator.pop(context);
                } else {
                  _showError("Code invalide");
                }
              }
            },
            child: Text(t('verify')),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, maxLines: 10), 
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 10),
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('login_title'))),
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Color(0xFF0F172A), shape: BoxShape.circle),
                child: const Icon(Icons.touch_app_rounded, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(child: _toggleBtn(t('login_btn'), true)),
                        Expanded(child: _toggleBtn(t('signup_btn'), false)),
                      ]),
                      const SizedBox(height: 20),

                      if (!_isLogin)
                        TextFormField(controller: _nameController, decoration: InputDecoration(labelText: t('name_label'), prefixIcon: const Icon(Icons.person))),
                      
                      const SizedBox(height: 10),
                      TextFormField(controller: _emailController, decoration: InputDecoration(labelText: t('email_label'), prefixIcon: const Icon(Icons.email))),
                      const SizedBox(height: 10),
                      TextFormField(controller: _passwordController, obscureText: _obscurePassword, decoration: InputDecoration(labelText: t('pass_label'), prefixIcon: const Icon(Icons.lock), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)))),
                      
                      const SizedBox(height: 20),
                      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isLogin ? t('login_btn') : t('signup_btn')))),
                      
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),
                      
                      OutlinedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: const Icon(FontAwesomeIcons.google, size: 24, color: Colors.red), 
                        label: Text(t('google_btn'), style: const TextStyle(color: Colors.black)),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _startPhoneAuth,
                        icon: const Icon(Icons.phone, color: Colors.black),
                        label: Text(t('phone_btn'), style: const TextStyle(color: Colors.black)),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleBtn(String text, bool isLogin) {
    bool selected = _isLogin == isLogin;
    return GestureDetector(
      onTap: () => setState(() => _isLogin = isLogin),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: selected ? const Color(0xFFF1F5F9) : Colors.white, borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? Colors.black : Colors.grey)),
      ),
    );
  }
}