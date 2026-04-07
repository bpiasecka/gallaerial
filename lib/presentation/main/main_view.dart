import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallaerial/domain/entities/filter_model.dart';
import 'package:gallaerial/domain/entities/sort_model.dart';
import 'package:gallaerial/main.dart';
import 'package:gallaerial/presentation/tag_list/tag_list_view.dart';
import 'package:gallaerial/presentation/main/main_bloc.dart';
import 'package:gallaerial/presentation/video_list/video_list_view.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  late PageController _pageController;
  FilterModel? filterModel;
  SortModel? sortModel = SortModel.empty();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MainBloc>(
      create: (context) => service<MainBloc>(),
      child: BlocConsumer<MainBloc, MainViewState>(
        listenWhen: (previous, current) => previous.selectedTabIdx != current.selectedTabIdx,
        listener: (context, state) {
          if (_pageController.hasClients && _pageController.page?.round() != state.selectedTabIdx) {
            _pageController.animateToPage(
              state.selectedTabIdx,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        builder: (context, state) => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
          appBar: AppBar(
            centerTitle: true,
            flexibleSpace: Image.asset(
              "assets/icon/branding_wide_empty.jpeg", 
              fit: BoxFit.fitWidth, 
              alignment: const Alignment(0, -0.8)
            ),
            title: Text(
              state.selectedTabIdx == 0 ? "Files" : "Labels",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          bottomNavigationBar: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  "assets/icon/branding_wide_empty.jpeg",
                  fit: BoxFit.fitWidth,
                  alignment: const Alignment(0, 0.8),
                ),
              ),
              NavigationBar(
                height: 70,
                selectedIndex: state.selectedTabIdx,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.video_collection), label: "Files"),
                  NavigationDestination(icon: Icon(Icons.label), label: "Labels"),
                ],
                onDestinationSelected: (idx) {
                  context.read<MainBloc>().add(SwitchTabEvent(newTabIdx: idx));
                },
              ),
            ],
          ),
          body: PageView(
            controller: _pageController,
            onPageChanged: (idx) {
              context.read<MainBloc>().add(SwitchTabEvent(newTabIdx: idx));
            },
            children: const [
              VideoListView(),
              TagListView(),
            ],
          ),
        ),
      ),
    );
  }
}
