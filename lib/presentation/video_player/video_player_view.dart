import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallaerial/domain/entities/video_entity.dart';
import 'package:gallaerial/extensions/color_extension.dart';
import 'package:gallaerial/main.dart';
import 'package:gallaerial/presentation/common/inline_editable_text.dart';
import 'package:gallaerial/presentation/video_edit/video_edit_view.dart';
import 'package:gallaerial/presentation/video_player/video_player_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:collection/collection.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  final VideoEntity videoEntity;

  const FullScreenVideoPlayer({super.key, required this.videoEntity});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  double _volumeBeforeMute = 1.0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final AssetEntity? asset = await AssetEntity.fromId(widget.videoEntity.assetId);

    if (asset == null) return;

    final File? videoFile = await asset.file;
    if (videoFile == null) return;

    _controller = VideoPlayerController.file(videoFile);
    try {
      await _controller.initialize();
      _controller.addListener(_videoListener);
      setState(() {
        _isInitialized = true;
      });
      _controller.play();
      _startHideControlsTimer();
    } catch (e) {
      debugPrint("Error initializing video player: $e");
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _videoListener() {
    if (mounted) setState(() {});
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _hideControlsTimer?.cancel();
        _showControls = true;
      } else {
        _controller.play();
        _startHideControlsTimer();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      if (_controller.value.volume > 0) {
        _volumeBeforeMute = _controller.value.volume;
        _controller.setVolume(0.0);
      } else {
        _controller.setVolume(_volumeBeforeMute > 0 ? _volumeBeforeMute : 1.0);
      }
      _resetHideControlsTimer();
    });
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _resetHideControlsTimer() {
    if (_showControls && _controller.value.isPlaying) {
      _startHideControlsTimer();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "${duration.inMinutes}:$twoDigitSeconds";
  }

  // ===========================================================================
  // WIDGET BUILDERS (Extracted to keep build() clean)
  // ===========================================================================

  Widget _buildVideoLayer() {
    return Center(
      child: _isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          : const CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildControlsOverlay(BuildContext context, VideoPlayerState state) {
    if (!_isInitialized) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !_showControls, // Prevent taps when hidden
        child: Stack(
          children: [
            _buildGradientBackground(),
            _buildTagsList(context, state),
            _buildTopBackButton(context),
            _buildNameEditor(context, state),
            _buildCenterPlayPause(),
            _buildBottomControls(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent, Colors.transparent, Colors.black87],
          stops: [0.0, 0.2, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildTagsList(BuildContext context, VideoPlayerState state) {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color.fromARGB(195, 0, 0, 0), Colors.transparent],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 60, left: 20),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (_) => showDialog(
              context: context, 
              builder: (context) => VideoEditView(initialVideo: state.videoEntity!)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 25,
            children: state.videoEntity!.tagIds.where((tagId) => state.allTags.any((tag) => tag.id == tagId))
                .map((tagId) => _tagElement(tagId, state))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _tagElement(String tagId, VideoPlayerState state) {
    var tag = state.allTags.firstWhereOrNull((t) => t.id == tagId);
    if (tag == null) return Container(width: 20, height: 20, color: Colors.blue);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tag.color.toColor().withAlpha(180),
            boxShadow: [
              BoxShadow(
                blurRadius: 5,
                spreadRadius: 0.001,
                color: Theme.of(context).colorScheme.shadow.withAlpha(100),
                offset: const Offset(0, 2),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            tag.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTopBackButton(BuildContext context) {
    return Positioned(
      top: -10,
      left: 10,
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 30),
        onPressed: () => Navigator.of(context).pop(), // Exit full screen
      ),
    );
  }

  Widget _buildNameEditor(BuildContext context, VideoPlayerState state) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 240,
        child: InlineEditableText(
          initialText: state.videoEntity!.name,
          limit: 24,
          onTextChanged: (text) => context
              .read<VideoPlayerBloc>()
              .add(EditVideoNameEvent(newName: text)),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildCenterPlayPause() {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: IconButton(
        iconSize: 50,
        icon: Icon(
          _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
          color: Colors.white.withAlpha(204),
        ),
        onPressed: _togglePlay,
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTapDown: (_) => _hideControlsTimer?.cancel(),
            onTapUp: (_) => _resetHideControlsTimer(),
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Theme.of(context).colorScheme.primary,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.grey,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                IconButton(
                  icon: Icon(
                    _controller.value.volume > 0 ? Icons.volume_up : Icons.volume_off,
                    color: Colors.white,
                  ),
                  onPressed: _toggleMute,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MAIN BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => service<VideoPlayerBloc>()
        ..add(InitializeWithVideoEvent(videoEntity: widget.videoEntity)),
      child: BlocBuilder<VideoPlayerBloc, VideoPlayerState>(
        builder: (context, state) {
          if (state.videoEntity == null) return const SizedBox.shrink();

          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showControls = !_showControls;
                    if (_showControls) {
                      _resetHideControlsTimer();
                    }
                  });
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildVideoLayer(),
                    _buildControlsOverlay(context, state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}