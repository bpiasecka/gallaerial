import 'package:flutter/material.dart';
import 'package:gallaerial/data/v_hive/dto/settings_dto.dart';
import 'package:gallaerial/data/v_hive/dto/tag_dto.dart';
import 'package:gallaerial/data/v_hive/dto/video_dto.dart';
import 'package:gallaerial/domain/useCases/settings/edit_settings_use_case%20copy.dart';
import 'package:gallaerial/domain/useCases/settings/get_settings_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/change_tags_order_use_case.dart';
import 'package:gallaerial/domain/useCases/videos/edit_video_cover_use_case.dart';
import 'package:gallaerial/domain/useCases/videos/edit_video_tags_use_case.dart';
import 'package:gallaerial/domain/useCases/videos/get_video_use_case.dart';
import 'package:gallaerial/presentation/main/main_view.dart';
import 'package:gallaerial/presentation/video_edit/video_edit_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:gallaerial/data/v_hive/repositories/user_repository_hive_impl.dart';
import 'package:gallaerial/domain/useCases/tags/add_tag_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/edit_tag_color_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/edit_tag_name_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/load_tags_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/remove_tag_use_case.dart';
import 'package:gallaerial/domain/useCases/videos/add_video_use_case.dart';
import 'package:gallaerial/domain/useCases/videos/edit_video_name_use_case.dart';
import 'package:gallaerial/domain/useCases/videos/load_videos_use_case.dart';
import 'package:gallaerial/domain/useCases/videos/remove_video_use_case.dart';
import 'package:gallaerial/domain/repositories/user_repository.dart';
import 'package:gallaerial/presentation/main/main_bloc.dart';
import 'package:gallaerial/presentation/tag_list/tag_list_bloc.dart';
import 'package:gallaerial/presentation/video_list/video_list_bloc.dart';
import 'package:gallaerial/presentation/video_player/video_player_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:photo_manager/photo_manager.dart';

final GetIt service = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PhotoManager.clearFileCache();
  await initHive();
  await initService();
  runApp(const MyApp());

}

Future<void> initHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TagDtoAdapter());
    Hive.registerAdapter(VideoDtoAdapter());
    Hive.registerAdapter(SettingsDtoAdapter());
}

Future<void> initService() async {
  service.registerFactory(() => MainBloc());
  service.registerFactory(() => VideoListBloc());
  service.registerFactory(() => VideoPlayerBloc());
  service.registerFactory(() => TagListBloc());
  service.registerFactory(() => VideoEditBloc());
  service.registerLazySingleton(() => EditSettingsUsecase(userRepository: service()));
  service.registerLazySingleton(() => GetSettingsUsecase(userRepository: service()));
  service.registerLazySingleton(() => ChangeTagsOrderUseCase(userRepository: service()));
  service.registerLazySingleton(() => EditVideoCoverUseCase(userRepository: service()));
  service.registerLazySingleton(() => GetVideoUsecase(userRepository: service()));
  service.registerLazySingleton(() => LoadVideosUsecase(userRepository: service()));
  service.registerLazySingleton(() => AddVideosUsecase(userRepository: service()));
  service.registerLazySingleton(() => RemoveVideoUsecase(userRepository: service()));
  service.registerLazySingleton(() => EditVideoNameUseCase(userRepository: service()));
  service.registerLazySingleton(() => EditVideoTagsUseCase(userRepository: service()));
  service.registerLazySingleton(() => LoadTagsUsecase(userRepository: service()));
  service.registerLazySingleton(() => AddTagUsecase(userRepository: service()));
  service.registerLazySingleton(() => RemoveTagUsecase(userRepository: service()));
  service.registerLazySingleton(() => EditTagNameUseCase(userRepository: service()));
  service.registerLazySingleton(() => EditTagColorUseCase(userRepository: service()));
  service.registerLazySingleton<UserRepository>(() => UserRepositoryHiveImpl());

  await service<UserRepository>().initialize();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gallaerial',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor:  Color.fromARGB(255, 14, 168, 173)),//const Color.fromARGB(255, 33, 107, 235)),
        useMaterial3: true,
        textTheme: GoogleFonts.loraTextTheme(
          Theme.of(context).textTheme,
        ),
        navigationBarTheme: NavigationBarThemeData(
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 15, fontWeight: FontWeight.bold);
        }
        return const TextStyle(fontSize: 15);
      }),
    ),
      ),
      home: const MainView(),
    );
  }
}
