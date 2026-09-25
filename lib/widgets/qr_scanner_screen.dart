import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  /// Titre affiché en haut
  final String title;

  /// Message d'aide sous le titre
  final String? subtitle;

  const QrScannerScreen({
    super.key,
    this.title = "Scanner un QR code",
    this.subtitle,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    final codes = capture.barcodes;
    if (codes.isEmpty) return;

    final raw = codes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    _handled = true;
    Navigator.pop(context, raw.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 👉 CAMÉRA
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // 👉 OVERLAY avec cadre
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
              child: Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF1E88E5),
                      width: 4,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 👉 Coin coloré autour du cadre (effet scanner)
          IgnorePointer(
            child: Center(
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  children: [
                    Positioned(
                      top: -2, left: -2,
                      child: _corner(),
                    ),
                    Positioned(
                      top: -2, right: -2,
                      child: Transform.rotate(
                        angle: 1.5708,
                        child: _corner(),
                      ),
                    ),
                    Positioned(
                      bottom: -2, right: -2,
                      child: Transform.rotate(
                        angle: 3.1416,
                        child: _corner(),
                      ),
                    ),
                    Positioned(
                      bottom: -2, left: -2,
                      child: Transform.rotate(
                        angle: 4.7124,
                        child: _corner(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 👉 TEXTE D'AIDE
          if (widget.subtitle != null)
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _corner() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white, width: 4),
          left: BorderSide(color: Colors.white, width: 4),
        ),
      ),
    );
  }
}