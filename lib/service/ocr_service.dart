import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  TextRecognizer? _textRecognizer;

  /// ML Kit text recognition only works on Android & iOS.
  static bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Extract text from an image file.
  /// Throws [UnsupportedError] on Web / Windows / macOS / Linux.
  Future<String> extractText(File imageFile) async {
    if (!isSupported) {
      final platform = kIsWeb ? 'Web' : defaultTargetPlatform.name;
      debugPrint(
          '📝 [OCR] Text recognition is not supported on $platform. '
          'Please use an Android or iOS device.');
      throw UnsupportedError(
          'OCR scanning is only available on Android and iOS devices. '
          'Current platform: $platform.');
    }

    try {
      _textRecognizer ??=
          TextRecognizer(script: TextRecognitionScript.latin);

      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer!.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        debugPrint('📝 [OCR] No text found in image');
        return '';
      }

      debugPrint('📝 [OCR] Raw recognized text: ${recognizedText.text}');
      debugPrint('📝 [OCR] Found ${recognizedText.blocks.length} text blocks');

      // Build structured text from blocks for better parsing
      final buffer = StringBuffer();

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final lineText = line.text.trim();
          if (lineText.isNotEmpty) {
            buffer.writeln(lineText);
          }
        }
        // Add extra newline between blocks for separation
        buffer.writeln();
      }

      final result = buffer.toString().trim();
      debugPrint('📝 [OCR] Processed text:\n$result');
      return result;
    } on MissingPluginException catch (e) {
      debugPrint('📝 [OCR] ML Kit plugin not available: $e');
      debugPrint('📝 [OCR] Try: flutter clean && flutter pub get && flutter run');
      throw UnsupportedError(
          'OCR plugin failed to initialize. '
          'Please run "flutter clean", then rebuild the app.');
    } catch (e) {
      debugPrint('📝 [OCR] Error extracting text: $e');
      rethrow;
    }
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
