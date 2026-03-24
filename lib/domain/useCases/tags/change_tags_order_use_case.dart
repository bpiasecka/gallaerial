import 'package:fpdart/fpdart.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';

class ChangeTagsOrderUseCase extends UseCase<List<TagEntity>, ChangeTagsOrderParams>{
  final UserRepository userRepository;

  ChangeTagsOrderUseCase({required this.userRepository});

  @override
  Future<Either<Error, List<TagEntity>>> call(params) async {
    try{
      var entities = await userRepository.changeTagsOrder(params.movedTag.order, params.newTagOrder);
      return Right(entities);
    }
    on Error catch (error, _){
      return Left(error);
    }
  }
}

class ChangeTagsOrderParams{
  final TagEntity movedTag;
  final int newTagOrder;

  ChangeTagsOrderParams({required this.movedTag, required this.newTagOrder});

}