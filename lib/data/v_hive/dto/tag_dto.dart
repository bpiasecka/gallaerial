import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:hive/hive.dart';

part 'tag_dto.g.dart';

@HiveType(typeId: 0)
class TagDto{
  
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String color;
  @HiveField(3, defaultValue: -1) int order;

  TagDto({required this.id, required this.name, required this.color, required this.order});

  static TagDto fromTagEntity(TagEntity entity){
    return TagDto(id: entity.id, color: entity.color, name: entity.name, order: entity.order);
  }

  TagEntity toTagEntity(){
    return TagEntity(id: id, color: color, name: name, order: order);
  }
}