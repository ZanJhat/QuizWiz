class MediaUrl {
  static bool isImage(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.png') ||
        lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.gif') ||
        lower.contains('.webp') ||
        lower.contains('.bmp');
  }

  static bool isAudio(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp3') ||
        lower.contains('.wav') ||
        lower.contains('.m4a') ||
        lower.contains('.aac') ||
        lower.contains('.ogg');
  }

  static bool isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.webm') ||
        lower.contains('.mkv') ||
        youtubeId(url) != null;
  }

  static String guessType(String url) {
    if (isImage(url)) return 'image';
    if (isAudio(url)) return 'audio';
    if (isVideo(url)) return 'video';
    return 'embed';
  }

  static String? youtubeId(String url) {
    final patterns = [
      RegExp(r'youtu\.be\/([A-Za-z0-9_-]{6,})'),
      RegExp(r'youtube\.com\/watch\?v=([A-Za-z0-9_-]{6,})'),
      RegExp(r'youtube\.com\/embed\/([A-Za-z0-9_-]{6,})'),
      RegExp(r'youtube\.com\/shorts\/([A-Za-z0-9_-]{6,})'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static String? youtubeThumbnail(String url) {
    final id = youtubeId(url);
    if (id == null) return null;
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }
}
