import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/entities/filter_model.dart';
import 'package:gallaerial/domain/entities/settings_model.dart';
import 'package:gallaerial/domain/entities/sort_model.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/repositories/image_repository.dart';
import 'package:gallaerial/domain/repositories/settings_repository.dart';
import 'package:gallaerial/domain/repositories/video_repository.dart';
import 'package:gallaerial/domain/useCases/assets/add_assets_use_case.dart';
import 'package:gallaerial/domain/useCases/assets/edit_asset_name_use_case.dart';
import 'package:gallaerial/domain/useCases/assets/remove_asset_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/load_tags_use_case.dart';
import 'package:gallaerial/main.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:rxdart/rxdart.dart';

enum AssetFilterType {all, video, image}

class AssetListViewEvent {}

class LoadAssetsEvent extends AssetListViewEvent {
  final FilterModel? filter;
  final SortModel? sort;

  LoadAssetsEvent({required this.filter, required this.sort});
}

class AssetAddedEvent extends AssetListViewEvent {
  final List<String> assetIds;

  AssetAddedEvent({required this.assetIds});
}

class AssetRemovedEvent extends AssetListViewEvent {
  final UserAssetEntity asset;

  AssetRemovedEvent({required this.asset});
}

class EditAssetNameEvent extends AssetListViewEvent {
  final UserAssetEntity asset;
  final String newName;

  EditAssetNameEvent({required this.asset, required this.newName});
}

class SetFilterAndSortEvent extends AssetListViewEvent {
  final FilterModel filter;
  final SortModel sort;
  final AssetFilterType assetType;

  SetFilterAndSortEvent({required this.filter, required this.sort, required this.assetType});
}

class AssetListViewState {
  final List<VideoEntity> allVideos;
  final List<ImageEntity> allImages;
  final List<UserAssetEntity> displayedAssets;
  final List<TagEntity> allTags;
  final FilterModel filter;
  final SortModel sort;
  final SettingsModel settings;
  final AssetFilterType assetType;

  AssetListViewState({
    required this.allVideos,
    required this.allImages,
    required this.displayedAssets,
    required this.allTags,
    required this.filter,
    required this.sort,
    required this.settings,
    required this.assetType,
  });

  AssetListViewState copyWith({
    List<VideoEntity>? allVideos,
    List<ImageEntity>? allImages,
    List<UserAssetEntity>? displayedAssets,
    List<TagEntity>? allTags,
    FilterModel? filter,
    SortModel? sort,
    SettingsModel? settings,
    AssetFilterType? assetType,
  }) {
    return AssetListViewState(
      allVideos: allVideos ?? this.allVideos,
      allImages: allImages ?? this.allImages,
      displayedAssets: displayedAssets ?? this.displayedAssets,
      allTags: allTags ?? this.allTags,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      settings: settings ?? this.settings,
      assetType: assetType ?? this.assetType,
    );
  }
}

class AssetListBloc extends Bloc<AssetListViewEvent, AssetListViewState> {
  AssetListBloc() : super(
    AssetListViewState(
      allVideos: [], 
      allImages: [],
      displayedAssets: [],
      allTags: [],
      filter: FilterModel(), 
      sort: SortModel.empty(), 
      settings: SettingsModel(), 
      assetType: AssetFilterType.video)) {

    on<LoadAssetsEvent>((event, emit) async {
      var tagsRes = await dependencyService<LoadTagsUsecase>().call(NoParams());
      var tags = tagsRes.fold((l) => <TagEntity>[], (r) => r);

      final combinedStream = Rx.combineLatest3(
        dependencyService<VideoRepository>().entityDataStream,
        dependencyService<ImageRepository>().entityDataStream,
        dependencyService<SettingsRepository>().settingsStream,
        (List<VideoEntity> videos, List<ImageEntity> images, SettingsModel settings) {
          return (videos: videos, images: images, settings: settings);
        }
      ).asyncMap((data) async {
        final processedAssets = await _processAssets(
          videos: data.videos,
          images: data.images,
          filter: state.filter,
          sort: state.sort,
          assetType: state.assetType,
        );
        return (rawData: data, processed: processedAssets);
      });

      await emit.forEach(
        combinedStream,
        onData: (result) {
          return state.copyWith(
            allVideos: result.rawData.videos,
            allImages: result.rawData.images,
            settings: result.rawData.settings,
            displayedAssets: result.processed,
            allTags: tags,
          );
        },
      );
    });

    on<AssetAddedEvent>((event, emit) async {
      switch (state.assetType) {
        case AssetFilterType.video:
          await dependencyService<AddAssetsUseCase<VideoEntity>>().call(event.assetIds);
        case AssetFilterType.image:
          await dependencyService<AddAssetsUseCase<ImageEntity>>().call(event.assetIds);
        case AssetFilterType.all:
          break;
      }
    });

    on<AssetRemovedEvent>((event, emit) {
      switch (event.asset) {
        case VideoEntity video:
          dependencyService<RemoveAssetUseCase<VideoEntity>>().call(video);
        case ImageEntity image:
          dependencyService<RemoveAssetUseCase<ImageEntity>>().call(image);
      }
    });

    on<EditAssetNameEvent>((event, emit) async {
      switch (event.asset) {
        case VideoEntity video:
          await dependencyService<EditAssetNameUseCase<VideoEntity>>().call(
              EditAssetNameUseCaseParams(newName: event.newName, asset: video));
        case ImageEntity image:
          await dependencyService<EditAssetNameUseCase<ImageEntity>>().call(
              EditAssetNameUseCaseParams(newName: event.newName, asset: image));
      }
    });

    on<SetFilterAndSortEvent>((event, emit) async {
      final processedAssets = await _processAssets(
        videos: state.allVideos,
        images: state.allImages,
        filter: event.filter,
        sort: event.sort,
        assetType: event.assetType,
      );

      emit(state.copyWith(
        displayedAssets: processedAssets,
        filter: event.filter,
        sort: event.sort,
        assetType: event.assetType,
      ));
    });
  }

  Future<List<UserAssetEntity>> _processAssets ({
    required List<VideoEntity> videos,
    required List<ImageEntity> images,
    required FilterModel filter,
    required SortModel sort,
    required AssetFilterType assetType,
  }) async {
    List<UserAssetEntity> combined = [];

    if (assetType == AssetFilterType.video || assetType == AssetFilterType.all) {
      combined.addAll(videos);
    }
    if (assetType == AssetFilterType.image || assetType == AssetFilterType.all) {
      combined.addAll(images);
    }

    combined = combined.where((asset) => filter.match(asset)).toList();
    await sort.sort(combined); 

    return combined;
  }
}
