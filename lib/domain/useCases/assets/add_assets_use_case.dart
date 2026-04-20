import 'package:fpdart/src/either.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/repositories/asset_repository.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';

class AddAssetsUseCase<E extends UserAssetEntity> extends UseCase<Iterable<UserAssetEntity>, List<String>>{
  final AssetRepository<E> repository;

  AddAssetsUseCase({required this.repository});

  @override
  Future<Either<Error, List<E>>> call(paths) async {
    try{
      var newEntities = await repository.addAssets(paths);
      return Right(newEntities);
    }
    on Error catch (error, _){
      return Left(error);
    }
    
  }
}