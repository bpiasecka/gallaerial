import 'package:fpdart/src/either.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/repositories/asset_repository.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';

class EditAssetNameUseCase<E extends UserAssetEntity> extends UseCase<UserAssetEntity, EditAssetNameUseCaseParams<E>>{
  final AssetRepository<E> repository;

  EditAssetNameUseCase({required this.repository});

  @override
  Future<Either<Error, E>> call(params) async {
    try{
      var newEntity = await repository.editAsset(params.asset, params.newName, params.asset.tagIds);
      return Right(newEntity);
    }
    on Error catch (error, _){
      return Left(error);
    }
  }
}

class EditAssetNameUseCaseParams<E extends UserAssetEntity>{
  final E asset;
  final String newName;

  EditAssetNameUseCaseParams({required this.asset, required this.newName});
}