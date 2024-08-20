import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;
  late List<CameraDescription> _cameras;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Initialize the cameras and the controller
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException(
            'No cameras available', 'No cameras found on the device');
      }
      final firstCamera = _cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      _initializeControllerFuture = _controller.initialize();
      await _initializeControllerFuture;
      await _controller.lockCaptureOrientation(DeviceOrientation.portraitUp);

      setState(() {});
    } on CameraException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.description}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: _initializeControllerFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // Use AspectRatio to maintain the aspect ratio of the camera preview
                  return SizedBox(
                      width: size.width,
                      height: size.height,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                            width:
                                100, // the actual width is not important here
                            child: CameraPreview(_controller)),
                      ));
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
    );
  }
}
