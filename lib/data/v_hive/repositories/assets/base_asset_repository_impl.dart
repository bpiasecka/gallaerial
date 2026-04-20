import 'package:gallaerial/data/v_hive/dto/assets/asset_dto.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/entities/filter_model.dart';
import 'package:gallaerial/domain/entities/sort_model.dart';
import 'package:hive/hive.dart';
import 'package:rxdart/rxdart.dart';

abstract class BaseAssetRepository<E extends UserAssetEntity, D extends AssetDto> {
  Box<D> get box;
  String get defaultName;

  final BehaviorSubject<List<E>> _dataSubject = BehaviorSubject<List<E>>();
  Stream<List<E>> get entityDataStream => _dataSubject.stream;

  E mapToEntity(D dto);
  D mapToDto(E entity);
  D createNewDto(String id, String assetId, String name);

  Future<void> cleanUpInfrastructure(E entity);

  void dispose() {
    _dataSubject.close();
  }

  Future<void> initData() async {
    await broadcastUpdate();
  }

  Future<List<E>> getAssets({FilterModel? filterModel, SortModel? sortModel}) async {
    List<E> assets = box.values.map((dto) => mapToEntity(dto)).toList();
    
    if (filterModel != null) {
      assets = assets.where((a) => filterModel.match(a)).toList();
    }
    if (sortModel != null) {
      await sortModel.sort(assets);
    }
    return assets;
  }

  Future<List<E>> addAssets(List<String> assetIds) async {
    final List<E> addedAssets = [];

    for (String assetId in assetIds) {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final dto = createNewDto(id, assetId, defaultName);

      await box.put(id, dto);
      addedAssets.add(mapToEntity(dto));
    }

    await broadcastUpdate();
    return addedAssets;
  }

  Future<void> removeAsset(E asset) async {
    await box.delete(asset.id);
    await cleanUpInfrastructure(asset);
    await broadcastUpdate();
  }

  Future<E> editAsset(E asset, String newName, List<String> newTagIds) async {
    final updatedDto = mapToDto(asset)..name = newName..tagIds = newTagIds; 
    
    await box.put(asset.id, updatedDto);
    await broadcastUpdate();
    
    return mapToEntity(updatedDto);
  }

  Future<void> broadcastUpdate() async {
    var updatedAssets = await getAssets();
    _dataSubject.add(updatedAssets);
  }
}