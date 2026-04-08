import 'package:fpdart/src/either.dart';
import 'package:gallaerial/domain/entities/settings_model.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';

class GetSettingsUsecase extends UseCase<SettingsModel, NoParams>{
  final UserRepository userRepository;

  GetSettingsUsecase({required this.userRepository});

  @override
  Future<Either<Error, SettingsModel>> call(_) async {
    try{
      var settings = await userRepository.getSettings();
      return Right(settings);
    }
    on Error catch (error, _){
      return Left(error);
    }
    
  }
}
