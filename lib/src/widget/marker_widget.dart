import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/src/layer/anchor_util.dart';
import 'package:flutter_map_supercluster/src/layer/flutter_map_state_extension.dart';
import 'package:flutter_map_supercluster/src/splay/displaced_marker.dart';

class MarkerWidget extends StatelessWidget {
  final Marker marker;
  final WidgetBuilder markerBuilder;
  final VoidCallback onTap;
  final Point<double> position;
  final double mapRotationRad;

  final AlignmentGeometry? rotateAlignment;
  final bool removeRotateOrigin;

  MarkerWidget({
    Key? key,
    required FlutterMapState mapState,
    required this.marker,
    required this.markerBuilder,
    required this.onTap,
  })  : mapRotationRad = mapState.rotationRad,
        position = _getMapPointPixel(mapState, marker),
        rotateAlignment = marker.rotateAlignment,
        removeRotateOrigin = false,
        super(key: key);

  MarkerWidget.displaced({
    Key? key,
    required DisplacedMarker displacedMarker,
    required CustomPoint position,
    required this.markerBuilder,
    required this.onTap,
    required this.mapRotationRad,
  })  : marker = displacedMarker.marker,
        position = AnchorUtil.removeAnchor(
          position,
          displacedMarker.marker.width,
          displacedMarker.marker.height,
          displacedMarker.anchor,
        ),
        rotateAlignment = DisplacedMarker.rotateAlignment,
        removeRotateOrigin = true,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: markerBuilder(context),
    );

    return Positioned(
      key: ObjectKey(marker),
      width: marker.width,
      height: marker.height,
      left: position.x,
      top: position.y,
      child: marker.rotate != true
          ? child
          : Transform.rotate(
              angle: -mapRotationRad,
              origin: removeRotateOrigin ? null : marker.rotateOrigin,
              alignment: rotateAlignment,
              child: child,
            ),
    );
  }

  static Point<double> _getMapPointPixel(
    FlutterMapState mapState,
    Marker marker,
  ) {
    return AnchorUtil.removeAnchor(
      mapState.getPixelOffset(marker.point),
      marker.width,
      marker.height,
      marker.anchor,
    );
  }
}
