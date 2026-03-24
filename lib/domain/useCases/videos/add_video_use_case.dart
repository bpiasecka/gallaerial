import 'package:fpdart/src/either.dart';
import 'package:gallaerial/domain/entities/video_entity.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';

class AddVideosUsecase extends UseCase<Iterable<VideoEntity>, List<String>>{
  final UserRepository userRepository;

  AddVideosUsecase({required this.userRepository});

  @override
  Future<Either<Error, List<VideoEntity>>> call(paths) async {
    try{
      var newEntities = await userRepository.addVideos(paths);
      return Right(newEntities);
    }
    on Error catch (error, _){
      return Left(error);
    }
    
  }
}