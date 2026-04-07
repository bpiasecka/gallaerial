import 'package:fpdart/src/either.dart';
import 'package:gallaerial/domain/entities/video_entity.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';

class EditVideoTagsUseCase extends UseCase<VideoEntity, EditVideoTagsUseCaseParams>{
  final UserRepository userRepository;

  EditVideoTagsUseCase({required this.userRepository});

  @override
  Future<Either<Error, VideoEntity>> call(params) async {
    try{
      var newTags = <String>[];
      if(params.video.tagIds.contains(params.clickedTagId)){
        newTags = params.video.tagIds..removeWhere((tagId) => tagId == params.clickedTagId);
      }
      else{
        newTags = params.video.tagIds..add(params.clickedTagId);
      }
      var newEntity = await userRepository.editVideo(params.video, params.video.name, newTags, params.video.coverPath);
      return Right(newEntity);
    }
    on Error catch (error, _){
      return Left(error);
    }
  }
}

class EditVideoTagsUseCaseParams{
  final VideoEntity video;
  final String clickedTagId;

  EditVideoTagsUseCaseParams({required this.video, required this.clickedTagId});
}