import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quizwiz/src/core/services/attachment_storage.dart';
import 'package:quizwiz/src/core/utils/media_url.dart';
import 'package:quizwiz/src/features/cards/data/data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class CardAttachmentsView extends StatelessWidget {
  final List<CardAttachment> attachments;
  const CardAttachmentsView({super.key, required this.attachments});

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return Column(
      children: attachments
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AttachmentTile(attachment: item),
              ))
          .toList(),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final CardAttachment attachment;
  const _AttachmentTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    switch (attachment.type) {
      case 'video':
        return _VideoTile(attachment: attachment);
      case 'audio':
        return _AudioTile(attachment: attachment);
      case 'embed':
        return _EmbedTile(attachment: attachment);
      default:
        return _ImageTile(attachment: attachment);
    }
  }
}

class _ImageTile extends StatelessWidget {
  final CardAttachment attachment;
  const _ImageTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _image(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
              height: 120, child: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data!;
      },
    );
  }

  Future<Widget> _image(BuildContext context) async {
    ImageProvider provider;
    if (attachment.isRemote) {
      provider = NetworkImage(attachment.source);
    } else {
      final path = await AttachmentStorage.absolutePath(attachment.source);
      provider = FileImage(File(path));
    }
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _ImageZoomPage(
            provider: provider,
            title: attachment.fileName,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image(
          image: provider,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ListTile(
            leading: Icon(Icons.broken_image),
            title: Text('Không tải được ảnh'),
          ),
        ),
      ),
    );
  }
}

class _ImageZoomPage extends StatelessWidget {
  final ImageProvider provider;
  final String title;
  const _ImageZoomPage({required this.provider, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontSize: 14)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Image(image: provider),
        ),
      ),
    );
  }
}

class _PlayLimitGate extends StatefulWidget {
  final CardAttachment attachment;
  final Widget Function(bool canPlay, int remaining, VoidCallback onPlay)
      builder;
  const _PlayLimitGate({required this.attachment, required this.builder});

  @override
  State<_PlayLimitGate> createState() => _PlayLimitGateState();
}

class _PlayLimitGateState extends State<_PlayLimitGate> {
  int _plays = 0;

  @override
  Widget build(BuildContext context) {
    final unlimited = widget.attachment.isUnlimited;
    final remaining =
        unlimited ? -1 : (widget.attachment.playLimit - _plays).clamp(0, 999);
    final canPlay = unlimited || remaining > 0;
    return widget.builder(canPlay, remaining, () {
      if (!canPlay) return;
      setState(() => _plays++);
    });
  }
}

class _AudioTile extends StatefulWidget {
  final CardAttachment attachment;
  const _AudioTile({required this.attachment});

  @override
  State<_AudioTile> createState() => _AudioTileState();
}

class _AudioTileState extends State<_AudioTile>
    with AutomaticKeepAliveClientMixin {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  late final StreamSubscription<void> _completionSubscription;

  @override
  bool get wantKeepAlive => _playing;

  @override
  void initState() {
    super.initState();
    _completionSubscription = _player.onPlayerComplete.listen((_) {
      _setPlaying(false);
    });
  }

  @override
  void dispose() {
    unawaited(_completionSubscription.cancel());
    _player.dispose();
    super.dispose();
  }

  void _setPlaying(bool playing) {
    if (!mounted) return;
    setState(() => _playing = playing);
    updateKeepAlive();
  }

  Future<void> _toggle(bool canPlay, VoidCallback onPlay) async {
    if (_playing) {
      await _player.stop();
      _setPlaying(false);
      return;
    }
    if (!canPlay) return;
    onPlay();
    _setPlaying(true);
    var started = false;
    try {
      if (widget.attachment.isRemote) {
        await _player.play(UrlSource(widget.attachment.source));
      } else {
        final path =
            await AttachmentStorage.absolutePath(widget.attachment.source);
        await _player.play(DeviceFileSource(path));
      }
      started = true;
    } finally {
      if (!started) _setPlaying(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _PlayLimitGate(
      attachment: widget.attachment,
      builder: (canPlay, remaining, onPlay) {
        return Card(
          child: ListTile(
            leading: Icon(_playing ? Icons.stop : Icons.audiotrack),
            title: Text(widget.attachment.fileName.isEmpty
                ? 'Audio'
                : widget.attachment.fileName),
            subtitle: Text(
              widget.attachment.isUnlimited
                  ? 'Phát không giới hạn'
                  : canPlay
                      ? 'Còn $remaining lần phát'
                      : 'Đã hết lượt phát',
            ),
            trailing: IconButton(
              onPressed:
                  canPlay || _playing ? () => _toggle(canPlay, onPlay) : null,
              icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
            ),
          ),
        );
      },
    );
  }
}

class _VideoTile extends StatefulWidget {
  final CardAttachment attachment;
  const _VideoTile({required this.attachment});

  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  VideoPlayerController? _controller;
  bool _unsupported = false;
  int _sessionPlays = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (kIsWeb) {
      setState(() => _unsupported = true);
      return;
    }
    if (!(Platform.isAndroid || Platform.isIOS)) {
      setState(() => _unsupported = true);
      return;
    }
    try {
      if (widget.attachment.isRemote) {
        _controller = VideoPlayerController.networkUrl(
            Uri.parse(widget.attachment.source));
      } else {
        final path =
            await AttachmentStorage.absolutePath(widget.attachment.source);
        _controller = VideoPlayerController.file(File(path));
      }
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _unsupported = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  bool get _canPlay {
    if (widget.attachment.isUnlimited) return true;
    return _sessionPlays < widget.attachment.playLimit;
  }

  Future<void> _toggle() async {
    final controller = _controller;
    if (controller == null) {
      final uri = widget.attachment.isRemote
          ? Uri.parse(widget.attachment.source)
          : Uri.file(
              await AttachmentStorage.absolutePath(widget.attachment.source));
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
      setState(() {});
      return;
    }
    if (!_canPlay) return;
    setState(() => _sessionPlays++);
    await controller.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.attachment.isUnlimited
        ? null
        : (widget.attachment.playLimit - _sessionPlays).clamp(0, 999);
    if (_unsupported ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.videocam),
          title: Text(widget.attachment.fileName.isEmpty
              ? 'Video'
              : widget.attachment.fileName),
          subtitle: Text(
            remaining == null
                ? 'Mở video'
                : _canPlay
                    ? 'Còn $remaining lần phát'
                    : 'Đã hết lượt phát',
          ),
          trailing: IconButton(
            onPressed: _canPlay ? _toggle : null,
            icon: const Icon(Icons.open_in_new),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio == 0
              ? 16 / 9
              : _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        Row(
          children: [
            IconButton(
              onPressed:
                  _canPlay || _controller!.value.isPlaying ? _toggle : null,
              icon: Icon(_controller!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow),
            ),
            Expanded(
              child: Text(
                remaining == null
                    ? 'Phát không giới hạn'
                    : _canPlay
                        ? 'Còn $remaining lần phát'
                        : 'Đã hết lượt phát',
              ),
            ),
          ],
        )
      ],
    );
  }
}

class _EmbedTile extends StatelessWidget {
  final CardAttachment attachment;
  const _EmbedTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final thumb = MediaUrl.youtubeThumbnail(attachment.source);
    if (MediaUrl.isImage(attachment.source)) {
      return _ImageTile(attachment: attachment);
    }
    if (MediaUrl.isAudio(attachment.source)) {
      return _AudioTile(attachment: attachment);
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(attachment.source),
            mode: LaunchMode.externalApplication),
        child: Column(
          children: [
            if (thumb != null)
              Image.network(
                thumb,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(attachment.fileName.isEmpty
                  ? attachment.source
                  : attachment.fileName),
              subtitle: const Text('Nhấn để mở liên kết'),
              trailing: const Icon(Icons.open_in_new),
            ),
          ],
        ),
      ),
    );
  }
}
