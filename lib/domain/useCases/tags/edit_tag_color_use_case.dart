import 'dart:ui';
import 'package:fpdart/fpdart.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/repositories/tags_repository.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/extensions/color_extension.dart';

class EditTagColorUseCase extends UseCase<TagEntity, EditTagColorParams>{
  final TagsRepository repository;

  EditTagColorUseCase({required this.repository});

  @override
  Future<Either<Error, TagEntity>> call(params) async {
    try{
      var newEntity = await repository.editTag(params.oldTag, params.color.toHex(), params.oldTag.name);
      return Right(newEntity);
    }
    on Error catch (error, _){
      return Left(error);
    }
  }
}

class EditTagColorParams{
  final Color color;
  final TagEntity oldTag;

  EditTagColorParams({required this.color, required this.oldTag});

}