import 'package:fpdart/fpdart.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/repositories/tags_repository.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';

class RemoveTagUsecase extends UseCase<Null, TagEntity>{
  final TagsRepository repository;

  RemoveTagUsecase({required this.repository});

  @override
  Future<Either<Error, Null>> call(params) async {
    try{
      repository.removeTag(params);
      return const Right(null);
    }
    on Error catch (error, _){
      return Left(error);
    }
    
  }

}