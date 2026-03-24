import 'package:fpdart/src/either.dart';
import 'package:gallaerial/domain/entities/filter_model.dart';
import 'package:gallaerial/domain/entities/sort_model.dart';
import 'package:gallaerial/domain/entities/video_entity.dart';
import 'package:gallaerial/domain/useCases/use_case.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';

class LoadVideosUsecase extends UseCase<List<VideoEntity>, LoadVideoParams>{
  final UserRepository userRepository;

  LoadVideosUsecase({required this.userRepository});

  @override
  Future<Either<Error, List<VideoEntity>>> call(params) async {
    try{
      var videos = await userRepository.getVideos(filterModel: params.filter, sortModel: params.sort);
      return Right(videos);
    }
    on Error catch (error, _){
      return Left(error);
    }
    
  }
}

class LoadVideoParams{
  final FilterModel? filter;
  final SortModel? sort;

  LoadVideoParams({this.filter, this.sort});
}