import 'package:fpdart/src/either.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/repositories/asset_repository.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';

class GetAssetUseCase<E extends UserAssetEntity> extends UseCase<UserAssetEntity, String>{
  final AssetRepository<E> repository;

  GetAssetUseCase({required this.repository});

  @override
  Future<Either<Error, E>> call(id) async {
    try{
      var assets = await repository.getAssets();
      return Right(assets.firstWhere((v) => v.id == id));
    }
    on Error catch (error, _){
      return Left(error);
    }
    
  }
}