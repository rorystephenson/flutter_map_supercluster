import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_fast_cluster/src/map_calculator.dart';

import 'rotate.dart';

class MarkerWidget extends StatelessWidget {
  final Marker marker;
  final Size size;
  final VoidCallback onTap;
  final Point<double> position;
  final Rotate? rotate;

  MarkerWidget({
    Key? key,
    required MapCalculator mapCalculator,
    required this.marker,
    required this.size,
    required this.onTap,
    required this.rotate,
  })  : position = _getMapPointPixel(mapCalculator, marker),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: marker.builder(context),
    );

    return Positioned(
      key: ObjectKey(marker),
      width: size.width,
      height: size.height,
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
    MapCalculator mapCalculator,
    Marker marker,
  ) {
    final pos = mapCalculator.getPixelFromPoint(marker.point);
    return mapCalculator.removeAnchor(
        pos, marker.width, marker.height, marker.anchor);
  }
}
