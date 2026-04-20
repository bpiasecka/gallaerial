import 'dart:async';
import 'dart:developer';

import 'package:gallaerial/data/v_hive/dto/tag_dto.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/repositories/tags_repository.dart';
import 'package:hive/hive.dart';
import 'package:rxdart/subjects.dart';

class TagsRepositoryImpl implements TagsRepository {
  Box<TagDto> tagBox = Hive.box<TagDto>('tags');
  final _tagDataSubject = BehaviorSubject<List<TagEntity>>();

  void dispose() {
    _tagDataSubject.close();
  }

  Future<void> initData() async {
    await _migrateTagsOrder();

    if (tagBox.isEmpty) {
      await addTag("#FFFFFFFF", "Easy");
      await addTag("#FF888888", "Medium");
      await addTag("#FF000000", "Hard");
    }
    else {
      _broadcastUpdate();
    }
  }

  Future<void> _broadcastUpdate() async {
    var updatedTags = await getTags();
    _tagDataSubject.add(updatedTags);
  }

  @override
  Stream<List<TagEntity>> get tagDataStream => _tagDataSubject.stream;

  @override
  Future<List<TagEntity>> getTags() async {
    final tags = tagBox.values.map((dto) => dto.toTagEntity()).toList();
    tags.sort((a, b) => a.order.compareTo(b.order));
    return tags;
  }

  @override
  Future<TagEntity> addTag(String colorHex, String name) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final order = tagBox.length;

    final dto = TagDto(id: id, color: colorHex, name: name, order: order);
    await tagBox.put(id, dto);

    _broadcastUpdate();

    return dto.toTagEntity();
  }

  @override
  Future<void> removeTag(TagEntity tag) async {
    await tagBox.delete(tag.id);
    final tagsToShift = tagBox.values.where((dto) => dto.order > tag.order).toList();

    for (var dto in tagsToShift) {
      final updatedDto = TagDto(
        id: dto.id,
        color: dto.color,
        name: dto.name,
        order: dto.order - 1,
      );
      await tagBox.put(dto.id, updatedDto);
    }

    _broadcastUpdate();
  }

  @override
  Future<TagEntity> editTag(TagEntity tag, String newColorHex, String newName) async {
    final updatedDto = TagDto(
      id: tag.id, 
      color: newColorHex, 
      name: newName,
      order: tag.order
    );
    
    await tagBox.put(tag.id, updatedDto);

    _broadcastUpdate();

    return updatedDto.toTagEntity();
  }

@override
  Future<List<TagEntity>> changeTagsOrder(int oldTagOrder, int newTagOrder) async {
    if (oldTagOrder == newTagOrder) return await getTags();

    final allTags = tagBox.values.toList();
    final movedTagDto = allTags.firstWhere((dto) => dto.order == oldTagOrder);

    for (var dto in allTags) {
      if (dto.id == movedTagDto.id) continue;

      int updatedOrder = dto.order;

      if (oldTagOrder < newTagOrder) {
        if (dto.order > oldTagOrder && dto.order <= newTagOrder) {
          updatedOrder--;
        }
      } else {
        if (dto.order >= newTagOrder && dto.order < oldTagOrder) {
          updatedOrder++;
        }
      }
      if (updatedOrder != dto.order) {
        final shiftedDto = TagDto(
          id: dto.id,
          color: dto.color,
          name: dto.name,
          order: updatedOrder,
        );
        await tagBox.put(dto.id, shiftedDto);
      }
    }

    final updatedMovedDto = TagDto(
      id: movedTagDto.id,
      color: movedTagDto.color,
      name: movedTagDto.name,
      order: newTagOrder,
    );
    await tagBox.put(movedTagDto.id, updatedMovedDto);

    await _broadcastUpdate();

    return _tagDataSubject.value;
  }

  // ==========================================
  // MIGRATIONS

  Future<void> _migrateTagsOrder() async {
    final legacyTags = tagBox.values.where((dto) => dto.order == -1).toList();

    if (legacyTags.isEmpty) {
      return;
    }

    int currentMaxOrder = 0;
    for (var dto in tagBox.values) {
      if (dto.order > currentMaxOrder) {
        currentMaxOrder = dto.order;
      }
    }

    for (int i = 0; i < legacyTags.length; i++) {
      final oldDto = legacyTags[i];
      
      final updatedDto = TagDto(
        id: oldDto.id,
        color: oldDto.color,
        name: oldDto.name,
        order: currentMaxOrder + i + 1, 
      );
      await tagBox.put(updatedDto.id, updatedDto);
    }
    
    log("Hive Migration Complete: Updated ${legacyTags.length} legacy tags.");
  }
}