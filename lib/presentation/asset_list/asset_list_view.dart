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
import 'package:gallaerial/presentation/settings/settings_drawer.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class AssetListView extends StatefulWidget {
  const AssetListView({super.key, this.filterModel, this.sortModel});
  final FilterModel? filterModel;
  final SortModel? sortModel;

  @override
  State<AssetListView> createState() => _AssetListViewState();
}

class _AssetListViewState extends State<AssetListView> with AutomaticKeepAliveClientMixin{
  final ValueNotifier<String?> _animatedThumbnailNotifier = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _animatedThumbnailNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openAsset(UserAssetEntity asset, AssetListViewState state, BuildContext context) async {
    final returnedId = await Navigator.of(context).push(MaterialPageRoute(
        builder: (loopContext) => BlocProvider<AssetListBloc>.value(
          value: context.read<AssetListBloc>(), 
          child: AssetsLoop(
            initialAsset: asset,
            sortedAssets: state.displayedAssets,
        ))
    ));

    if (returnedId != null && returnedId is String) {
      final targetIndex = state.displayedAssets.indexWhere((a) => a.id == returnedId);

      if (targetIndex != -1 && context.mounted) {
        final screenWidth = MediaQuery.of(context).size.width;
        const crossAxisCount = 2;
        const crossAxisSpacing = 10.0;
        const mainAxisSpacing = 10.0;
        const horizontalPadding = 10.0 * 2;

        final availableWidth = screenWidth - horizontalPadding - (crossAxisSpacing * (crossAxisCount - 1));
        final itemWidth = availableWidth / crossAxisCount;
        final childAspectRatio = state.settings.showNames ? 0.7 : 0.82;
        final itemHeight = itemWidth / childAspectRatio;

        final rowIndex = targetIndex ~/ crossAxisCount;
        double targetOffset = (rowIndex * (itemHeight + mainAxisSpacing));

        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          if (targetOffset > maxScroll) targetOffset = maxScroll;

          await _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          );
        }
      }
      _animatedThumbnailNotifier.value = returnedId;
      
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _animatedThumbnailNotifier.value = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return BlocProvider<AssetListBloc>(
      create: (_) => dependencyService()..add(LoadAssetsEvent(filter: widget.filterModel, sort: widget.sortModel)),
      child: BlocBuilder<AssetListBloc, AssetListViewState>(
        builder: (context, state) => 
        DefaultTabController(length: 3, child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withAlpha(150),
          appBar: _appBar(context),
          drawer: Padding(
            padding: const EdgeInsets.only(bottom: 16.0, top: 142),
            child: Drawer(
              child: FilterSortSideMenu(
              currentFilter: state.filter,
              currentSort: state.sort,
              allTags: state.allTags,
              currentAssetType: state.assetType,
              ),
            ),
          ),
          endDrawer:SafeArea(child: Padding(padding: const EdgeInsets.only(top: 90, bottom: 90), 
          child: Drawer(child: SettingsSideMenu(settings: state.settings)))),
          body: Column(
            children: [
              const Align(alignment: Alignment.centerLeft, child: FilterSortAppBar()),
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                child: state.displayedAssets.isEmpty
                    ? _noAssetsText(context, state)
                    : GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 80, top: 10),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: state.settings.showNames ? 0.7 : 0.82,
                        ),
                        itemCount: state.displayedAssets.length,
                        itemBuilder: (context, idx) => AssetThumbnailWidget(
                          key: ValueKey(state.displayedAssets[idx].id),
                          asset: state.displayedAssets[idx],
                          tags: state.allTags,
                          sortedAssetsIds: state.displayedAssets.map((v) => v.id).toList(),
                          animatedNotifier: _animatedThumbnailNotifier,
                          settings: state.settings,
                          onTap: () => _openAsset(
                            state.displayedAssets[idx], 
                            state,
                            context
                          ),
                        ),
                      )),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () => pickAssets(context, state),
            child: const Icon(Icons.add),
          ),
        )),
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
    final assets = await pickAssetsAndGetIds(context, state.assetType);

    if (assets != null && context.mounted) {
      context.read<AssetListBloc>().add(AssetAddedEvent(videosIds: assets[AssetType.video]!, imagesIds: assets[AssetType.image]!));
    }
  }

  Future<Map<AssetType, List<String>>?> pickAssetsAndGetIds(BuildContext context, AssetFilterType assetType) async {
    final List<AssetEntity>? pickedAssets = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: 100,
        requestType: RequestType.fromTypes([RequestType.image, RequestType.video])
      ),
    );

    if (pickedAssets == null || pickedAssets.isEmpty) {
      return null;
    }
    List<String> videoIds = pickedAssets.where((a) => a.type == AssetType.video).map((asset) => asset.id).toList();
    List<String> imageIds = pickedAssets.where((a) => a.type == AssetType.image).map((asset) => asset.id).toList();

    return {AssetType.video: videoIds, AssetType.image: imageIds};
  }

  AppBar _appBar(BuildContext context){
    return AppBar(
            centerTitle: true,
            automaticallyImplyLeading: false,
            flexibleSpace: Image.asset(
              "assets/icon/branding_wide_empty.jpeg", 
              fit: BoxFit.fitWidth, 
              alignment: const Alignment(0, -0.8)
            ),
            title: Text(
              "Files",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            bottom: PreferredSize(preferredSize: const Size.fromHeight(30), child: SizedBox(height: 30, child: TabBar(
            labelColor: Colors.black,
            labelStyle: Theme.of(context).textTheme.titleMedium,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            onTap: (int index) {
              AssetFilterType assetType;
              switch(index){
                case 0:
                  assetType = AssetFilterType.all;
                  break;
                case 1:
                  assetType = AssetFilterType.video;
                  break;
                case 2:
                  assetType = AssetFilterType.image;
                  break;
                default:
                  assetType = AssetFilterType.all;
              }
              if (context.mounted) {
                context.read<AssetListBloc>().add(
              SetAssetTypeEvent( assetType: assetType));
              }
            },
            
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Videos'),
              Tab(text: 'Images'),
            ],
          ))),
      );
  }
}