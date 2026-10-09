import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../services/receipt_parser.dart';
import 'ocr_review_screen.dart';

// Lets the user take a photo of a receipt, preview it, and extract its text.
// After OCR runs, the user taps "Review & Save" to check the detected fields.
class ReceiptCaptureScreen extends StatefulWidget {
  const ReceiptCaptureScreen({super.key});

  @override
  State<ReceiptCaptureScreen> createState() => _ReceiptCaptureScreenState();
}

class _ReceiptCaptureScreenState extends State<ReceiptCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  File? _image; // null until a photo is taken
  // String? _extractedText; // REMOVED: only the debug box used it
  ParsedReceipt? _parsed; // null until OCR has run
  bool _isProcessing = false;

  @override
  void dispose() {
    // Free the OCR engine when the screen closes.
    _recognizer.close();
    super.dispose();
  }

  // REMOVED: only the debug box used this helper.
  // String _formatDate(DateTime d) {
  //   return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
  //       '${d.day.toString().padLeft(2, '0')}';
  // }

  // Opens the camera and waits for the photo.
  Future<void> _takePhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      // null means the user cancelled the camera.
      if (picked == null) return;

      setState(() {
        _image = File(picked.path);
        // _extractedText = null; // REMOVED
        _parsed = null; // a new photo means the old OCR result is outdated
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open the camera: $e')));
    }
  }

  // Runs OCR on the current photo.
  Future<void> _extractText() async {
    if (_image == null) return;

    setState(() => _isProcessing = true);

    try {
      final inputImage = InputImage.fromFile(_image!);
      final result = await _recognizer.processImage(inputImage);

      if (!mounted) return;
      setState(() {
        // _extractedText = result.text; // REMOVED
        _parsed = ReceiptParser.parse(result.text);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not read the receipt: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt Capture')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo preview
            Expanded(
              // flex: 3, // REMOVED: the photo now uses all the free space
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: _image == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            const Text('No photo yet'),
                          ],
                        ),
                      )
                    : Image.file(_image!, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 12),

            // REMOVED: the temporary "Detected" debug box.
            // if (_extractedText != null)
            //   Expanded(
            //     flex: 2,
            //     child: Container(
            //       padding: const EdgeInsets.all(12),
            //       decoration: BoxDecoration(
            //         border: Border.all(color: Theme.of(context).dividerColor),
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //       child: SingleChildScrollView(
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               'Detected',
            //               style: Theme.of(context).textTheme.titleSmall,
            //             ),
            //             const SizedBox(height: 4),
            //             Text('Title: ${_parsed?.title ?? 'not found'}'),
            //             Text(
            //               'Amount: ${_parsed?.amount == null ? 'not found' : '₱${_parsed!.amount!.toStringAsFixed(2)}'}',
            //             ),
            //             Text(
            //               'Date: ${_parsed?.date == null ? 'not found' : _formatDate(_parsed!.date!)}',
            //             ),
            //             const Divider(height: 24),
            //             Text(
            //               'Raw text',
            //               style: Theme.of(context).textTheme.titleSmall,
            //             ),
            //             const SizedBox(height: 4),
            //             Text(
            //               _extractedText!.isEmpty
            //                   ? 'No text found in the photo'
            //                   : _extractedText!,
            //             ),
            //           ],
            //         ),
            //       ),
            //     ),
            //   ),
            // if (_extractedText != null) const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isProcessing ? null : _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: Text(_image == null ? 'Take Photo' : 'Retake Photo'),
            ),
            if (_image != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isProcessing ? null : _extractText,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.text_snippet),
                label: Text(_isProcessing ? 'Reading...' : 'Extract Text'),
              ),
            ],
            if (_parsed != null) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OcrReviewScreen(
                              image: _image!,
                              parsed: _parsed!,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.fact_check),
                label: const Text('Review & Save'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
