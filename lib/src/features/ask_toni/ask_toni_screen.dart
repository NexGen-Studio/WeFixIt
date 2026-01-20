import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../i18n/app_localizations.dart';
import '../../models/chat_message.dart';
import '../../services/credit_service.dart';
import '../../services/purchase_service.dart';
import '../../services/ask_toni_service.dart';

class AskToniScreen extends StatefulWidget {
  const AskToniScreen({super.key});

  @override
  State<AskToniScreen> createState() => _AskToniScreenState();
}

class _AskToniScreenState extends State<AskToniScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  final CreditService _creditService = CreditService();
  final AskToniService _askToniService = AskToniService();
  RewardedAd? _rewardedAd;
  bool _isLoadingAd = false;
  
  // Chat History
  List<Map<String, dynamic>> _chatHistory = [];
  String? _currentChatId;
  bool _showHistoryDropdown = false;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
    _loadChatHistory();
  }
  
  Future<void> _loadChatHistory() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      
      final response = await Supabase.instance.client
        .from('chat_history')
        .select('id, title, created_at, updated_at')
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .limit(15);
      
      if (mounted) {
        setState(() {
          _chatHistory = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      print('⚠️ Fehler beim Laden der Chat-History: $e');
    }
  }
  
  Future<void> _loadChat(String chatId) async {
    try {
      final response = await Supabase.instance.client
        .from('chat_history')
        .select('messages')
        .eq('id', chatId)
        .single();
      
      final messages = response['messages'] as List;
      
      if (mounted) {
        setState(() {
          _currentChatId = chatId;
          _messages.clear();
          
          for (var i = 0; i < messages.length; i++) {
            final msg = messages[i] as Map<String, dynamic>;
            _messages.add(ChatMessage(
              id: '$chatId-$i',
              text: msg['content'] as String,
              isUser: msg['role'] == 'user',
              timestamp: DateTime.now(),
            ));
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('⚠️ Fehler beim Laden des Chats: $e');
    }
  }
  
  Future<void> _saveChat() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null || _messages.isEmpty) return;
      
      // Konvertiere Messages zu JSON
      final messagesJson = _messages.map((m) => {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      }).toList();
      
      if (_currentChatId != null) {
        // Update existierenden Chat
        await Supabase.instance.client
          .from('chat_history')
          .update({
            'messages': messagesJson,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentChatId!);
      } else {
        // Erstelle neuen Chat mit Titel
        final title = await _generateChatTitle(_messages[0].text);
        
        final response = await Supabase.instance.client
          .from('chat_history')
          .insert({
            'user_id': userId,
            'title': title,
            'messages': messagesJson,
          })
          .select('id')
          .single();
        
        _currentChatId = response['id'] as String;
      }
      
      await _loadChatHistory();
    } catch (e) {
      print('⚠️ Fehler beim Speichern des Chats: $e');
    }
  }
  
  Future<String> _generateChatTitle(String firstMessage) async {
    // Lade Fahrzeugdaten für Titel
    String vehiclePrefix = '';
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final vehicleData = await Supabase.instance.client
          .from('vehicles')
          .select('make, model')
          .eq('user_id', userId)
          .maybeSingle();
        
        if (vehicleData != null) {
          // Bevorzuge Modell, falls nicht vorhanden dann Marke
          if (vehicleData['model'] != null && (vehicleData['model'] as String).isNotEmpty) {
            vehiclePrefix = '${vehicleData['model']} ';
          } else if (vehicleData['make'] != null && (vehicleData['make'] as String).isNotEmpty) {
            vehiclePrefix = '${vehicleData['make']} ';
          }
        }
      }
    } catch (e) {
      print('⚠️ Fehler beim Laden der Fahrzeugdaten für Titel: $e');
    }
    
    // Titel mit Fahrzeug-Präfix (max 50 Zeichen)
    final maxLength = 50 - vehiclePrefix.length;
    final cleanMessage = firstMessage.length > maxLength 
      ? '${firstMessage.substring(0, maxLength - 3)}...'
      : firstMessage;
    
    return '$vehiclePrefix$cleanMessage';
  }
  
  void _startNewChat() {
    setState(() {
      _currentChatId = null;
      _messages.clear();
      _textController.clear();
    });
  }
  
  Future<void> _deleteChat(String chatId) async {
    try {
      await Supabase.instance.client
        .from('chat_history')
        .delete()
        .eq('id', chatId);
      
      if (!mounted) return;
      
      setState(() {
        // Wenn der gelöschte Chat der aktive war, zurücksetzen
        if (_currentChatId == chatId) {
          _currentChatId = null;
          _messages.clear();
          _textController.clear();
        }
      });
      
      await _loadChatHistory();
    } catch (e) {
      print('⚠️ Fehler beim Löschen des Chats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Löschen des Chats'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // Test-ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  Future<void> _showRewardedAd() async {
    if (_rewardedAd == null) {
      _loadRewardedAd();
      // Wait max 5 seconds for ad to load
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (_rewardedAd != null) break;
      }
    }

    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) async {
          await _creditService.addFreeCredits(1, 'watched_ad');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Du hast 1 Credit erhalten!'),
                backgroundColor: Color(0xFFF8AD20),
              ),
            );
          }
        },
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Werbung konnte nicht geladen werden. Bitte versuche es später erneut.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return; // ← Verhindert Doppel-Send!

    // 1. Prüfen ob Pro User oder Credits vorhanden
    final isPro = await PurchaseService().isProUser();
    
    // Wenn nicht Pro, versuche Credits/Quota zu nutzen
    if (!isPro) {
      final success = await _creditService.consumeQuotaOrCredits(1, 'chat_message');
      if (!success) {
        if (mounted) _showNoCreditsDialog();
        return;
      }
    }

    // 2. Nachricht senden
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().toIso8601String(),
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
      _textController.clear();
    });
    _scrollToBottom();

    // 3. Fahrzeugdaten vom User laden (aus vehicles Tabelle)
    Map<String, dynamic>? vehicleContext;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final vehicleData = await Supabase.instance.client
          .from('vehicles')
          .select('make, model, year, engine_code, vin, mileage_km, power_kw, displacement_cc, share_vehicle_data_with_ai')
          .eq('user_id', userId)
          .maybeSingle();
        
        // Prüfe ob User Datenfreigabe aktiviert hat
        final shareWithAI = (vehicleData?['share_vehicle_data_with_ai'] as bool?) ?? true;
        
        if (vehicleData != null && shareWithAI) {
          vehicleContext = {
            if (vehicleData['make'] != null) 'make': vehicleData['make'],
            if (vehicleData['model'] != null) 'model': vehicleData['model'],
            if (vehicleData['year'] != null) 'year': vehicleData['year'],
            if (vehicleData['engine_code'] != null) 'engine': vehicleData['engine_code'],
            if (vehicleData['vin'] != null) 'vin': vehicleData['vin'],
            if (vehicleData['mileage_km'] != null) 'mileage': vehicleData['mileage_km'],
            if (vehicleData['power_kw'] != null) 'power_kw': vehicleData['power_kw'],
            if (vehicleData['displacement_cc'] != null) 'displacement_cc': vehicleData['displacement_cc'],
          };
          print('🚗 Fahrzeugdaten geladen: ${vehicleData['make']} ${vehicleData['model']} (${vehicleData['year']})');
        } else {
          print('ℹ️ Keine Fahrzeugdaten gefunden für User');
        }
      }
    } catch (e) {
      print('⚠️ Fehler beim Laden der Fahrzeugdaten: $e');
      // Weiter ohne Fahrzeugdaten
    }

    // 4. Echte AI Antwort von Toni holen
    // Konvertiere bisherige Messages zu conversationHistory
    final conversationHistory = _messages
        .where((msg) => msg.text.isNotEmpty)
        .map((msg) => {
              'role': msg.isUser ? 'user' : 'assistant',
              'content': msg.text,
            })
        .toList();
    
    try {
      final response = await _askToniService.sendMessage(
        message: text,
        language: 'de',
        conversationHistory: conversationHistory,
        vehicleContext: vehicleContext,
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            id: DateTime.now().toIso8601String(),
            text: response.reply,
            isUser: false,
            timestamp: DateTime.now(),
            sources: response.sources,
            errorCodes: response.errorCodes,
            knowledgeSource: response.knowledgeSource,
          ));
        });
        _scrollToBottom();
        
        // Speichere Chat in History
        _saveChat();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            id: DateTime.now().toIso8601String(),
            text: 'Entschuldigung, es gab einen Fehler: $e',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    }
  }

  void _showNoCreditsDialog() {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1A2028),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header mit Schloss-Icon
                Row(
                  children: [
                    const Icon(Icons.lock, color: Color(0xFFF8AD20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.tr('chatbot.no_credits_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  t.tr('chatbot.no_credits_message'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 24),
                Text(
                  t.tr('dialog.unlock_with'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                // Option: Werbung ansehen
                _buildUnlockOptionWithButton(
                  Icons.tv,
                  t.tr('chatbot.watch_ad'),
                  '1x Credits',
                  () {
                    Navigator.pop(ctx);
                    _showRewardedAd();
                  },
                ),
                const SizedBox(height: 8),
                // Option: Credits kaufen
                _buildUnlockOption(
                  Icons.shopping_cart,
                  t.tr('chatbot.buy_credits'),
                  t.tr('chatbot.credits_price'),
                  () {
                    Navigator.pop(ctx);
                    context.push('/paywall');
                  },
                ),
                const SizedBox(height: 8),
                // Option: Premium kaufen
                _buildUnlockOption(
                  Icons.star,
                  t.tr('chatbot.buy_premium'),
                  t.tr('chatbot.premium_price'),
                  () {
                    Navigator.pop(ctx);
                    context.push('/paywall');
                  },
                ),
                const SizedBox(height: 24),
                // Buttons unten
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        t.tr('common.cancel'),
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/paywall');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF8AD20),
                        foregroundColor: Colors.black,
                      ),
                      child: Text(t.tr('chatbot.go_to_paywall')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockOptionWithButton(IconData icon, String title, String buttonText, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF8AD20), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF8AD20),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockOption(IconData icon, String title, String price, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFF8AD20), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            Text(
              price,
              style: const TextStyle(
                color: Color(0xFFF8AD20),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ChatGPT-Style Sidebar mit Chat-Historie
  Widget _buildChatHistorySidebar(BuildContext context, AppLocalizations t) {
    return Drawer(
      backgroundColor: const Color(0xFF0B1117),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Color(0xFFFFB129), size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Ask Toni!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            
            // Neuer Chat Button (ohne Hintergrund, links)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _startNewChat();
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_square,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Neuer Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Divider(color: Color(0xFF2A2A2A), height: 1),
            ),
            
            const SizedBox(height: 16),
            
            // Chat-Liste
            if (_chatHistory.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Keine Chat-Historie',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _chatHistory.length,
                  itemBuilder: (context, index) {
                    final chat = _chatHistory[index];
                    final isActive = chat['id'] == _currentChatId;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white54,
                          size: 18,
                        ),
                        title: Text(
                          chat['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _loadChat(chat['id'] as String);
                        },
                        onLongPress: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              backgroundColor: const Color(0xFF1A1A1A),
                              title: const Text(
                                'Chat löschen?',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                'Möchtest du "${chat['title']}" wirklich löschen?',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(false),
                                  child: const Text(
                                    'Abbrechen',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(true),
                                  child: const Text(
                                    'Löschen',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed == true) {
                            // Schließe Sidebar
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                            // Lösche Chat
                            await _deleteChat(chat['id'] as String);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0B1117),
      drawer: _buildChatHistorySidebar(context, t),
      body: Column(
          children: [
            // Header mit Hamburger-Menü
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  // Hamburger-Menü links (feste Breite)
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu, color: Colors.white),
                      tooltip: 'Chat-Verlauf',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  
                  // Zentrierter Text (expanded nimmt verfügbaren Platz)
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Ask Toni!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          t.chatbot_subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Neuer Chat Button rechts (feste Breite, nur wenn Chat aktiv)
                  if (_messages.isNotEmpty)
                    IconButton(
                      onPressed: _startNewChat,
                      icon: const Icon(Icons.edit_square, color: Color(0xFFFFB129)),
                      tooltip: 'Neuer Chat',
                      padding: EdgeInsets.zero,
                    )
                  else
                    // Platzhalter wenn kein Button (symmetrisch)
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Chat-Bereich
            Expanded(
              child: _messages.isEmpty 
                ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Toni Bild (größer und weiter oben)
                    Image.asset(
                      'assets/images/Toni_Mechatroni.png',
                      width: 250,
                      height: 250,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      t.chatbot_how_can_i_help,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.chatbot_ask_questions,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Vorschläge
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        t.chatbot_popular_questions,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SuggestionCard(
                      icon: Icons.warning_amber_rounded,
                      text: t.chatbot_question_engine_light,
                      onTap: () => _sendMessage(t.chatbot_question_engine_light),
                    ),
                    const SizedBox(height: 8),
                    _SuggestionCard(
                      icon: Icons.error_outline,
                      text: t.chatbot_question_error_code,
                      onTap: () => _sendMessage(t.chatbot_question_error_code),
                    ),
                    const SizedBox(height: 8),
                    _SuggestionCard(
                      icon: Icons.build_outlined,
                      text: t.chatbot_question_maintenance,
                      onTap: () => _sendMessage(t.chatbot_question_maintenance),
                    ),
                    const SizedBox(height: 8),
                    _SuggestionCard(
                      icon: Icons.hearing,
                      text: t.chatbot_question_noise,
                      onTap: () => _sendMessage(t.chatbot_question_noise),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (ctx, index) {
                      if (index == _messages.length) {
                        // "Toni denkt nach..." Animation
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Toni denkt nach',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _ThinkingDots(),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.symmetric(
                            horizontal: msg.isUser ? 16 : 0,
                            vertical: msg.isUser ? 12 : 0,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.85,
                          ),
                          decoration: msg.isUser
                              ? BoxDecoration(
                                  color: const Color(0xFFF8AD20),
                                  borderRadius: BorderRadius.circular(16),
                                )
                              : null, // Kein Container für Toni
                          child: msg.isUser
                              ? Text(
                                  msg.text,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                  ),
                                )
                              : MarkdownBody(
                                  data: msg.text,
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                    h1: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h2: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h3: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    h4: const TextStyle(
                                      color: Color(0xFFF8AD20),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    strong: const TextStyle(
                                      color: Color(0xFFF8AD20),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    listBullet: const TextStyle(
                                      color: Color(0xFFF8AD20),
                                    ),
                                    code: const TextStyle(
                                      backgroundColor: Color(0xFF1A1F26),
                                      color: Color(0xFFF8AD20),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
            ),

            // Eingabefeld fixiert am Boden
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF151C23),
                border: Border(
                  top: BorderSide(color: Colors.white12, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 40, // Dünner wenn leer
                        maxHeight: 120, // Max Höhe
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F26),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: null,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: t.tr('chatbot.input_hint'),
                          hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8AD20),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF8AD20).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => _sendMessage(_textController.text),
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      iconSize: 22,
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

class _ThinkingDots extends StatefulWidget {
  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final opacity = ((_controller.value + delay) % 1.0) < 0.5 ? 1.0 : 0.3;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Color(0xFFF8AD20).withOpacity(opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.icon, required this.text, required this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF151C23),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white12, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFFF57C00), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
