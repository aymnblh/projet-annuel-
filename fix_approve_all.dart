// Script: Approuver toutes les annonces existantes dans Firestore
// Exécuter avec: dart run fix_approve_all.dart

import 'dart:io';

// Ce script doit être exécuté via la console Firebase Admin SDK
// ou directement via la console Firebase.

// OPTION SIMPLE : Copier-coller cette règle dans la console Firebase
// Firestore → Données → collection "products" → filtrer isApproved == false
// Puis éditer chaque document manuellement.

// OPTION AUTOMATIQUE via Firebase CLI :
// Allez sur : https://console.firebase.google.com
// Ouvrez l'éditeur de règles et exécutez depuis Cloud Functions, 
// ou utilisez le script Node.js ci-dessous dans Firebase Functions :

void main() {
  print('''
=======================================================
INSTRUCTIONS POUR APPROUVER TOUTES LES ANNONCES
=======================================================

1. Allez sur https://console.firebase.google.com
2. Sélectionnez votre projet
3. Firestore Database → onglet "Données"
4. Cliquez sur la collection "products"
5. Pour chaque document avec isApproved = false :
   - Cliquez sur le document
   - Trouvez le champ "isApproved"
   - Changez la valeur de false à true
   - Cliquez sur "Mettre à jour"

OU utilisez ce script Node.js dans Firebase Console Shell :

const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();

async function approveAll() {
  const snapshot = await db.collection("products")
    .where("isApproved", "==", false)
    .get();
  
  const batch = db.batch();
  snapshot.docs.forEach(doc => {
    batch.update(doc.ref, { isApproved: true });
  });
  
  await batch.commit();
  console.log(\`✅ \${snapshot.size} annonces approuvées !\`);
}

approveAll();

=======================================================
''');
  exit(0);
}
