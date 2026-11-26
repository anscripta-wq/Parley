class UserProfile {
  final String id;
  final String handle;
  final String nativeLang;
  final String learningLang;
  final String bio;
  final String? avatarUrl;
  final int streakCount;

  const UserProfile({
    required this.id,
    required this.handle,
    required this.nativeLang,
    required this.learningLang,
    required this.bio,
    this.avatarUrl,
    this.streakCount = 1,
  });

  factory UserProfile.fromMap(Map map) {
    final rawHandle = (map['handle'] ?? '').toString().trim();
    final formattedHandle = rawHandle.startsWith('@') ? rawHandle : '@$rawHandle';
    return UserProfile(
      id: map['id'].toString(),
      handle: formattedHandle,
      nativeLang: (map['native_lang'] ?? 'English').toString(),
      learningLang: (map['learning_lang'] ?? 'Spanish').toString(),
      bio: (map['bio'] ?? '').toString(),
      avatarUrl: map['avatar_url']?.toString(),
      streakCount: (map['streak_count'] as int?) ?? 1,
    );
  }

  String get initial {
    final clean = handle.replaceFirst('@', '').trim();
    return clean.isEmpty ? 'P' : clean.substring(0, 1).toUpperCase();
  }
}

class PostItem {
  final String id;
  final String userId;
  final String authorHandle;
  final String content;
  int likesCount;
  int commentsCount;
  bool isLiked;
  bool isSaved;
  final DateTime createdAt;

  PostItem({
    required this.id,
    required this.userId,
    required this.authorHandle,
    required this.content,
    required this.likesCount,
    this.commentsCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    required this.createdAt,
  });

  factory PostItem.fromMap(Map map) {
    final rawHandle = (map['author_handle'] ?? '@reader').toString().trim();
    final formattedHandle = rawHandle.startsWith('@') ? rawHandle : '@$rawHandle';
    return PostItem(
      id: map['id'].toString(),
      userId: (map['user_id'] ?? '').toString(),
      authorHandle: formattedHandle,
      content: (map['content'] ?? '').toString(),
      likesCount: (map['likes_count'] as int?) ?? 0,
      commentsCount: (map['comments_count'] as int?) ?? 0,
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString())?.toLocal() ?? DateTime.now(),
    );
  }

  String get initial {
    final clean = authorHandle.replaceFirst('@', '').trim();
    return clean.isEmpty ? 'P' : clean.substring(0, 1).toUpperCase();
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes == 0) return 'Just now';
    if (diff.inMinutes <= 59) return '${diff.inMinutes}m ago';
    if (diff.inHours <= 23) return '${diff.inHours}h ago';
    if (diff.inDays <= 6) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

class CommentItem {
  final String id;
  final String postId;
  final String userId;
  final String authorHandle;
  final String content;
  final DateTime createdAt;

  CommentItem({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorHandle,
    required this.content,
    required this.createdAt,
  });

  factory CommentItem.fromMap(Map map) {
    final rawHandle = (map['author_handle'] ?? '@reader').toString().trim();
    final formattedHandle = rawHandle.startsWith('@') ? rawHandle : '@$rawHandle';
    return CommentItem(
      id: map['id'].toString(),
      postId: (map['post_id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      authorHandle: formattedHandle,
      content: (map['content'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString())?.toLocal() ?? DateTime.now(),
    );
  }

  String get initial {
    final clean = authorHandle.replaceFirst('@', '').trim();
    return clean.isEmpty ? 'P' : clean.substring(0, 1).toUpperCase();
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes == 0) return 'Just now';
    if (diff.inMinutes <= 59) return '${diff.inMinutes}m ago';
    if (diff.inHours <= 23) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final bool isVoiceNote;
  final String? audioUrl;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.isVoiceNote = false,
    this.audioUrl,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map map) {
    return ChatMessage(
      id: map['id'].toString(),
      senderId: (map['sender_id'] ?? '').toString(),
      receiverId: (map['receiver_id'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
      isVoiceNote: (map['is_voice_note'] as bool?) ?? false,
      audioUrl: map['audio_url']?.toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString())?.toLocal() ?? DateTime.now(),
    );
  }
}

String languageToIsoCode(String lang) {
  const map = {
    'Afrikaans': 'af', 'Albanian': 'sq', 'Amharic': 'am', 'Arabic': 'ar',
    'Armenian': 'hy', 'Azerbaijani': 'az', 'Bengali': 'bn', 'Bulgarian': 'bg',
    'Burmese': 'my', 'Catalan': 'ca', 'Chinese (Mandarin)': 'zh-CN',
    'Croatian': 'hr', 'Czech': 'cs', 'Danish': 'da', 'Dutch': 'nl',
    'English': 'en', 'Estonian': 'et', 'Filipino': 'tl', 'Finnish': 'fi',
    'French': 'fr', 'Georgian': 'ka', 'German': 'de', 'Greek': 'el',
    'Gujarati': 'gu', 'Hebrew': 'iw', 'Hindi': 'hi', 'Hungarian': 'hu',
    'Icelandic': 'is', 'Indonesian': 'id', 'Irish': 'ga', 'Italian': 'it',
    'Japanese': 'ja', 'Kannada': 'kn', 'Kazakh': 'kk', 'Khmer': 'km',
    'Korean': 'ko', 'Lao': 'lo', 'Latvian': 'lv', 'Lithuanian': 'lt',
    'Macedonian': 'mk', 'Malay': 'ms', 'Malayalam': 'ml', 'Maltese': 'mt',
    'Marathi': 'mr', 'Mongolian': 'mn', 'Nepali': 'ne', 'Norwegian': 'no',
    'Persian': 'fa', 'Polish': 'pl', 'Portuguese': 'pt', 'Punjabi': 'pa',
    'Romanian': 'ro', 'Russian': 'ru', 'Serbian': 'sr', 'Sinhala': 'si',
    'Slovak': 'sk', 'Slovenian': 'sl', 'Somali': 'so', 'Spanish': 'es',
    'Swahili': 'sw', 'Swedish': 'sv', 'Tamil': 'ta', 'Telugu': 'te',
    'Thai': 'th', 'Turkish': 'tr', 'Ukrainian': 'uk', 'Urdu': 'ur',
    'Uzbek': 'uz', 'Vietnamese': 'vi', 'Welsh': 'cy', 'Zulu': 'zu',
  };
  return map[lang] ?? 'en';
}

const List kSupportedLanguages = [
  'Afrikaans', 'Albanian', 'Amharic', 'Arabic', 'Armenian', 'Azerbaijani',
  'Bengali', 'Bulgarian', 'Burmese', 'Catalan', 'Chinese (Mandarin)',
  'Croatian', 'Czech', 'Danish', 'Dutch', 'English', 'Estonian', 'Filipino',
  'Finnish', 'French', 'Georgian', 'German', 'Greek', 'Gujarati', 'Hebrew',
  'Hindi', 'Hungarian', 'Icelandic', 'Indonesian', 'Irish', 'Italian',
  'Japanese', 'Kannada', 'Kazakh', 'Khmer', 'Korean', 'Lao', 'Latvian',
  'Lithuanian', 'Macedonian', 'Malay', 'Malayalam', 'Maltese', 'Marathi',
  'Mongolian', 'Nepali', 'Norwegian', 'Persian', 'Polish', 'Portuguese',
  'Punjabi', 'Romanian', 'Russian', 'Serbian', 'Sinhala', 'Slovak',
  'Slovenian', 'Somali', 'Spanish', 'Swahili', 'Swedish', 'Tamil', 'Telugu',
  'Thai', 'Turkish', 'Ukrainian', 'Urdu', 'Uzbek', 'Vietnamese', 'Welsh', 'Zulu',
];
