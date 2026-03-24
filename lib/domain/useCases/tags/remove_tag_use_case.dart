import 'package:fpdart/fpdart.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';

class RemoveTagUsecase extends UseCase<Null, TagEntity>{
  final UserRepository userRepository;

  RemoveTagUsecase({required this.userRepository});

  @override
  Future<Either<Error, Null>> call(params) async {
    try{
      userRepository.removeTag(params);
      return const Right(null);
    }
    on Error catch (error, _){
      return Left(error);
    }
    
  }

}