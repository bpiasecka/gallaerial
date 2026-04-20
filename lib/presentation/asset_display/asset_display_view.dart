import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/extensions/color_extension.dart';
import 'package:gallaerial/main.dart';
import 'package:gallaerial/presentation/asset_display/asset_display_bloc.dart';
import 'package:gallaerial/presentation/asset_tags_edit/asset_edit_view.dart';
import 'package:gallaerial/presentation/common/inline_editable_text.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class FullScreenAssetViewer extends StatefulWidget {
  final UserAssetEntity initialAsset;
  final bool isActive;

  const FullScreenAssetViewer({
    super.key, 
    required this.initialAsset, 
    this.isActive = true,
  });

  @override
  State<FullScreenAssetViewer> createState() => _FullScreenAssetViewerState();
}

class _FullScreenAssetViewerState extends State<FullScreenAssetViewer> {
  bool _isInitializing = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  File? _mediaFile;

  VideoPlayerController? _controller;
  double _volumeBeforeMute = 1.0;

  @override
  void didUpdateWidget(covariant FullScreenAssetViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller != null && _controller!.value.isInitialized) {
      if (widget.isActive && !oldWidget.isActive) {
        _controller!.play();
        _startHideControlsTimer();
      } else if (!widget.isActive && oldWidget.isActive) {
        _controller!.pause();
        _hideControlsTimer?.cancel();
      }
    }
  }

  Future<void> _initializeMedia(UserAssetEntity entity) async {
    if (_isInitializing) return;
    _isInitializing = true;

    final AssetEntity? pickerAsset = await AssetEntity.fromId(entity.assetId);
    if (pickerAsset == null) return;

    final File? file = await pickerAsset.file;
    if (file == null) return;

    if (mounted) setState(() => _mediaFile = file);

    if (entity is VideoEntity) {
      final newController = VideoPlayerController.file(file);
      try {
        await newController.initialize();
        newController.addListener(() { if (mounted) setState(() {}); });

        if (mounted) {
          setState(() => _controller = newController);
          if (widget.isActive) {
            _controller!.play();
            _startHideControlsTimer();
          }
        }
      } catch (e) {
        debugPrint("Error initializing video: $e");
      }
    } else {
      _startHideControlsTimer();
    }

    _isInitializing = false;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  // --- TIMERS ---
  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (widget.initialAsset is VideoEntity && _controller != null && !_controller!.value.isPlaying) {
        return; 
      }
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _resetHideControlsTimer() {
    if (_showControls) _startHideControlsTimer();
  }

  void _togglePlay() {
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _hideControlsTimer?.cancel();
        _showControls = true;
      } else {
        _controller!.play();
        _startHideControlsTimer();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      if (_controller!.value.volume > 0) {
        _volumeBeforeMute = _controller!.value.volume;
        _controller!.setVolume(0.0);
      } else {
        _controller!.setVolume(_volumeBeforeMute > 0 ? _volumeBeforeMute : 1.0);
      }
      _resetHideControlsTimer();
    });
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => dependencyService<AssetDisplayBloc>()
        ..add(InitializeAssetEvent(initialAsset: widget.initialAsset)),
      child: BlocConsumer<AssetDisplayBloc, AssetDisplayState>(
        listener: (context, state) {
          if (state.asset != null && _mediaFile == null && !_isInitializing) {
            _initializeMedia(state.asset!);
          }
        },
        builder: (context, state) {
          if (state.asset == null) {
            return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
          }

          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showControls = !_showControls;
                    _resetHideControlsTimer();
                  });
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildMediaLayer(state.asset!),
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

  // --- LAYER ROUTING (Pattern Matching) ---
  Widget _buildMediaLayer(UserAssetEntity asset) {
    if (_mediaFile == null) return const Center(child: CircularProgressIndicator(color: Colors.white));

    switch (asset) {
      case ImageEntity _:
        return Center(child: Image.file(_mediaFile!, fit: BoxFit.contain));
      case VideoEntity _:
        return Center(
          child: _controller != null && _controller!.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                )
              : const CircularProgressIndicator(color: Colors.white),
        );
    }
  }

  Widget _buildControlsOverlay(BuildContext context, AssetDisplayState state) {
    if (_isInitializing) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !_showControls,
        child: Stack(
          children: [
            // Shared Overlays
            _buildGradientBackground(), // Keep your existing method
            _buildTagsList(context, state), // Keep your existing method
            _buildTopBackButton(context), // Keep your existing method
            _buildNameEditor(context, state), // Keep your existing method

            // Video-Specific Overlays
            if (state.asset is VideoEntity && _controller != null) ...[
              _buildCenterPlayPause(), // Keep your existing method
              _savePreviewButton(context), // Keep your existing method
              _buildBottomControls(context), // Keep your existing method
            ]
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
          colors: [
            Colors.black87,
            Colors.transparent,
            Colors.transparent,
            Colors.black87
          ],
          stops: [0.0, 0.2, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildTagsList(BuildContext context, AssetDisplayState state) {
    var tagsList = state.allTags
        .where((t) => state.asset!.tagIds.contains(t.id))
        .toList();
    tagsList.sort();
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color.fromARGB(195, 0, 0, 0), Colors.transparent],
          stops: [0.0, 0.5],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 60, left: 20),
        child: GestureDetector(
          onTapUp: (_) => showDialog(
              context: context,
              builder: (context) =>
                  AssetEditView(initialAsset: state.asset!)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 25,
            children: tagsList.map((tag) => _tagElement(tag, state)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _tagElement(TagEntity tag, AssetDisplayState state) {
    //if (tag == null) return Container(width: 20, height: 20, color: Colors.blue);

    return Container(
        color: Colors.transparent,
        child: Row(
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
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ));
  }

  Widget _buildTopBackButton(BuildContext context) {
    return Positioned(
      top: -10,
      left: 10,
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 30),
        onPressed: () =>
            Navigator.of(context).pop(widget.initialAsset.id),
      ),
    );
  }

  Widget _buildNameEditor(BuildContext context, AssetDisplayState state) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 240,
        child: InlineEditableText(
          initialText: state.asset!.name,
          limit: 50,
          onTextChanged: (text) => context
              .read<AssetDisplayBloc>()
              .add(EditAssetNameEvent(newName: text)),
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _savePreviewButton(BuildContext context) {
    return Positioned(
      bottom: 10, right: 120, left: 120,
      child: TextButton.icon(
  style: TextButton.styleFrom(
    backgroundColor: Colors.black54, // Dark, semi-transparent pill
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Colors.white24, width: 1), // Optional subtle border
    ),
  ),
  icon: const Icon(Icons.image_outlined, size: 20),
  label: const Text(
    "Set Cover", 
    style: TextStyle(fontWeight: FontWeight.w600),
  ),
  onPressed: () async {
    await _captureCurrentFrame(context);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cover image updated!'),
          margin: EdgeInsets.only(bottom: 90, left: 10, right: 10),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  },
));
  }

  Widget _buildCenterPlayPause() {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: IconButton(
        iconSize: 50,
        icon: Icon(
          _controller!.value.isPlaying
              ? Icons.pause_circle_filled
              : Icons.play_circle_filled,
          color: Colors.white.withAlpha(204),
        ),
        onPressed: _togglePlay,
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}",
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(color: Colors.white),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        _controller!.value.volume > 0
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: Colors.white,
                      ),
                      onPressed: _toggleMute,
                    ),
                  ],
                )
              ],
            ),
          ),
          GestureDetector(
            onTapDown: (_) => _hideControlsTimer?.cancel(),
            onTapUp: (_) => _resetHideControlsTimer(),
            child: VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Theme.of(context).colorScheme.primary,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.grey,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureCurrentFrame(BuildContext context) async {
    if (_controller == null || _mediaFile == null) return;

    final bool wasPlaying = _controller!.value.isPlaying;
    if (wasPlaying) _controller!.pause();

    final currentPosition = _controller!.value.position;

    debugPrint("Capturing frame at: ${currentPosition.inMilliseconds} ms");

    final Uint8List? frameBytes = await VideoThumbnail.thumbnailData(
      video: _mediaFile!.path,
      imageFormat: ImageFormat.JPEG,
      timeMs: currentPosition.inMilliseconds,
      quality: 70,
    );

    if (frameBytes != null && context.mounted) {
      context.read<AssetDisplayBloc>().add(SetCoverImageEvent(image: frameBytes));
    }

    if (wasPlaying) {
      _controller!.play();
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
}