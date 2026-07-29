import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // N'oubliez pas cet import !
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/app_translations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../main.dart'; 

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // ... (Garder vos méthodes _handleFirebaseError, signUp, signIn, etc. inchangées) ...
  // Je remets les méthodes principales pour que le fichier soit complet et sans erreur

  String _handleFirebaseError(FirebaseAuthException e) {
    String lang = languageNotifier.value;
    switch (e.code) {
      case 'email-already-in-use': return AppTranslations.get(lang, 'email_taken');
      case 'invalid-email': return AppTranslations.get(lang, 'invalid_email');
      case 'weak-password': return AppTranslations.get(lang, 'weak_password');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': return "Email ou mot de passe incorrect.";
      default: return "${AppTranslations.get(lang, 'unknown_error')}\n[${e.code}] ${e.message}";
    }
  }
  Future<void> _saveUserToken(String userId) async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      // Use set+merge instead of update() to avoid failure when document doesn't exist yet
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }
  Future<String?> signUp({required String email, required String password}) async {
    try {
      // Créer l'utilisateur Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // Créer la fiche utilisateur vide dans Firestore
      if (cred.user != null) {
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'profileCompleted': false, // Important pour savoir s'il doit compléter son profil
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) {
        await _saveUserToken(cred.user!.uid); 
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return e.toString();
    }
  }

// --- 3. GOOGLE SIGN IN (CORRIGÉ) ---
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // Annulé par l'utilisateur

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // 1. D'abord, on vérifie/crée le document utilisateur
        final doc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!doc.exists) {
          // Création du profil pour le nouveau venu
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'name': user.displayName,
            'createdAt': FieldValue.serverTimestamp(),
            'profileCompleted': false,
            // On peut même mettre le token directement ici pour économiser une écriture
            // mais on va appeler _saveUserToken après pour être cohérent
          });
        }

        // 2. MAINTENANT que le document existe c'est sûr, on sauvegarde le token
        // Cela mettra à jour le token pour les anciens ET les nouveaux
        await _saveUserToken(user.uid);
      }

      return user;
    } catch (e) {
      print("Erreur Google: $e");
      return null;
    }
  }
  
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onVerificationFailed,
    required Function() onAutoVerifySuccess,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        onAutoVerifySuccess();
      },
      verificationFailed: (FirebaseAuthException e) => onVerificationFailed(_handleFirebaseError(e)),
      codeSent: (String verificationId, int? resendToken) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

Future<String?> signInWithOTP({required String verificationId, required String smsCode}) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
      UserCredential cred = await _auth.signInWithCredential(credential);
      
      if (cred.user != null) {
        final user = cred.user!;
        // Create Firestore document for new phone-auth users (first time login)
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'phone': user.phoneNumber,
            'createdAt': FieldValue.serverTimestamp(),
            'profileCompleted': false,
          });
        }
        // Save FCM token (uses set+merge so it works even if doc just created)
        await _saveUserToken(user.uid);
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // --- ✅ LA NOUVELLE MÉTHODE ---
  Future<void> completeProfile({
    required String phone,
    required String country,
    required String city,
  }) async {
    User? user = _auth.currentUser;
    if (user != null) {
      // On met à jour le document existant avec SetOptions(merge: true)
      await _firestore.collection('users').doc(user.uid).set({
        'phone': phone,
        'wilaya': country,   // kept as 'wilaya' in Firestore for data compatibility
        'commune': city,     // kept as 'commune' in Firestore for data compatibility
        'country': country,  // new explicit field
        'city': city,        // new explicit field
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      throw Exception("Aucun utilisateur connecté");
    }
  }
}