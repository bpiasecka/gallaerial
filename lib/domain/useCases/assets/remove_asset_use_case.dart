import 'package:fpdart/src/either.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/repositories/asset_repository.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';

class RemoveAssetUseCase<E extends UserAssetEntity> extends UseCase<Null, E>{
  final AssetRepository<E> repository;

  RemoveAssetUseCase({required this.repository});

  @override
  Future<Either<Error, Null>> call(asset) async {
    try{
      repository.removeAsset(asset);
      return const Right(null);
    }
    on Error catch (error, _){
      return Left(error);
    }
  }
}