import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/entities/video_entity.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';
import 'package:gallaerial/domain/useCases/tags/load_tags_use_case.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/domain/useCases/videos/edit_video_name_use_case.dart';
import 'package:gallaerial/domain/useCases/videos/get_video_use_case.dart';
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

class VideoPlayerState {
  final VideoEntity? videoEntity;
  final List<TagEntity> allTags;

  VideoPlayerState({required this.videoEntity, required this.allTags});
}

class VideoPlayerBloc extends Bloc<VideoPlayerEvent, VideoPlayerState>{
  VideoPlayerBloc() : super(VideoPlayerState(videoEntity: null, allTags: [])){
    on<InitializeWithVideoEvent>((event, emit) async {
      var getVideo = await service<GetVideoUsecase>().call(event.videoId);
      var videoEntity = getVideo.fold((e){}, (v) => v);
      var tags = await service<LoadTagsUsecase>().call(NoParams());
      
      tags.fold((e){}, (tags) => emit(VideoPlayerState(videoEntity: videoEntity, allTags: tags)));

       await emit.forEach<List<VideoEntity>>(
        service<UserRepository>().videoDataStream,
        onData: (updatedVideos) {
          return VideoPlayerState(videoEntity: updatedVideos.firstWhere((v) => v.id == state.videoEntity!.id), allTags: state.allTags);
        },
      );
    });
    on<EditVideoNameEvent>((event, emit) async {
      service<EditVideoNameUseCase>().call(
          EditVideoNameUseCaseParams(newName: event.newName, video: state.videoEntity!));
    });
  }
}