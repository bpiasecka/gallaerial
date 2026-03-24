import 'package:bloc/bloc.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';
import 'package:gallaerial/domain/useCases/tags/load_tags_use_case.dart';
import 'package:gallaerial/main.dart';
import 'package:gallaerial/domain/entities/video_entity.dart';
import 'package:gallaerial/domain/useCases/videos/add_video_use_case.dart';
import 'package:gallaerial/domain/useCases/videos/edit_video_name_use_case.dart';
import 'package:gallaerial/domain/useCases/videos/load_videos_use_case.dart';
import 'package:gallaerial/domain/useCases/videos/remove_video_use_case.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';

class VideoListViewEvent {}

class LoadVideosEvent extends VideoListViewEvent {}

class VideoAddedEvent extends VideoListViewEvent {
  final List<String> assetIds;

  VideoAddedEvent({required this.assetIds});
}

class VideoRemovedEvent extends VideoListViewEvent {
  final VideoEntity video;

  VideoRemovedEvent({required this.video});
}

class EditVideoNameEvent extends VideoListViewEvent {
  final VideoEntity video;
  final String newName;

  EditVideoNameEvent({required this.video, required this.newName});
}

class VideoListViewState {
  List<VideoEntity> addedVideosAssets;
  List<TagEntity> allTags;

  VideoListViewState({required this.addedVideosAssets, required this.allTags});
}

class VideoListBloc extends Bloc<VideoListViewEvent, VideoListViewState> {
  VideoListBloc() : super(VideoListViewState(addedVideosAssets: [], allTags: [])) {
    on<LoadVideosEvent>((event, emit) async {
      var resVideos = await service<LoadVideosUsecase>().call(NoParams());
      var resTags = await service<LoadTagsUsecase>().call(NoParams());

      List<VideoEntity> videos = resVideos.fold(
          (l) => <VideoEntity>[], (r) => r);
      List<TagEntity> tags = resTags.fold(
          (l) => [], (r) => r);
      emit(VideoListViewState(addedVideosAssets: videos, allTags: tags));

//Listen to stream
      await emit.forEach<List<VideoEntity>>(
        service<UserRepository>().videoDataStream,
        onData: (updatedVideos) {
          return VideoListViewState(addedVideosAssets: updatedVideos, allTags: state.allTags);
        },
      );
      
    });
    on<VideoAddedEvent>((event, emit) async {
      service<AddVideosUsecase>().call(event.assetIds);
    });
    on<VideoRemovedEvent>((event, emit) {
      service<RemoveVideoUsecase>().call(event.video);
    });
    on<EditVideoNameEvent>((event, emit) async {
      service<EditVideoNameUseCase>().call(
          EditVideoNameUseCaseParams(newName: event.newName, video: event.video));
    });
  }
}
