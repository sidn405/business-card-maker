import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from image file
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      print('Error extracting text: $e');
      rethrow;
    }
  }

  /// Extract text with detailed block information
  Future<Map<String, dynamic>> extractDetailedText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      List<Map<String, dynamic>> blocks = [];
      
      for (TextBlock block in recognizedText.blocks) {
        blocks.add({
          'text': block.text,
          'boundingBox': {
            'left': block.boundingBox.left,
            'top': block.boundingBox.top,
            'right': block.boundingBox.right,
            'bottom': block.boundingBox.bottom,
          },
          'lines': block.lines.map((line) => {
            'text': line.text,
            'confidence': line.confidence,
          }).toList(),
        });
      }

      return {
        'fullText': recognizedText.text,
        'blocks': blocks,
      };
    } catch (e) {
      print('Error extracting detailed text: $e');
      rethrow;
    }
  }

  /// Preprocess image for better OCR results
  Future<String> preprocessImage(String imagePath) async {
    try {
      // Read the image
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Apply preprocessing
      // 1. Convert to grayscale
      image = img.grayscale(image);

      // 2. Increase contrast
      image = img.adjustColor(image, contrast: 1.5);

      // 3. Optional: Apply threshold for better text detection
      // image = img.threshold(image, threshold: 128);

      // Save preprocessed image
      final preprocessedPath = imagePath.replaceAll('.jpg', '_processed.jpg');
      final preprocessedFile = File(preprocessedPath);
      await preprocessedFile.writeAsBytes(img.encodeJpg(image));

      return preprocessedPath;
    } catch (e) {
      print('Error preprocessing image: $e');
      return imagePath; // Return original if preprocessing fails
    }
  }

  /// Extract specific fields from business card
  Future<Map<String, String>> extractBusinessCardFields(String imagePath) async {
    try {
      final text = await extractTextFromImage(imagePath);
      return _parseBusinessCardText(text);
    } catch (e) {
      print('Error extracting business card fields: $e');
      rethrow;
    }
  }

  /// Parse business card text into structured fields
  Map<String, String> _parseBusinessCardText(String text) {
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    Map<String, String> fields = {
      'name': '',
      'title': '',
      'company': '',
      'email': '',
      'phone': '',
      'website': '',
      'address': '',
    };

    // Email regex
    final emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    
    // Phone regex (supports various formats)
    final phoneRegex = RegExp(r'[\+]?[(]?[0-9]{1,4}[)]?[-\s\.]?[(]?[0-9]{1,4}[)]?[-\s\.]?[0-9]{1,5}[-\s\.]?[0-9]{1,5}');
    
    // Website regex
    final websiteRegex = RegExp(r'(www\.|https?://)[^\s]+|[a-zA-Z0-9-]+\.(com|net|org|io|co|edu|gov)', caseSensitive: false);

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();

      // Extract email
      final emailMatch = emailRegex.firstMatch(line);
      if (emailMatch != null && fields['email']!.isEmpty) {
        fields['email'] = emailMatch.group(0)!;
        continue;
      }

      // Extract phone
      final phoneMatch = phoneRegex.firstMatch(line);
      if (phoneMatch != null && phoneMatch.group(0)!.length >= 10 && fields['phone']!.isEmpty) {
        fields['phone'] = phoneMatch.group(0)!;
        continue;
      }

      // Extract website
      final websiteMatch = websiteRegex.firstMatch(line);
      if (websiteMatch != null && fields['website']!.isEmpty) {
        fields['website'] = websiteMatch.group(0)!;
        continue;
      }

      // First substantial line is usually the name
      if (fields['name']!.isEmpty && line.length > 2 && !line.contains('@')) {
        fields['name'] = line;
        continue;
      }

      // Second line might be title or company
      if (fields['name']!.isNotEmpty && fields['title']!.isEmpty) {
        fields['title'] = line;
        continue;
      }

      // Third line might be company
      if (fields['title']!.isNotEmpty && fields['company']!.isEmpty) {
        fields['company'] = line;
        continue;
      }

      // Remaining lines might be address
      if (fields['address']!.isEmpty && line.length > 5) {
        fields['address'] = line;
      }
    }

    return fields;
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}
