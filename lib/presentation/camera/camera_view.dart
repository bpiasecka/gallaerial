import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:gallaerial/presentation/asset_list/asset_list_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

enum CameraMode { photo, video }

class CameraView extends StatefulWidget {
  final AssetListBloc assetListBloc;

  const CameraView({super.key, required this.assetListBloc});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;

  CameraMode _cameraMode = CameraMode.photo;
  bool _isRecording = false;
  
  // FIX: Concurrency Lock to prevent spam-click crashes
  bool _isProcessing = false; 
  
  // ANIMATION: Screen flash state
  bool _showCaptureFlash = false;

  Timer? _recordTimer;
  int _recordDuration = 0;

  FlashMode _currentFlashMode = FlashMode.off;
  double _baseZoomLevel = 1.0;
  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await [Permission.camera, Permission.microphone].request();

    bool hasGalleryAccess = await Gal.hasAccess(toAlbum: true);
    if (!hasGalleryAccess) {
      hasGalleryAccess = await Gal.requestAccess(toAlbum: true);
    }

    await PhotoManager.requestPermissionExtend();

    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    await _initCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _initCameraController(CameraDescription description) async {
    // FIX: Check if Mic is permanently denied so the camera doesn't crash
    final micStatus = await Permission.microphone.status;
    final bool enableAudio = micStatus.isGranted;

    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      _minZoomLevel = await controller.getMinZoomLevel();
      _maxZoomLevel = await controller.getMaxZoomLevel();

      if (mounted) {
        setState(() {
          _controller = controller;
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // FIX: If app is backgrounded while recording, stop & save the video gracefully
      if (_isRecording && !_isProcessing) {
        _toggleRecording(); 
      }
      cameraController.dispose();
      if (mounted) setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(cameraController.description);
    }
  }

  // --- TIMER LOGIC ---
  void _startTimer() {
    _recordDuration = 0;
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _recordDuration++);
    });
  }

  void _stopTimer() {
    _recordTimer?.cancel();
    _recordDuration = 0;
  }

  String get _formattedTime {
    int minutes = _recordDuration ~/ 60;
    int seconds = _recordDuration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // --- HELPER: GET RECENT ASSET IDS (SNAPSHOT) ---
  Future<List<String>> _getRecentAssetIds(RequestType type) async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: type,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );

    if (paths.isEmpty) return [];

    // FIX: Increased to 50 to protect against simultaneous Cloud Sync downloads
    final List<AssetEntity> recentAssets = await paths.first.getAssetListPaged(page: 0, size: 50);
    
    return recentAssets.map((e) => e.id).toList();
  }

  // --- ACTIONS ---
  void _onShutterPressed() {
    if (_isProcessing) return; // FIX: Block spam clicks
    
    if (_cameraMode == CameraMode.photo) {
      _takePicture();
    } else {
      _toggleRecording();
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isRecording) return;

    setState(() => _isProcessing = true);

    // ANIMATION: Trigger the shutter flash
    setState(() => _showCaptureFlash = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _showCaptureFlash = false);
    });

    try {
      final List<String> oldIds = await _getRecentAssetIds(RequestType.image);

      final XFile photo = await _controller!.takePicture();
      await Gal.putImage(photo.path, album: 'Gallaerial');

      String? newAssetId;
      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        final List<String> currentIds = await _getRecentAssetIds(RequestType.image);
        
        for (String id in currentIds) {
          if (!oldIds.contains(id)) {
            newAssetId = id;
            break;
          }
        }
        if (newAssetId != null) break; 
      }

      if (mounted && newAssetId != null) {
        widget.assetListBloc.add(
          AssetAddedEvent(videosIds: const [], imagesIds: [newAssetId])
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image saved successfully!"))
        );
      }
    // Inside _toggleRecording() and _takePicture()
    } on CameraException catch (e) {
      // Catch native camera hardware crashes (like Out of Space)
      debugPrint("CameraException: ${e.code} - ${e.description}");
      if (mounted) {
        String errorMsg = "A camera error occurred.";
        if (e.description != null && e.description!.toLowerCase().contains("space")) {
          errorMsg = "Device storage is full! Please free up space.";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ));
      }
    } on GalException catch (e) {
      // Catch Gallery saving errors
      debugPrint("Gal Error saving media: ${e.type}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to save. Device storage might be full."),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      // General fallback
      debugPrint("Unknown Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() => _isProcessing = true);

    try {
      if (_isRecording) {
        final XFile video = await _controller!.stopVideoRecording();
        _stopTimer();
        setState(() => _isRecording = false);

        final List<String> oldIds = await _getRecentAssetIds(RequestType.video);

        await Gal.putVideo(video.path, album: 'Gallaerial');

        String? newAssetId;
        // FIX: Increased loop to 20 (10 seconds) for slower hard drives saving large videos
        for (int i = 0; i < 20; i++) { 
          await Future.delayed(const Duration(milliseconds: 500));
          
          final List<String> currentIds = await _getRecentAssetIds(RequestType.video);
          
          for (String id in currentIds) {
            if (!oldIds.contains(id)) {
              newAssetId = id;
              break;
            }
          }
          if (newAssetId != null) break;
        }

        if (mounted && newAssetId != null) {
          widget.assetListBloc.add(
            AssetAddedEvent(videosIds: [newAssetId], imagesIds: const [])
          );
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video saved successfully!"))
        );
        }
      } else {
        await _controller!.startVideoRecording();
        _startTimer();
        setState(() => _isRecording = true);
      }
    // Inside _toggleRecording() and _takePicture()
    } on CameraException catch (e) {
      // Catch native camera hardware crashes (like Out of Space)
      debugPrint("CameraException: ${e.code} - ${e.description}");
      if (mounted) {
        String errorMsg = "A camera error occurred.";
        if (e.description != null && e.description!.toLowerCase().contains("space")) {
          errorMsg = "Device storage is full! Please free up space.";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ));
      }
    } on GalException catch (e) {
      // Catch Gallery saving errors
      debugPrint("Gal Error saving media: ${e.type}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to save. Device storage might be full."),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      // General fallback
      debugPrint("Unknown Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length < 2 || _isProcessing) return;
    
    // 1. Instantly trigger a rebuild to hide the CameraPreview widget
    // by marking the camera as uninitialized.
    setState(() {
      _isProcessing = true;
      _isCameraInitialized = false; // <--- ADD THIS LINE
    });

    // 2. Safely destroy the old controller while the UI shows a loading spinner
    await _controller?.dispose();
    
    // 3. Fire up the new camera
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initCameraController(_cameras[_selectedCameraIndex]);
    
    // 4. Unlock the UI (the _initCameraController method will automatically
    // set _isCameraInitialized back to true when it finishes).
    if (mounted) setState(() => _isProcessing = false);
  }
  
  Future<void> _handleFlashToggle() async {
    if (_controller == null || _isProcessing) return;
    try {
      final newMode = _currentFlashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      await _controller!.setFlashMode(newMode);
      setState(() => _currentFlashMode = newMode);
    } catch (e) {
      // FIX: Handle devices with no front-facing flash gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Flash not supported on this camera."))
        );
      }
    }
  }

  // --- UI COMPONENTS ---
  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator()));
    }

    // FIX: PopScope prevents user from breaking the app by swiping back while recording
    return PopScope(
      canPop: !_isRecording && !_isProcessing,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_isRecording) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Saving video before exiting..."))
          );
          await _toggleRecording();
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Camera Preview
            Center(
              child: CameraPreview(
                _controller!,
                child: LayoutBuilder(builder: (context, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: (details) => _baseZoomLevel = _currentZoomLevel,
                    onScaleUpdate: (details) {
                      double zoom = _baseZoomLevel * details.scale;
                      if (zoom < _minZoomLevel) zoom = _minZoomLevel;
                      if (zoom > _maxZoomLevel) zoom = _maxZoomLevel;
                      _currentZoomLevel = zoom;
                      _controller!.setZoomLevel(_currentZoomLevel);
                    },
                  );
                }),
              ),
            ),

            // ANIMATION: White flash overlay
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showCaptureFlash ? 0.7 : 0.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                child: Container(color: Colors.white),
              ),
            ),

            // 2. Back Button (Top Left)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: IconButton(
                  padding: const EdgeInsets.all(16),
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () async {
                    // Mirror the PopScope logic for the manual back button
                    if (_isRecording) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Saving video before exiting..."))
                      );
                      await _toggleRecording();
                    }
                    if (mounted && !_isProcessing) Navigator.of(context).pop();
                  },
                ),
              ),
            ),

            // 3. Recording Timer (Top Center)
            if (_isRecording)
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Colors.red, size: 12),
                        const SizedBox(width: 8),
                        Text(
                          _formattedTime,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 4. Right-Side Controls (Flash & Flip)
            if (!_isRecording)
              Positioned(
                right: 20,
                bottom: 60,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _currentFlashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
                          color: Colors.white,
                        ),
                        onPressed: _handleFlashToggle, // Updated to use safe toggle
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                        onPressed: _toggleCamera,
                      ),
                    ),
                  ],
                ),
              ),

            // 5. Bottom Center Controls (Shutter & Mode Switcher)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _onShutterPressed,
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: _isRecording ? 30 : 60,
                            width: _isRecording ? 30 : 60,
                            decoration: BoxDecoration(
                              color: _cameraMode == CameraMode.video ? Colors.red : Colors.white,
                              borderRadius: BorderRadius.circular(_isRecording ? 8 : 30),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (!_isRecording)
                      Transform.scale(
                        scale: 0.85,
                        child: SegmentedButton<CameraMode>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: CameraMode.photo, 
                              label: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('PHOTO', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            ButtonSegment(
                              value: CameraMode.video, 
                              label: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('VIDEO', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                          selected: {_cameraMode},
                          onSelectionChanged: (Set<CameraMode> newSelection) {
                            if (!_isProcessing) {
                              setState(() => _cameraMode = newSelection.first);
                            }
                          },
                          style: SegmentedButton.styleFrom(
                            backgroundColor: Colors.black45,
                            foregroundColor: Colors.white,
                            selectedForegroundColor: Colors.black,
                            selectedBackgroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}