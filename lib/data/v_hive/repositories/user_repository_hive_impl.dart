import 'dart:async';
import 'dart:developer';

import 'package:gallaerial/data/v_hive/dto/tag_dto.dart';
import 'package:gallaerial/data/v_hive/dto/video_dto.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/entities/video_entity.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';

import 'package:hive/hive.dart';

class UserRepositoryHiveImpl implements UserRepository {
  late Box<VideoDto> videoBox;
  late Box<TagDto> tagBox;

  final _videoDataController = StreamController<List<VideoEntity>>.broadcast();
  final _tagDataController = StreamController<List<TagEntity>>.broadcast();

  @override
  Stream<List<VideoEntity>> get videoDataStream => _videoDataController.stream;
  @override
  Stream<List<TagEntity>> get tagDataStream => _tagDataController.stream;

  @override
  Future<void> initialize() async {
    videoBox = await Hive.openBox('videos');
    tagBox = await Hive.openBox('tags');

    await _migrateTagsOrder();

    if(tagBox.isEmpty){
      addTag("#FFFFFFFF", "Easy");
      addTag("#FF888888", "Medium");
      addTag("#FF000000", "Hard");

    }
  }

  void dispose() {
    _videoDataController.close();
    _tagDataController.close();
  }

  // ==========================================
  // VIDEOS

  @override
  Future<List<VideoEntity>> getVideos() async {
    return videoBox.values.map((dto) => dto.toVideoEntity()).toList();
  }

  @override
  Future<List<VideoEntity>> addVideos(List<String> assetIds) async {
    final List<VideoEntity> addedVideos = [];

    for (String assetId in assetIds) {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      const String defaultName = "video name"; 
      final dto = VideoDto(id: id, assetId: assetId, name: defaultName, tagIds: []);

      await videoBox.put(id, dto);
      addedVideos.add(dto.toVideoEntity());
    }

    var updatedVideos = await getVideos();
    _videoDataController.add(updatedVideos);

    return addedVideos;
  }

  @override
  Future<void> removeVideo(VideoEntity video) async {
    await videoBox.delete(video.id);

    var updatedVideos = await getVideos();
    _videoDataController.add(updatedVideos);
  }

  @override
  Future<VideoEntity> editVideo(VideoEntity video, String newName, List<String> newTagIds) async {
    final updatedDto = VideoDto(
      id: video.id, 
      assetId: video.assetId,
      name: newName,
      tagIds: video.tagIds
    );
    
    await videoBox.put(video.id, updatedDto);

    var updatedVideos = await getVideos();
    _videoDataController.add(updatedVideos);
    
    return updatedDto.toVideoEntity();
  }

  // ==========================================
  // TAGS

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

    var updatedTags = await getTags();
    _tagDataController.add(updatedTags);

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

    var updatedTags = await getTags();
    _tagDataController.add(updatedTags);
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

    var updatedTags = await getTags();
    _tagDataController.add(updatedTags);

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

    var updatedTags = await getTags();
    _tagDataController.add(updatedTags);

    return updatedTags;
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