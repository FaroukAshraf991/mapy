/// Available map visual styles.
enum MapStyle { street, satellite, terrain }

/// Available travel modes for routing.
enum TravelMode { driving, foot, bicycle, motorcycle }

/// Locate-me button follow state — mirrors Google Maps behaviour.
/// none     → button is grey; map is free to pan.
/// follow   → button is blue (filled); camera tracks position, no rotation.
/// compass  → button is blue (arrow); camera tracks position AND rotates with device heading.
enum LocationFollowMode { none, follow, compass }
