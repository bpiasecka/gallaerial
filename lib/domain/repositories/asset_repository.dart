import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/entities/filter_model.dart';
import 'package:gallaerial/domain/entities/sort_model.dart';

abstract class AssetRepository<Entity extends UserAssetEntity> {
  Stream<List<Entity>> get entityDataStream;

  Future<List<Entity>> getAssets({FilterModel? filterModel, SortModel? sortModel});
  Future<List<Entity>> addAssets(List<String> paths);
  Future<void> removeAsset(Entity asset);
  Future<Entity> editAsset(Entity asset, String newName, List<String> newTagIds);
}