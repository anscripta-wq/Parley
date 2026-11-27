class UserProfile {
  final String id;
  final String handle;
  final String gender;
  final String country;
  final String nativeLang;
  final String learningLang;
  final String bio;
  final String? avatarUrl;
  final int streakCount;

  const UserProfile({
    required this.id,
    required this.handle,
    this.gender = 'Not specified',
    this.country = 'Pakistan',
    required this.nativeLang,
    required this.learningLang,
    required this.bio,
    this.avatarUrl,
    this.streakCount = 1,
  });

  factory UserProfile.fromMap(Map map) {
    final raw = (map['handle'] ?? '').toString().trim();
    return UserProfile(
      id: map['id'].toString(),
      handle: raw.startsWith('@') ? raw : '@$raw',
      gender: (map['gender'] ?? 'Not specified').toString(),
      country: (map['country'] ?? 'Pakistan').toString(),
      nativeLang: (map['native_lang'] ?? 'English (US) 🇺🇸').toString(),
      learningLang: (map['learning_lang'] ?? 'English (UK) 🇬🇧').toString(),
      bio: (map['bio'] ?? '').toString(),
      avatarUrl: map['avatar_url']?.toString(),
      streakCount: (map['streak_count'] as int?) ?? 1,
    );
  }

  String get initial {
    final c = handle.replaceFirst('@', '').trim();
    return c.isEmpty ? 'P' : c.substring(0, 1).toUpperCase();
  }

  String get countryFlag => countryToFlag(country);
}

class PostItem {
  final String id, userId, authorHandle, content;
  int likesCount, commentsCount;
  bool isLiked, isSaved;
  final DateTime createdAt;

  PostItem({required this.id, required this.userId, required this.authorHandle, required this.content, required this.likesCount, this.commentsCount = 0, this.isLiked = false, this.isSaved = false, required this.createdAt});

  factory PostItem.fromMap(Map map) {
    final raw = (map['author_handle'] ?? '@reader').toString().trim();
    return PostItem(
      id: map['id'].toString(),
      userId: (map['user_id'] ?? '').toString(),
      authorHandle: raw.startsWith('@') ? raw : '@$raw',
      content: (map['content'] ?? '').toString(),
      likesCount: (map['likes_count'] as int?) ?? 0,
      commentsCount: (map['comments_count'] as int?) ?? 0,
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString())?.toLocal() ?? DateTime.now(),
    );
  }

  String get initial => authorHandle.replaceFirst('@', '').isEmpty ? 'P' : authorHandle.replaceFirst('@', '').substring(0, 1).toUpperCase();
  String get timeAgo {
    final d = DateTime.now().difference(createdAt);
    if (d.inMinutes == 0) return 'Just now';
    if (d.inMinutes <= 59) return '${d.inMinutes}m ago';
    if (d.inHours <= 23) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

class CommentItem {
  final String id, postId, userId, authorHandle, content;
  final DateTime createdAt;
  CommentItem({required this.id, required this.postId, required this.userId, required this.authorHandle, required this.content, required this.createdAt});
  factory CommentItem.fromMap(Map map) {
    final raw = (map['author_handle'] ?? '@reader').toString().trim();
    return CommentItem(id: map['id'].toString(), postId: (map['post_id'] ?? '').toString(), userId: (map['user_id'] ?? '').toString(), authorHandle: raw.startsWith('@') ? raw : '@$raw', content: (map['content'] ?? '').toString(), createdAt: DateTime.tryParse((map['created_at'] ?? '').toString())?.toLocal() ?? DateTime.now());
  }
  String get initial => authorHandle.replaceFirst('@', '').isEmpty ? 'P' : authorHandle.replaceFirst('@', '').substring(0, 1).toUpperCase();
  String get timeAgo {
    final d = DateTime.now().difference(createdAt);
    if (d.inMinutes == 0) return 'Just now';
    if (d.inMinutes <= 59) return '${d.inMinutes}m ago';
    if (d.inHours <= 23) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

class ChatMessage {
  final String id, senderId, receiverId, text;
  final bool isVoiceNote;
  final String? audioUrl;
  final DateTime createdAt;
  ChatMessage({required this.id, required this.senderId, required this.receiverId, required this.text, this.isVoiceNote = false, this.audioUrl, required this.createdAt});
  factory ChatMessage.fromMap(Map map) => ChatMessage(id: map['id'].toString(), senderId: (map['sender_id'] ?? '').toString(), receiverId: (map['receiver_id'] ?? '').toString(), text: (map['text'] ?? '').toString(), isVoiceNote: (map['is_voice_note'] as bool?) ?? false, audioUrl: map['audio_url']?.toString(), createdAt: DateTime.tryParse((map['created_at'] ?? '').toString())?.toLocal() ?? DateTime.now());
}

const Map kCountryFlags = {'Australia': '🇦🇺', 'Bangladesh': '🇧🇩', 'Brazil': '🇧🇷', 'Canada': '🇨🇦', 'China': '🇨🇳', 'Egypt': '🇪🇬', 'France': '🇫🇷', 'Germany': '🇩🇪', 'India': '🇮🇳', 'Indonesia': '🇮🇩', 'Iran': '🇮🇷', 'Italy': '🇮🇹', 'Japan': '🇯🇵', 'Kenya': '🇰🇪', 'Malaysia': '🇲🇾', 'Mexico': '🇲🇽', 'Morocco': '🇲🇦', 'Nepal': '🇳🇵', 'Netherlands': '🇳🇱', 'New Zealand': '🇳🇿', 'Nigeria': '🇳🇬', 'Oman': '🇴🇲', 'Pakistan': '🇵🇰', 'Philippines': '🇵🇭', 'Poland': '🇵🇱', 'Qatar': '🇶🇦', 'Russia': '🇷🇺', 'Saudi Arabia': '🇸🇦', 'South Africa': '🇿🇦', 'South Korea': '🇰🇷', 'Spain': '🇪🇸', 'Sri Lanka': '🇱🇰', 'Sweden': '🇸🇪', 'Turkey': '🇹🇷', 'UAE': '🇦🇪', 'UK': '🇬🇧', 'Ukraine': '🇺🇦', 'USA': '🇺🇸', 'Vietnam': '🇻🇳'};
String countryToFlag(String c) => kCountryFlags[c] ?? '🌍';

const List kSupportedLanguages = ['English (US) 🇺🇸', 'English (UK) 🇬🇧', 'English (Australia) 🇦🇺', 'Arabic', 'Bengali', 'Chinese (Mandarin)', 'Dutch', 'Filipino', 'French', 'German', 'Greek', 'Gujarati', 'Hebrew', 'Hindi', 'Indonesian', 'Italian', 'Japanese', 'Korean', 'Malay', 'Marathi', 'Nepali', 'Persian', 'Polish', 'Portuguese', 'Punjabi', 'Russian', 'Spanish', 'Swahili', 'Swedish', 'Tamil', 'Telugu', 'Thai', 'Turkish', 'Ukrainian', 'Urdu', 'Vietnamese'];
String languageToIsoCode(String lang) {
  if (lang.startsWith('English')) return 'en';
  const m = {'Arabic': 'ar', 'Bengali': 'bn', 'Chinese (Mandarin)': 'zh-CN', 'Dutch': 'nl', 'Filipino': 'tl', 'French': 'fr', 'German': 'de', 'Greek': 'el', 'Gujarati': 'gu', 'Hebrew': 'iw', 'Hindi': 'hi', 'Indonesian': 'id', 'Italian': 'it', 'Japanese': 'ja', 'Korean': 'ko', 'Malay': 'ms', 'Marathi': 'mr', 'Nepali': 'ne', 'Persian': 'fa', 'Polish': 'pl', 'Portuguese': 'pt', 'Punjabi': 'pa', 'Russian': 'ru', 'Spanish': 'es', 'Swahili': 'sw', 'Swedish': 'sv', 'Tamil': 'ta', 'Telugu': 'te', 'Thai': 'th', 'Turkish': 'tr', 'Ukrainian': 'uk', 'Urdu': 'ur', 'Vietnamese': 'vi'};
  return m[lang] ?? 'en';
}
