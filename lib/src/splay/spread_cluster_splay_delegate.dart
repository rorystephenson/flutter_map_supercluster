import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_supercluster/src/layer/supercluster_layer.dart';
import 'package:flutter_map_supercluster/src/splay/cluster_splay_delegate.dart';
import 'package:flutter_map_supercluster/src/splay/displaced_marker.dart';
import 'package:flutter_map_supercluster/src/splay/displaced_marker_offset.dart';
import 'package:latlong2/latlong.dart';
import 'package:supercluster/supercluster.dart';

/// Builder for the cluster widget when it is splayed.
typedef SplayClusterWidgetBuilder = Widget Function(
  BuildContext context,
  LatLng position,
  int markerCount,
  ClusterDataBase? extraClusterData,
  double animation,
);

/// Displays splayed markers in a circle around their cluster.
class SpreadClusterSplayDelegate extends ClusterSplayDelegate {
  static const pi2 = pi * 2;
  static const circleStartAngle = 0;

  final SplayClusterWidgetBuilder? builder;
  final double clusterOpacity;
  final SplayLineOptions? splayLineOptions;
  final double distanceIncrement;

  const SpreadClusterSplayDelegate({
    /// Duration of the splay animation.
    required super.duration,

    /// How far the markers are splayed from the cluster.
    super.distance = 70.0,

    /// The Curve of the splay animation.
    super.curve = Curves.easeInOut,

    /// Option for displaying lines from the splayed markers to the cluster
    /// center.
    this.splayLineOptions,

    /// The opacity of the cluster marker when it is expanded. If null it will
    /// be fully opaque. If [builder] is provided this has no effect.
    this.clusterOpacity = 0.4,

    // Optional builder used for the expanded cluster. If provided
    // [clusterOpacity] has no affect.
    this.builder,

    // the displacement radius is increased by this number depending on the markers count
    this.distanceIncrement = 4.0,
  });

  @override
  Widget buildCluster(
    BuildContext context,
    ClusterWidgetBuilder clusterBuilder,
    LatLng position,
    int markerCount,
    ClusterDataBase? extraClusterData,
    double animationProgress,
  ) {
    if (builder != null) {
      return builder!(
        context,
        position,
        markerCount,
        extraClusterData,
        animationProgress,
      );
    } else {
      return Opacity(
        opacity: 1 - ((1 - clusterOpacity) * animationProgress),
        child: clusterBuilder(
          context,
          position,
          markerCount,
          extraClusterData,
        ),
      );
    }
  }

  @override
  List<DisplacedMarker> displaceMarkers(
    List<Marker> markers, {
    required LatLng clusterPosition,
    required Point Function(LatLng latLng) project,
    required LatLng Function(Point point) unproject,
  }) {
    final markersWithAngles = markers
        .map(
          (marker) => _MarkerWithAngle(
            marker,
            _angle(marker.point, clusterPosition),
          ),
        )
        .toList()
      ..sort((a, b) => a.angle.compareTo(b.angle));

    final circleOffsets = _clockwiseCircle(
        distance + (distanceIncrement * markersWithAngles.length),
        markersWithAngles.length);
    final clusterPointAtMaxZoom = project(clusterPosition);

    final result = <DisplacedMarker>[];

    for (int i = 0; i < markersWithAngles.length; i++) {
      result.add(
        DisplacedMarker(
          marker: markersWithAngles[i].marker,
          displacedPoint: unproject(clusterPointAtMaxZoom + circleOffsets[i]),
        ),
      );
    }

    return result;
  }

  @override
  List<DisplacedMarkerOffset> displacedMarkerOffsets(
    List<DisplacedMarker> displacedMarkers,
    double animationProgress,
    Point<num> Function(LatLng point) getPixelOffset,
    Point clusterPosition,
  ) {
    return displacedMarkers
        .map(
          (displacedMarker) => DisplacedMarkerOffset(
            displacedMarker: displacedMarker,
            displacedOffset: (getPixelOffset(displacedMarker.displacedPoint) -
                    clusterPosition) *
                animationProgress,
            originalOffset:
                getPixelOffset(displacedMarker.originalPoint) - clusterPosition,
          ),
        )
        .toList();
  }

  @override
  Widget? splayDecoration(List<DisplacedMarkerOffset> displacedMarkerOffsets) =>
      splayLineOptions == null
          ? null
          : _DisplacedMarkerSplay(
              width: distance +
                  (distanceIncrement * displacedMarkerOffsets.length) * 2.0,
              height: distance +
                  (distanceIncrement * displacedMarkerOffsets.length) * 2.0,
              displacedMarkerOffsets: displacedMarkerOffsets,
              splayLineOptions: splayLineOptions!,
            );

  // Get the angle in radians from [origin] to [other].
  static double _angle(LatLng origin, LatLng other) {
    final dLon = other.longitudeInRad - origin.longitudeInRad;
    final y = sin(dLon);
    final x = cos(origin.latitudeInRad) * tan(other.latitudeInRad) -
        sin(origin.latitudeInRad) * cos(dLon);

    return atan2(y, x);
  }

  static List<Point> _clockwiseCircle(double radius, int count) {
    final angleStep = pi2 / count;

    return List<Point>.generate(count, (index) {
      final angle = circleStartAngle + index * angleStep;

      return Point<double>(
        radius * cos(angle),
        radius * sin(angle),
      );
    });
  }
}

class SplayLineOptions {
  final Color lineColor;
  final double lineWidth;

  const SplayLineOptions({
    this.lineColor = Colors.black26,
    this.lineWidth = 2,
  });
}

class _MarkerWithAngle {
  final Marker marker;
  final double angle;

  const _MarkerWithAngle(this.marker, this.angle);
}

class _DisplacedMarkerSplay extends StatelessWidget {
  final double width;
  final double height;
  final SplayLineOptions splayLineOptions;
  final List<DisplacedMarkerOffset> displacedMarkerOffsets;

  const _DisplacedMarkerSplay({
    required this.width,
    required this.height,
    required this.splayLineOptions,
    required this.displacedMarkerOffsets,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      foregroundPainter: _DisplacementPainter(
        splayLineOptions: splayLineOptions,
        offsets: displacedMarkerOffsets,
        centerOffset: Offset(width / 2, height / 2),
      ),
    );
  }
}

class _DisplacementPainter extends CustomPainter {
  final SplayLineOptions splayLineOptions;
  final List<DisplacedMarkerOffset> offsets;
  final Offset centerOffset;

  const _DisplacementPainter({
    required this.splayLineOptions,
    required this.offsets,
    required this.centerOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = splayLineOptions.lineColor
      ..strokeWidth = splayLineOptions.lineWidth;

    for (final offset in offsets) {
      canvas.drawLine(
        Offset(centerOffset.dx, centerOffset.dy),
        Offset(
          offset.displacedOffset.x + centerOffset.dx,
          offset.displacedOffset.y + centerOffset.dy,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DisplacementPainter oldDelegate) =>
      oldDelegate.splayLineOptions != splayLineOptions ||
      oldDelegate.offsets != offsets ||
      oldDelegate.centerOffset != centerOffset;
}
