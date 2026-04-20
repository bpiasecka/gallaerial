import 'package:fpdart/fpdart.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/repositories/tags_repository.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';

class LoadTagsUsecase extends UseCase<List<TagEntity>, NoParams>{
  final TagsRepository repository;

  LoadTagsUsecase({required this.repository});

  @override
  Future<Either<Error, List<TagEntity>>> call(params) async {
    try{
      var tags = await repository.getTags();
      return Right(tags);
    }
    on Error catch (error, _){
      return Left(error);
    }
    
  }

}