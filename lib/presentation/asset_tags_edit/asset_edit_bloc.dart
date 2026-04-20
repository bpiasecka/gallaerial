import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/useCases/assets/edit_asset_tags_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/load_tags_use_case.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/main.dart';

class AssetEditEvent {}

class InitWithAssetEvent extends AssetEditEvent {
  final UserAssetEntity asset;

  InitWithAssetEvent({required this.asset});
}

class TagClickedEvent extends AssetEditEvent {
  final TagEntity tag;

  TagClickedEvent({required this.tag});
}

class AssetEditState{
  final UserAssetEntity? assetEntity;
  final List<TagEntity>? allTags;

  AssetEditState({required this.assetEntity, required this.allTags});
}

class AssetEditBloc extends Bloc<AssetEditEvent, AssetEditState>{
  AssetEditBloc() : super(AssetEditState(assetEntity: null, allTags: null)){

    on<InitWithAssetEvent>((event, emit) async {
      var res = await dependencyService<LoadTagsUsecase>().call(NoParams());
      res.fold((e){}, (tags) => emit(AssetEditState(assetEntity: event.asset, allTags: tags)));
    });

    on<TagClickedEvent>((event, emit) async {
      final currentAsset = state.assetEntity;
      if (currentAsset == null) return;

      Either<Error, UserAssetEntity> result;
      switch (currentAsset) {
        case VideoEntity video:
          result = await dependencyService<EditAssetTagsUseCase<VideoEntity>>().call(
            EditAssetTagsUseCaseParams(asset: video, clickedTagId: event.tag.id)
          );
        case ImageEntity image:
          result = await dependencyService<EditAssetTagsUseCase<ImageEntity>>().call(
            EditAssetTagsUseCaseParams(asset: image, clickedTagId: event.tag.id)
          );
      }

      result.fold(
        (e) {}, 
        (updatedAsset) => emit(AssetEditState(assetEntity: updatedAsset, allTags: state.allTags))
      );
    });
  }
  
}