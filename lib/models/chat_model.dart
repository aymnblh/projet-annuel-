import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String type; // 'text', 'audio'
  final String? audioUrl;
  final int? duration; // en millisecondes
  
  // NEW: Read receipts & status
  final String status; // 'sending', 'sent', 'delivered', 'read'
  final List<String> readBy; // User IDs who read this message
  
  // NEW: Reactions
  final Map<String, String> reactions; // {userId: emoji}

  ChatMessage({
    required this.id,
    required this.senderId, 
    required this.text, 
    required this.timestamp,
    this.type = 'text',
    this.audioUrl,
    this.duration,
    this.status = 'sent',
    this.readBy = const [],
    this.reactions = const {},
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      // SÉCURITÉ AJOUTÉE ICI : On gère le cas où la date est nulle ou en cours d'écriture
      timestamp: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'text',
      audioUrl: data['audioUrl'],
      duration: data['duration'],
      status: data['status'] ?? 'sent',
      readBy: List<String>.from(data['readBy'] ?? []),
      reactions: Map<String, String>.from(data['reactions'] ?? {}),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'createdAt': Timestamp.fromDate(timestamp),
      'type': type,
      'audioUrl': audioUrl,
      'duration': duration,
      'status': status,
      'readBy': readBy,
      'reactions': reactions,
    };
  }
}


class ChatConversation {
  final String id;
  final List<String> users; 
  final String lastMessage;
  final DateTime lastMessageTime;
  final String productId; 
  final String productName; 
  final String productImage;
  
  // NEW: Typing indicators
  final Map<String, bool> typingUsers; // {userId: isTyping}
  
  // NEW: Unread counters
  final Map<String, int> unreadCount; // {userId: count}

  ChatConversation({
    required this.id,
    required this.users,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.productId,
    required this.productName,
    required this.productImage,
    this.typingUsers = const {},
    this.unreadCount = const {},
  });

  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatConversation(
      id: doc.id,
      users: List<String>.from(data['users'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      // SÉCURITÉ DÉJÀ PRÉSENTE ICI (C'est très bien)
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productImage: data['productImage'] ?? '',
      typingUsers: Map<String, bool>.from(data['typingUsers'] ?? {}),
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }
  
  // Helper to get other user ID
  String getOtherUserId(String currentUserId) {
    return users.firstWhere((id) => id != currentUserId, orElse: () => '');
  }
  
  // Helper to check if other user is typing
  bool isOtherUserTyping(String currentUserId) {
    final otherUserId = getOtherUserId(currentUserId);
    return typingUsers[otherUserId] ?? false;
  }
  
  // Helper to get unread count for current user
  int getUnreadCount(String currentUserId) {
    return unreadCount[currentUserId] ?? 0;
  }
}
