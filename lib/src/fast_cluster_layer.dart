import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_fast_cluster/src/center_zoom_controller.dart';
import 'package:flutter_map_fast_cluster/src/cluster_widget.dart';
import 'package:flutter_map_fast_cluster/src/fast_cluster_layer_controller.dart';
import 'package:flutter_map_fast_cluster/src/fast_cluster_layer_options.dart';
import 'package:flutter_map_fast_cluster/src/map_calculator.dart';
import 'package:flutter_map_fast_cluster/src/marker_widget.dart';
import 'package:flutter_map_fast_cluster/src/rotate.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supercluster/supercluster.dart';

import 'cluster_data.dart';

class FastClusterLayer extends StatefulWidget {
  static const defaultMinZoom = 1;
  static const defaultMaxZoom = 20;

  final FastClusterLayerOptions options;
  final MapState mapState;

  final int minZoom;
  final int maxZoom;

  final Stream<void> stream;

  FastClusterLayer(this.options, this.mapState, this.stream, {Key? key})
      : minZoom = mapState.options.minZoom?.ceil() ?? defaultMinZoom,
        maxZoom = mapState.options.maxZoom?.ceil() ?? defaultMaxZoom,
        super(key: key);

  @override
  State<FastClusterLayer> createState() => _FastClusterLayerState();
}

class _FastClusterLayerState extends State<FastClusterLayer>
    with TickerProviderStateMixin {
  late MapCalculator _mapCalculator;
  late Supercluster<Marker> _supercluster;

  late CenterZoomController _centerZoomController;
  late final FastClusterLayerController _controller;
  late final bool _shouldDisposeController;
  late final StreamSubscription<MarkerEvent> _controllerSubscription;
  StreamSubscription<void>? _movementStreamSubscription;
  int? _hidePopupIfZoomLessThan;

  PopupState? _popupState;

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

    _initializeClusterManager(widget.options.initialMarkers);
    _centerZoomController = CenterZoomController(
      vsync: this,
      mapState: widget.mapState,
      animationOptions: widget.options.clusterZoomAnimation,
    );

    _controller = widget.options.controller ?? FastClusterLayerController();
    _shouldDisposeController = widget.options.controller == null;
    _controllerSubscription =
        _controller.markerEventStream.listen(_onMarkerEvent);

    super.initState();
  }

  @override
  void didUpdateWidget(FastClusterLayer oldWidget) {
    final oldOptions = oldWidget.options;
    final newOptions = widget.options;

    if (oldOptions.maxClusterRadius != newOptions.maxClusterRadius ||
        (oldOptions.controller is MutableFastClusterLayerController !=
            newOptions.controller is MutableFastClusterLayerController) ||
        oldOptions.minimumClusterSize != newOptions.minimumClusterSize ||
        oldWidget.minZoom != widget.minZoom ||
        oldWidget.maxZoom != widget.maxZoom) {
      debugPrint('WARNING: Changes to the FastClusterLayer options have caused'
          'a rebuild of the clusters. This is a slow operation with many'
          'markers and should be avoided when possible.');
      _initializeClusterManager(_supercluster.getLeaves().toList());
    }

    if (oldOptions.clusterZoomAnimation != newOptions.clusterZoomAnimation) {
      _centerZoomController.animationOptions = newOptions.clusterZoomAnimation;
    }
    super.didUpdateWidget(oldWidget);
  }

  void _initializeClusterManager(List<Marker> markers) {
    final controller = widget.options.controller;
    if (controller is MutableFastClusterLayerController) {
      _supercluster = SuperclusterMutable<Marker>(
        maxEntries: controller.maxMarkers,
        getX: (m) => m.point.longitude,
        getY: (m) => m.point.latitude,
        minZoom: widget.minZoom,
        maxZoom: widget.maxZoom,
        extractClusterData: (marker) => ClusterData(
          marker,
          innerExtractor: widget.options.clusterDataExtractor,
        ),
        radius: widget.options.maxClusterRadius,
        onClusterDataChange: controller.onClusterDataChange == null
            ? null
            : (clusterData) =>
                controller.onClusterDataChange!(clusterData as ClusterData?),
      )..load(markers);
    } else {
      _supercluster = SuperclusterImmutable<Marker>(
        points: markers,
        getX: (m) => m.point.longitude,
        getY: (m) => m.point.latitude,
        minZoom: widget.minZoom,
        maxZoom: widget.maxZoom,
        extractClusterData: (marker) => ClusterData(
          marker,
          innerExtractor: widget.options.clusterDataExtractor,
        ),
        radius: widget.options.maxClusterRadius,
        minPoints: widget.options.minimumClusterSize,
      );
    }
  }

  @override
  void dispose() {
    _movementStreamSubscription?.cancel();
    _centerZoomController.dispose();

    if (_shouldDisposeController) _controller.dispose();
    _controllerSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: widget.stream, // a Stream<void> or null
      builder: (BuildContext context, _) {
        final popupOptions = widget.options.popupOptions;

        return _wrapWithPopupStateIfPopupsEnabled(
          (popupState) => Stack(
            children: [
              ..._buildClustersAndMarkers(),
              if (popupOptions != null)
                PopupLayer(
                  mapState: widget.mapState,
                  popupState: _popupState!,
                  popupBuilder: popupOptions.popupBuilder,
                  popupSnap: popupOptions.popupSnap,
                  popupController: popupOptions.popupController,
                  popupAnimation: popupOptions.popupAnimation,
                  markerRotate: popupOptions.markerRotate,
                )
            ],
          ),
        );
      },
    );
  }

  Widget _wrapWithPopupStateIfPopupsEnabled(
      Widget Function(PopupState? popupState) builder) {
    if (widget.options.popupOptions == null) return builder(null);

    return PopupStateWrapper(builder: (context, popupState) {
      _popupState = popupState;
      if (widget.options.popupOptions!.selectedMarkerBuilder != null) {
        context.watch<PopupState>();
      }
      return builder(popupState);
    });
  }

  Iterable<Widget> _buildClustersAndMarkers() {
    final paddedBounds = _mapCalculator.paddedMapBounds();
    return _supercluster
        .search(
          paddedBounds.west,
          paddedBounds.south,
          paddedBounds.east,
          paddedBounds.north,
          widget.mapState.zoom.ceil(),
        )
        .map((e) => _buildMarkerOrCluster(e));
  }

  Widget _buildMarkerOrCluster(LayerElement<Marker> layerElement) {
    return layerElement.handle(
      cluster: _buildMarkerClusterLayer,
      point: _buildMarkerLayer,
    );
  }

  Widget _buildMarkerClusterLayer(LayerCluster<Marker> cluster) {
    return ClusterWidget(
      mapCalculator: _mapCalculator,
      cluster: cluster,
      builder: widget.options.builder,
      onTap: _onClusterTap(cluster),
      size: widget.options.clusterWidgetSize,
    );
  }

  Widget _buildMarkerLayer(LayerPoint<Marker> mapPoint) {
    final marker = mapPoint.originalPoint;

    var markerBuilder = marker.builder;
    final popupOptions = widget.options.popupOptions;
    if (popupOptions?.selectedMarkerBuilder != null &&
        _popupState!.selectedMarkers.contains(marker)) {
      markerBuilder = ((context) =>
          widget.options.popupOptions!.selectedMarkerBuilder!(context, marker));
    }

    return MarkerWidget(
      mapCalculator: _mapCalculator,
      marker: marker,
      markerBuilder: markerBuilder,
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

  VoidCallback _onClusterTap(LayerCluster<Marker> cluster) {
    return () {
      _centerZoomController.moveTo(
        CenterZoom(
          center: LatLng(cluster.latitude, cluster.longitude),
          zoom: cluster.highestZoom + 1,
        ),
      );
    };
  }

  VoidCallback _onMarkerTap(LayerPoint<Marker> mapPoint) {
    return () {
      if (widget.options.popupOptions != null) {
        assert(_popupState != null);

        final popupOptions = widget.options.popupOptions!;
        popupOptions.markerTapBehavior.apply(
          mapPoint.originalPoint,
          _popupState!,
          popupOptions.popupController,
        );
        _hidePopupIfZoomLessThan = mapPoint.lowestZoom;

        if (popupOptions.selectedMarkerBuilder != null) setState(() {});
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

  void _onMarkerEvent(MarkerEvent markerEvent) {
    assert(
      _supercluster is SuperclusterMutable<Marker>,
      'Addition and removal are only supported when using a mutable Supercluster',
    );

    if (markerEvent is AddMarkerEvent) {
      (_supercluster as SuperclusterMutable<Marker>).insert(markerEvent.marker);
    } else if (markerEvent is RemoveMarkerEvent) {
      (_supercluster as SuperclusterMutable<Marker>).remove(markerEvent.marker);
    } else if (markerEvent is ReplaceAllMarkerEvent) {
      _initializeClusterManager(markerEvent.markers);
    } else if (markerEvent is ModifyMarkerEvent) {
      (_supercluster as SuperclusterMutable<Marker>).modifyPointData(
        markerEvent.oldMarker,
        markerEvent.newMarker,
        updateParentClusters: markerEvent.updateParentClusters,
      );
    } else {
      throw 'Unknown $MarkerEvent type ${markerEvent.runtimeType}';
    }

    widget.mapState.rebuildLayers();
  }
}
