import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receipt_app/screens/add_receipt_screen.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  String? _imagePath;

  Future<void> _capturePhoto() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
      _navigateToAddReceipt();
    }
  }

  Future<void> _importPhoto() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
      _navigateToAddReceipt();
    }
  }

  void _navigateToAddReceipt() {
    if (_imagePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddReceiptScreen(
            imagePath: _imagePath,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scan Receipt'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Dashed border frame
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.transparent,
                    width: 0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    // Dashed border using CustomPaint
                    CustomPaint(
                      size: const Size(double.infinity, 300),
                      painter: DashedBorderPainter(
                        color: theme.colorScheme.primary,
                        strokeWidth: 2,
                      ),
                    ),
                    // Camera icon and text
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera,
                            size: 64,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Align receipt in frame',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // Capture button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _capturePhoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Capture',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Navigation buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.list, size: 18),
                      label: const Text('List'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: Colors.grey[400]!,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Search'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: Colors.grey[400]!,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: Colors.grey[400]!,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Tap to import from gallery option
              GestureDetector(
                onTap: _importPhoto,
                child: Text(
                  'Or tap to import from gallery',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for dashed border
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 8.0;
    const radius = 8.0;

    // Draw dashed borders
    _drawDashedLine(canvas, Offset(radius, 0), Offset(size.width - radius, 0), paint, dashWidth, dashSpace);
    _drawDashedLine(canvas, Offset(size.width, radius), Offset(size.width, size.height - radius), paint, dashWidth, dashSpace);
    _drawDashedLine(canvas, Offset(size.width - radius, size.height), Offset(radius, size.height), paint, dashWidth, dashSpace);
    _drawDashedLine(canvas, Offset(0, size.height - radius), Offset(0, radius), paint, dashWidth, dashSpace);

    // Draw corner arcs
    final arcPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Top-left corner
    canvas.drawArc(Rect.fromCircle(center: const Offset(radius, radius), radius: radius), math.pi, math.pi / 2, false, arcPaint);
    // Top-right corner
    canvas.drawArc(Rect.fromCircle(center: Offset(size.width - radius, radius), radius: radius), math.pi + math.pi / 2, math.pi / 2, false, arcPaint);
    // Bottom-right corner
    canvas.drawArc(Rect.fromCircle(center: Offset(size.width - radius, size.height - radius), radius: radius), 0, math.pi / 2, false, arcPaint);
    // Bottom-left corner
    canvas.drawArc(Rect.fromCircle(center: Offset(radius, size.height - radius), radius: radius), math.pi / 2, math.pi / 2, false, arcPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, double dashWidth, double dashSpace) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final dashCount = (distance / (dashWidth + dashSpace)).ceil();

    for (int i = 0; i < dashCount; i++) {
      final progress = (i * (dashWidth + dashSpace)) / distance;
      final progressEnd = ((i * (dashWidth + dashSpace)) + dashWidth) / distance;

      if (progress < 1.0) {
        final x1 = start.dx + dx * progress;
        final y1 = start.dy + dy * progress;
        final x2 = start.dx + dx * (progressEnd < 1.0 ? progressEnd : 1.0);
        final y2 = start.dy + dy * (progressEnd < 1.0 ? progressEnd : 1.0);

        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
