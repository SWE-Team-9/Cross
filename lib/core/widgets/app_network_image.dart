import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 120),
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final WidgetBuilder? placeholder;
  final WidgetBuilder? errorWidget;
  final Duration fadeInDuration;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return _buildError(context);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: fadeInDuration,
      placeholder: (context, _) => _buildPlaceholder(context),
      errorWidget: (context, _, __) => _buildError(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) return placeholder!(context);
    return const ColoredBox(
      color: Color(0xFF202020),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    if (errorWidget != null) return errorWidget!(context);
    return const ColoredBox(color: Color(0xFF202020));
  }
}
