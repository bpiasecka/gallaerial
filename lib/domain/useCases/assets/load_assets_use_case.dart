import 'package:fpdart/src/either.dart';
import 'package:gallaerial/domain/entities/filter_model.dart';
import 'package:gallaerial/domain/entities/sort_model.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/repositories/asset_repository.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';

class LoadAssetsUseCase<E extends UserAssetEntity> extends UseCase<List<UserAssetEntity>, LoadAssetParams>{
  final AssetRepository<E> repository;

  LoadAssetsUseCase({required this.repository});

  @override
  Future<Either<Error, List<E>>> call(params) async {
    try{
      var assets = await repository.getAssets(filterModel: params.filter, sortModel: params.sort);
      return Right(assets);
    }
    on Error catch (error, _){
      return Left(error);
    }
    
  }
}

class LoadAssetParams{
  final FilterModel? filter;
  final SortModel? sort;

  LoadAssetParams({this.filter, this.sort});
}