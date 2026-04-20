import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/repositories/tags_repository.dart';
import 'package:gallaerial/domain/useCases/tags/add_tag_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/change_tags_order_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/edit_tag_color_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/edit_tag_name_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/remove_tag_use_case.dart';
import 'package:gallaerial/main.dart';

class TagListViewEvent {}

class LoadTagsEvent extends TagListViewEvent {}

class AddTagEvent extends TagListViewEvent {
  final Color color;
  final String name;

  AddTagEvent({required this.color, required this.name});
}

class RemoveTagEvent extends TagListViewEvent {
  final TagEntity tag;

  RemoveTagEvent({required this.tag});
}

class EditTagColorEvent extends TagListViewEvent {
  final TagEntity oldTag;
  final Color color;

  EditTagColorEvent({required this.oldTag, required this.color});
}

class EditTagNameEvent extends TagListViewEvent {
  final TagEntity oldTag;
  final String name;

  EditTagNameEvent({required this.oldTag, required this.name});
}

class ChangeOrderEvent extends TagListViewEvent {
  final TagEntity tag;
  final int newOrder;

  ChangeOrderEvent({required this.tag, required this.newOrder});
}

class TagListViewState {
  final List<TagEntity> tags;

  TagListViewState({required this.tags});
}

class TagListBloc extends Bloc<TagListViewEvent, TagListViewState>{
  TagListBloc() : super(TagListViewState(tags: [])){
    on<LoadTagsEvent>((event, emit) async {
      await emit.forEach<List<TagEntity>>(
        dependencyService<TagsRepository>().tagDataStream,
        onData: (updatedTags) {
          return TagListViewState(tags: updatedTags);
        },
      );
    });

    on<AddTagEvent>((event, emit) async {
      dependencyService<AddTagUsecase>().call(TagParams(name: event.name, color: event.color));
    });

    on<RemoveTagEvent>((event, emit){
      dependencyService<RemoveTagUsecase>().call(event.tag);
    });

    on<EditTagColorEvent>((event, emit){
      dependencyService<EditTagColorUseCase>().call(EditTagColorParams(color: event.color, oldTag: event.oldTag));
    });

    on<EditTagNameEvent>((event, emit){
      dependencyService<EditTagNameUseCase>().call(EditTagNameParams(newName: event.name, oldTag: event.oldTag));
    });

    on<ChangeOrderEvent>((event, emit) async {
      final optimisticTags = List<TagEntity>.from(state.tags)
      ..sort((a, b) => a.order.compareTo(b.order));
    final oldIndex = optimisticTags.indexWhere((t) => t.id == event.tag.id);
    if (oldIndex != -1) {
      final movedTag = optimisticTags.removeAt(oldIndex);
      optimisticTags.insert(event.newOrder, movedTag);

      emit(TagListViewState(tags: optimisticTags)); 

      var res = await dependencyService<ChangeTagsOrderUseCase>().call(ChangeTagsOrderParams(movedTag: event.tag, newTagOrder: event.newOrder));
      res.fold((e){}, (tags) => emit(TagListViewState(tags: tags)));
    }
    });
  }
  
}