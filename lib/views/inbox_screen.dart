import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/chat_service.dart';
import '../models/chat_model.dart'; // Assurez-vous d'avoir créé ce fichier à l'étape précédente
import 'chat_room_screen.dart';
import '../utils/app_translations.dart';
import '../main.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final ChatService _chatService = ChatService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  String t(String key) => AppTranslations.get(languageNotifier.value, key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Messages",
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getMyChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  Text("Aucune discussion", style: GoogleFonts.cairo(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final chat = ChatConversation.fromFirestore(doc);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(
                      chatId: chat.id,
                      otherUserName: chat.productName, // On affiche le nom du produit comme titre
                      productName: "Discussion sur l'article",
                    )));
                  },
                  // Image du produit
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 60, height: 60,
                      child: chat.productImage.isNotEmpty
                          ? CachedNetworkImage(imageUrl: chat.productImage, fit: BoxFit.cover)
                          : Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                    ),
                  ),
                  // Titre (Nom du produit)
                  title: Text(
                    chat.productName,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  // Dernier message
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(color: Colors.grey[600]),
                        ),
                      ),
                      Text(
                        timeago.format(chat.lastMessageTime, locale: 'fr_short'),
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  // NEW: Unread badge + chevron
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // NEW: Unread count badge
                      if (chat.getUnreadCount(currentUserId) > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          child: Center(
                            child: Text(
                              chat.getUnreadCount(currentUserId).toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}