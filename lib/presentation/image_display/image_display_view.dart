import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/extensions/color_extension.dart';
import 'package:gallaerial/main.dart';
import 'package:gallaerial/presentation/common/inline_editable_text.dart';
import 'package:gallaerial/presentation/image_display/image_display_bloc.dart';
import 'package:gallaerial/presentation/asset_tags_edit/asset_edit_view.dart';
import 'package:photo_manager/photo_manager.dart';


class FullScreenImageDisplay extends StatefulWidget {
  final String imageEntityId;

  const FullScreenImageDisplay(
      {super.key, required this.imageEntityId});

  @override
  State<FullScreenImageDisplay> createState() => _FullScreenImageDisplayState();
}

class _FullScreenImageDisplayState extends State<FullScreenImageDisplay> {
  bool _isInitializing = false;
  bool _showControls = false;
  Timer? _hideControlsTimer;
  File? imageFile;

  Future<void> _initializeDisplay(ImageDisplayState state) async {
    if (_isInitializing) return;
    _isInitializing = true;

    final AssetEntity? asset =
        await AssetEntity.fromId(state.imageEntity!.assetId);
    if (asset == null) return;

    var file = await asset.file;
    setState((){
      imageFile = file;
    });
    if (imageFile == null) return;
    _isInitializing = false;

  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => dependencyService<ImageDisplayBloc>()
        ..add(InitializeWithImageEvent(imageId: widget.imageEntityId)),
      child: BlocConsumer<ImageDisplayBloc, ImageDisplayState>(
        listener: (context, state) {
          if (state.imageEntity != null &&
              !_isInitializing) {
            _initializeDisplay(state);
          }
        },
        builder: (context, state) {
          if (state.imageEntity == null) {
            return const Center(child: CircularProgressIndicator());
          }

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
                    _buildImageLayer(),
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

  Widget _buildImageLayer() {
    return Center(
      child: imageFile != null
          ? Image.file(imageFile!, fit: BoxFit.contain,)
          : const CircularProgressIndicator(color: Colors.white),
    );
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _resetHideControlsTimer() {
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  Widget _buildControlsOverlay(BuildContext context, ImageDisplayState state) {
    if (_isInitializing) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !_showControls,
        child: Stack(
          children: [
            _buildGradientBackground(),
            _buildTagsList(context, state),
            _buildTopBackButton(context),
            _buildNameEditor(context, state),
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

  Widget _buildTagsList(BuildContext context, ImageDisplayState state) {
    var tagsList = state.allTags
        .where((t) => state.imageEntity!.tagIds.contains(t.id))
        .toList();
    tagsList.sort();
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
          onTapUp: (_) => showDialog(
              context: context,
              builder: (context) =>
                  AssetEditView(initialAsset: state.imageEntity!)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 25,
            children: tagsList.map((tag) => _tagElement(tag, state)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _tagElement(TagEntity tag, ImageDisplayState state) {
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
            Navigator.of(context).pop(widget.imageEntityId),
      ),
    );
  }

  Widget _buildNameEditor(BuildContext context, ImageDisplayState state) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 240,
        child: InlineEditableText(
          initialText: state.imageEntity!.name,
          limit: 50,
          onTextChanged: (text) => context
              .read<ImageDisplayBloc>()
              .add(EditImageNameEvent(newName: text)),
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
