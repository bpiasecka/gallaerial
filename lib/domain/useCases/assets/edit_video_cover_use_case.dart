import 'dart:typed_data';

import 'package:fpdart/src/either.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/repositories/video_repository.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';

class EditVideoCoverUseCase extends UseCase<VideoEntity, EditVideoCoverUseCaseParams>{
  final VideoRepository repository;

  EditVideoCoverUseCase({required this.repository});

  @override
  Future<Either<Error, VideoEntity>> call(params) async {
    try{
      var newEntity = await repository.setVideoCover(params.video, params.cover);
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