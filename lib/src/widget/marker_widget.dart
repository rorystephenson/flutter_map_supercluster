import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/src/layer/anchor_util.dart';
import 'package:flutter_map_supercluster/src/layer/flutter_map_state_extension.dart';

import 'rotate.dart';

class MarkerWidget extends StatelessWidget {
  final Marker marker;
  final WidgetBuilder markerBuilder;
  final VoidCallback onTap;
  final Point<double> position;
  final Rotate? rotate;

  MarkerWidget({
    Key? key,
    required FlutterMapState mapState,
    required this.marker,
    required this.markerBuilder,
    required this.onTap,
    required this.rotate,
  })  : position = _getMapPointPixel(mapState, marker),
        super(key: key);

  MarkerWidget.withPosition({
    Key? key,
    required CustomPoint position,
    required this.marker,
    required this.markerBuilder,
    required this.onTap,
    required this.rotate,
  })  : position = AnchorUtil.removeAnchor(
          position,
          marker.width,
          marker.height,
          marker.anchor,
        ),
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
      child: rotate == null
          ? child
          : Transform.rotate(
              angle: rotate!.angle,
              origin: rotate!.origin,
              alignment: rotate!.alignment,
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
