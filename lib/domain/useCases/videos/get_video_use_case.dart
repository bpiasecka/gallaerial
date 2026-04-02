import 'package:fpdart/src/either.dart';
import 'package:gallaerial/domain/entities/video_entity.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';

class GetVideoUsecase extends UseCase<VideoEntity, String>{
  final UserRepository userRepository;

  GetVideoUsecase({required this.userRepository});

  @override
  Future<Either<Error, VideoEntity>> call(videoId) async {
    try{
      var videos = await userRepository.getVideos();
      return Right(videos.firstWhere((v) => v.id == videoId));
    }
    on Error catch (error, _){
      return Left(error);
    }
    
  }
}
