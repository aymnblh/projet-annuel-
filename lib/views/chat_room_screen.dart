import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/chat_service.dart';
import '../models/chat_model.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import '../services/ai_service.dart';
import '../main.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String productName;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.productName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final AIService _aiService = AIService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // --- AUDIO ---
  late AudioRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;
  bool _isRecording = false;
  String? _currentPlayingUrl;
  bool _isPlaying = false;
  
  // --- ANIMATION ---
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // NEW: Typing indicator
  Timer? _typingTimer;
  bool _isTyping = false;

  // NEW: Chat conversation stream for typing status
  Stream<DocumentSnapshot>? _chatStream;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
    
    // Animation Pulse pour l'enregistrement
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pulseController.repeat(reverse: true);

    // Listeners Audio
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
         _isPlaying = false;
         _currentPlayingUrl = null;
      });
      }
    });

    // NEW: Reset unread count when opening chat
    _chatService.resetUnreadCount(widget.chatId);

    // NEW: Listen to chat for typing status
    _chatStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .snapshots();

    // NEW: Listen to text changes for typing indicator
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _pulseController.dispose();
    _typingTimer?.cancel();
    
    // NEW: Set typing to false when leaving
    if (_isTyping) {
      _chatService.setTypingStatus(widget.chatId, false);
    }
    
    super.dispose();
  }

  // NEW: Handle typing indicator with debouncing
  void _onTextChanged() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _chatService.setTypingStatus(widget.chatId, true);
    }

    // Reset timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 500), () {
      if (_isTyping) {
        _isTyping = false;
        _chatService.setTypingStatus(widget.chatId, false);
      }
    });
  }

  // --- AUDIO ACTIONS ---
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
        final String filePath = '${appDocumentsDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: filePath);
        setState(() => _isRecording = true);
      }
    } catch (e) {
      print("Erreur Enregistrement: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      
      if (path != null) {
        _sendAudioMessage(path);
      }
    } catch (e) {
       print("Erreur Stop Enregistrement: $e");
    }
  }

  Future<void> _sendAudioMessage(String path) async {
     await _chatService.sendMessage(widget.chatId, "🎤 Message Vocal", type: 'audio', duration: 2000);
     _scrollToBottom();
  }

  Future<void> _playAudio(String url) async {
    if (_isPlaying && _currentPlayingUrl == url) {
      await _audioPlayer.pause();
    } else {
      print("Lecture Audio (Simulation): $url");
      setState(() {
        _currentPlayingUrl = url;
        _isPlaying = true;
      });
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _isPlaying = false;
        _currentPlayingUrl = null;
      });
    }
  }

  // --- AI ACTIONS ---
  Future<void> _generateSmartReply() async {
    String? reply = await _aiService.generateSmartReply(
      productTitle: widget.productName,
      productDescription: "...",
      price: "...", 
      lastUserMessage: "...",
      historyContext: "...",
    );
    
    if (reply != null) {
      _messageController.text = reply;
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await _chatService.sendMessage(widget.chatId, _messageController.text.trim());
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // NEW: Show emoji picker for reactions
  void _showEmojiPicker(BuildContext context, ChatMessage message) {
    final emojis = ['❤️', '👍', '😂', '😮', '😢', '🙏'];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Réagir au message', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 15,
              children: emojis.map((emoji) {
                final hasReacted = message.reactions[currentUserId] == emoji;
                return GestureDetector(
                  onTap: () {
                    if (hasReacted) {
                      _chatService.removeReaction(widget.chatId, message.id);
                    } else {
                      _chatService.addReaction(widget.chatId, message.id, emoji);
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasReacted ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: hasReacted ? Border.all(color: Colors.blue, width: 2) : null,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 32)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Mark message as read when visible
  void _markAsReadIfNeeded(ChatMessage message) {
    if (message.senderId != currentUserId && !message.readBy.contains(currentUserId)) {
      _chatService.markAsRead(widget.chatId, message.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
            // NEW: Typing indicator in AppBar
            StreamBuilder<DocumentSnapshot>(
              stream: _chatStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final chat = ChatConversation.fromFirestore(snapshot.data!);
                  final isOtherTyping = chat.isOtherUserTyping(currentUserId);
                  
                  if (isOtherTyping) {
                    return Text(
                      'en train d\'écrire...',
                      style: GoogleFonts.cairo(fontSize: 12, color: Colors.green, fontStyle: FontStyle.italic),
                    );
                  }
                }
                return Text(widget.productName, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700]));
              },
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // --- LISTE DES MESSAGES ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Erreur de chargement"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<ChatMessage> messages = snapshot.data!.docs
                    .map((doc) => ChatMessage.fromFirestore(doc))
                    .toList();

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      "Dites bonjour ! 👋",
                      style: GoogleFonts.cairo(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUserId;

                    // NEW: Mark as read when message is visible
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _markAsReadIfNeeded(msg);
                    });

                    return GestureDetector(
                      onLongPress: () => _showEmojiPicker(context, msg),
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey[300], 
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                              bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (msg.type == 'audio')
                                GestureDetector(
                                  onTap: () => _playAudio(msg.audioUrl ?? ''),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2), 
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.white,
                                          radius: 18,
                                          child: Icon(
                                            (_isPlaying && _currentPlayingUrl == msg.audioUrl) ? Icons.pause : Icons.play_arrow, 
                                            color: isMe ? Colors.blue : Colors.black87, 
                                            size: 24
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        ...List.generate(5, (i) => Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 2),
                                            width: 3, 
                                            height: 10.0 + (i % 2 * 10) + ((_isPlaying && _currentPlayingUrl == msg.audioUrl) ? (i * 2 % 10) : 0), 
                                            color: Colors.white
                                        )),
                                        const SizedBox(width: 8),
                                        Text(
                                          "${msg.duration != null ? (msg.duration! / 1000).toStringAsFixed(0) : '2'}s",
                                          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                                        )
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  msg.text,
                                  style: GoogleFonts.cairo(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    timeago.format(msg.timestamp, locale: 'fr_short'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  // NEW: Read receipts (checkmarks)
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      msg.status == 'read' ? Icons.done_all : Icons.done,
                                      size: 14,
                                      color: msg.status == 'read' ? Colors.lightBlue : Colors.white70,
                                    ),
                                  ],
                                ],
                              ),
                              // NEW: Reactions display
                              if (msg.reactions.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  children: msg.reactions.entries.map((entry) {
                                    final count = msg.reactions.values.where((e) => e == entry.value).length;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(entry.value, style: const TextStyle(fontSize: 14)),
                                          if (count > 1) ...[
                                            const SizedBox(width: 2),
                                            Text(
                                              count.toString(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isMe ? Colors.white : Colors.black87,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                // AI MAGIC BUTTON
                IconButton(
                   icon: const Icon(Icons.auto_awesome, color: Colors.purple),
                   onPressed: _generateSmartReply,
                   tooltip: "Smart Reply (AI)",
                ),
              
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Écrire un message...",
                      hintStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                
                // MIC OR SEND
                GestureDetector(
                  onLongPress: _startRecording,
                  onLongPressUp: _stopRecording,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                       return Transform.scale(
                         scale: _isRecording ? _pulseAnimation.value : 1.0,
                         child: Container(
                            decoration: _isRecording ? BoxDecoration(
                               shape: BoxShape.circle,
                               boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 10, spreadRadius: 5)]
                            ) : null,
                            child: CircleAvatar(
                              backgroundColor: _isRecording ? Colors.red : const Color(0xFF0F172A),
                              radius: 24,
                              child: _isRecording 
                                ? const Icon(Icons.mic, color: Colors.white, size: 24)
                                : IconButton(
                                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                                    onPressed: _sendMessage,
                                  ),
                            ),
                         ),
                       );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
