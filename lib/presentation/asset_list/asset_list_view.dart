import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/entities/filter_model.dart';
import 'package:gallaerial/domain/entities/sort_model.dart';
import 'package:gallaerial/main.dart';
import 'package:gallaerial/presentation/asset_list/filter_sort_app_bar.dart';
import 'package:gallaerial/presentation/asset_list/filter_sort_side_menu.dart';
import 'package:gallaerial/presentation/asset_list/asset_thumbnail.dart';
import 'package:gallaerial/presentation/asset_list/asset_list_bloc.dart';
import 'package:gallaerial/presentation/asset_display/assets_loop.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class AssetListView extends StatefulWidget {
  const AssetListView({super.key, this.filterModel, this.sortModel});
  final FilterModel? filterModel;
  final SortModel? sortModel;

  @override
  State<AssetListView> createState() => _AssetListViewState();
}

class _AssetListViewState extends State<AssetListView> {
  final ValueNotifier<String?> _animatedThumbnailNotifier = ValueNotifier(null);

  @override
  void dispose() {
    _animatedThumbnailNotifier.dispose();
    super.dispose();
  }

  Future<void> _openAsset(UserAssetEntity asset, List<UserAssetEntity> sortedAssets, BuildContext context) async {
    final returnedId = await Navigator.of(context).push(MaterialPageRoute(
        builder: (loopContext) => BlocProvider<AssetListBloc>.value(
          value: context.read<AssetListBloc>(), 
          child: AssetsLoop(
            initialAsset: asset, 
            sortedAssets: sortedAssets,
        ))
    ));

    if (returnedId != null && returnedId is String) {
      _animatedThumbnailNotifier.value = returnedId;
      
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _animatedThumbnailNotifier.value = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AssetListBloc>(
      create: (_) => dependencyService()..add(LoadAssetsEvent(filter: widget.filterModel, sort: widget.sortModel)),
      child: BlocBuilder<AssetListBloc, AssetListViewState>(
        builder: (context, state) => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withAlpha(150),
          appBar: const FilterSortAppBar(),
          endDrawer: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Drawer(
              child: FilterSortSideMenu(
              currentFilter: state.filter,
              currentSort: state.sort,
              allTags: state.allTags,
              currentAssetType: state.assetType,
              ),
            ),
          ),
          body: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            child: state.displayedAssets.isEmpty
                ? _noAssetsText(context, state)
                : GridView.builder(
                    padding: const EdgeInsets.only(bottom: 80, top: 10),
                    gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: state.settings.showNames ? 0.7 : 0.82,
                        ),
                    itemBuilder: (context, idx) => idx < state.displayedAssets.length
                        ? AssetThumbnailWidget(
                            key: ValueKey(state.displayedAssets[idx].id),
                            asset: state.displayedAssets[idx],
                            tags: state.allTags,
                            sortedAssetsIds: state.displayedAssets.map((v) => v.id).toList(),
                            animatedNotifier: _animatedThumbnailNotifier,
                            settings: state.settings,
                            onTap: () => _openAsset(
                              state.displayedAssets[idx], 
                              state.displayedAssets,
                              context
                            ),
                          )
                        : null,
                  ),
          ),
          floatingActionButton: FloatingActionButton(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    onPressed: () => pickAssets(context, state),
                    child: const Icon(Icons.add),
                  ),
        ),
      ),
    );
  }

  Widget _noAssetsText(BuildContext context, AssetListViewState state) {
    return Align(
      alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Card.outlined(
            color: Theme.of(context).colorScheme.primary.withAlpha(100),
            elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: !state.filter.isEmpty() 
                  ? const Text("No files found, try change your filter settings.",
                    textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold,))
                  : RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: 14), 
                      children: [
                        TextSpan(
                          text: 'Add first file by clicking on the plus button.\n\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: 'Remember that no copy of a file is created - if you delete it from your device, it will be removed from this app as well.',),
                      ],
                    ),)
              )),
        ));
  }

  Future<void> pickAssets(BuildContext context, AssetListViewState state) async {
    final assetsIds = await pickAssetsAndGetIds(context, state.assetType);

    if (assetsIds != null && context.mounted) {
      context.read<AssetListBloc>().add(AssetAddedEvent(assetIds: assetsIds));
    }
  }

  Future<List<String>?> pickAssetsAndGetIds(BuildContext context, AssetFilterType assetType) async {
    final List<AssetEntity>? pickedAssets = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: 100,
        requestType: assetType == AssetFilterType.video ? RequestType.video : RequestType.image,
      ),
    );

    if (pickedAssets == null || pickedAssets.isEmpty) {
      return null;
    }
    List<String> videoIds = pickedAssets.map((asset) => asset.id).toList();

    return videoIds;
  }
}
