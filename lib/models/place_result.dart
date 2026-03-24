// PlaceResult model
class PlaceResult {
  final String displayName;
  final double lat;
  final double lon;

  const PlaceResult({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      displayName: json['display_name'] as String,
      lat: json['lat'] is String
          ? double.parse(json['lat'] as String)
          : (json['lat'] as num).toDouble(),
      lon: json['lon'] is String
          ? double.parse(json['lon'] as String)
          : (json['lon'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'lat': lat,
        'lon': lon,
      };

  /// Short label: the first segment of display_name (usually the place name).
  String get shortName => displayName.split(',').first.trim();

  /// Subtitle: the rest of the address after the first segment.
  String get address {
    final parts = displayName.split(',');
    return parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
  }
}
