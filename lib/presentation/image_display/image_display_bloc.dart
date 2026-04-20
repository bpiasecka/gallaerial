import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/repositories/image_repository.dart';
import 'package:gallaerial/domain/useCases/assets/edit_asset_name_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/load_tags_use_case.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/main.dart';

class ImageDisplayEvent {}

class InitializeWithImageEvent extends ImageDisplayEvent {
  final String imageId;

  InitializeWithImageEvent({required this.imageId});
}

class EditImageNameEvent extends ImageDisplayEvent {
  final String newName;

  EditImageNameEvent({required this.newName});
}

class ImageDisplayState {
  final ImageEntity? imageEntity;
  final List<TagEntity> allTags;

  ImageDisplayState({required this.imageEntity, required this.allTags});
}

class ImageDisplayBloc extends Bloc<ImageDisplayEvent, ImageDisplayState>{
  ImageDisplayBloc() : super(ImageDisplayState(imageEntity: null, allTags: [])){
    on<InitializeWithImageEvent>((event, emit) async {
      var tagsResult = await dependencyService<LoadTagsUsecase>().call(NoParams());
      var tags = tagsResult.fold((l) => <TagEntity>[], (r) => r);

       await emit.forEach<List<ImageEntity>>(
        dependencyService<ImageRepository>().entityDataStream,
        onData: (updatedImages) {
          final currentImage = updatedImages
              .where((img) => img.id == event.imageId)
              .firstOrNull;

          return ImageDisplayState(
            imageEntity: currentImage, 
            allTags: tags
          );
        },
        onError: (error, stackTrace) {
          return state; 
        },
      );
    });
    on<EditImageNameEvent>((event, emit) async {
      dependencyService<EditAssetNameUseCase<ImageEntity>>().call(
          EditAssetNameUseCaseParams(newName: event.newName, asset: state.imageEntity!));
    });
  }
}