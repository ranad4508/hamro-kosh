import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Opens [imageUrl] full-screen with pinch-to-zoom/pan — used wherever an
/// uploaded image (payment proof, QR code, receipt) is shown as a small
/// preview and needs to actually be inspected closely, for both the admin
/// reviewing it and the member who uploaded it.
Future<void> showFullScreenImage(
  BuildContext context,
  String imageUrl, {
  String? heroTag,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, animation, _) => FadeTransition(
        opacity: animation,
        child: _FullScreenImageViewer(imageUrl: imageUrl, heroTag: heroTag),
      ),
    ),
  );
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        _transformationController.value = _animationController.drive(
          Matrix4Tween(
            begin: _transformationController.value,
            end: Matrix4.identity(),
          ),
        ).value;
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _animationController.forward(from: 0);
    } else {
      final position = _doubleTapDetails!.localPosition;
      // Zoom in to 3x scale at the double-tap position
      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx * 2, -position.dy * 2)
        ..scale(3.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.contain,
      progressIndicatorBuilder: (context, url, progress) => Center(
        child: CircularProgressIndicator(value: progress.progress),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onDoubleTapDown: (d) => _doubleTapDetails = d,
        onDoubleTap: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1,
          maxScale: 5,
          boundaryMargin: const EdgeInsets.all(20),
          child: Center(
            child: widget.heroTag == null
                ? image
                : Hero(tag: widget.heroTag!, child: image),
          ),
        ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  const _FullScreenImageViewer({required this.imageUrl, this.heroTag});

  final String imageUrl;
  final String? heroTag;

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}
