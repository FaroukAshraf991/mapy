/// A single geocoding result returned from the Nominatim API.
class PlaceResult {
  final String displayName;
  final double lat;
  final double lon;

  const PlaceResult({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  // ── Serialisation ─────────────────────────────────────────────────────────

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      displayName: json['display_name'] as String,
      // Nominatim returns strings; local history stores doubles — handle both.
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

  // ── Display helpers ───────────────────────────────────────────────────────

  /// The primary name — everything before the first comma.
  String get shortName => displayName.split(',').first.trim();

  /// The rest of the address after the primary name.
  String get address {
    final parts = displayName.split(',');
    return parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
  }
}
