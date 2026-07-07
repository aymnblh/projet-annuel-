import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Démarrer une nouvelle discussion (ou récupérer l'existante)
  Future<String> startChat({
    required String otherUserId,
    required String productId,
    required String productName,
    required String productImage,
  }) async {
    final currentUserId = _auth.currentUser!.uid;

    // Vérifier si une discussion existe déjà pour ce produit entre ces 2 personnes
    // Note: Pour simplifier, on filtre côté client ou on crée un ID unique combiné
    // Ici on crée un ID unique basé sur les IDs pour éviter les doublons
    List<String> ids = [currentUserId, otherUserId];
    ids.sort(); // Pour que l'ID soit toujours le même quel que soit qui commence (A-B ou B-A)
    String chatId = "${ids[0]}_${ids[1]}_$productId";

    final doc = await _firestore.collection('chats').doc(chatId).get();

    if (!doc.exists) {
      await _firestore.collection('chats').doc(chatId).set({
        'users': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'productId': productId,
        'productName': productName,
        'productImage': productImage,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  // 2. Envoyer un message
  Future<void> sendMessage(String chatId, String text, {String type = 'text', String? audioUrl, int? duration}) async {
    final currentUserId = _auth.currentUser!.uid;

    // Ajouter le message dans la sous-collection
    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': currentUserId,
      'text': text,
      'type': type,
      'audioUrl': audioUrl, 
      'duration': duration,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'sent', // NEW: Initial status
      'readBy': [], // NEW: Empty initially
      'reactions': {}, // NEW: No reactions initially
    });

    // Mettre à jour le dernier message de la conversation (pour la liste principale)
    String previewMsg = text;
    if (type == 'audio') {
      previewMsg = '🎤 Message vocal';
    }

    // Get chat to find other user
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final users = List<String>.from(chatDoc.data()?['users'] ?? []);
    final otherUserId = users.firstWhere((id) => id != currentUserId, orElse: () => '');

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': previewMsg,
      'lastMessageTime': FieldValue.serverTimestamp(),
      // NEW: Increment unread count for other user
      'unreadCount.$otherUserId': FieldValue.increment(1),
    });
  }

  // 3. Récupérer mes conversations
  Stream<QuerySnapshot> getMyChats() {
    final currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('chats')
        .where('users', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // 4. Récupérer les messages d'une conversation
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true) // Du plus récent au plus vieux (pour l'affichage inversé)
        .snapshots();
  }

  // NEW: 5. Marquer un message comme lu
  Future<void> markAsRead(String chatId, String messageId) async {
    final currentUserId = _auth.currentUser!.uid;
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'readBy': FieldValue.arrayUnion([currentUserId]),
      'status': 'read',
    });
  }

  // NEW: 6. Définir le statut de frappe (typing)
  Future<void> setTypingStatus(String chatId, bool isTyping) async {
    final currentUserId = _auth.currentUser!.uid;
    
    await _firestore.collection('chats').doc(chatId).update({
      'typingUsers.$currentUserId': isTyping,
    });
  }

  // NEW: 7. Réinitialiser le compteur de messages non lus
  Future<void> resetUnreadCount(String chatId) async {
    final currentUserId = _auth.currentUser!.uid;
    
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount.$currentUserId': 0,
    });
  }

  // NEW: 8. Ajouter une réaction à un message
  Future<void> addReaction(String chatId, String messageId, String emoji) async {
    final currentUserId = _auth.currentUser!.uid;
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.$currentUserId': emoji,
    });
  }

  // NEW: 9. Retirer une réaction d'un message
  Future<void> removeReaction(String chatId, String messageId) async {
    final currentUserId = _auth.currentUser!.uid;
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.$currentUserId': FieldValue.delete(),
    });
  }

  // NEW: 10. Mettre à jour le statut d'un message
  Future<void> updateMessageStatus(String chatId, String messageId, String status) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'status': status,
    });
  }
}