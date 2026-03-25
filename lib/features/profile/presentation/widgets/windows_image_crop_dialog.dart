import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/profile_repository.dart';

class WindowsImageCropDialog extends StatefulWidget {
  final String sourcePath;
  final ProfileImageType imageType;

  const WindowsImageCropDialog({
    super.key,
    required this.sourcePath,
    required this.imageType,
  });

  @override
  State<WindowsImageCropDialog> createState() => _WindowsImageCropDialogState();
}

class _WindowsImageCropDialogState extends State<WindowsImageCropDialog> {
  ui.Image? _decodedImage;

  double _imageWidth = 0;
  double _imageHeight = 0;

  double _zoom = 1.0;
  double _baseScale = 1.0;

  Offset _offset = Offset.zero;
  Size? _viewportSize;

  bool _isExporting = false;

  double get _aspectRatio =>
      widget.imageType == ProfileImageType.AVATAR ? 1.0 : (16 / 9);

  String get _title => widget.imageType == ProfileImageType.AVATAR
      ? 'Crop avatar'
      : 'Crop cover';

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final file = File(widget.sourcePath);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    if (!mounted) return;

    setState(() {
      _decodedImage = frame.image;
      _imageWidth = frame.image.width.toDouble();
      _imageHeight = frame.image.height.toDouble();
    });
  }

  void _initializeForViewport(Size viewportSize) {
    if (_decodedImage == null) return;
    if (_viewportSize == viewportSize) return;

    _viewportSize = viewportSize;

    _baseScale = math.max(
      viewportSize.width / _imageWidth,
      viewportSize.height / _imageHeight,
    );

    _zoom = 1.0;

    final scaledWidth = _imageWidth * _baseScale * _zoom;
    final scaledHeight = _imageHeight * _baseScale * _zoom;

    _offset = Offset(
      (viewportSize.width - scaledWidth) / 2,
      (viewportSize.height - scaledHeight) / 2,
    );

    _clampOffset();
  }

  double get _displayScale => _baseScale * _zoom;

  Size get _displayedImageSize => Size(
        _imageWidth * _displayScale,
        _imageHeight * _displayScale,
      );

  void _clampOffset() {
    final viewport = _viewportSize;
    if (viewport == null) return;

    final displayed = _displayedImageSize;

    double minDx = viewport.width - displayed.width;
    double minDy = viewport.height - displayed.height;

    const double epsilon = 0.000001;

    if (minDx > -epsilon) {
      minDx = 0.0;
    }

    if (minDy > -epsilon) {
      minDy = 0.0;
    }

    final safeMinDx = math.min(minDx, 0.0);
    final safeMinDy = math.min(minDy, 0.0);

    final dx = _offset.dx.clamp(safeMinDx, 0.0).toDouble();
    final dy = _offset.dy.clamp(safeMinDy, 0.0).toDouble();

    _offset = Offset(dx, dy);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta;
      _clampOffset();
    });
  }

  void _onZoomChanged(double value) {
    final viewport = _viewportSize;
    if (viewport == null) return;

    final oldScale = _displayScale;
    final newZoom = value;
    final newScale = _baseScale * newZoom;

    final viewportCenter = Offset(
      viewport.width / 2,
      viewport.height / 2,
    );

    final imagePointAtCenter = Offset(
      (viewportCenter.dx - _offset.dx) / oldScale,
      (viewportCenter.dy - _offset.dy) / oldScale,
    );

    setState(() {
      _zoom = newZoom;
      _offset = Offset(
        viewportCenter.dx - imagePointAtCenter.dx * newScale,
        viewportCenter.dy - imagePointAtCenter.dy * newScale,
      );
      _clampOffset();
    });
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || _decodedImage == null) {
      return;
    }

    final viewport = _viewportSize;
    if (viewport == null) return;

    final oldScale = _displayScale;

    final zoomDelta = event.scrollDelta.dy > 0 ? -0.08 : 0.08;
    final newZoom = (_zoom + zoomDelta).clamp(1.0, 3.0);

    if ((newZoom - _zoom).abs() < 0.0001) {
      return;
    }

    final newScale = _baseScale * newZoom;

    final localFocalPoint = event.localPosition;

    final imagePointAtCursor = Offset(
      (localFocalPoint.dx - _offset.dx) / oldScale,
      (localFocalPoint.dy - _offset.dy) / oldScale,
    );

    setState(() {
      _zoom = newZoom;
      _offset = Offset(
        localFocalPoint.dx - imagePointAtCursor.dx * newScale,
        localFocalPoint.dy - imagePointAtCursor.dy * newScale,
      );
      _clampOffset();
    });
  }

  Future<String> _exportCroppedImage() async {
    final viewport = _viewportSize;
    final decodedImage = _decodedImage;

    if (viewport == null || decodedImage == null) {
      throw Exception('Cropper is not ready yet.');
    }

    final scale = _displayScale;

    double srcLeft = (-_offset.dx) / scale;
    double srcTop = (-_offset.dy) / scale;
    double srcWidth = viewport.width / scale;
    double srcHeight = viewport.height / scale;

    srcLeft = srcLeft.clamp(0.0, _imageWidth);
    srcTop = srcTop.clamp(0.0, _imageHeight);

    if (srcLeft + srcWidth > _imageWidth) {
      srcWidth = _imageWidth - srcLeft;
    }

    if (srcTop + srcHeight > _imageHeight) {
      srcHeight = _imageHeight - srcTop;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final outputWidth =
        widget.imageType == ProfileImageType.AVATAR ? 512 : 1280;
    final outputHeight =
        widget.imageType == ProfileImageType.AVATAR ? 512 : 720;

    final srcRect = Rect.fromLTWH(
      srcLeft,
      srcTop,
      srcWidth,
      srcHeight,
    );

    final dstRect = Rect.fromLTWH(
      0,
      0,
      outputWidth.toDouble(),
      outputHeight.toDouble(),
    );

    canvas.drawImageRect(decodedImage, srcRect, dstRect, Paint());

    final picture = recorder.endRecording();
    final renderedImage = await picture.toImage(outputWidth, outputHeight);
    final byteData = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw Exception('Failed to export cropped image.');
    }

    final tempDir = await getTemporaryDirectory();
    final fileName = widget.imageType == ProfileImageType.AVATAR
        ? 'cropped_avatar_${DateTime.now().millisecondsSinceEpoch}.png'
        : 'cropped_cover_${DateTime.now().millisecondsSinceEpoch}.png';

    final outputFile = File('${tempDir.path}/$fileName');
    await outputFile.writeAsBytes(byteData.buffer.asUint8List());

    return outputFile.path;
  }

  @override
  Widget build(BuildContext context) {
    final cropAreaHeight =
        widget.imageType == ProfileImageType.AVATAR ? 360.0 : 240.0;
    final cropAreaWidth = cropAreaHeight * _aspectRatio;

    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      title: Text(
        _title,
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 560,
        child: _decodedImage == null
            ? const SizedBox(
                height: 240,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Drag to move the image. Use the slider to zoom.',
                    style: TextStyle(
                      color: Color(0xFFBBBBBB),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final viewport = Size(cropAreaWidth, cropAreaHeight);

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              _initializeForViewport(viewport);
                            }
                          });

                          final displayed = _displayedImageSize;

                          return Listener(
                            onPointerSignal: _onPointerSignal,
                            child: GestureDetector(
                              onPanUpdate: _onDragUpdate,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.grab,
                                child: Container(
                                  width: cropAreaWidth,
                                  height: cropAreaHeight,
                                  color: Colors.black,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: _offset.dx,
                                        top: _offset.dy,
                                        width: displayed.width,
                                        height: displayed.height,
                                        child: Image.file(
                                          File(widget.sourcePath),
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                      IgnorePointer(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: const Color(0xFFFF5500),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text(
                        'Zoom',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Expanded(
                        child: Slider(
                          value: _zoom,
                          min: 1.0,
                          max: 3.0,
                          divisions: 20,
                          activeColor: const Color(0xFFFF5500),
                          inactiveColor: const Color(0xFF444444),
                          onChanged:
                              _decodedImage == null ? null : _onZoomChanged,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFFAAAAAA)),
          ),
        ),
        TextButton(
          onPressed: _decodedImage == null || _isExporting
              ? null
              : () async {
                  try {
                    setState(() {
                      _isExporting = true;
                    });

                    final croppedPath = await _exportCroppedImage();

                    if (!mounted) return;
                    Navigator.of(context).pop(croppedPath);
                  } catch (_) {
                    if (!mounted) return;

                    setState(() {
                      _isExporting = false;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Failed to crop image. Please try again.',
                        ),
                        backgroundColor: Colors.red.shade800,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
          child: _isExporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFF5500),
                  ),
                )
              : const Text(
                  'Crop',
                  style: TextStyle(color: Color(0xFFFF5500)),
                ),
        ),
      ],
    );
  }
}
