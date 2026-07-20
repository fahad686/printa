import 'package:flutter/material.dart';

class SignatureCanvasWidget extends StatefulWidget {
  final ValueChanged<List<Offset?>>? onSignatureChanged;

  const SignatureCanvasWidget({super.key, this.onSignatureChanged});

  @override
  State<SignatureCanvasWidget> createState() => _SignatureCanvasWidgetState();
}

class _SignatureCanvasWidgetState extends State<SignatureCanvasWidget> {
  final List<Offset?> _points = [];

  void _clear() {
    setState(() {
      _points.clear();
    });
    if (widget.onSignatureChanged != null) {
      widget.onSignatureChanged!(_points);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Customer Signature',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            TextButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onPanUpdate: (details) {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                final localPos = renderBox.globalToLocal(details.globalPosition);
                setState(() {
                  _points.add(localPos);
                });
                if (widget.onSignatureChanged != null) {
                  widget.onSignatureChanged!(_points);
                }
              },
              onPanEnd: (details) {
                setState(() {
                  _points.add(null);
                });
                if (widget.onSignatureChanged != null) {
                  widget.onSignatureChanged!(_points);
                }
              },
              child: CustomPaint(
                painter: _SignaturePainter(points: _points),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
