import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/ocr_service.dart';
import 'card_edit_screen.dart';
import '../models/business_card.dart';

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({Key? key}) : super(key: key);

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  final CameraService _cameraService = CameraService();
  final OCRService _ocrService = OCRService();
  bool _isInitialized = false;
  bool _isProcessing = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
      }
    }
  }

  Future<void> _captureAndProcess() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Capture image
      final imagePath = await _cameraService.captureImage();

      // Show processing dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing business card...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Extract text using OCR
      final extractedText = await _ocrService.extractTextFromImage(imagePath);

      // Create business card from extracted text
      final card = BusinessCard.fromOCRText(extractedText, imagePath);

      // Close processing dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Navigate to edit screen and wait for result
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CardEditScreen(
              card: card,
              isNewCard: true,
            ),
          ),
        );
        
        // After edit screen closes, close camera screen too
        if (mounted && result != false) {
          // Only close if card was saved (not cancelled)
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      print('Error processing card: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Close processing dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process card: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _toggleFlash() {
    setState(() {
      _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    });
    _cameraService.setFlashMode(_flashMode);
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Scan Business Card'),
        actions: [
          IconButton(
            icon: Icon(
              _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
            ),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: _isInitialized
          ? Stack(
              children: [
                // Camera preview
                SizedBox.expand(
                  child: CameraPreview(_cameraService.controller!),
                ),
                
                // Card frame overlay
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.width * 0.9 * 0.6,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                // Instructions
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    color: Colors.black54,
                    child: const Text(
                      'Align the business card within the frame',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                // Capture button
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _isProcessing ? null : _captureAndProcess,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.grey, width: 4),
                        ),
                        child: _isProcessing
                            ? const Padding(
                                padding: EdgeInsets.all(15),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(
                                Icons.camera,
                                size: 35,
                                color: Colors.black,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
