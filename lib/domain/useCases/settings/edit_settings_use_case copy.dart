import 'package:fpdart/src/either.dart';
import 'package:gallaerial/domain/entities/settings_model.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';

class EditSettingsUsecase extends UseCase<SettingsModel, SettingsModel>{
  final UserRepository userRepository;

  EditSettingsUsecase({required this.userRepository});

  @override
  Future<Either<Error, SettingsModel>> call(newSettings) async {
    try{
      var settings = await userRepository.editSettings(newSettings);
      return Right(settings);
    }
    on Error catch (error, _){
      return Left(error);
    }
    
  }
}
