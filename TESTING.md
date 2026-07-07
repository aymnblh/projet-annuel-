# Guide de Test & Validation - OneClick

Ce guide détaille comment valider les fonctionnalités avancées sur un appareil physique Android.

**Pré-requis** : 
- Android SDK Platform-Tools (`adb`) installé.
- Téléphone connecté en mode "Débogage USB".
- Application installée (`flutter run --release`).

**Identifiant Application** : `com.example.oneshot`

---

## 1. 🔗 Deep Linking

**Objectif** : Vérifier que l'application s'ouvre et navigue vers un produit spécifique via une URL personnalisée.

1. Assurez-vous que l'application est installée. Elle peut être fermée ou en arrière-plan.
2. Ouvrez un terminal et exécutez la commande suivante (Remplacez `PRODUCT_ID` par un ID de produit existant dans votre base Firestore) :

   ```bash
   adb shell am start -W -a android.intent.action.VIEW -d "oneclick://product/PRODUCT_ID_ICI" com.example.oneshot
   ```

3. **Résultat attendu** :
   - L'application s'ouvre immédiatement.
   - Un écran de chargement apparaît brièvement.
   - La page "Détails du Produit" s'affiche avec les données du produit correspondant.

---

## 2. 📡 Mode Offline (Brouillons)

**Objectif** : Vérifier que les annonces en cours de rédaction sont sauvegardées localement et peuvent être restaurées.

1. Ouvrez l'application et allez sur l'écran **"Vendre"**.
2. Remplissez quelques champs (ex: Titre = "Test Brouillon", Prix = "5000").
3. Cliquez sur l'icône **Sauvegarder** (en haut à droite dans la barre d'actions).
   - *Message* : "Brouillon sauvegardé !" doit apparaître.
4. Quittez l'écran ou fermez complètement l'application (supprimez-la des applications récentes).
5. (Optionnel) Coupez la connexion Internet pour simuler un vrai cas "Offline".
6. Relancez l'application et retournez sur l'écran **"Vendre"**.
7. **Résultat attendu** :
   - Une barre de notification (SnackBar) apparaît en bas : *"Brouillon trouvé, restaurer ?"*.
8. Cliquez sur **"OUI"**.
   - Le titre "Test Brouillon" et le prix "5000" doivent se remplir automatiquement.

---

## 3. 🔍 Recherche Avancée (Algolia)

**Objectif** : Valider l'intégration de la recherche tolerante aux fautes.

**Pré-requis** : Vous devez avoir configuré `ALGOLIA_APP_ID` et `ALGOLIA_API_KEY` dans votre fichier `.env`.

1. Sur l'écran d'accueil, cliquez sur la barre de recherche.
2. Tapez un mot clé correspondant à un produit (ex: "iphone" ou "voiture").
3. Essayez avec une faute de frappe légère (ex: "iphoe").
4. **Résultat attendu** :
   - Si Algolia est configuré : La grille de produits se met à jour avec les résultats pertinents provenant d'Algolia.
   - Si Algolia n'est **PAS** configuré : La liste sera vide (vérifiez les logs pour voir l'erreur "Keys missing").
