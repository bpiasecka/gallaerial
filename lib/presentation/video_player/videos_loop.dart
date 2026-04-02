import 'package:flutter/material.dart';
import 'package:gallaerial/presentation/video_player/video_player_view.dart';

class VideosLoop extends StatefulWidget {
  final String initialVideoId;
  final List<String> sortedVideosIds;

  const VideosLoop({super.key, required this.initialVideoId, required this.sortedVideosIds});

  @override
  State<VideosLoop> createState() => _VideosLoopState();
}

class _VideosLoopState extends State<VideosLoop> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.sortedVideosIds.indexOf(widget.initialVideoId);
    if (_currentIndex == -1) _currentIndex = 0; 
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sortedVideosIds.isEmpty) return const SizedBox.shrink();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(widget.sortedVideosIds[_currentIndex]);
      }, 
      child: PageView.builder(
      controller: _pageController,
      itemCount: widget.sortedVideosIds.length,
      onPageChanged: (idx) {
        setState(() {
          _currentIndex = idx;
        });
      },
      itemBuilder: (context, idx) {
        return FullScreenVideoPlayer(
          videoEntityId: widget.sortedVideosIds[idx],
          isActive: _currentIndex == idx,
        );
      },
    ));
  }
}