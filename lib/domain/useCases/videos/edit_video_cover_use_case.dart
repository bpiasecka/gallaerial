import 'dart:typed_data';

import 'package:fpdart/src/either.dart';
import 'package:gallaerial/domain/entities/video_entity.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';

class EditVideoCoverUseCase extends UseCase<VideoEntity, EditVideoCoverUseCaseParams>{
  final UserRepository userRepository;

  EditVideoCoverUseCase({required this.userRepository});

  @override
  Future<Either<Error, VideoEntity>> call(params) async {
    try{
      var newEntity = await userRepository.setVideoCover(params.video, params.cover);
      return Right(newEntity);
    }
    on Error catch (error, _){
      return Left(error);
    }
  }
}

class EditVideoCoverUseCaseParams{
  final VideoEntity video;
  final Uint8List cover;

  EditVideoCoverUseCaseParams({required this.video, required this.cover});
}