import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../features/content_library/data/real_content_library_repository.dart';
import '../network/api_exception.dart';
import '../theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Paylaşımlı tam ekran medya oynatıcı - hem içerik kütüphanesi hem
/// gelişim takibi medyası (bkz.
/// docs/superpowers/specs/2026-09-20-progress-media-design.md'nin "content-
/// library'nin oynatıcı bileşeni yeniden kullanılır" notu) tarafından
/// kullanılır. Video için video_player (kimlik doğrulamalı URL +
/// Authorization header), görsel için dio ile indirilen byte'lar üzerinden
/// Image.memory kullanılır - GET /api/media/{id} her iki durumda da aynı,
/// kimlik doğrulamalı endpoint.
class MediaPlayerScreen extends ConsumerWidget {
  const MediaPlayerScreen({required this.mediaFileId, required this.mediaContentType, required this.title, super.key});

  final int mediaFileId;
  final String mediaContentType;
  final String title;

  bool get _isVideo => mediaContentType.startsWith('video/');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Center(
          child: _isVideo
              ? _VideoPlayerView(mediaFileId: mediaFileId, l10n: l10n)
              : _ImageView(mediaFileId: mediaFileId, l10n: l10n),
        ),
      ),
    );
  }
}

class _VideoPlayerView extends ConsumerStatefulWidget {
  const _VideoPlayerView({required this.mediaFileId, required this.l10n});

  final int mediaFileId;
  final AppLocalizations l10n;

  @override
  ConsumerState<_VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends ConsumerState<_VideoPlayerView> {
  VideoPlayerController? _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final repository = ref.read(contentLibraryRepositoryProvider);
      final headers = await repository.mediaAuthHeaders();
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(repository.mediaUrl(widget.mediaFileId)),
        httpHeaders: headers,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      controller.play();
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => _errorMessage = exception.localizedMessage(context));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = widget.l10n.commonError);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Text(_errorMessage!, style: const TextStyle(color: Colors.white));
    }
    final controller = _controller;
    if (controller == null) {
      return const CircularProgressIndicator(color: AppColors.primary);
    }
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(controller),
          _PlayPauseOverlay(controller: controller),
        ],
      ),
    );
  }
}

class _PlayPauseOverlay extends StatefulWidget {
  const _PlayPauseOverlay({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_PlayPauseOverlay> createState() => _PlayPauseOverlayState();
}

class _PlayPauseOverlayState extends State<_PlayPauseOverlay> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.controller.value.isPlaying ? widget.controller.pause() : widget.controller.play(),
      child: AnimatedOpacity(
        opacity: widget.controller.value.isPlaying ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: const Icon(Icons.play_circle_outline, color: Colors.white70, size: 64),
      ),
    );
  }
}

class _ImageView extends ConsumerWidget {
  const _ImageView({required this.mediaFileId, required this.l10n});

  final int mediaFileId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<int>>(
      future: ref.read(contentLibraryRepositoryProvider).downloadMediaBytes(mediaFileId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator(color: AppColors.primary);
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return Text(
            error is ApiException ? error.localizedMessage(context) : l10n.commonError,
            style: const TextStyle(color: Colors.white),
          );
        }
        return InteractiveViewer(
          child: Image.memory(Uint8List.fromList(snapshot.data!)),
        );
      },
    );
  }
}
