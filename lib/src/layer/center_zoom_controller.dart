import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

import '../options/animation_options.dart';
import 'center_zoom_animation.dart';
import 'center_zoom_tween.dart';

class CenterZoomController {
  final TickerProvider _vsync;
  final FlutterMapState _mapState;
  AnimationController? _zoomController;
  CurvedAnimation? _animation;
  double? _velocity;
  CenterZoomTween? _centerZoomTween;
  static const distanceCalculator = Distance();

  CenterZoomController({
    required TickerProvider vsync,
    required FlutterMapState mapState,
    required AnimationOptions animationOptions,
  })  : _mapState = mapState,
        _vsync = vsync {
    this.animationOptions = animationOptions;
  }

  set animationOptions(AnimationOptions animationOptions) {
    _zoomController?.stop(canceled: false);
    _zoomController?.dispose();

    if (animationOptions is AnimationOptionsAnimate) {
      _zoomController = AnimationController(
        vsync: _vsync,
        duration: animationOptions.duration,
      )..addListener(_move);
      _animation = CurvedAnimation(
        parent: _zoomController!,
        curve: animationOptions.curve,
      );
      _velocity = animationOptions.velocity;
    } else if (animationOptions is AnimationOptionsNoAnimation) {
      _velocity = null;
      _zoomController = null;
      _animation = null;
    }
  }

  void dispose() {
    _zoomController?.stop(canceled: false);
    _zoomController?.dispose();
    _zoomController = null;
  }

  void moveTo(CenterZoom centerZoom) {
    if (_zoomController == null) {
      _mapState.move(
        centerZoom.center,
        centerZoom.zoom,
        source: MapEventSource.custom,
      );
    } else {
      _animateTo(centerZoom);
    }
  }

  void _animateTo(CenterZoom centerZoom) async {
    final startCenter = _mapState.center;
    final startZoom = _mapState.zoom;
    final begin = CenterZoom(center: startCenter, zoom: startZoom);
    final end = CenterZoom(center: centerZoom.center, zoom: centerZoom.zoom);
    _centerZoomTween = CenterZoomTween(begin: begin, end: end);
    _zoomController!.reset();

    if (_velocity != null) _setDynamicDuration(_velocity!, begin, end);

    _mapState.mapController.mapEventSink.add(
      MapEventMove(
        id: CenterZoomAnimation.started,
        source: MapEventSource.custom,
        center: startCenter,
        zoom: startZoom,
        targetCenter: centerZoom.center,
        targetZoom: centerZoom.zoom,
      ),
    );
    _zoomController!.forward().then((_) {
      _mapState.mapController.mapEventSink.add(
        MapEventMove(
          id: CenterZoomAnimation.finished,
          source: MapEventSource.custom,
          center: startCenter,
          zoom: startZoom,
          targetCenter: centerZoom.center,
          targetZoom: centerZoom.zoom,
        ),
      );
    });
  }

  void _setDynamicDuration(double velocity, CenterZoom begin, CenterZoom end) {
    final pixelsTranslated = _mapState
        .project(begin.center)
        .distanceTo(_mapState.project(end.center));
    final portionOfScreenTranslated =
        pixelsTranslated / ((_mapState.size.x + _mapState.size.y) / 2);
    final translateVelocity =
        ((portionOfScreenTranslated * 400) * velocity).round();

    final zoomDistance = (begin.zoom - end.zoom).abs();
    final zoomVelocity = 100 + (velocity * 175 * zoomDistance).round();

    _zoomController!.duration =
        Duration(milliseconds: min(max(translateVelocity, zoomVelocity), 2000));
  }

  void _move() {
    final centerZoom = _centerZoomTween!.evaluate(_animation!);
    _mapState.move(
      centerZoom.center,
      centerZoom.zoom,
      source: MapEventSource.custom,
      id: CenterZoomAnimation.inProgress,
    );
  }
}
