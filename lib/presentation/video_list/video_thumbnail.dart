import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/entities/video_entity.dart';
import 'package:gallaerial/presentation/common/inline_editable_text.dart';
import 'package:gallaerial/presentation/video_edit/video_edit_view.dart';
import 'package:gallaerial/presentation/video_list/video_list_bloc.dart';
import 'package:gallaerial/presentation/video_player/video_player_view.dart';
import 'package:gallaerial/presentation/video_player/videos_loop.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final VideoEntity video;
  final List<String> sortedVideosIds;
  final List<TagEntity> tags;

  final ValueNotifier<String?> animatedNotifier;
  final VoidCallback onTap;

  const VideoThumbnailWidget({
    super.key,
    required this.video,
    required this.tags,
    required this.sortedVideosIds,
    required this.animatedNotifier,
    required this.onTap,
  });

  @override
  State<VideoThumbnailWidget> createState() => VideoThumbnailState();
}

class VideoThumbnailState extends State<VideoThumbnailWidget> {
  Duration duration = const Duration(milliseconds: 0);
  bool _isTagsExpanded = false;
  double _scale = 1.0;
  final Color buttonsBackground = Colors.black54;

  late Future<Uint8List?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = _fetchThumbnail();
  widget.animatedNotifier.addListener(_checkAnimationTrigger);
  }

  @override
  void dispose() {
    widget.animatedNotifier.removeListener(_checkAnimationTrigger);
    super.dispose();
  }

  void _checkAnimationTrigger() async {
    if (widget.animatedNotifier.value == widget.video.id) {
      if (!mounted) return;
      setState(() => _scale = 1.2);
      
      await Future.delayed(const Duration(milliseconds: 150));
      
      if (!mounted) return;
      setState(() => _scale = 1.0);
    }
  }

  Future<Uint8List?> _fetchThumbnail() async {
    final AssetEntity? asset = await AssetEntity.fromId(widget.video.assetId);
    
    if (asset == null) {
      return null; 
    }

    final Uint8List? thumbnailData = await asset.thumbnailDataWithSize(
      const ThumbnailSize(250, 250),
    );

    duration = asset.videoDuration;
    return thumbnailData;
  }

  String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

  if (duration.inHours > 0) {
    return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
  }
  
  return "$twoDigitMinutes:$twoDigitSeconds";
}

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _thumbnailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return AnimatedScale(scale: _scale, duration: const Duration(milliseconds: 300), curve: Curves.easeInOutCubic,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(children: [
                      _videoThumbnail(context, snapshot),
                      _deleteButton(context),
                      _editButton(context),
                      _timeLabel(context),
                      _tagsPanel(context)
                    ]),
                  ),
                  const SizedBox(height: 6),
                  _nameWidget(context),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading video',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
        });
  }

  Widget _videoThumbnail(BuildContext context, snapshot) {
    if (snapshot.hasData && snapshot.data != null){
    return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors
                .black,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(blurRadius: 5, spreadRadius: 0.001, color: Theme.of(context).colorScheme.shadow.withAlpha(100), offset: const Offset(0, 2))]
          ),
          clipBehavior: Clip
              .antiAliasWithSaveLayer,
              child: GestureDetector(
                  onTapUp: (_) => widget.onTap(),
                  onLongPress: () => showDialog(context: context, builder: (_) => VideoEditView(initialVideo: widget.video,)),
                  child: Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  )),
    );
    }else{
      return Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
    }
  }

  Widget _deleteButton(BuildContext context) {
    return Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 3, bottom: 4),
          child: GestureDetector(
            child: Container(
                decoration: BoxDecoration(
                    color: buttonsBackground,
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: const Icon(
                  Icons.delete,
                  color: Color.fromARGB(195, 255, 255, 255),
                  size: 17,
                )),
            onTapUp: (_) => confirmAndRemove(context),
          ),
        ));
  }

  void confirmAndRemove(BuildContext context){
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Remove Video'),
        content: const Text('Are you sure you want to remove this video? (It will be removed only from this app, the original file remains on your device)'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); 
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<VideoListBloc>()
                  .add(VideoRemovedEvent(video: widget.video));
              
              Navigator.of(dialogContext).pop(); 
            },
            child: const Text(
              'Remove',
            ),
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
            child: Container(
                decoration: BoxDecoration(
                    color: buttonsBackground,
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: const Icon(
                  Icons.edit,
                  color: Color.fromARGB(195, 255, 255, 255),
                  size: 17,
                )),
            onTapUp: (_) => showDialog(context: context, builder: (_) => VideoEditView(initialVideo: widget.video,)),
        )));
  }

  Widget _timeLabel(BuildContext context) {
    return Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 3, bottom: 4),
          child: Container(
              decoration: BoxDecoration(
                  color: buttonsBackground,
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                formatDuration(duration),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                    ),
              )),
        ));
  }

  Widget _tagsPanel(BuildContext context) {
    if (!widget.video.tagIds.any((id) => widget.tags.map((t) => t.id).contains(id))) {
      return const SizedBox.shrink();
    }

    var tagsList = widget.tags.where((t) => widget.video.tagIds.contains(t.id)).toList();
    tagsList.sort();
    var limitedTagsList = List<TagEntity>.from(tagsList);
    if(limitedTagsList.length > 5) {
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
                      height: 18, child: Row(
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
                                color: Theme.of(context).colorScheme.shadow.withAlpha(100),
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
                              style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    )),
                  );
                }).toList()
                ..add(tagsList.length > 5 ? const Text("...", style: TextStyle(color: Colors.white)) : const SizedBox.shrink())
                ..add(const SizedBox(height: 10))
                
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nameWidget(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Align(
      alignment: Alignment.topCenter,
      child: InlineEditableText(
          initialText: widget.video.name,
          style: Theme.of(context).textTheme.labelMedium,
          limit: 50,
          onTextChanged: (name) => context
              .read<VideoListBloc>()
              .add(EditVideoNameEvent(video: widget.video, newName: name))),
    ));
  }
}
