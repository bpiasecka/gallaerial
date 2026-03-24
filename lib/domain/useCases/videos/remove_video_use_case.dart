import 'package:fpdart/src/either.dart';
import 'package:gallaerial/domain/entities/video_entity.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';

class RemoveVideoUsecase extends UseCase<Null, VideoEntity>{
  final UserRepository userRepository;

  RemoveVideoUsecase({required this.userRepository});

  @override
  Future<Either<Error, Null>> call(video) async {
    try{
      userRepository.removeVideo(video);
      return const Right(null);
    }
    on Error catch (error, _){
      return Left(error);
    }
  }
}