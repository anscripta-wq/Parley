import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_models.dart';
import '../../services/supabase_client.dart';
import '../../widgets/common_widgets.dart';
import '../partners/partners_screen.dart';

class MessagesScreen extends StatefulWidget {
  final UserProfile currentProfile;

  const MessagesScreen({super.key, required this.currentProfile});

  @override
  State createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State {
  String _searchQuery = '';
  bool _isLoading = true;
  List _threads = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    if (_channel != null) {
      supabase.removeChannel(_channel!);
    }
    super.dispose();
  }

  void _subscribeRealtime() {
    final w = widget as MessagesScreen;
    final myId = w.currentProfile.id;
    _channel = supabase.channel('inbox_$myId').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final record = payload.newRecord;
        if (record['sender_id'] == myId || record['receiver_id'] == myId) {
          if (record['receiver_id'] == myId) {
            SystemSound.play(SystemSoundType.alert);
            HapticFeedback.mediumImpact();
          }
          _loadConversations();
        }
      },
    ).subscribe();
  }

  Future _loadConversations() async {
    final w = widget as MessagesScreen;
    try {
      final myId = w.currentProfile.id;
      final msgs = await supabase
          .from('messages')
          .select()
          .or('sender_id.eq.$myId,receiver_id.eq.$myId')
          .order('created_at', ascending: false);

      final latestByPartner = {};
      for (final raw in (msgs as List)) {
        final msg = raw as Map;
        final partnerId = msg['sender_id'] == myId
            ? msg['receiver_id'].toString()
            : msg['sender_id'].toString();
        latestByPartner.putIfAbsent(partnerId, () => msg);
      }

      if (latestByPartner.isEmpty) {
        if (mounted) {
          setState(() {
            _threads = [];
            _isLoading = false;
          });
        }
        return;
      }

      final profilesRows = await supabase
          .from('profiles')
          .select()
          .inFilter('id', latestByPartner.keys.map((k) => k.toString()).toList());

      final profilesMap = {};
      for (final p in (profilesRows as List)) {
        final up = UserProfile.fromMap(p as Map);
        profilesMap[up.id] = up;
      }

      final built = [];
      for (final entry in latestByPartner.entries) {
        final partner = profilesMap[entry.key];
        if (partner != null) {
          built.add({
            'partner': partner,
            'lastMessage': (entry.value['text'] ?? '').toString(),
          });
        }
      }

      if (mounted) {
        setState(() {
          _threads = built;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as MessagesScreen;
    final filtered = _threads.where((t) {
      final partner = t['partner'] as UserProfile;
      return _searchQuery.isEmpty ||
          partner.handle.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Correspondence'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadConversations),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search letters...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'No conversations yet.\nGo to the Partners tab to message a fellow reader.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 15),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final partner = filtered[index]['partner'] as UserProfile;
                      final lastMessage = filtered[index]['lastMessage'] as String;

                      return ListTile(
                        leading: ParleyAvatar(profile: partner),
                        title: Text(partner.handle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(
                          partner.nativeLang,
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                currentProfile: w.currentProfile,
                                partner: partner,
                              ),
                            ),
                          );
                          _loadConversations();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final UserProfile currentProfile;
  final UserProfile partner;

  const ChatScreen({
    super.key,
    required this.currentProfile,
    required this.partner,
  });

  @override
  State createState() => _ChatScreenState();
}

class _ChatScreenState extends State {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List _messages = [];
  final Map _translations = {};
  final Set _translatingIds = {};
  bool _isLoading = true;
  RealtimeChannel? _chatChannel;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToChat();
  }

  @override
  void dispose() {
    if (_chatChannel != null) {
      supabase.removeChannel(_chatChannel!);
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _subscribeToChat() {
    final w = widget as ChatScreen;
    final myId = w.currentProfile.id;
    final otherId = w.partner.id;

    _chatChannel = supabase.channel('chat_${myId}_$otherId').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final r = payload.newRecord;
        final isRelevant = (r['sender_id'] == myId && r['receiver_id'] == otherId) ||
            (r['sender_id'] == otherId && r['receiver_id'] == myId);
        if (isRelevant && mounted) {
          final incoming = ChatMessage.fromMap(r);
          if (!_messages.any((m) => (m as ChatMessage).id == incoming.id)) {
            if (incoming.senderId == otherId) {
              SystemSound.play(SystemSoundType.click);
              HapticFeedback.lightImpact();
            }
            setState(() => _messages.add(incoming));
            _scrollToBottom();
          }
        }
      },
    ).subscribe();
  }

  Future _loadMessages() async {
    final w = widget as ChatScreen;
    final myId = w.currentProfile.id;
    final otherId = w.partner.id;

    try {
      final rows = await supabase
          .from('messages')
          .select()
          .or(
            'and(sender_id.eq.$myId,receiver_id.eq.$otherId),and(sender_id.eq.$otherId,receiver_id.eq.$myId)',
          )
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages = (rows as List).map((r) => ChatMessage.fromMap(r as Map)).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future _sendMessage() async {
    final w = widget as ChatScreen;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    HapticFeedback.lightImpact();

    try {
      await supabase.from('messages').insert({
        'sender_id': w.currentProfile.id,
        'receiver_id': w.partner.id,
        'text': text,
        'is_voice_note': false,
      });
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  Future _toggleTranslate(ChatMessage msg) async {
    if (_translations.containsKey(msg.id)) {
      setState(() => _translations.remove(msg.id));
      return;
    }
    if (_translatingIds.contains(msg.id)) return;

    final w = widget as ChatScreen;
    final isMine = msg.senderId == w.currentProfile.id;
    final targetLangName = isMine ? w.partner.nativeLang : w.currentProfile.nativeLang;
    final targetCode = languageToIsoCode(targetLangName);

    setState(() => _translatingIds.add(msg.id));

    try {
      final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
        'client': 'gtx',
        'sl': 'auto',
        'tl': targetCode,
        'dt': 't',
        'q': msg.text,
      });
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List;
        final segments = decoded[0] as List;
        final buffer = StringBuffer();
        for (final seg in segments) {
          buffer.write((seg as List)[0].toString());
        }
        if (mounted) {
          setState(() {
            _translations[msg.id] = '$targetLangName: ${buffer.toString()}';
            _translatingIds.remove(msg.id);
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _translations[msg.id] = 'Could not reach translation service right now.';
        _translatingIds.remove(msg.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as ChatScreen;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PartnerDetailScreen(
                  currentProfile: w.currentProfile,
                  partner: w.partner,
                ),
              ),
            );
          },
          child: Row(
            children: [
              ParleyAvatar(profile: w.partner, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.partner.handle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      'Speaks ${w.partner.nativeLang} • Learning ${w.partner.learningLang}',
                      style: TextStyle(fontSize: 11, color: Theme.of(context).disabledColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PartnerDetailScreen(
                    currentProfile: w.currentProfile,
                    partner: w.partner,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet.\nWrite your first letter to ${w.partner.handle}!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).disabledColor),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index] as ChatMessage;
                      final isMe = msg.senderId == w.currentProfile.id;
                      final translated = _translations[msg.id];
                      final isTranslating = _translatingIds.contains(msg.id);

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                                  fontSize: 15,
                                ),
                              ),
                              if (translated != null) ...[
                                const Divider(height: 10),
                                Text(
                                  translated.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: isMe ? Colors.white70 : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: isTranslating
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 1.5),
                                      )
                                    : InkWell(
                                        onTap: () => _toggleTranslate(msg),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.translate,
                                              size: 14,
                                              color: isMe ? Colors.white70 : Theme.of(context).disabledColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              translated != null ? 'Hide' : 'Translate',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isMe ? Colors.white70 : Theme.of(context).disabledColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Write a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF3E2F2F),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
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
