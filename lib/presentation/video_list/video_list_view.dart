import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallaerial/main.dart';
import 'package:gallaerial/presentation/video_list/video_thumbnail.dart';
import 'package:gallaerial/presentation/video_list/video_list_bloc.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class VideoListView extends StatelessWidget {
  const VideoListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VideoListBloc>(
        create: (_) => service()..add(LoadVideosEvent()),
        child: BlocBuilder<VideoListBloc, VideoListViewState>(
            builder: (context, state) => Scaffold(
                  body: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: GridView.builder(
                        padding: const EdgeInsets.only(bottom: 60),
                          itemBuilder: (context, idx) =>
                              idx < state.addedVideosAssets.length
                                  ? VideoThumbnailWidget(
                                      video: state.addedVideosAssets[idx],
                                      tags: state.allTags,)
                                  : null,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.8,
                            ),)),
                  floatingActionButton: FloatingActionButton(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    onPressed: () => pickVideos(context),
                    child: const Icon(Icons.add),
                  ),
                )));
  }

  Future<void> pickVideos(BuildContext context) async {
    final assetsIds = await pickVideoAndGetIds(context);

    if (assetsIds != null && context.mounted) {
      context.read<VideoListBloc>().add(VideoAddedEvent(assetIds: assetsIds));
    }
  }

  Future<List<String>?> pickVideoAndGetIds(BuildContext context) async {
  final List<AssetEntity>? pickedAssets = await AssetPicker.pickAssets(
    context,
    pickerConfig: const AssetPickerConfig(
      maxAssets: 10, 
      requestType: RequestType.video,
    ),
  );

  if (pickedAssets == null || pickedAssets.isEmpty) {
    return null;
  }
  List<String> videoIds = pickedAssets.map((asset) => asset.id).toList();
  
  return videoIds;
}
}
