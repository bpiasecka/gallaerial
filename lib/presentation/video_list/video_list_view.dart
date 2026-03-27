import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallaerial/main.dart';
import 'package:gallaerial/presentation/video_list/filter_sort_app_bar.dart';
import 'package:gallaerial/presentation/video_list/filter_sort_side_menu.dart';
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
                  appBar: const FilterSortAppBar(),
                  endDrawer: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Drawer(
                      child: FilterSortSideMenu(
                        currentFilter: state.filter,
                        currentSort: state.sort,
                        allTags: state.allTags,
                      ),
                    ),
                  ),
                  body: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 0),
                      child: state.addedVideosAssets.isEmpty 
                        ? _noVideosText(context, state)
                        : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 80, top: 10),
                        itemBuilder: (context, idx) => idx < state.addedVideosAssets.length
                            ? VideoThumbnailWidget(
                                key: ValueKey(state.addedVideosAssets[idx].id),
                                video: state.addedVideosAssets[idx],
                                tags: state.allTags,
                              )
                            : null,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.7,
                        ),
                      )),
                  floatingActionButton: FloatingActionButton(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    onPressed: () => pickVideos(context),
                    child: const Icon(Icons.add),
                  ),
                )));
  }

  Widget _noVideosText(BuildContext context, VideoListViewState state) {
    return Align(
      alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Card.outlined(
            color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: !state.filter.isEmpty() 
                  ? const Text("No videos found, try change your filter settings.",
                    textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold,))
                  : RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: 14), 
                      children: [
                        TextSpan(
                          text: 'Add first video by clicking on the plus button.\n\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: 'Remember that no copy of a video is created - if you delete it from your device, it will be removed from this app as well.',),
                      ],
                    ),)
              )),
        ));
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
        maxAssets: 100,
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
