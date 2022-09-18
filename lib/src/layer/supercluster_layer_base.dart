import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supercluster/supercluster.dart';

import '../controller/marker_event.dart';
import '../controller/supercluster_controller_impl.dart';
import '../options/animation_options.dart';
import '../options/popup_options.dart';
import '../widget/cluster_widget.dart';
import '../widget/marker_widget.dart';
import '../widget/rotate.dart';
import 'center_zoom_controller.dart';
import 'map_calculator.dart';

typedef ClusterWidgetBuilder = Widget Function(
    BuildContext context, int markerCount, ClusterDataBase? extraClusterData);

abstract class SuperclusterLayerBase extends StatefulWidget {
  /// Cluster builder
  final ClusterWidgetBuilder builder;

  SuperclusterControllerBase? get controller;

  /// Initial list of markers, additions/removals must be made using the
  /// [controller].
  final List<Marker> initialMarkers;

  /// The minimum number of points required to form a cluster, if there is less
  /// than this number of points within the [maxClusterRadius] the markers will
  /// be left unclustered.
  final int? minimumClusterSize;

  /// The maximum radius in pixels that a cluster can cover.
  final int maxClusterRadius;

  /// Implement this function to extract extra data from Markers which can be
  /// used in the [builder] and [computeSize].
  final ClusterDataBase Function(Marker marker)? clusterDataExtractor;

  /// Function to call when a Marker is tapped
  final void Function(Marker)? onMarkerTap;

  /// Popup's options that show when tapping markers or via the PopupController.
  final PopupOptions? popupOptions;

  /// If true markers will be counter rotated to the map rotation
  final bool? rotate;

  /// The origin of the coordinate system (relative to the upper left corner of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  final Offset? rotateOrigin;

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as the [rotateOrigin], both are applied.
  ///
  /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [Directionality.of] returns
  /// [TextDirection.ltr], and `1.0` if [Directionality.of] returns
  /// [TextDirection.rtl].	 Similarly [AlignmentDirectional.centerEnd] is the
  /// same as an [Alignment] whose [Alignment.x] value is `1.0` if
  /// [Directionality.of] returns	 [TextDirection.ltr], and `-1.0` if
  /// [Directionality.of] returns [TextDirection.rtl].
  final AlignmentGeometry? rotateAlignment;

  /// Cluster size
  final Size clusterWidgetSize;

  /// Cluster anchor
  final AnchorPos? anchor;

  /// Control cluster zooming (triggered by cluster tap) animation. Use
  /// [AnimationOptions.none] to disable animation. See
  ///  [AnimationOptions.animate] for more information on animation options.
  final AnimationOptions clusterZoomAnimation;

  const SuperclusterLayerBase({
    Key? key,
    required this.builder,
    this.initialMarkers = const [],
    this.onMarkerTap,
    this.minimumClusterSize,
    this.maxClusterRadius = 80,
    this.clusterDataExtractor,
    this.clusterWidgetSize = const Size(30, 30),
    this.clusterZoomAnimation = const AnimationOptions.animate(
      curve: Curves.linear,
      velocity: 1,
    ),
    this.popupOptions,
    this.rotate,
    this.rotateOrigin,
    this.rotateAlignment,
    this.anchor,
  }) : super(key: key);

  @override
  State<SuperclusterLayerBase> createState();
}

abstract class SuperclusterLayerStateBase<T extends SuperclusterLayerBase>
    extends State<T> with TickerProviderStateMixin {
  static const defaultMinZoom = 1;
  static const defaultMaxZoom = 20;

  FlutterMapState? _mapState;

  late int minZoom;
  late int maxZoom;
  late MapCalculator _mapCalculator;

  late CenterZoomController _centerZoomController;
  StreamSubscription<MarkerEvent>? _controllerSubscription;
  StreamSubscription<void>? _movementStreamSubscription;
  int? _hidePopupIfZoomLessThan;

  PopupState? _popupState;

  void onMarkerEvent(MarkerEvent markerEvent);

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
    minZoom = mapState.options.minZoom?.ceil() ?? defaultMinZoom;
    maxZoom = mapState.options.maxZoom?.ceil() ?? defaultMaxZoom;

    bool zoomsChanged =
        !firstInitialization && oldMinZoom != minZoom || oldMaxZoom != maxZoom;

    if (mapStateNewOrChanged) {
      _mapCalculator = MapCalculator(
        mapState: mapState,
        clusterWidgetSize: widget.clusterWidgetSize,
        clusterAnchorPos: widget.anchor,
      );
      if (!firstInitialization) _centerZoomController.dispose();
      _centerZoomController = CenterZoomController(
        vsync: this,
        mapState: mapState,
        animationOptions: widget.clusterZoomAnimation,
      );
      _controllerSubscription?.cancel();
      _controllerSubscription = widget.controller?.stream
          .listen((markerEvent) => onMarkerEvent(markerEvent));

      _movementStreamSubscription?.cancel();
      if (widget.popupOptions != null) {
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
        firstInitialization ? widget.initialMarkers : getAllMarkers().toList(),
      );
    }
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldOptions = oldWidget;
    final newOptions = widget;

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
          .listen((markerEvent) => onMarkerEvent(markerEvent));
    }

    if (widget.popupOptions != oldWidget.popupOptions) {
      _movementStreamSubscription?.cancel();
      if (widget.popupOptions != null) {
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

    final popupOptions = widget.popupOptions;

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
    if (widget.popupOptions == null) return builder(null);

    return PopupStateWrapper(builder: (context, popupState) {
      _popupState = popupState;
      if (widget.popupOptions!.selectedMarkerBuilder != null) {
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
      builder: widget.builder,
      onTap: _onClusterTap(cluster),
      size: widget.clusterWidgetSize,
    );
  }

  Widget _buildMarkerLayer(
    FlutterMapState mapState,
    LayerPoint<Marker> mapPoint,
  ) {
    final marker = mapPoint.originalPoint;

    var markerBuilder = marker.builder;
    final popupOptions = widget.popupOptions;
    if (popupOptions?.selectedMarkerBuilder != null &&
        _popupState!.selectedMarkers.contains(marker)) {
      markerBuilder = ((context) =>
          widget.popupOptions!.selectedMarkerBuilder!(context, marker));
    }

    return MarkerWidget(
      mapCalculator: _mapCalculator,
      marker: marker,
      markerBuilder: markerBuilder,
      onTap: _onMarkerTap(mapPoint),
      size: Size(marker.width, marker.height),
      rotate: marker.rotate != true && widget.rotate != true
          ? null
          : Rotate(
              angle: -mapState.rotationRad,
              origin: marker.rotateOrigin ?? widget.rotateOrigin,
              alignment: marker.rotateAlignment ?? widget.rotateAlignment,
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
      if (widget.popupOptions != null) {
        assert(_popupState != null);

        final popupOptions = widget.popupOptions!;
        popupOptions.markerTapBehavior.apply(
          mapPoint.originalPoint,
          _popupState!,
          popupOptions.popupController,
        );
        _hidePopupIfZoomLessThan = mapPoint.lowestZoom;

        if (popupOptions.selectedMarkerBuilder != null) setState(() {});
      }

      widget.onMarkerTap?.call(mapPoint.originalPoint);
    };
  }

  void _onMove(FlutterMapState mapState) {
    if (_hidePopupIfZoomLessThan != null &&
        mapState.zoom < _hidePopupIfZoomLessThan!) {
      widget.popupOptions?.popupController.hideAllPopups();
      _hidePopupIfZoomLessThan = null;
    }
  }
}
