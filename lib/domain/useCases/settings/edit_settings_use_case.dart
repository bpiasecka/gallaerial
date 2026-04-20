import 'package:fpdart/src/either.dart';
import 'package:gallaerial/domain/entities/settings_model.dart';
import 'package:gallaerial/domain/repositories/settings_repository.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';

class EditSettingsUseCase extends UseCase<SettingsModel, SettingsModel>{
  final SettingsRepository repository;

  EditSettingsUseCase({required this.repository});

  @override
  Future<Either<Error, SettingsModel>> call(newSettings) async {
    try{
      var settings = await repository.editSettings(newSettings);
      return Right(settings);
    }
    on Error catch (error, _){
      return Left(error);
    }
    
  }
}
