import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../services/chatbot_service.dart';
import '../main.dart';

// ═══════════════════════════════════════════════════════════════════════
// Modèle de message pour le chat
// ═══════════════════════════════════════════════════════════════════════
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ═══════════════════════════════════════════════════════════════════════
// Écran principal du Chatbot
// ═══════════════════════════════════════════════════════════════════════
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  // ─── Services & Controllers ─────────────────────────────────────
  final ChatbotService _chatbotService = ChatbotService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // ─── State ──────────────────────────────────────────────────────
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showSuggestions = true;

  // ─── Animation pour le typing indicator ─────────────────────────
  late AnimationController _dotAnimController;

  // ─── Couleurs constantes ────────────────────────────────────────
  static const Color _primaryNavy = Color(0xFF0F172A);
  static const MaterialColor _accentAmber = Colors.amber;

  @override
  void initState() {
    super.initState();
    _dotAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _dotAnimController.dispose();
    super.dispose();
  }

  // ─── Envoyer un message ─────────────────────────────────────────
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = _ChatMessage(text: text.trim(), isUser: true);

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
      _showSuggestions = false;
    });

    _textController.clear();
    _scrollToBottom();

    try {
      final response = await _chatbotService.sendMessage(text.trim());
      if (!mounted) return;

      final botMessage = _ChatMessage(text: response, isUser: false);

      setState(() {
        _isTyping = false;
        _messages.add(botMessage);
        _showSuggestions = true;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      final isAr = languageNotifier.value == 'ar';
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: isAr
              ? '❌ حدث خطأ. حاول مرة أخرى.'
              : '❌ Une erreur est survenue. Veuillez réessayer.',
          isUser: false,
        ));
        _showSuggestions = true;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _clearChat() {
    final isAr = languageNotifier.value == 'ar';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isAr ? 'مسح المحادثة' : 'Effacer la conversation',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isAr
              ? 'هل أنت متأكد أنك تريد مسح جميع الرسائل؟'
              : 'Êtes-vous sûr de vouloir supprimer tous les messages ?',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isAr ? 'إلغاء' : 'Annuler',
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _showSuggestions = true;
              });
              _chatbotService.clearHistory();
            },
            child: Text(
              isAr ? 'مسح' : 'Effacer',
              style: GoogleFonts.cairo(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isAr = languageNotifier.value == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
        appBar: _buildAppBar(isAr, isDark),
        body: Column(
          children: [
            // Messages list
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(isAr, isDark)
                  : _buildMessageList(isAr, isDark),
            ),

            // Typing indicator
            if (_isTyping) _buildTypingIndicator(isDark),

            // Suggestion chips
            if (_showSuggestions) _buildSuggestionChips(isAr, isDark),

            // Input bar
            _buildInputBar(isAr, isDark),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ─────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isAr, bool isDark) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      foregroundColor: isDark ? Colors.white : _primaryNavy,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            isAr ? 'مساعد IA ونكليك' : 'Assistant IA OneClick',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        if (_messages.isNotEmpty)
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            tooltip: isAr ? 'مسح المحادثة' : 'Effacer la conversation',
            onPressed: _clearChat,
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── État vide (welcome) ────────────────────────────────────────
  Widget _buildEmptyState(bool isAr, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Robot avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _accentAmber.withOpacity(0.2),
                    _accentAmber.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _accentAmber.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                size: 48,
                color: _accentAmber.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isAr ? 'مرحبًا! 👋' : 'Bonjour ! 👋',
              style: GoogleFonts.cairo(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : _primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAr
                  ? 'أنا مساعدك الذكي في OneClick Cars.\nاسألني أي شيء عن السيارات في الجزائر!'
                  : 'Je suis votre assistant intelligent OneClick Cars.\nPosez-moi n\'importe quelle question sur les voitures en Algérie !',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            // Feature pills
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFeaturePill(
                  Icons.search_rounded,
                  isAr ? 'بحث ذكي' : 'Recherche intelligente',
                  isDark,
                ),
                _buildFeaturePill(
                  Icons.gavel_rounded,
                  isAr ? 'الإجراءات القانونية' : 'Procédures légales',
                  isDark,
                ),
                _buildFeaturePill(
                  Icons.attach_money_rounded,
                  isAr ? 'تقدير الأسعار' : 'Estimation de prix',
                  isDark,
                ),
                _buildFeaturePill(
                  Icons.compare_arrows_rounded,
                  isAr ? 'مقارنة السيارات' : 'Comparaison',
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.07)
            : _primaryNavy.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : _primaryNavy.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _accentAmber.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : _primaryNavy,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Liste des messages ─────────────────────────────────────────
  Widget _buildMessageList(bool isAr, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _MessageBubble(
          key: ValueKey('msg_$index'),
          message: message,
          isDark: isDark,
          isAr: isAr,
          animationIndex: index,
        );
      },
    );
  }

  // ─── Typing Indicator (3 bouncing dots) ─────────────────────────
  Widget _buildTypingIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bot avatar
          CircleAvatar(
            radius: 14,
            backgroundColor: _accentAmber,
            child: const Icon(Icons.smart_toy_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          // Dots container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _dotAnimController,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    // Stagger the bounce for each dot
                    final delay = i * 0.2;
                    final t = (_dotAnimController.value - delay).clamp(0.0, 1.0);
                    final bounce = (t < 0.5)
                        ? (t * 2)    // Going up
                        : (2 - t * 2); // Coming down
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      child: Transform.translate(
                        offset: Offset(0, -6 * bounce),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _accentAmber
                                .withOpacity(0.5 + 0.5 * bounce),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Suggestion Chips ───────────────────────────────────────────
  Widget _buildSuggestionChips(bool isAr, bool isDark) {
    final suggestions =
        _chatbotService.getSuggestedQuestions(isArabic: isAr);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _sendMessage(suggestions[index]),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF1E293B),
                            const Color(0xFF1E293B),
                          ]
                        : [
                            _primaryNavy.withOpacity(0.06),
                            _primaryNavy.withOpacity(0.03),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? _accentAmber.withOpacity(0.2)
                        : _primaryNavy.withOpacity(0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: _accentAmber.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      suggestions[index],
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : _primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Input Bar ──────────────────────────────────────────────────
  Widget _buildInputBar(bool isAr, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) => _sendMessage(text),
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  color: isDark ? Colors.white : _primaryNavy,
                ),
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: isAr
                      ? 'اكتب سؤالك هنا...'
                      : 'Posez votre question...',
                  hintStyle: GoogleFonts.cairo(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isTyping ? null : () => _sendMessage(_textController.text),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: _isTyping
                      ? LinearGradient(
                          colors: [Colors.grey.shade400, Colors.grey.shade400],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_primaryNavy, Color(0xFF1E3A5F)],
                        ),
                  shape: BoxShape.circle,
                  boxShadow: _isTyping
                      ? []
                      : [
                          BoxShadow(
                            color: _primaryNavy.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Widget Bulle de message — avec animation d'entrée
// ═══════════════════════════════════════════════════════════════════════
class _MessageBubble extends StatefulWidget {
  final _ChatMessage message;
  final bool isDark;
  final bool isAr;
  final int animationIndex;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isDark,
    required this.isAr,
    required this.animationIndex,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  static const Color _primaryNavy = Color(0xFF0F172A);
  static const Color _accentAmber = Colors.amber;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.message.isUser ? 0.3 : -0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    final timeStr = intl.DateFormat('HH:mm').format(widget.message.timestamp);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bot avatar (left side)
              if (!isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _accentAmber,
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Message bubble
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? _primaryNavy
                        : (widget.isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white),
                    gradient: isUser
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_primaryNavy, Color(0xFF1E3A5F)],
                          )
                        : (widget.isDark
                            ? null
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.grey.shade50,
                                ],
                              )),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft:
                          isUser ? const Radius.circular(18) : const Radius.circular(4),
                      bottomRight:
                          isUser ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? _primaryNavy.withOpacity(0.2)
                            : Colors.black.withOpacity(widget.isDark ? 0.2 : 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Message text
                      SelectableText(
                        widget.message.text,
                        style: GoogleFonts.cairo(
                          fontSize: 14.5,
                          color: isUser
                              ? Colors.white
                              : (widget.isDark
                                  ? Colors.grey[200]
                                  : const Color(0xFF1E293B)),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Timestamp
                      Text(
                        timeStr,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: isUser
                              ? Colors.white.withOpacity(0.6)
                              : (widget.isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // User avatar (right side)
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _primaryNavy.withOpacity(0.1),
                  child: Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: _primaryNavy.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
