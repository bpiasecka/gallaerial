import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/repositories/image_repository.dart';
import 'package:gallaerial/domain/repositories/video_repository.dart';
import 'package:gallaerial/domain/useCases/assets/edit_asset_name_use_case.dart';
import 'package:gallaerial/domain/useCases/assets/edit_video_cover_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/load_tags_use_case.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/main.dart';

abstract class AssetDisplayEvent {}

class InitializeAssetEvent extends AssetDisplayEvent {
  final UserAssetEntity initialAsset;
  InitializeAssetEvent({required this.initialAsset});
}

class EditAssetNameEvent extends AssetDisplayEvent {
  final String newName;
  EditAssetNameEvent({required this.newName});
}

class SetCoverImageEvent extends AssetDisplayEvent {
  final Uint8List image;
  SetCoverImageEvent({required this.image});
}

class AssetDisplayState {
  final UserAssetEntity? asset;
  final List<TagEntity> allTags;

  AssetDisplayState({required this.asset, required this.allTags});
}

class AssetDisplayBloc extends Bloc<AssetDisplayEvent, AssetDisplayState> {
  AssetDisplayBloc() : super(AssetDisplayState(asset: null, allTags: [])) {
    
    on<InitializeAssetEvent>((event, emit) async {
      var tagsResult = await dependencyService<LoadTagsUsecase>().call(NoParams());
      var tags = tagsResult.fold((l) => <TagEntity>[], (r) => r);

      Stream<List<UserAssetEntity>> streamToListen;
      switch (event.initialAsset) {
        case VideoEntity _:
          streamToListen = dependencyService<VideoRepository>().entityDataStream;
        case ImageEntity _:
          streamToListen = dependencyService<ImageRepository>().entityDataStream;
      }

      await emit.forEach<List<UserAssetEntity>>(
        streamToListen,
        onData: (updatedAssets) {
          final currentAsset = updatedAssets.where((a) => a.id == event.initialAsset.id).firstOrNull;
          return AssetDisplayState(asset: currentAsset, allTags: tags);
        },
      );
    });

    on<EditAssetNameEvent>((event, emit) async {
      final currentAsset = state.asset;
      if (currentAsset == null) return;

      switch (currentAsset) {
        case VideoEntity video:
          dependencyService<EditAssetNameUseCase<VideoEntity>>().call(
              EditAssetNameUseCaseParams(newName: event.newName, asset: video));
        case ImageEntity image:
          dependencyService<EditAssetNameUseCase<ImageEntity>>().call(
              EditAssetNameUseCaseParams(newName: event.newName, asset: image));
      }
    });

    on<SetCoverImageEvent>((event, emit) {
      final currentAsset = state.asset;
      if (currentAsset is VideoEntity) {
        dependencyService<EditVideoCoverUseCase>().call(
            EditVideoCoverUseCaseParams(video: currentAsset, cover: event.image));
      }
    });
  }
}