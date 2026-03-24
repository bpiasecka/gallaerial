import 'package:fpdart/src/either.dart';
import 'package:gallaerial/domain/entities/video_entity.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';

class EditVideoNameUseCase extends UseCase<VideoEntity, EditVideoNameUseCaseParams>{
  final UserRepository userRepository;

  EditVideoNameUseCase({required this.userRepository});

  @override
  Future<Either<Error, VideoEntity>> call(params) async {
    try{
      var newEntity = await userRepository.editVideo(params.video, params.newName, params.video.tagIds);
      return Right(newEntity);
    }
    on Error catch (error, _){
      return Left(error);
    }
  }
}

class EditVideoNameUseCaseParams{
  final VideoEntity video;
  final String newName;

  EditVideoNameUseCaseParams({required this.video, required this.newName});
}