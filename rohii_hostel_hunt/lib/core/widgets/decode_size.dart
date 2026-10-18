import 'package:flutter/widgets.dart';

/// The width, in pixels, a picture should be DECODED at.
///
/// `Image.network` decodes the whole file by default: a 12 megapixel photo becomes about 48 MB of
/// memory even when it is drawn 120 points wide. Giving `cacheWidth` makes Flutter decode it at the
/// size it is drawn (never larger than the file, so a small picture is not stretched).
///
/// [logicalWidth] is the width it is drawn at, in points; pass `double.infinity` for a picture that
/// fills the screen. [max] stops a very wide screen from asking for more than the server sends.
int decodeWidth(BuildContext context, double logicalWidth, {int max = 1080}) {
  final ratio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
  final width = logicalWidth.isFinite ? logicalWidth : (MediaQuery.maybeSizeOf(context)?.width ?? 400.0);
  return (width * ratio).round().clamp(64, max);
}
