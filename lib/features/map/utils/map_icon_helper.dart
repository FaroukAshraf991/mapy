import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Helper class to handle the translation of Flutter Material Icons 
/// into byte-backed images for the MapLibre engine.
class MapIconHelper {
  /// Captures a [materialIcon] and converts it into a [Uint8List] the map can render.
  static Future<Uint8List> captureIcon(IconData materialIcon, Color color) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    textPainter.text = TextSpan(
      text: String.fromCharCode(materialIcon.codePoint),
      style: TextStyle(
        fontSize: 100.0,
        fontFamily: materialIcon.fontFamily,
        package: materialIcon.fontPackage,
        color: color,
        shadows: [
          Shadow(
            blurRadius: 10.0,
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(2, 2),
          ),
        ],
      ),
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(100, 100);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      return Uint8List(0); // Return empty rather than crashing
    }
    return bytes.buffer.asUint8List();
  }

  /// Adds all standard navigation icons (Home, Work, Destination, User) to the map.
  static Future<void> addStandardIcons(MapLibreMapController controller) async {
    final icons = {
      "dest-pin": [Icons.location_on_rounded, Colors.redAccent],
      "home-pin": [Icons.home_rounded, Colors.blueAccent],
      "work-pin": [Icons.work_rounded, Colors.orangeAccent],
      "user-arrow": [Icons.navigation_rounded, Colors.blueAccent],
    };

    for (final entry in icons.entries) {
      try {
        final bytes = await captureIcon(entry.value[0] as IconData, entry.value[1] as Color);
        if (bytes.isNotEmpty) {
          await controller.addImage(entry.key, bytes);
        }
      } catch (e) {
        debugPrint('Icon ${entry.key} failed to add/capture: $e');
      }
    }
  }
}
