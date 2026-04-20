import 'package:flutter/material.dart';
import 'package:gallaerial/data/v_hive/hive_database_service.dart';
import 'package:gallaerial/data/v_hive/repositories/assets/image_asset_repository_impl.dart';
import 'package:gallaerial/data/v_hive/repositories/settings_repository_impl.dart';
import 'package:gallaerial/data/v_hive/repositories/tags_repository_impl.dart';
import 'package:gallaerial/data/v_hive/repositories/assets/video_asset_repository_impl.dart';
import 'package:gallaerial/domain/entities/asset_entity.dart';
import 'package:gallaerial/domain/repositories/image_repository.dart';
import 'package:gallaerial/domain/repositories/settings_repository.dart';
import 'package:gallaerial/domain/repositories/tags_repository.dart';
import 'package:gallaerial/domain/repositories/video_repository.dart';
import 'package:gallaerial/domain/useCases/assets/edit_asset_name_use_case.dart';
import 'package:gallaerial/domain/useCases/assets/remove_asset_use_case.dart';
import 'package:gallaerial/domain/useCases/settings/edit_settings_use_case.dart';
import 'package:gallaerial/domain/useCases/settings/get_settings_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/change_tags_order_use_case.dart';
import 'package:gallaerial/domain/useCases/assets/edit_video_cover_use_case.dart';
import 'package:gallaerial/domain/useCases/assets/edit_asset_tags_use_case.dart';
import 'package:gallaerial/domain/useCases/assets/get_asset_use_case.dart';
import 'package:gallaerial/presentation/asset_display/asset_display_bloc.dart';
import 'package:gallaerial/presentation/main/main_view.dart';
import 'package:gallaerial/presentation/asset_tags_edit/asset_edit_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gallaerial/domain/useCases/tags/add_tag_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/edit_tag_color_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/edit_tag_name_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/load_tags_use_case.dart';
import 'package:gallaerial/domain/useCases/tags/remove_tag_use_case.dart';
import 'package:gallaerial/domain/useCases/assets/add_assets_use_case.dart';
import 'package:gallaerial/domain/useCases/assets/load_assets_use_case.dart';
import 'package:gallaerial/presentation/main/main_bloc.dart';
import 'package:gallaerial/presentation/tag_list/tag_list_bloc.dart';
import 'package:gallaerial/presentation/asset_list/asset_list_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:photo_manager/photo_manager.dart';

final GetIt dependencyService = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PhotoManager.clearFileCache();
  //PhotoManager.addChangeCallback();
  await HiveDatabaseService.initialize();
  await initDependencyService();
  runApp(const MyApp());

}

Future<void> initDependencyService() async {
  dependencyService.registerFactory(() => MainBloc());
  dependencyService.registerFactory(() => AssetListBloc());
  dependencyService.registerFactory(() => AssetDisplayBloc());
  dependencyService.registerFactory(() => TagListBloc());
  dependencyService.registerFactory(() => AssetEditBloc());
  dependencyService.registerLazySingleton(() => EditSettingsUseCase(repository: dependencyService()));
  dependencyService.registerLazySingleton(() => GetSettingsUseCase(repository: dependencyService()));
  dependencyService.registerLazySingleton(() => ChangeTagsOrderUseCase(repository: dependencyService()));
  dependencyService.registerLazySingleton(() => EditVideoCoverUseCase(repository: dependencyService()));
  dependencyService.registerLazySingleton(() => GetAssetUseCase<VideoEntity>(repository: dependencyService<VideoRepository>()));
  dependencyService.registerLazySingleton(() => GetAssetUseCase<ImageEntity>(repository: dependencyService<ImageRepository>()));
  dependencyService.registerLazySingleton(() => LoadAssetsUseCase<VideoEntity>(repository: dependencyService<VideoRepository>()));
  dependencyService.registerLazySingleton(() => LoadAssetsUseCase<ImageEntity>(repository: dependencyService<ImageRepository>()));
  dependencyService.registerLazySingleton(() => AddAssetsUseCase<VideoEntity>(repository: dependencyService<VideoRepository>()));
  dependencyService.registerLazySingleton(() => AddAssetsUseCase<ImageEntity>(repository: dependencyService<ImageRepository>()));
  dependencyService.registerLazySingleton(() => RemoveAssetUseCase<VideoEntity>(repository: dependencyService<VideoRepository>()));
  dependencyService.registerLazySingleton(() => RemoveAssetUseCase<ImageEntity>(repository: dependencyService<ImageRepository>()));
  dependencyService.registerLazySingleton(() => EditAssetNameUseCase<VideoEntity>(repository: dependencyService<VideoRepository>()));
  dependencyService.registerLazySingleton(() => EditAssetNameUseCase<ImageEntity>(repository: dependencyService<ImageRepository>()));
  dependencyService.registerLazySingleton(() => EditAssetTagsUseCase<VideoEntity>(repository: dependencyService<VideoRepository>()));
  dependencyService.registerLazySingleton(() => EditAssetTagsUseCase<ImageEntity>(repository: dependencyService<ImageRepository>()));
  dependencyService.registerLazySingleton(() => LoadTagsUsecase(repository: dependencyService()));
  dependencyService.registerLazySingleton(() => AddTagUsecase(repository: dependencyService()));
  dependencyService.registerLazySingleton(() => RemoveTagUsecase(repository: dependencyService()));
  dependencyService.registerLazySingleton(() => EditTagNameUseCase(repository: dependencyService()));
  dependencyService.registerLazySingleton(() => EditTagColorUseCase(repository: dependencyService()));
  dependencyService.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl()..initData());
  dependencyService.registerLazySingleton<TagsRepository>(() => TagsRepositoryImpl()..initData());
  dependencyService.registerLazySingleton<VideoRepository>(() => VideoAssetRepositoryImpl()..initData());
  dependencyService.registerLazySingleton<ImageRepository>(() => ImageAssetRepositoryImpl()..initData());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gallaerial',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor:  const Color.fromARGB(255, 14, 168, 173)),
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
