import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/entities/settings_model.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/presentation/common/inline_editable_text.dart';
import 'package:gallaerial/presentation/asset_tags_edit/asset_edit_view.dart';
import 'package:gallaerial/presentation/asset_list/asset_list_bloc.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class AssetThumbnailWidget extends StatefulWidget {
  final UserAssetEntity asset;
  final List<String> sortedAssetsIds;
  final List<TagEntity> tags;
  final SettingsModel settings;

  final ValueNotifier<String?> animatedNotifier;
  final VoidCallback onTap;

  const AssetThumbnailWidget({
    super.key,
    required this.asset,
    required this.tags,
    required this.sortedAssetsIds,
    required this.animatedNotifier,
    required this.onTap,
    required this.settings,
  });

  @override
  State<AssetThumbnailWidget> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<AssetThumbnailWidget> {
  Duration _duration = const Duration(milliseconds: 0);
  bool _isTagsExpanded = false;
  double _scale = 1.0;
  final Color buttonsBackground = Colors.black54;

  late Future<Uint8List?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = _fetchThumbnail();
    widget.animatedNotifier.addListener(_checkAnimationTrigger);
    _isTagsExpanded = widget.settings.expandTags;
  }

  @override
  void didUpdateWidget(covariant AssetThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.expandTags != widget.settings.expandTags) {
      setState(() => _isTagsExpanded = widget.settings.expandTags);
    }
  }

  @override
  void dispose() {
    widget.animatedNotifier.removeListener(_checkAnimationTrigger);
    super.dispose();
  }

  void _checkAnimationTrigger() async {
    if (widget.animatedNotifier.value == widget.asset.id) {
      if (!mounted) return;
      setState(() => _scale = 1.2);
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() => _scale = 1.0);
    }
  }

  Future<Uint8List?> _fetchThumbnail() async {
    final AssetEntity? pickerAsset = await AssetEntity.fromId(widget.asset.assetId);
    if (pickerAsset == null) return null;

    final Uint8List? thumbnailData = await pickerAsset.thumbnailDataWithSize(
      const ThumbnailSize(250, 250),
    );

    if (pickerAsset.type == AssetType.video) {
      _duration = pickerAsset.videoDuration;
    }

    return thumbnailData;
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds"
        : "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        } 
        
        if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading asset', style: TextStyle(color: Colors.white, fontSize: 10)),
          );
        }

        return AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    _buildImageLayer(snapshot.data),

                    _deleteButton(context),
                    _editButton(context),
                    _tagsPanel(context),

                    if (widget.asset is VideoEntity) _timeLabel(context),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _nameWidget(context),
            ],
          ),
        );
      }
    );
  }

  Widget _buildImageLayer(Uint8List? defaultThumbnail) {
    Widget imageContent;

    switch (widget.asset) {
      case VideoEntity video:
        if (video.coverPath != null) {
          imageContent = Image.file(File(video.coverPath!), fit: BoxFit.cover, width: double.infinity);
        } else if (defaultThumbnail != null) {
          imageContent = Image.memory(defaultThumbnail, fit: BoxFit.cover, width: double.infinity);
        } else {
          imageContent = const Center(child: Icon(Icons.broken_image, color: Colors.grey));
        }
      case ImageEntity _:
        if (defaultThumbnail != null) {
          imageContent = Image.memory(defaultThumbnail, fit: BoxFit.cover, width: double.infinity);
        } else {
          imageContent = const Center(child: Icon(Icons.broken_image, color: Colors.grey));
        }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            blurRadius: 5,
            spreadRadius: 0.001,
            color: Theme.of(context).colorScheme.shadow.withAlpha(100),
            offset: const Offset(0, 2),
          )
        ],
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: GestureDetector(
        onTapUp: (_) => widget.onTap(),
        onLongPress: () => showDialog(
          context: context,
          builder: (_) => AssetEditView(initialAsset: widget.asset),
        ),
        child: imageContent,
      ),
    );
  }

  Widget _deleteButton(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 3, bottom: 4),
        child: GestureDetector(
          onTapUp: (_) => confirmAndRemove(context),
          child: Container(
            decoration: BoxDecoration(color: buttonsBackground, borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: const Icon(Icons.delete, color: Color.fromARGB(195, 255, 255, 255), size: 17),
          ),
        ),
      ),
    );
  }

  void confirmAndRemove(BuildContext context) {
    final assetTypeName = widget.asset is VideoEntity ? "Video" : "Image";

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Remove $assetTypeName'),
          content: Text('Are you sure you want to remove this ${assetTypeName.toLowerCase()}? (It will be removed only from this app, the original file remains on your device)'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<AssetListBloc>().add(AssetRemovedEvent(asset: widget.asset));
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  Widget _editButton(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 3, bottom: 35),
        child: GestureDetector(
          onTapUp: (_) => showDialog(
            context: context,
            builder: (_) => AssetEditView(initialAsset: widget.asset),
          ),
          child: Container(
            decoration: BoxDecoration(color: buttonsBackground, borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: const Icon(Icons.edit, color: Color.fromARGB(195, 255, 255, 255), size: 17),
          ),
        ),
      ),
    );
  }

  Widget _timeLabel(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 3, bottom: 4),
        child: Container(
          decoration: BoxDecoration(color: buttonsBackground, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            formatDuration(_duration),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _tagsPanel(BuildContext context) {
    if (!widget.asset.tagIds
        .any((id) => widget.tags.map((t) => t.id).contains(id))) {
      return const SizedBox.shrink();
    }

    var tagsList =
        widget.tags.where((t) => widget.asset.tagIds.contains(t.id)).toList();
    tagsList.sort();
    var limitedTagsList = List<TagEntity>.from(tagsList);
    if (limitedTagsList.length > 5) {
      limitedTagsList = limitedTagsList.getRange(0, 5).toList();
    }

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isTagsExpanded = !_isTagsExpanded;
            });
          },
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topLeft,
            child: Container(
              decoration: BoxDecoration(
                color: buttonsBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: limitedTagsList.map<Widget>((tag) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: SizedBox(
                          height: 18,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tag.color.toColor()!,
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 5,
                                      spreadRadius: 0.001,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .shadow
                                          .withAlpha(100),
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                              ),
                              if (_isTagsExpanded)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    tag.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall!
                                        .copyWith(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          )),
                    );
                  }).toList()
                    ..add(tagsList.length > 5
                        ? const Text("...",
                            style: TextStyle(color: Colors.white))
                        : const SizedBox.shrink())
                    ..add(const SizedBox(height: 10))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameWidget(BuildContext context) {
    if (!widget.settings.showNames) return Container();

    return SizedBox(
        height: 40,
        child: Align(
          alignment: Alignment.topCenter,
          child: InlineEditableText(
              initialText: widget.asset.name,
              style: Theme.of(context).textTheme.labelMedium,
              limit: 50,
              onTextChanged: (name) => context
                  .read<AssetListBloc>()
                  .add(EditAssetNameEvent(asset: widget.asset, newName: name))),
        ));
  }
}
