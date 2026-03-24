import 'package:fpdart/fpdart.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';

class LoadTagsUsecase extends UseCase<List<TagEntity>, NoParams>{
  final UserRepository userRepository;

  LoadTagsUsecase({required this.userRepository});

  @override
  Future<Either<Error, List<TagEntity>>> call(params) async {
    try{
      var tags = await userRepository.getTags();
      return Right(tags);
    }
    on Error catch (error, _){
      return Left(error);
    }
    
  }

}