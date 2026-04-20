import 'package:gallaerial/domain/entities/asset_entity.dart';

class FilterModel {
  final String? name;
  final List<String>? tagIds;
  final bool alternativeTags;

  FilterModel({this.name, this.tagIds,  this.alternativeTags = false});

  bool match(UserAssetEntity asset){
    if(name != null && name!.isNotEmpty){
      if(!asset.name.toLowerCase().contains(name!.toLowerCase())){
        return false;
      }
    }
    if(tagIds != null && tagIds!.isNotEmpty){
      if(asset.tagIds.isEmpty) return false;
      if(alternativeTags){
        if(!asset.tagIds.any((tagId) => tagIds!.contains(tagId))){
          return false;
        }
      } else{
        if(tagIds!.any((selectedTag) => !asset.tagIds.contains(selectedTag))){
          return false;
        }
      }
    }

    return true;
  }

  bool isEmpty(){
    return (name == null || name!.isEmpty) && (tagIds == null || tagIds!.isEmpty);
  }
}