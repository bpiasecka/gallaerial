import 'package:bloc/bloc.dart';
import 'package:gallaerial/domain/entities/filter_model.dart';
import 'package:gallaerial/domain/entities/sort_model.dart';
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

class SetFilterAndSortEvent extends VideoListViewEvent {
  final FilterModel filter;
  final SortModel sort;

  SetFilterAndSortEvent({required this.filter, required this.sort});
}

class VideoListViewState {
  List<VideoEntity> addedVideosAssets;
  List<TagEntity> allTags;
  FilterModel filter;
  SortModel sort;

  VideoListViewState({required this.addedVideosAssets, required this.allTags, required this.filter, required this.sort});
}

class VideoListBloc extends Bloc<VideoListViewEvent, VideoListViewState> {
  VideoListBloc() : super(VideoListViewState(addedVideosAssets: [], allTags: [], filter: FilterModel(), sort: SortModel.empty())) {
    on<LoadVideosEvent>((event, emit) async {
      var resVideos = await service<LoadVideosUsecase>().call(
        LoadVideoParams(filter: state.filter, sort: state.sort));
      var resTags = await service<LoadTagsUsecase>().call(NoParams());

      List<VideoEntity> videos = resVideos.fold(
          (l) => <VideoEntity>[], (r) => r);
      List<TagEntity> tags = resTags.fold(
          (l) => [], (r) => r);
      emit(VideoListViewState(addedVideosAssets: videos, allTags: tags, filter: state.filter, sort: state.sort));

//Listen to stream
      await emit.forEach<List<VideoEntity>>(
        service<UserRepository>().videoDataStream,
        onData: (updatedVideos) {
          if(updatedVideos.length > state.addedVideosAssets.length) add(SetFilterAndSortEvent(filter: state.filter, sort: state.sort));
          return VideoListViewState(addedVideosAssets: updatedVideos, allTags: state.allTags, filter: state.filter, sort: state.sort);
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
    on<SetFilterAndSortEvent>((event, emit) async {
      var resVideos = await service<LoadVideosUsecase>().call(
        LoadVideoParams(filter: event.filter, sort: event.sort));

      List<VideoEntity> videos = resVideos.fold(
          (e) => <VideoEntity>[], (r) => r);
      emit(VideoListViewState(addedVideosAssets: videos, allTags: state.allTags, filter: event.filter, sort: event.sort));
    });
  }
}
