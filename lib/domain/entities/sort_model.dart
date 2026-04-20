import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:photo_manager/photo_manager.dart';

class SortModel {
  final DateSortParameter dateParameter;
  final DurationSortParameter durationParameter;

  SortModel({required this.dateParameter, required this.durationParameter});

  static SortModel empty() => SortModel(dateParameter: DateSortParameter.none, durationParameter: DurationSortParameter.none);

  Future<void> sort(List<UserAssetEntity> list) async {
    if(dateParameter == DateSortParameter.none && durationParameter == DurationSortParameter.none) return;

    final Map<String, AssetEntity?> assetCache = {};

    await Future.wait(list.map((userAsset) async {
      var asset = await AssetEntity.fromId(userAsset.assetId);
      assetCache[userAsset.assetId] = asset;
    }));

    if(dateParameter == DateSortParameter.newest){
      list.sort((a, b) {
        var assetA = assetCache[a.assetId];
        var assetB = assetCache[b.assetId];    

        var dateA = assetA?.createDateTime ?? DateTime.fromMicrosecondsSinceEpoch(0);
        var dateB = assetB?.createDateTime ?? DateTime.fromMicrosecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
    }

    if(dateParameter == DateSortParameter.oldest){
      list.sort((a, b) {
        var assetA = assetCache[a.assetId];
        var assetB = assetCache[b.assetId];   

        var dateA = assetA?.createDateTime ?? DateTime.fromMicrosecondsSinceEpoch(0);
        var dateB = assetB?.createDateTime ?? DateTime.fromMicrosecondsSinceEpoch(0);
        return dateA.compareTo(dateB);
      });
    }

    if(durationParameter == DurationSortParameter.longest){
      list.sort((a, b) {
        var assetA = assetCache[a.assetId];
        var assetB = assetCache[b.assetId];  

        var durationA = assetA?.duration ?? 0;
        var durationB = assetB?.duration ?? 0;
        return durationB.compareTo(durationA);
      });
    }

    if(durationParameter == DurationSortParameter.shortest){
      list.sort((a, b) {
        var assetA = assetCache[a.assetId];
        var assetB = assetCache[b.assetId];  

        var durationA = assetA?.duration ?? 0;
        var durationB = assetB?.duration ?? 0;
        return durationA.compareTo(durationB);
      });
    }
  }
}

enum DateSortParameter{
  newest, oldest, none
}

enum DurationSortParameter{
  longest, shortest, none
}