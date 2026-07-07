# 🛍️ OneClick - Marketplace Algérie 🇩🇿

**OneClick** est une application mobile e-commerce moderne conçue pour le marché algérien. Elle permet aux particuliers de vendre leurs objets (style OuedKniss/Avito) et aux professionnels de créer des boutiques virtuelles.

---

## 🚀 Fonctionnalités Principales

### 👤 Pour les Utilisateurs (Acheteurs/Vendeurs)
*   **Fil d'actualité Intelligent** : Algorithme de tri (Boosts en premier, puis Récents) avec pagination infinie.
*   **Recherche & Filtres** : Recherche instantanée (par titre, catégorie, wilaya, commune) avec historique.
*   **Messagerie Temps Réel** : Chat intégré (Texte, Audio, Images) avec statuts "Lu/Distribué".
*   **Système de Favoris** : Sauvegarde des articles préférés.
*   **Deep Linking** : Partage d'annonces via liens `oneclick://product/ID` qui ouvrent directement l'app.
*   **Mode Sombre** : Interface adaptée (Light/Dark mode) au look "Luxe/Premium".

### 💼 Pour les Pros (Boutiques & Vendeurs Vérifiés)
*   **Compte PRO** : Création d'une page "Boutique" dédiée avec couverture, logo, et bio.
*   **Dashboard** : Statistiques de vues (Graphiques) pour suivre la performance des annonces.
*   **Boost d'Annonces** : Système de mise en avant payante (Urgent, 24h, 7j) pour plus de visibilité.
*   **Badge Vérifié 🛡️** : Statut spécial après vérification d'identité.

### 🛡️ Sécurité & Confiance
*   **Modération AI (Gemini)** : Analyse automatique des images lors de l'upload pour bloquer le contenu inapproprié (NSFW, Violence) avant publication.
*   **Vérification d'Identité** : Upload sécurisé de pièce d'identité + Selfie pour obtenir le badge bleu. Validé par Admin.

### 👑 Administration
*   **Panel Admin Mobile** : Dashboard secret intégré à l'app pour valider/refuser les demandes de vérification d'identité.

---

## 🛠️ Stack Technique

*   **Frontend** : Flutter (Dart).
*   **Backend** : Firebase (Auth, Firestore, Storage, Messaging, Analytics).
*   **AI (Intelligence Artificielle)** : 
    *   **Google Gemini** : Pour l'analyse de sécurité des images et l'aide à la rédaction d'annonces (Titre/Description auto).
    *   **ML Kit** : Pour le détourage automatique des photos (suppression d'arrière-plan).
*   **Search** : Custom Search Service (Algolia-like) via API REST.
*   **Analytics** : Firebase Analytics pour le tracking (Recherches, Vues articles).

---

## 📲 Comment Lancer le Projet

### 1. Pré-requis
*   Flutter SDK installé.
*   Projet Firebase configuré (fichiers `google-services.json` / `GoogleService-Info.plist`).
*   Fichier `.env` à la racine contenant :
    ```env
    ALGOLIA_APP_ID=...
    ALGOLIA_API_KEY=...
    GEMINI_API_KEY=...
    ```

### 2. Commandes
```bash
# Installer les dépendances
flutter pub get

# Lancer en mode Debug
flutter run

# Analyser le code
flutter analyze

# Construire pour Android (APK)
flutter build apk --release
```

---

*Développé avec 💙 pour l'Algérie.*
