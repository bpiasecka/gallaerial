import 'package:gallaerial/domain/entities/video_entity.dart';

class FilterModel {
  final String? name;
  final List<String>? tagIds;
  final bool alternativeTags;

  FilterModel({this.name, this.tagIds,  this.alternativeTags = false});

  bool match(VideoEntity video){
    if(name != null && name!.isNotEmpty){
      if(!video.name.contains(name!)){
        return false;
      }
    }
    if(tagIds != null && tagIds!.isNotEmpty){
      if(alternativeTags){
        if(!video.tagIds.any((tagId) => tagIds!.contains(tagId))){
          return false;
        }
      } else{
        if(video.tagIds.any((tagId) => !tagIds!.contains(tagId))){
          return false;
        }
      }
    }

    return true;
  }
}