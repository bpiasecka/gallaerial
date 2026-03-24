import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/entities/video_entity.dart';
import 'package:gallaerial/domain/useCases/tags/load_tags_use_case.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/domain/useCases/videos/edit_video_tags_use_case.dart';
import 'package:gallaerial/main.dart';

class VideoEditEvent {}

class InitWithVideoEvent extends VideoEditEvent {
  final VideoEntity video;

  InitWithVideoEvent({required this.video});
}

class TagClickedEvent extends VideoEditEvent {
  final TagEntity tag;

  TagClickedEvent({required this.tag});
}

class VideoEditState{
  final VideoEntity? videoEntity;
  final List<TagEntity>? allTags;

  VideoEditState({required this.videoEntity, required this.allTags});
}

class VideoEditBloc extends Bloc<VideoEditEvent, VideoEditState>{
  VideoEditBloc() : super(VideoEditState(videoEntity: null, allTags: null)){

    on<InitWithVideoEvent>((event, emit) async {
      var res = await service<LoadTagsUsecase>().call(NoParams());
      res.fold((e){}, (tags) => emit(VideoEditState(videoEntity: event.video, allTags: tags)));
    });

    on<TagClickedEvent>((event, emit) async {
      var res = await service<EditVideoTagsUseCase>().call(EditVideoTagsUseCaseParams(video: state.videoEntity!, clickedTagId: event.tag.id));
      res.fold((e){}, (video) => emit(VideoEditState(videoEntity: video, allTags: state.allTags)));
    });
  }
  
}