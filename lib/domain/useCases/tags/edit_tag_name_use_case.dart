import 'package:fpdart/fpdart.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';

class EditTagNameUseCase extends UseCase<TagEntity, EditTagNameParams>{
  final UserRepository userRepository;

  EditTagNameUseCase({required this.userRepository});

  @override
  Future<Either<Error, TagEntity>> call(params) async {
    try{
      var newEnityty = await userRepository.editTag(params.oldTag, params.oldTag.color, params.newName);
      return Right(newEnityty);
    }
    on Error catch (error, _){
      return Left(error);
    }
    
  }

}

class EditTagNameParams{
  final String newName;
  final TagEntity oldTag;

  EditTagNameParams({required this.newName, required this.oldTag});

}