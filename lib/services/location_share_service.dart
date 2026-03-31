import 'package:share_plus/share_plus.dart';

class LocationShareService {
  static Future<void> shareLocation({
    required double latitude,
    required double longitude,
    String? placeName,
  }) async {
    final googleMapsUrl = 'https://www.google.com/maps?q=$latitude,$longitude';
    final text = placeName != null && placeName.isNotEmpty
        ? 'Check out this location: $placeName\n$googleMapsUrl'
        : 'My current location: $googleMapsUrl';

    await SharePlus.instance.share(ShareParams(text: text));
  }

  static Future<void> sharePlace({
    required String placeName,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final googleMapsUrl = 'https://www.google.com/maps?q=$latitude,$longitude';
    final text = '$placeName\n$address\n$googleMapsUrl';

    await SharePlus.instance.share(ShareParams(text: text, subject: placeName));
  }
}
