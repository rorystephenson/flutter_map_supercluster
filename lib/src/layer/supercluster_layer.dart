import 'dart:async';
import 'dart:math';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:flutter_map_supercluster/src/controller/supercluster_event.dart';
import 'package:flutter_map_supercluster/src/controller/supercluster_state.dart';
import 'package:flutter_map_supercluster/src/layer/create_supercluster.dart';
import 'package:flutter_map_supercluster/src/layer/expanded_cluster_manager.dart';
import 'package:flutter_map_supercluster/src/layer/flutter_map_state_extension.dart';
import 'package:flutter_map_supercluster/src/layer/loading_overlay.dart';
import 'package:flutter_map_supercluster/src/layer/supercluster_config.dart';
import 'package:flutter_map_supercluster/src/layer_element_extension.dart';
import 'package:flutter_map_supercluster/src/options/index_builder.dart';
import 'package:flutter_map_supercluster/src/options/popup_options_impl.dart';
import 'package:flutter_map_supercluster/src/splay/cluster_splay_delegate.dart';
import 'package:flutter_map_supercluster/src/splay/popup_spec_builder.dart';
import 'package:flutter_map_supercluster/src/splay/spread_cluster_splay_delegate.dart';
import 'package:flutter_map_supercluster/src/widget/expandable_cluster_widget.dart';
import 'package:flutter_map_supercluster/src/widget/expanded_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supercluster/supercluster.dart';

import '../controller/supercluster_controller.dart';
import '../controller/supercluster_controller_impl.dart';
import '../options/popup_options.dart';
import '../widget/cluster_widget.dart';
import '../widget/marker_widget.dart';
import 'cluster_data.dart';

/// Builder for the cluster widget.
typedef ClusterWidgetBuilder = Widget Function(
  BuildContext context,
  LatLng position,
  int markerCount,
  ClusterDataBase? extraClusterData,
);

/// See [SuperclusterLayer.onClusterTap].
typedef ClusterTapCallback = FutureOr<void> Function(
  LatLng center,
  double expansionZoom,
  bool splayCluster,
);

class SuperclusterLayer extends StatefulWidget {
  static const popupNamespace = 'flutter_map_supercluster';

  final bool _isMutableSupercluster;

  /// Cluster builder
  final ClusterWidgetBuilder builder;

  /// Controller for managing [Marker]s and listening to changes.
  final SuperclusterController? controller;

  /// Initial list of markers, additions/removals must be made using the
  /// [controller].
  final List<Marker> initialMarkers;

  /// Builder used to create the supercluster index. See [IndexBuilders] for
  /// predefined builders and guidelines on which one to use.
  final IndexBuilder indexBuilder;

  /// The minimum number of points required to form a cluster, if there is less
  /// than this number of points within the [maxClusterRadius] the markers will
  /// be left unclustered.
  final int? minimumClusterSize;

  /// The maximum radius in pixels that a cluster can cover.
  final int maxClusterRadius;

  /// The maximum zoom at which clusters will be formed. Defaults to the
  /// FlutterMapState maxZoom or, if none is set, 20.
  final int? maxClusterZoom;

  /// Implement this function to extract extra data from Markers which can be
  /// used in the [builder].
  ///
  /// Note that if index creation happens in an isolate, code which does not
  /// work on a separate isolate (e.g. riverpod) will fail. In this case either
  /// refactor your clusterDataExtractor to stop using code which does not work
  /// in a separate isolate or see [wrapIndexCreation] for how to prevent index
  /// creation from occuring in a separate isolate.
  final ClusterDataBase Function(Marker marker)? clusterDataExtractor;

  /// When a cluster is tapped this callback fires to pan/zoom the map and then
  /// then, if the cluster is a splay cluster (see [clusterSplayDelegate]),
  /// splaying occurs. This callback is not called when collapsing a splay
  /// cluster.
  ///
  /// The default behaviour is to center the map on the cluster and zoom to the
  /// minimum zoom required to open the cluster. This callback can be overriden
  /// in order to animate movement. Note that if a Future is returned splaying
  /// will not occur until the future completes.
  final ClusterTapCallback? onClusterTap;

  /// Function to call when a Marker is tapped
  final void Function(Marker)? onMarkerTap;

  /// A builder used to override the override which is displayed whilst the
  /// supercluster index is being built.
  final WidgetBuilder? loadingOverlayBuilder;

  /// If provided popups will be enabled for markers. Depending on the provided
  /// options they will appear when markers are tapped or when triggered by a
  /// provided PopupController.
  final PopupOptionsImpl? popupOptions;

  /// Cluster size
  final Size clusterWidgetSize;

  /// Cluster anchor
  final AnchorPos? anchor;

  /// If true then whenever the aggregated cluster data changes (that is, the
  /// combined cluster data of all Markers as calculated by
  /// [clusterDataExtractor]) then the new value will be added to the
  /// [controller]'s [aggregatedClusterDataStream].
  final bool calculateAggregatedClusterData;

  /// Splaying occurs when it is not possible to open a cluster because its
  /// points are visible at a zoom higher than the max zoom. This delegate
  /// controls the animation and style of the cluster splaying.
  final ClusterSplayDelegate clusterSplayDelegate;

  const SuperclusterLayer.immutable({
    Key? key,
    SuperclusterImmutableController? this.controller,
    required this.builder,
    required this.indexBuilder,
    this.initialMarkers = const [],
    this.onClusterTap,
    this.onMarkerTap,
    this.minimumClusterSize,
    this.maxClusterRadius = 80,
    this.maxClusterZoom,
    this.clusterDataExtractor,
    this.calculateAggregatedClusterData = false,
    this.clusterWidgetSize = const Size(30, 30),
    this.loadingOverlayBuilder,
    PopupOptions? popupOptions,
    this.anchor,
    this.clusterSplayDelegate = const SpreadClusterSplayDelegate(
      duration: Duration(milliseconds: 300),
      splayLineOptions: SplayLineOptions(),
    ),
  })  : _isMutableSupercluster = false,
        popupOptions =
            popupOptions == null ? null : popupOptions as PopupOptionsImpl,
        super(key: key);

  const SuperclusterLayer.mutable({
    Key? key,
    SuperclusterMutableController? this.controller,
    required this.builder,
    required this.indexBuilder,
    this.initialMarkers = const [],
    this.onClusterTap,
    this.onMarkerTap,
    this.minimumClusterSize,
    this.maxClusterRadius = 80,
    this.maxClusterZoom,
    this.clusterDataExtractor,
    this.calculateAggregatedClusterData = false,
    this.clusterWidgetSize = const Size(30, 30),
    this.loadingOverlayBuilder,
    PopupOptions? popupOptions,
    this.anchor,
    this.clusterSplayDelegate = const SpreadClusterSplayDelegate(
      duration: Duration(milliseconds: 400),
    ),
  })  : _isMutableSupercluster = true,
        popupOptions =
            popupOptions == null ? null : popupOptions as PopupOptionsImpl,
        super(key: key);

  @override
  State<SuperclusterLayer> createState() => _SuperclusterLayerState();
}

class _SuperclusterLayerState extends State<SuperclusterLayer>
    with TickerProviderStateMixin {
  static const defaultMinZoom = 1;
  static const defaultMaxZoom = 20;

  bool _initialized = false;

  late int minZoom;
  late int maxZoom;

  late FlutterMapState _mapState;
  late final ExpandedClusterManager _expandedClusterManager;

  StreamSubscription<SuperclusterEvent>? _controllerSubscription;
  StreamSubscription<void>? _movementStreamSubscription;

  int? _lastMovementZoom;

  PopupState? _popupState;

  CancelableCompleter<Supercluster<Marker>> _superclusterCompleter =
      CancelableCompleter();

  @override
  void initState() {
    super.initState();
    _expandedClusterManager = ExpandedClusterManager(
      onRemoveStart: (expandedClusters) {
        widget.popupOptions?.popupController.hidePopupsOnlyFor(
          expandedClusters
              .expand((expandedCluster) => expandedCluster.markers)
              .toList(),
        );
      },
      onRemoved: (expandedClusters) => setState(() {}),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _mapState = FlutterMapState.maybeOf(context)!;

    final oldMinZoom = !_initialized ? null : minZoom;
    final oldMaxZoom = !_initialized ? null : maxZoom;
    minZoom = _mapState.options.minZoom?.ceil() ?? defaultMinZoom;
    maxZoom = widget.maxClusterZoom ??
        _mapState.options.maxZoom?.ceil() ??
        defaultMaxZoom;

    bool zoomsChanged =
        _initialized && oldMinZoom != minZoom || oldMaxZoom != maxZoom;

    if (!_initialized) {
      _lastMovementZoom = _mapState.zoom.ceil();
      _controllerSubscription = widget.controller == null
          ? null
          : (widget.controller! as SuperclusterControllerImpl).stream.listen(
              (superclusterEvent) => _onSuperclusterEvent(superclusterEvent));

      _movementStreamSubscription = _mapState.mapController.mapEventStream
          .listen((_) => _onMove(_mapState));
    }

    if (!_initialized || zoomsChanged) {
      if (_initialized) {
        debugPrint(
            'WARNING: Changes to the FlutterMapState have caused a rebuild of '
            'the Supercluster clusters. This can be a slow operation and '
            'should be avoided whenever possible.');
      }
      _initializeClusterManager(
        !_initialized
            ? Future.value(widget.initialMarkers)
            : _superclusterCompleter.operation.value
                .then((supercluster) => supercluster.getLeaves().toList()),
      );
    }
    _initialized = true;
  }

  @override
  void didUpdateWidget(SuperclusterLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget._isMutableSupercluster != widget._isMutableSupercluster ||
        oldWidget.controller != widget.controller) {
      _onControllerChange(
        oldWidget.controller as SuperclusterControllerImpl?,
        widget.controller as SuperclusterControllerImpl?,
      );
    }

    if (oldWidget._isMutableSupercluster != widget._isMutableSupercluster ||
        oldWidget.maxClusterRadius != widget.maxClusterRadius ||
        oldWidget.minimumClusterSize != widget.minimumClusterSize ||
        oldWidget.maxClusterZoom != widget.maxClusterZoom ||
        oldWidget.calculateAggregatedClusterData !=
            widget.calculateAggregatedClusterData) {
      debugPrint(
          'WARNING: Changes to the Supercluster options have caused a rebuild '
          'of the Supercluster clusters. This can be a slow operation and '
          'should be avoided whenever possible.');
      _initializeClusterManager(_superclusterCompleter.operation
          .valueOrCancellation()
          .then((supercluster) => supercluster?.getLeaves().toList() ?? []));
    }

    if (widget.popupOptions != oldWidget.popupOptions) {
      oldWidget.popupOptions?.popupController.dispose();
      _movementStreamSubscription?.cancel();
      _movementStreamSubscription = _mapState.mapController.mapEventStream
          .listen((_) => _onMove(_mapState));
    }
  }

  @override
  void dispose() {
    widget.popupOptions?.popupController.dispose();
    _movementStreamSubscription?.cancel();
    _controllerSubscription?.cancel();
    super.dispose();
  }

  void _initializeClusterManager(Future<List<Marker>> markersFuture) {
    (widget.controller as SuperclusterControllerImpl).updateState(
        const SuperclusterState(loading: true, aggregatedClusterData: null));

    final supercluster =
        markersFuture.catchError((_) => <Marker>[]).then((markers) {
      final superclusterConfig = SuperclusterConfig(
        isMutableSupercluster: widget._isMutableSupercluster,
        markers: markers,
        minZoom: minZoom,
        maxZoom: maxZoom,
        maxClusterRadius: widget.maxClusterRadius,
        minimumClusterSize: widget.minimumClusterSize,
        innerClusterDataExtractor: widget.clusterDataExtractor,
      );

      if (_superclusterCompleter.isCompleted ||
          _superclusterCompleter.isCanceled) {
        setState(() {
          _superclusterCompleter = CancelableCompleter();
        });
      }

      final newSupercluster =
          widget.indexBuilder.call(createSupercluster, superclusterConfig);

      _superclusterCompleter.complete(newSupercluster);
      _superclusterCompleter.operation.value.then((supercluster) {
        _onMarkersChange();
        _expandedClusterManager.clear();
        widget.popupOptions?.popupController.hidePopupsWhereSpec(
          (popupSpec) =>
              popupSpec.namespace == SuperclusterLayer.popupNamespace,
        );
      });

      return newSupercluster;
    });

    if (widget.controller != null) {
      (widget.controller as SuperclusterControllerImpl)
          .setSupercluster(supercluster);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = FlutterMapState.maybeOf(context)!;

    return _wrapWithPopupStateIfPopupsEnabled(
      (popupState) => Stack(
        children: [
          _clustersAndMarkers(mapState),
          if (widget.popupOptions?.popupDisplayOptions != null)
            PopupLayer(
              popupDisplayOptions: widget.popupOptions!.popupDisplayOptions!,
            ),
          LoadingOverlay(
            superclusterFuture: _superclusterCompleter.operation.value,
            loadingOverlayBuilder: widget.loadingOverlayBuilder,
          ),
        ],
      ),
    );
  }

  Widget _wrapWithPopupStateIfPopupsEnabled(
      Widget Function(PopupState? popupState) builder) {
    if (widget.popupOptions == null) return builder(null);

    return InheritOrCreatePopupScope(
      popupController: widget.popupOptions!.popupController,
      builder: (context, popupState) {
        _popupState = popupState;
        if (widget.popupOptions!.selectedMarkerBuilder != null) {
          context.watch<PopupState>();
        }
        return builder(popupState);
      },
    );
  }

  Widget _clustersAndMarkers(FlutterMapState mapState) {
    final paddedBounds = mapState.paddedMapBounds(widget.clusterWidgetSize);

    return FutureBuilder<Supercluster<Marker>>(
      future: _superclusterCompleter.operation.value,
      builder: (context, snapshot) {
        final supercluster = snapshot.data;
        if (supercluster == null) return const SizedBox.shrink();

        return Stack(children: [
          ..._buildClustersAndMarkers(mapState, supercluster, paddedBounds)
        ]);
      },
    );
  }

  Iterable<Widget> _buildClustersAndMarkers(
    FlutterMapState mapState,
    Supercluster<Marker> supercluster,
    LatLngBounds paddedBounds,
  ) sync* {
    final selectedMarkerBuilder =
        widget.popupOptions != null && _popupState!.selectedMarkers.isNotEmpty
            ? widget.popupOptions!.selectedMarkerBuilder
            : null;
    final List<LayerPoint<Marker>> selectedLayerPoints = [];
    final List<LayerCluster<Marker>> clusters = [];

    // Build non-selected markers first, queue the rest to build afterwards
    // so they appear above these markers.
    for (final layerElement in supercluster.search(
      paddedBounds.west,
      paddedBounds.south,
      paddedBounds.east,
      paddedBounds.north,
      mapState.zoom.ceil(),
    )) {
      if (layerElement is LayerCluster<Marker>) {
        clusters.add(layerElement);
        continue;
      }
      layerElement as LayerPoint<Marker>;
      if (selectedMarkerBuilder != null &&
          _popupState!.selectedMarkers.contains(layerElement.originalPoint)) {
        selectedLayerPoints.add(layerElement);
        continue;
      }
      yield _buildMarker(mapState, layerElement);
    }

    // Build selected markers.
    for (final selectedLayerPoint in selectedLayerPoints) {
      yield _buildMarker(mapState, selectedLayerPoint, selected: true);
    }

    // Build non expanded clusters.
    for (final cluster in clusters) {
      if (_expandedClusterManager.contains(cluster)) continue;
      yield _buildCluster(mapState, supercluster, cluster);
    }

    // Build expanded clusters.
    for (final expandedCluster in _expandedClusterManager.all) {
      yield _buildExpandedCluster(mapState, expandedCluster);
    }
  }

  Widget _buildMarker(
    FlutterMapState mapState,
    LayerPoint<Marker> mapPoint, {
    bool selected = false,
  }) {
    final marker = mapPoint.originalPoint;

    final markerBuilder = !selected
        ? marker.builder
        : (context) =>
            widget.popupOptions!.selectedMarkerBuilder!(context, marker);

    return MarkerWidget(
      mapState: _mapState,
      marker: marker,
      markerBuilder: markerBuilder,
      onTap: () => _onMarkerTap(PopupSpecBuilder.forLayerPoint(mapPoint)),
    );
  }

  Widget _buildCluster(
    FlutterMapState mapState,
    Supercluster<Marker> supercluster,
    LayerCluster<Marker> cluster,
  ) {
    return ClusterWidget(
      mapState: _mapState,
      cluster: cluster,
      builder: widget.builder,
      onTap: () => _onClusterTap(supercluster, cluster),
      size: widget.clusterWidgetSize,
      anchorPos: widget.anchor,
    );
  }

  Widget _buildExpandedCluster(
    FlutterMapState mapState,
    ExpandedCluster expandedCluster,
  ) {
    final selectedMarkerBuilder = widget.popupOptions?.selectedMarkerBuilder;
    final Widget Function(BuildContext context, Marker marker) markerBuilder =
        selectedMarkerBuilder == null
            ? ((context, marker) => marker.builder(context))
            : ((context, marker) =>
                _popupState?.selectedMarkers.contains(marker) == true
                    ? selectedMarkerBuilder(context, marker)
                    : marker.builder(context));

    return ExpandableClusterWidget(
      mapState: mapState,
      expandedCluster: expandedCluster,
      builder: widget.builder,
      size: widget.clusterWidgetSize,
      anchorPos: widget.anchor,
      markerBuilder: markerBuilder,
      onCollapse: () {
        widget.popupOptions?.popupController
            .hidePopupsOnlyFor(expandedCluster.markers.toList());
        _expandedClusterManager
            .collapseThenRemove(expandedCluster.layerCluster);
      },
      onMarkerTap: _onMarkerTap,
    );
  }

  void _onClusterTap(
    Supercluster<Marker> supercluster,
    LayerCluster<Marker> layerCluster,
  ) async {
    if (layerCluster.highestZoom >= maxZoom) {
      await _clusterTapCallback(
        layerCluster.latLng,
        layerCluster.highestZoom.toDouble(),
        true,
      );

      setState(() {
        _expandedClusterManager.add(
          vsync: this,
          mapState: _mapState,
          supercluster: supercluster,
          layerCluster: layerCluster,
          clusterSplayDelegate: widget.clusterSplayDelegate,
          expansionZoom: min(maxZoom, layerCluster.highestZoom).toDouble(),
        );
      });
    }

    await _clusterTapCallback(
      layerCluster.latLng,
      layerCluster.highestZoom + 0.000001,
      false,
    );
  }

  FutureOr<void> _clusterTapCallback(
      LatLng center, double zoom, bool splayCluster) {
    if (widget.onClusterTap != null) {
      return widget.onClusterTap!(center, zoom, splayCluster);
    }

    _mapState.move(center, zoom, source: MapEventSource.custom);
  }

  void _onMarkerTap(PopupSpec popupSpec) {
    if (widget.popupOptions != null) {
      assert(_popupState != null);

      final popupOptions = widget.popupOptions!;
      popupOptions.markerTapBehavior.apply(
        popupSpec,
        _popupState!,
        popupOptions.popupController,
      );

      if (popupOptions.selectedMarkerBuilder != null) setState(() {});
    }

    widget.onMarkerTap?.call(popupSpec.marker);
  }

  void _onMove(FlutterMapState mapState) {
    final zoom = mapState.zoom.ceil();

    if (_lastMovementZoom == null || zoom < _lastMovementZoom!) {
      _expandedClusterManager.removeIfZoomGreaterThan(zoom);
    }

    _lastMovementZoom = zoom;
  }

  void _onMarkersChange() {
    if (widget.controller == null) return;

    _superclusterCompleter.operation.value.then((supercluster) {
      final aggregatedClusterData = widget.calculateAggregatedClusterData
          ? supercluster.aggregatedClusterData()
          : null;
      final clusterData = aggregatedClusterData == null
          ? null
          : (aggregatedClusterData as ClusterData);
      (widget.controller as SuperclusterControllerImpl).updateState(
        SuperclusterState(
          loading: false,
          aggregatedClusterData: clusterData,
        ),
      );
    });
  }

  void _onControllerChange(
    SuperclusterControllerImpl? oldController,
    SuperclusterControllerImpl? newController,
  ) {
    _controllerSubscription?.cancel();
    _controllerSubscription =
        newController?.stream.listen((event) => _onSuperclusterEvent(event));

    if (oldController != null) {
      oldController.removeSupercluster();
    }
    if (newController != null) {
      newController.setSupercluster(_superclusterCompleter.operation.value);
    }
  }

  void _onSuperclusterEvent(SuperclusterEvent event) async {
    if (event is AddMarkerEvent) {
      _superclusterCompleter.operation.then((supercluster) {
        (supercluster as SuperclusterMutable<Marker>).insert(event.marker);
        _onMarkersChange();
      });
    } else if (event is RemoveMarkerEvent) {
      _superclusterCompleter.operation.then((supercluster) {
        final removed =
            (supercluster as SuperclusterMutable<Marker>).remove(event.marker);
        if (removed) _onMarkersChange();
      });
    } else if (event is ReplaceAllMarkerEvent) {
      _initializeClusterManager(Future.value(event.markers));
    } else if (event is ModifyMarkerEvent) {
      _superclusterCompleter.operation.then((supercluster) {
        final modified =
            (supercluster as SuperclusterMutable<Marker>).modifyPointData(
          event.oldMarker,
          event.newMarker,
          updateParentClusters: event.updateParentClusters,
        );

        if (modified) _onMarkersChange();
      });
    } else if (event is CollapseSplayedClustersEvent) {
      _expandedClusterManager.collapseThenRemoveAll();
    } else if (event is ShowPopupsAlsoForEvent) {
      widget.popupOptions?.popupController.showPopupsAlsoForSpecs(
        PopupSpecBuilder.buildList(
          supercluster: await _superclusterCompleter.operation.value,
          zoom: _mapState.zoom.ceil(),
          maxZoom: maxZoom,
          markers: event.markers,
          expandedClusters: _expandedClusterManager.all,
        ),
        disableAnimation: event.disableAnimation,
      );
    } else if (event is ShowPopupsOnlyForEvent) {
      widget.popupOptions?.popupController.showPopupsOnlyForSpecs(
        PopupSpecBuilder.buildList(
          supercluster: await _superclusterCompleter.operation.value,
          zoom: _mapState.zoom.ceil(),
          maxZoom: maxZoom,
          markers: event.markers,
          expandedClusters: _expandedClusterManager.all,
        ),
        disableAnimation: event.disableAnimation,
      );
    } else if (event is HideAllPopupsEvent) {
      widget.popupOptions?.popupController.hideAllPopups(
        disableAnimation: event.disableAnimation,
      );
    } else if (event is HidePopupsWhereEvent) {
      widget.popupOptions?.popupController.hidePopupsWhere(
        event.test,
        disableAnimation: event.disableAnimation,
      );
    } else if (event is HidePopupsOnlyForEvent) {
      widget.popupOptions?.popupController.hidePopupsOnlyFor(
        event.markers,
        disableAnimation: event.disableAnimation,
      );
    } else if (event is TogglePopupEvent) {
      final popupSpec = PopupSpecBuilder.build(
        supercluster: await _superclusterCompleter.operation.value,
        zoom: _mapState.zoom.ceil(),
        maxZoom: maxZoom,
        marker: event.marker,
        expandedClusters: _expandedClusterManager.all,
      );
      if (popupSpec == null) return;
      widget.popupOptions?.popupController.togglePopupSpec(
        popupSpec,
        disableAnimation: event.disableAnimation,
      );
    } else {
      throw 'Unknown $SuperclusterEvent type ${event.runtimeType}';
    }

    setState(() {});
  }
}
