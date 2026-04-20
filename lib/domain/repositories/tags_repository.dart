import 'package:gallaerial/domain/entities/tag_entity.dart';

abstract class TagsRepository {
  Stream<List<TagEntity>> get tagDataStream;

  Future<List<TagEntity>> getTags();
  Future<TagEntity> addTag(String colorHex, String name);
  Future<void> removeTag(TagEntity tag);
  Future<TagEntity> editTag(TagEntity tag, String newColorHex, String newName);
  Future<List<TagEntity>> changeTagsOrder(int oldTagOrder, int newTagOrder);
}