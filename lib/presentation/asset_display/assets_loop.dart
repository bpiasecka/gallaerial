import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/presentation/asset_display/asset_display_view.dart';
import 'package:gallaerial/presentation/asset_list/asset_list_bloc.dart';

class AssetsLoop extends StatefulWidget {
  final UserAssetEntity initialAsset;
  final List<UserAssetEntity> sortedAssets;


  const AssetsLoop({super.key, required this.initialAsset, required this.sortedAssets});

  @override
  State<AssetsLoop> createState() => _AssetsLoopState();
}

class _AssetsLoopState extends State<AssetsLoop> {
  late PageController _pageController;
  late int _currentIndex;
  late List<UserAssetEntity> _loopAssets;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.sortedAssets.indexOf(widget.initialAsset);
    if (_currentIndex == -1) _currentIndex = 0; 
    _pageController = PageController(initialPage: _currentIndex);
    _loopAssets = List.from(widget.sortedAssets);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loopAssets.isEmpty) return const SizedBox.shrink();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_loopAssets[_currentIndex].id);
      }, 
      child: BlocListener<AssetListBloc, AssetListViewState>(
        listener: (context, state) {
          final liveIds = state.allVideos.map((v) => v.id).toSet()
            ..addAll(state.allImages.map((i) => i.id));
          final hasRemovals = _loopAssets.any((a) => !liveIds.contains(a.id));

          if (hasRemovals) {
            setState(() {
              _loopAssets.removeWhere((a) => !liveIds.contains(a.id));
              if (_currentIndex >= _loopAssets.length) {
                _currentIndex = _loopAssets.length - 1;
              }
            });
          }
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: _loopAssets.length,
          onPageChanged: (idx) {
            setState(() {
              _currentIndex = idx;
            });
          },
          itemBuilder: (context, idx) {
            return FullScreenAssetViewer(
              initialAsset: _loopAssets[idx],
              isActive: _currentIndex == idx,
            );
          },
        ),
      ),
    );
  }
}