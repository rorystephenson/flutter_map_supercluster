import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_fast_cluster/flutter_map_fast_cluster.dart';
import 'package:flutter_map_fast_cluster/src/center_zoom_controller.dart';
import 'package:flutter_map_fast_cluster/src/cluster_widget.dart';
import 'package:flutter_map_fast_cluster/src/fast_cluster_layer_options.dart';
import 'package:flutter_map_fast_cluster/src/map_calculator.dart';
import 'package:flutter_map_fast_cluster/src/marker_widget.dart';
import 'package:flutter_map_fast_cluster/src/rotate.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:supercluster/supercluster.dart';

import 'cluster_data.dart';

class FastClusterLayer extends StatefulWidget {
  static const defaultMinZoom = 1;
  static const defaultMaxZoom = 20;

  final FastClusterLayerOptions options;
  final MapState mapState;

  final Stream<void> stream;

  const FastClusterLayer(this.options, this.mapState, this.stream, {Key? key})
      : super(key: key);

  int get minZoom => mapState.options.minZoom == null
      ? defaultMinZoom
      : mapState.options.minZoom!.ceil();

  int get maxZoom => mapState.options.maxZoom == null
      ? defaultMaxZoom
      : mapState.options.maxZoom!.ceil() - 1;

  @override
  State<FastClusterLayer> createState() => _FastClusterLayerState();
}

class _FastClusterLayerState extends State<FastClusterLayer>
    with TickerProviderStateMixin {
  late MapCalculator _mapCalculator;
  late Supercluster<Marker> _supercluster;
  late int _maxZoom;
  late int _minZoom;

  late CenterZoomController _centerZoomController;
  StreamSubscription<void>? _movementStreamSubscription;
  int? _hidePopupIfZoomLessThan;

  _FastClusterLayerState();

  @override
  void initState() {
    if (widget.options.popupOptions != null) {
      _movementStreamSubscription = widget.stream.listen(_onMove);
    }

    _mapCalculator = MapCalculator(
      widget.mapState,
      clusterAnchorPos: widget.options.anchor,
    );

    _minZoom = widget.minZoom;
    _maxZoom = widget.maxZoom;
    _initializeClusterManager();
    _centerZoomController = CenterZoomController(
      vsync: this,
      mapState: widget.mapState,
      animationOptions: widget.options.clusterZoomAnimation,
    );

    super.initState();
  }

  @override
  void didUpdateWidget(FastClusterLayer oldWidget) {
    if (oldWidget.options.markers != widget.options.markers ||
        oldWidget.options.maxClusterRadius != widget.options.maxClusterRadius ||
        oldWidget.options.minimumClusterSize !=
            widget.options.minimumClusterSize ||
        _minZoom != (widget.minZoom) ||
        _maxZoom != widget.maxZoom) {
      _minZoom = widget.minZoom;
      _maxZoom = widget.maxZoom;

      _initializeClusterManager();
    }

    if (oldWidget.options.clusterZoomAnimation !=
        widget.options.clusterZoomAnimation) {
      _centerZoomController.animationOptions =
          widget.options.clusterZoomAnimation;
    }
    super.didUpdateWidget(oldWidget);
  }

  void _initializeClusterManager() {
    _supercluster = Supercluster<Marker>(
      points: widget.options.markers,
      getX: (m) => m.point.longitude,
      getY: (m) => m.point.latitude,
      minZoom: _minZoom,
      maxZoom: _maxZoom,
      extractClusterData: (marker) => ClusterData(
        marker,
        computeVisualSize:
            widget.options.computeSize ?? (_, __) => widget.options.size,
        innerExtractor: widget.options.clusterDataExtractor,
      ),
      radius: widget.options.maxClusterRadius,
      minPoints: widget.options.minimumClusterSize,
    );
  }

  @override
  void dispose() {
    _movementStreamSubscription?.cancel();
    _centerZoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: widget.stream, // a Stream<void> or null
      builder: (BuildContext context, _) {
        final popupOptions = widget.options.popupOptions;

        return Stack(
          children: [
            ..._buildClustersAndMarkers(),
            if (popupOptions != null)
              PopupLayer(
                popupBuilder: popupOptions.popupBuilder,
                popupSnap: popupOptions.popupSnap,
                popupController: popupOptions.popupController,
                popupAnimation: popupOptions.popupAnimation,
                markerRotate: popupOptions.markerRotate,
                mapState: widget.mapState,
              )
          ],
        );
      },
    );
  }

  Iterable<Widget> _buildClustersAndMarkers() {
    return _supercluster
        .getClustersAndPoints(
          widget.mapState.bounds.west,
          widget.mapState.bounds.south,
          widget.mapState.bounds.east,
          widget.mapState.bounds.north,
          widget.mapState.zoom.ceil(),
        )
        .map(_buildMarkerOrCluster);
  }

  Widget _buildMarkerOrCluster(ClusterOrMapPoint<Marker> clusterOrMapPoint) {
    return clusterOrMapPoint.map(
      cluster: _buildMarkerClusterLayer,
      mapPoint: _buildMarkerLayer,
    );
  }

  Widget _buildMarkerClusterLayer(Cluster<Marker> cluster) {
    return ClusterWidget(
      mapCalculator: _mapCalculator,
      cluster: cluster,
      builder: widget.options.builder,
      onTap: _onClusterTap(cluster),
      size: _mapCalculator.clusterSize(cluster),
    );
  }

  Widget _buildMarkerLayer(MapPoint<Marker> mapPoint) {
    final marker = mapPoint.originalPoint;

    return MarkerWidget(
      mapCalculator: _mapCalculator,
      marker: marker,
      onTap: _onMarkerTap(mapPoint),
      size: Size(marker.width, marker.height),
      rotate: marker.rotate != true && widget.options.rotate != true
          ? null
          : Rotate(
              angle: -widget.mapState.rotationRad,
              origin: marker.rotateOrigin ?? widget.options.rotateOrigin,
              alignment:
                  marker.rotateAlignment ?? widget.options.rotateAlignment,
            ),
    );
  }

  VoidCallback _onClusterTap(Cluster<Marker> cluster) {
    return () {
      _centerZoomController.moveTo(
        CenterZoom(
          center: LatLng(cluster.latitude, cluster.longitude),
          zoom: _supercluster.getClusterExpansionZoom(cluster.id).toDouble(),
        ),
      );
    };
  }

  VoidCallback _onMarkerTap(MapPoint mapPoint) {
    return () {
      if (widget.options.popupOptions != null) {
        final popupOptions = widget.options.popupOptions!;
        popupOptions.markerTapBehavior.apply(
          mapPoint.originalPoint,
          popupOptions.popupController,
        );
        _hidePopupIfZoomLessThan = mapPoint.zoom;
      }

      widget.options.onMarkerTap?.call(mapPoint.originalPoint);
    };
  }

  void _onMove(void _) {
    if (_hidePopupIfZoomLessThan != null &&
        widget.mapState.zoom < _hidePopupIfZoomLessThan!) {
      widget.options.popupOptions?.popupController.hideAllPopups();
      _hidePopupIfZoomLessThan = null;
    }
  }
}
