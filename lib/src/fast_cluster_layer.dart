import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_fast_cluster/flutter_map_fast_cluster.dart';
import 'package:flutter_map_fast_cluster/src/center_zoom_controller.dart';
import 'package:flutter_map_fast_cluster/src/cluster_layer_controller.dart';
import 'package:flutter_map_fast_cluster/src/cluster_widget.dart';
import 'package:flutter_map_fast_cluster/src/marker_widget.dart';
import 'package:flutter_map_fast_cluster/src/rotate.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:latlong2/latlong.dart';

class FastClusterLayer extends StatefulWidget {
  final FastClusterLayerOptions options;
  final MapState mapState;

  final Stream<void> stream;

  const FastClusterLayer(this.options, this.mapState, this.stream, {Key? key})
      : super(key: key);

  @override
  State<FastClusterLayer> createState() => _FastClusterLayerState();
}

class _FastClusterLayerState extends State<FastClusterLayer>
    with TickerProviderStateMixin {
  late final MapCalculator _mapCalculator;

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
      mapState: widget.mapState,
      clusterWidgetSize: widget.options.clusterWidgetSize,
      clusterAnchorPos: widget.options.anchor,
    );

    _centerZoomController = CenterZoomController(
      vsync: this,
      mapState: widget.mapState,
      animationOptions: widget.options.clusterZoomAnimation,
    );

    super.initState();
  }

  @override
  void didUpdateWidget(FastClusterLayer oldWidget) {
    if (oldWidget.options.clusterZoomAnimation !=
        widget.options.clusterZoomAnimation) {
      _centerZoomController.animationOptions =
          widget.options.clusterZoomAnimation;
    }
    super.didUpdateWidget(oldWidget);
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
        final rotatedOverlay =
            _clusterManager.buildRotatedOverlay(context, _mapCalculator);
        final nonRotatedOverlay = _nonRotatedOverlay(context);

        return Stack(
          children: [
            ..._buildClustersAndMarkers(),
            if (rotatedOverlay != null) rotatedOverlay,
            if (nonRotatedOverlay != null) nonRotatedOverlay,
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
    final paddedBounds = _mapCalculator.paddedMapBounds();
    return _clusterManager
        .getClustersAndPointsIn(
          paddedBounds,
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
      size: widget.options.clusterWidgetSize,
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

  Widget? _nonRotatedOverlay(BuildContext context) {
    final overlay =
        _clusterManager.buildNonRotatedOverlay(context, _mapCalculator);
    if (overlay == null) return null;
    if (!InteractiveFlag.hasFlag(
        _mapCalculator.mapState.options.interactiveFlags,
        InteractiveFlag.rotate)) {
      return overlay;
    }

    final CustomPoint<num> size = widget.mapState.size;
    final sizeChangeDueToRotation =
        size - (widget.mapState.originalSize ?? widget.mapState.size)
            as CustomPoint<double>;
    return Positioned.fill(
      top: sizeChangeDueToRotation.y / 2,
      bottom: sizeChangeDueToRotation.y / 2,
      left: sizeChangeDueToRotation.x / 2,
      right: sizeChangeDueToRotation.x / 2,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..rotateZ(-widget.mapState.rotationRad),
        child: overlay,
      ),
    );
  }

  VoidCallback _onClusterTap(Cluster<Marker> cluster) {
    return () {
      _centerZoomController.moveTo(
        CenterZoom(
          center: LatLng(cluster.latitude, cluster.longitude),
          zoom: _clusterManager.getClusterExpansionZoom(cluster),
        ),
      );
    };
  }

  VoidCallback _onMarkerTap(MapPoint<Marker> mapPoint) {
    return () {
      if (widget.options.popupOptions != null) {
        final popupOptions = widget.options.popupOptions!;
        popupOptions.markerTapBehavior.apply(
          mapPoint.originalPoint,
          popupOptions.popupController,
        );
        _hidePopupIfZoomLessThan = mapPoint.zoom;
      }

      debugPrint('tapping: ${mapPoint.originalPoint.point}');
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

  void _onControllerEvent(ClusterLayerEvent event) {
    setState(() {});
  }
}
