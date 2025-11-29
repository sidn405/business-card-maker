import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  /// Initialize camera
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      // Use the back camera by default
      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing camera: $e');
      rethrow;
    }
  }

  /// Capture image and save to file
  Future<String> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    try {
      // Get the directory to save the image
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = path.join(directory.path, 'card_$timestamp.jpg');

      // Capture the image
      final XFile image = await _controller!.takePicture();
      
      // Copy to permanent location
      final File imageFile = File(image.path);
      await imageFile.copy(imagePath);
      
      return imagePath;
    } catch (e) {
      print('Error capturing image: $e');
      rethrow;
    }
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      return;
    }

    try {
      final currentLens = _controller!.description.lensDirection;
      final newCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection != currentLens,
        orElse: () => _cameras!.first,
      );

      await _controller?.dispose();
      
      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
    } catch (e) {
      print('Error switching camera: $e');
      rethrow;
    }
  }

  /// Set flash mode
  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller == null) return;
    
    try {
      await _controller!.setFlashMode(mode);
    } catch (e) {
      print('Error setting flash mode: $e');
    }
  }

  /// Dispose camera controller
  void dispose() {
    _controller?.dispose();
    _isInitialized = false;
  }
}
