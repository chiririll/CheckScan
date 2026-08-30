import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../receipt_detail/receipt_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, required this.state});

  final AppState state;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: true,
  );
  bool _busy = false;
  bool _frozen = false;
  Uint8List? _frozenFrame;
  String? _progress;
  bool _torch = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRaw(String raw) async {
    if (_busy || raw.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _frozen = true;
      _progress = l10n.progressGeneric;
    });
    await _controller.stop();
    final result = await widget.state.session.process(
      raw,
      onStatus: (status) {
        if (!mounted) return;
        setState(() {
          _progress = switch (status) {
            'ru_fns_loading' => l10n.progressRu,
            'eq_reading' => l10n.progressEq,
            _ => l10n.progressGeneric,
          };
        });
      },
    );
    if (!mounted) return;
    if (result.unknown) {
      await _showUnknown();
      return;
    }
    await widget.state.reload();
    if (!mounted) return;
    final id = result.record!.id;
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReceiptPage(state: widget.state, receiptId: id)),
    );
  }

  Future<void> _showUnknown() async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unknownTitle),
        content: Text(l10n.unknownBody),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l10n.gotIt))],
      ),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _frozen = false;
      _frozenFrame = null;
      _progress = null;
    });
    await _controller.start();
  }

  Future<void> _pickGallery() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final barcodes = await _controller.analyzeImage(file.path);
    final raw = barcodes?.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            content: Text(l10n.galleryNoQr),
            actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l10n.gotIt))],
          );
        },
      );
      return;
    }
    await _handleRaw(raw);
  }

  Future<void> _ensureCamera() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return;
    final next = await Permission.camera.request();
    if (!next.isGranted && mounted) {
      final l10n = AppLocalizations.of(context);
      final open = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(l10n.cameraDenied),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.close)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.openSettings)),
          ],
        ),
      );
      if (open == true) await openAppSettings();
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureCamera();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_busy) return;
              final raw = capture.barcodes.map((b) => b.rawValue).whereType<String>().where((v) => v.isNotEmpty);
              if (raw.isEmpty) return;
              setState(() => _frozenFrame = capture.image);
              _handleRaw(raw.first);
            },
          ),
          if (_frozenFrame != null)
            Positioned.fill(
              child: Image.memory(_frozenFrame!, fit: BoxFit.cover),
            ),
          if (_frozen) Container(color: Colors.black.withValues(alpha: 0.35)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 188,
                  height: 188,
                  child: CustomPaint(
                    painter: _FramePainter(color: Colors.white),
                    child: _frozen
                        ? const Center(
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _progress ?? l10n.aimQr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _busy ? null : _pickGallery,
                        icon: const Icon(Icons.photo_outlined, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () async {
                          await _controller.toggleTorch();
                          setState(() => _torch = !_torch);
                        },
                        icon: Icon(_torch ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)), paint);
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) => oldDelegate.color != color;
}
