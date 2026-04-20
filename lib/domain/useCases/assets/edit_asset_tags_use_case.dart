import 'package:fpdart/src/either.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/repositories/asset_repository.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';

class EditAssetTagsUseCase<E extends UserAssetEntity> extends UseCase<UserAssetEntity, EditAssetTagsUseCaseParams<E>>{
  final AssetRepository<E> repository;

  EditAssetTagsUseCase({required this.repository});

  @override
  Future<Either<Error, E>> call(params) async {
    try{
      var newTags = <String>[];
      if(params.asset.tagIds.contains(params.clickedTagId)){
        newTags = params.asset.tagIds..removeWhere((tagId) => tagId == params.clickedTagId);
      }
      else{
        newTags = params.asset.tagIds..add(params.clickedTagId);
      }
      var newEntity = await repository.editAsset(params.asset, params.asset.name, newTags);
      return Right(newEntity);
    }
    on Error catch (error, _){
      return Left(error);
    }
  }
}

class EditAssetTagsUseCaseParams<E extends UserAssetEntity>{
  final E asset;
  final String clickedTagId;

  EditAssetTagsUseCaseParams({required this.asset, required this.clickedTagId});
}