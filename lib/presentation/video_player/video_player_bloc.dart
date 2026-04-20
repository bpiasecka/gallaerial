import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/repositories/video_repository.dart';
import 'package:gallaerial/domain/useCases/assets/edit_asset_name_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/load_tags_use_case.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/domain/useCases/assets/edit_video_cover_use_case.dart';
import 'package:gallaerial/main.dart';

class VideoPlayerEvent {}

class InitializeWithVideoEvent extends VideoPlayerEvent {
  final String videoId;

  InitializeWithVideoEvent({required this.videoId});
}

class EditVideoNameEvent extends VideoPlayerEvent {
  final String newName;

  EditVideoNameEvent({required this.newName});
}

class SetCoverImageEvent extends VideoPlayerEvent {
  final Uint8List image;

  SetCoverImageEvent({required this.image});
}

class VideoPlayerState {
  final VideoEntity? videoEntity;
  final List<TagEntity> allTags;

  VideoPlayerState({required this.videoEntity, required this.allTags});
}

class VideoPlayerBloc extends Bloc<VideoPlayerEvent, VideoPlayerState>{
  VideoPlayerBloc() : super(VideoPlayerState(videoEntity: null, allTags: [])){
    on<InitializeWithVideoEvent>((event, emit) async {
      var tagsResult = await dependencyService<LoadTagsUsecase>().call(NoParams());
      var tags = tagsResult.fold((l) => <TagEntity>[], (r) => r);

       await emit.forEach<List<VideoEntity>>(
        dependencyService<VideoRepository>().entityDataStream,
        onData: (updatedVideos) {
          final currentVideo = updatedVideos
              .where((v) => v.id == event.videoId)
              .firstOrNull;

          return VideoPlayerState(
            videoEntity: currentVideo, 
            allTags: tags
          );
        },
        onError: (error, stackTrace) {
          return state; 
        },
      );
    });
    on<EditVideoNameEvent>((event, emit) async {
      dependencyService<EditAssetNameUseCase<VideoEntity>>().call(
          EditAssetNameUseCaseParams(newName: event.newName, asset: state.videoEntity!));
    });
    on<SetCoverImageEvent>((event, emit){
      dependencyService<EditVideoCoverUseCase>().call(EditVideoCoverUseCaseParams(video: state.videoEntity!, cover: event.image));
    });
  }
}