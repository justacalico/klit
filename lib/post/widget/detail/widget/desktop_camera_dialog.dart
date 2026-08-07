import 'dart:io';

import 'package:camera/camera.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Opens a desktop camera capture dialog and returns the path to a captured
/// JPEG, or null if the user cancelled / no camera was available.
Future<String?> showDesktopCameraDialog(BuildContext context) async {
  return showDialog<String>(
    context: context,
    builder: (context) => const _DesktopCameraDialog(),
  );
}

class _DesktopCameraDialog extends StatefulWidget {
  const _DesktopCameraDialog();

  @override
  State<_DesktopCameraDialog> createState() => _DesktopCameraDialogState();
}

class _DesktopCameraDialogState extends State<_DesktopCameraDialog> {
  CameraController? _controller;
  String? _error;
  bool _initializing = true;
  String? _capturedPath;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _error = AppLocalizations.of(context).cameraNoCameras;
          _initializing = false;
        });
        return;
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.description ?? AppLocalizations.of(context).cameraInitError;
        _initializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).cameraInitError;
        _initializing = false;
      });
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final file = await controller.takePicture();
      setState(() => _capturedPath = file.path);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.description ?? AppLocalizations.of(context).cameraInitError);
    }
  }

  void _retake() => setState(() => _capturedPath = null);

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    Widget body;
    if (_initializing) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    } else if (_capturedPath != null) {
      body = Image.file(File(_capturedPath!), fit: BoxFit.contain);
    } else {
      final preview = CameraPreview(_controller!);
      body = Platform.isWindows
          ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(-1, 1, 1),
              child: preview,
            )
          : preview;
    }

    final actions = <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(l10n.commonCancel),
      ),
    ];
    if (_error == null && !_initializing) {
      if (_capturedPath != null) {
        actions.addAll([
          TextButton(
            onPressed: _retake,
            child: Text(l10n.cameraRetake),
          ),
          const SizedBox(width: 6),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(_capturedPath),
            icon: const Icon(Icons.check),
            label: Text(l10n.commonSave),
          ),
        ]);
      } else {
        actions.add(
          const SizedBox(width: 6),
        );
        actions.add(
          FilledButton.icon(
            onPressed: _capture,
            icon: const Icon(Icons.camera_alt),
            label: Text(l10n.cameraCapture),
          ),
        );
      }
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.postTakePhoto, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: body,
              )),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
