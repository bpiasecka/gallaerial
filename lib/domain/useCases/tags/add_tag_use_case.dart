import 'dart:ui';

import 'package:fpdart/fpdart.dart';
import 'package:gallaerial/domain/entities/tag_entity.dart';
import 'package:gallaerial/domain/repositories/tags_repository.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/extensions/color_extension.dart';

class AddTagUsecase extends UseCase<TagEntity, TagParams>{
  final TagsRepository repository;

  AddTagUsecase({required this.repository});

  @override
  Future<Either<Error, TagEntity>> call(params) async {
    try{
      var entity = await repository.addTag(params.color.toHex(), params.name);
      return Right(entity);
    }
    on Error catch (error, _){
      return Left(error);
    }
  }
}

class TagParams{
  final String name;
  final Color color;

  TagParams({required this.name, required this.color});
}