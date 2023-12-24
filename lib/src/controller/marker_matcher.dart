import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Matches a given marker either by equality (MarkerMatcher.equalsMarker) or
/// using a location and test (MarkerMatcher.withPredicate).
class MarkerMatcher {
  final Marker? _marker;
  final LatLng point;
  final bool Function(Marker marker)? _predicate;

  /// Matches a [Marker] which equals the provided marker. This relies on the
  /// marker's == implementation. If your SuperclusterLayer's indexBuilder
  /// builds the supercluster index in a separate isolate be sure to read the
  /// documentation of [IndexBuilders.computeWithOriginalMarkers] and
  /// [IndexBuilders.computeWithCopiedMarkers] for an explanation on how this
  /// may affect == comparison.
  MarkerMatcher.equalsMarker(Marker this._marker)
      : point = _marker.point,
        _predicate = null;

  /// Matches a [Marker] at the given [point] for which the [predicate] returns
  /// true.
  MarkerMatcher.withPredicate({
    required this.point,
    required bool Function(Marker marker) predicate,
  })  : _predicate = predicate,
        _marker = null;

  bool matches(Marker marker) =>
      _marker != null ? _marker == marker : _predicate!(marker);
}
