import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_map_supercluster/src/supercluster_controller_impl.dart';
import 'package:flutter_map_supercluster/src/util.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supercluster/supercluster.dart';

import 'center_zoom_controller.dart';
import 'cluster_widget.dart';
import 'map_calculator.dart';
import 'marker_event.dart';
import 'marker_widget.dart';
import 'rotate.dart';
import 'supercluster_layer_options.dart';

abstract class SuperclusterLayerBase extends StatefulWidget {
  final SuperclusterLayerOptions options;

  SuperclusterControllerBase? get controller;

  const SuperclusterLayerBase({
    Key? key,
    required this.options,
  }) : super(key: key);

  @override
  State<SuperclusterLayerBase> createState();
}

abstract class SuperclusterLayerStateBase<T extends SuperclusterLayerBase>
    extends State<T> with TickerProviderStateMixin {
  FlutterMapState? _mapState;

  late int minZoom;
  late int maxZoom;
  late MapCalculator _mapCalculator;

  late CenterZoomController _centerZoomController;
  StreamSubscription<MarkerEvent>? _controllerSubscription;
  StreamSubscription<void>? _movementStreamSubscription;
  int? _hidePopupIfZoomLessThan;

  PopupState? _popupState;

  void onMarkerEvent(
    FlutterMapState mapState,
    MarkerEvent markerEvent,
  );

  void initializeClusterManager(List<Marker> markers);

  List<Marker> getAllMarkers();

  List<LayerElement<Marker>> search(
    double westLng,
    double southLat,
    double eastLng,
    double northLat,
    int zoom,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final previousMapState = _mapState;
    final mapState = FlutterMapState.maybeOf(context)!;
    _mapState = mapState;

    bool firstInitialization = previousMapState == null;
    bool mapStateNewOrChanged =
        firstInitialization || mapState != previousMapState;

    final oldMinZoom = firstInitialization ? null : minZoom;
    final oldMaxZoom = firstInitialization ? null : maxZoom;
    minZoom = minZoomFor(mapState);
    maxZoom = maxZoomFor(mapState);

    bool zoomsChanged =
        !firstInitialization && oldMinZoom != minZoom || oldMaxZoom != maxZoom;

    if (mapStateNewOrChanged) {
      _mapCalculator = MapCalculator(
        mapState: mapState,
        clusterWidgetSize: widget.options.clusterWidgetSize,
        clusterAnchorPos: widget.options.anchor,
      );
      if (!firstInitialization) _centerZoomController.dispose();
      _centerZoomController = CenterZoomController(
        vsync: this,
        mapState: mapState,
        animationOptions: widget.options.clusterZoomAnimation,
      );
      _controllerSubscription?.cancel();
      _controllerSubscription = widget.controller?.stream
          .listen((markerEvent) => onMarkerEvent(mapState, markerEvent));

      _movementStreamSubscription?.cancel();
      if (widget.options.popupOptions != null) {
        _movementStreamSubscription = mapState.mapController.mapEventStream
            .listen((_) => _onMove(mapState));
      }
    }

    if (mapStateNewOrChanged || zoomsChanged) {
      if (!firstInitialization) {
        debugPrint(
            'WARNING: Changes to the FlutterMapState have caused a rebuild of '
            'the Supercluster clusters. This can be a slow operation and '
            'should be avoided whenever possible.');
      }
      initializeClusterManager(
        firstInitialization
            ? widget.options.initialMarkers
            : getAllMarkers().toList(),
      );
    }
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldOptions = oldWidget.options;
    final newOptions = widget.options;

    final mapState = _mapState!;

    if (oldOptions.maxClusterRadius != newOptions.maxClusterRadius ||
        oldOptions.minimumClusterSize != newOptions.minimumClusterSize) {
      debugPrint(
          'WARNING: Changes to the Supercluster options have caused a rebuild '
          'of the Supercluster clusters. This can be a slow operation and '
          'should be avoided whenever possible.');
      initializeClusterManager(getAllMarkers().toList());
    }

    if (oldOptions.clusterZoomAnimation != newOptions.clusterZoomAnimation) {
      _centerZoomController.animationOptions = newOptions.clusterZoomAnimation;
    }
    if (oldWidget.controller != widget.controller) {
      _controllerSubscription?.cancel();
      _controllerSubscription = widget.controller?.stream
          .listen((markerEvent) => onMarkerEvent(mapState, markerEvent));
    }

    if (widget.options.popupOptions != oldWidget.options.popupOptions) {
      _movementStreamSubscription?.cancel();
      if (widget.options.popupOptions != null) {
        _movementStreamSubscription = mapState.mapController.mapEventStream
            .listen((_) => _onMove(mapState));
      }
    }
  }

  @override
  void dispose() {
    _movementStreamSubscription?.cancel();
    _centerZoomController.dispose();
    _controllerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = FlutterMapState.maybeOf(context)!;

    final popupOptions = widget.options.popupOptions;

    return _wrapWithPopupStateIfPopupsEnabled(
      (popupState) => Stack(
        children: [
          ..._buildClustersAndMarkers(mapState),
          if (popupOptions != null)
            PopupLayer(
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

  Iterable<Widget> _buildClustersAndMarkers(FlutterMapState mapState) {
    final paddedBounds = _mapCalculator.paddedMapBounds();
    return search(
      paddedBounds.west,
      paddedBounds.south,
      paddedBounds.east,
      paddedBounds.north,
      mapState.zoom.ceil(),
    ).map((layerElement) => _buildMarkerOrCluster(mapState, layerElement));
  }

  Widget _buildMarkerOrCluster(
    FlutterMapState mapState,
    LayerElement<Marker> layerElement,
  ) {
    return layerElement.handle(
      cluster: _buildMarkerClusterLayer,
      point: (point) => _buildMarkerLayer(mapState, point),
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

  Widget _buildMarkerLayer(
    FlutterMapState mapState,
    LayerPoint<Marker> mapPoint,
  ) {
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
              angle: -mapState.rotationRad,
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

  void _onMove(FlutterMapState mapState) {
    if (_hidePopupIfZoomLessThan != null &&
        mapState.zoom < _hidePopupIfZoomLessThan!) {
      widget.options.popupOptions?.popupController.hideAllPopups();
      _hidePopupIfZoomLessThan = null;
    }
  }
}
