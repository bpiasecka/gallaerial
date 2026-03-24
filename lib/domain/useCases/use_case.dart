import 'package:fpdart/fpdart.dart';

// Type: What the UseCase returns (e.g., Weather)
// Params: What the UseCase needs to do its job (e.g., String cityName)
abstract class UseCase<ReturnType, Params> {
  Future<Either<Error, ReturnType>> call(Params params);
}

// A special type for UseCases that don't need any parameters
class NoParams {}