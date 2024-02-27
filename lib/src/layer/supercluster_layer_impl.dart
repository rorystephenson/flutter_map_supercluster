import 'dart:async';
import 'dart:math';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:flutter_map_supercluster/src/controller/supercluster_controller_impl.dart';
import 'package:flutter_map_supercluster/src/controller/supercluster_event.dart';
import 'package:flutter_map_supercluster/src/layer/create_supercluster.dart';
import 'package:flutter_map_supercluster/src/layer/expanded_cluster_manager.dart';
import 'package:flutter_map_supercluster/src/layer/loading_overlay.dart';
import 'package:flutter_map_supercluster/src/layer/map_camera_extension.dart';
import 'package:flutter_map_supercluster/src/layer/supercluster_config.dart';
import 'package:flutter_map_supercluster/src/layer/supercluster_parameters.dart';
import 'package:flutter_map_supercluster/src/layer_element_extension.dart';
import 'package:flutter_map_supercluster/src/options/popup_options_impl.dart';
import 'package:flutter_map_supercluster/src/splay/popup_spec_builder.dart';
import 'package:flutter_map_supercluster/src/state/inherited_supercluster_scope.dart';
import 'package:flutter_map_supercluster/src/supercluster_extension.dart';
import 'package:flutter_map_supercluster/src/widget/cluster_widget.dart';
import 'package:flutter_map_supercluster/src/widget/expandable_cluster_widget.dart';
import 'package:flutter_map_supercluster/src/widget/expanded_cluster.dart';
import 'package:flutter_map_supercluster/src/widget/marker_widget.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class SuperclusterLayerImpl extends StatefulWidget {
  final bool isMutableSupercluster;
  final MapCamera mapCamera;
  final MapController mapController;
  final ClusterWidgetBuilder builder;
  final SuperclusterControllerImpl? controller;
  final List<Marker> initialMarkers;
  final IndexBuilder indexBuilder;
  final int? maxClusterZoom;
  final int? minimumClusterSize;
  final int maxClusterRadius;
  final ClusterDataBase Function(Marker marker)? clusterDataExtractor;
  final MoveMapCallback? moveMap;
  final void Function(Marker)? onMarkerTap;
  final WidgetBuilder? loadingOverlayBuilder;
  final PopupOptionsImpl? popupOptions;
  final Size clusterWidgetSize;
  final Alignment clusterAlignment;
  final bool calculateAggregatedClusterData;
  final ClusterSplayDelegate clusterSplayDelegate;

  const SuperclusterLayerImpl({
    super.key,
    required this.isMutableSupercluster,
    required this.mapCamera,
    required this.mapController,
    required this.controller,
    required this.builder,
    required this.indexBuilder,
    required this.initialMarkers,
    required this.moveMap,
    required this.onMarkerTap,
    required this.maxClusterZoom,
    required this.minimumClusterSize,
    required this.maxClusterRadius,
    required this.clusterDataExtractor,
    required this.calculateAggregatedClusterData,
    required this.clusterWidgetSize,
    required this.loadingOverlayBuilder,
    required this.popupOptions,
    required this.clusterAlignment,
    required this.clusterSplayDelegate,
  });

  @override
  State<SuperclusterLayerImpl> createState() => _SuperclusterLayerImplState();
}

class _SuperclusterLayerImplState extends State<SuperclusterLayerImpl>
    with TickerProviderStateMixin {
  late SuperclusterConfigImpl _superclusterConfig;

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

    _lastMovementZoom = widget.mapCamera.zoom.ceil();
    _controllerSubscription = widget.controller?.stream
        .listen((superclusterEvent) => _onSuperclusterEvent(superclusterEvent));

    _movementStreamSubscription =
        widget.mapController.mapEventStream.listen((_) => _onMove());

    _superclusterConfig = SuperclusterConfigImpl(
      isMutableSupercluster: widget.isMutableSupercluster,
      mapCamera: widget.mapCamera,
      maxClusterZoom: widget.maxClusterZoom,
      maxClusterRadius: widget.maxClusterRadius,
      innerClusterDataExtractor: widget.clusterDataExtractor,
      minimumClusterSize: widget.minimumClusterSize,
    );

    _expandedClusterManager = ExpandedClusterManager(
      onRemoveStart: (expandedClusters) {
        // The flutter_map_marker_popup package takes care of hiding popups
        // when zooming out but when an ExpandedCluster removal is triggered by
        // SuperclusterController.collapseSplayedClusters we need to remove the
        // popups ourselves.

        widget.popupOptions?.popupController.hidePopupsOnlyFor(
          expandedClusters
              .expand((expandedCluster) => expandedCluster.markers)
              .toList(),
        );
      },
      onRemoved: (expandedClusters) => setState(() {}),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSupercluster(Future.value(widget.initialMarkers));
    });
  }

  @override
  void didUpdateWidget(SuperclusterLayerImpl oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldSuperclusterConfig = _superclusterConfig;
    _superclusterConfig = SuperclusterConfigImpl(
      isMutableSupercluster: widget.isMutableSupercluster,
      mapCamera: widget.mapCamera,
      maxClusterZoom: widget.maxClusterZoom,
      maxClusterRadius: widget.maxClusterRadius,
      innerClusterDataExtractor: widget.clusterDataExtractor,
      minimumClusterSize: widget.minimumClusterSize,
    );

    // Change the controller if necessary.
    if (oldSuperclusterConfig.isMutableSupercluster !=
            _superclusterConfig.isMutableSupercluster ||
        oldWidget.controller != widget.controller) {
      _controllerSubscription?.cancel();
      _controllerSubscription = widget.controller?.stream
          .listen((event) => _onSuperclusterEvent(event));
    }

    if (oldSuperclusterConfig.mapStateZoomLimitsHaveChanged(widget.mapCamera)) {
      debugPrint(
          'WARNING: Changes to the FlutterMapState have caused a rebuild of '
          'the Supercluster clusters. This can be a slow operation and '
          'should be avoided whenever possible.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeSupercluster(_superclusterCompleter.operation
            .valueOrCancellation()
            .then((supercluster) => supercluster?.getLeaves().toList() ?? []));
      });
    } else if (oldSuperclusterConfig != _superclusterConfig) {
      debugPrint(
          'WARNING: Changes to the Supercluster options have caused a rebuild '
          'of the Supercluster clusters. This can be a slow operation and '
          'should be avoided whenever possible.');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeSupercluster(_superclusterCompleter.operation
            .valueOrCancellation()
            .then((supercluster) => supercluster?.getLeaves().toList() ?? []));
      });
    }

    if (widget.popupOptions != oldWidget.popupOptions) {
      oldWidget.popupOptions?.popupController.dispose();
    }
  }

  @override
  void dispose() {
    widget.popupOptions?.popupController.dispose();
    _movementStreamSubscription?.cancel();
    _controllerSubscription?.cancel();
    super.dispose();
  }

  void _initializeSupercluster(Future<List<Marker>> markersFuture) {
    InheritedSuperclusterScope.of(context, listen: false).setSuperclusterState(
      const SuperclusterStateImpl(
        supercluster: null,
        aggregatedClusterData: null,
      ),
    );
    markersFuture.catchError((_) => <Marker>[]).then((markers) {
      if (_superclusterCompleter.isCompleted ||
          _superclusterCompleter.isCanceled) {
        setState(() {
          _superclusterCompleter = CancelableCompleter();
        });
      }

      final newSupercluster = widget.indexBuilder.call(
        createSupercluster,
        SuperclusterParameters(config: _superclusterConfig, markers: markers),
      );

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
  }

  @override
  Widget build(BuildContext context) {
    return _wrapWithPopupStateIfPopupsEnabled(
      (popupState) => Stack(
        children: [
          MobileLayerTransformer(child: _clustersAndMarkers()),
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

  Widget _clustersAndMarkers() {
    final paddedBounds =
        widget.mapCamera.paddedMapBounds(widget.clusterWidgetSize);

    return FutureBuilder<Supercluster<Marker>>(
      future: _superclusterCompleter.operation.value,
      builder: (context, snapshot) {
        final supercluster = snapshot.data;
        if (supercluster == null) return const SizedBox.shrink();

        return Stack(children: [
          ..._buildClustersAndMarkers(supercluster, paddedBounds)
        ]);
      },
    );
  }

  Iterable<Widget> _buildClustersAndMarkers(
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
      widget.mapCamera.zoom.ceil(),
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
      yield _buildMarker(layerElement);
    }

    // Build selected markers.
    for (final selectedLayerPoint in selectedLayerPoints) {
      yield _buildMarker(selectedLayerPoint, selected: true);
    }

    // Build non expanded clusters.
    for (final cluster in clusters) {
      if (_expandedClusterManager.contains(cluster)) continue;
      yield _buildCluster(supercluster, cluster);
    }

    // Build expanded clusters.
    for (final expandedCluster in _expandedClusterManager.all) {
      yield _buildExpandedCluster(expandedCluster);
    }
  }

  Widget _buildMarker(
    LayerPoint<Marker> mapPoint, {
    bool selected = false,
  }) {
    final marker = mapPoint.originalPoint;

    final markerChild = !selected
        ? marker.child
        : widget.popupOptions!.selectedMarkerBuilder!(context, marker);

    return MarkerWidget(
      mapCamera: widget.mapCamera,
      marker: marker,
      markerChild: markerChild,
      onTap: () => _onMarkerTap(PopupSpecBuilder.forLayerPoint(mapPoint)),
    );
  }

  Widget _buildCluster(
    Supercluster<Marker> supercluster,
    LayerCluster<Marker> cluster,
  ) {
    return ClusterWidget(
      mapCamera: widget.mapCamera,
      cluster: cluster,
      builder: widget.builder,
      onTap: () => _onClusterTap(supercluster, cluster),
      size: widget.clusterWidgetSize,
      alignment: widget.clusterAlignment,
    );
  }

  Widget _buildExpandedCluster(
    ExpandedCluster expandedCluster,
  ) {
    final selectedMarkerBuilder = widget.popupOptions?.selectedMarkerBuilder;
    final Widget Function(BuildContext context, Marker marker) markerBuilder =
        selectedMarkerBuilder == null
            ? ((context, marker) => marker.child)
            : ((context, marker) =>
                _popupState?.selectedMarkers.contains(marker) == true
                    ? selectedMarkerBuilder(context, marker)
                    : marker.child);

    return ExpandableClusterWidget(
      mapCamera: widget.mapCamera,
      expandedCluster: expandedCluster,
      builder: widget.builder,
      size: widget.clusterWidgetSize,
      clusterAlignment: widget.clusterAlignment,
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
    if (layerCluster.highestZoom >= _superclusterConfig.maxZoom) {
      await _moveMapIfNotAt(
        layerCluster.latLng,
        layerCluster.highestZoom.toDouble(),
      );

      final splayAnimation = _expandedClusterManager.putIfAbsent(
        layerCluster,
        () => ExpandedCluster(
          vsync: this,
          mapCamera: widget.mapCamera,
          layerPoints:
              supercluster.childrenOf(layerCluster).cast<LayerPoint<Marker>>(),
          layerCluster: layerCluster,
          clusterSplayDelegate: widget.clusterSplayDelegate,
        ),
      );
      if (splayAnimation != null) setState(() {});
    } else {
      await _moveMapIfNotAt(
        layerCluster.latLng,
        layerCluster.highestZoom + 0.5,
      );
    }
  }

  FutureOr<void> _moveMapIfNotAt(
    LatLng center,
    double zoom, {
    FutureOr<void> Function(LatLng center, double zoom)? moveMapOverride,
  }) {
    if (center == widget.mapCamera.center && zoom == widget.mapCamera.zoom) {
      return Future.value();
    }

    final moveMap = moveMapOverride ??
        widget.moveMap ??
        (center, zoom) => widget.mapController.move(center, zoom);

    return moveMap.call(center, zoom);
  }

  void _onMarkerTap(PopupSpec popupSpec) {
    _selectMarker(popupSpec);
    widget.onMarkerTap?.call(popupSpec.marker);
  }

  void _selectMarker(PopupSpec popupSpec) {
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
  }

  void _onMove() {
    final zoom = widget.mapCamera.zoom.ceil();

    if (_lastMovementZoom == null || zoom < _lastMovementZoom!) {
      _expandedClusterManager.removeIfZoomGreaterThan(zoom);
    }

    _lastMovementZoom = zoom;
  }

  void _onMarkersChange() {
    _superclusterCompleter.operation.value.then((supercluster) {
      final aggregatedClusterData = widget.calculateAggregatedClusterData
          ? supercluster.aggregatedClusterData()
          : null;
      final clusterData = aggregatedClusterData == null
          ? null
          : (aggregatedClusterData as ClusterData);
      final superclusterState = SuperclusterStateImpl(
        aggregatedClusterData: clusterData,
        supercluster: supercluster,
      );
      InheritedSuperclusterScope.of(context, listen: false)
          .setSuperclusterState(superclusterState);
    });
  }

  void _moveToMarker({
    required MarkerMatcher markerMatcher,
    required bool showPopup,
    required FutureOr<void> Function(LatLng center, double zoom)? moveMap,
  }) async {
    // Create a shorthand for the map movement function.
    move(center, zoom) =>
        _moveMapIfNotAt(center, zoom, moveMapOverride: moveMap);

    /// Find the Marker's LayerPoint.
    final supercluster = await _superclusterCompleter.operation.value;
    LayerPoint<Marker>? foundLayerPoint =
        supercluster.layerPointMatching(markerMatcher);
    if (foundLayerPoint == null) return;

    final markerInSplayCluster =
        _superclusterConfig.maxZoom < foundLayerPoint.lowestZoom;
    if (markerInSplayCluster) {
      await _moveToSplayClusterMarker(
        supercluster: supercluster,
        layerPoint: foundLayerPoint,
        move: move,
        showPopup: showPopup,
      );
    } else {
      await move(
        foundLayerPoint.latLng,
        max(foundLayerPoint.lowestZoom.toDouble(), widget.mapCamera.zoom),
      );
      if (showPopup) {
        _selectMarker(PopupSpecBuilder.forLayerPoint(foundLayerPoint));
      }
    }
  }

  /// Move to Marker inside splay cluster. There are three possibilities:
  ///  1. There is already an ExpandedCluster containing the Marker and it
  ///     remains expanded during movement.
  ///  2. There is already an ExpandedCluster and it closes during movement so
  ///     we must create a new one once movement finishes.
  ///  3. There is NOT already an ExpandedCluster, we should create one and add
  ///     it once movement finishes.
  Future<void> _moveToSplayClusterMarker({
    required Supercluster<Marker> supercluster,
    required LayerPoint<Marker> layerPoint,
    required FutureOr<void> Function(LatLng center, double zoom) move,
    required bool showPopup,
  }) async {
    // Find the parent.
    final layerCluster = supercluster.parentOf(layerPoint)!;

    // Shorthand for creating an ExpandedCluster.
    createExpandedCluster() => ExpandedCluster(
          vsync: this,
          mapCamera: widget.mapCamera,
          layerPoints:
              supercluster.childrenOf(layerCluster).cast<LayerPoint<Marker>>(),
          layerCluster: layerCluster,
          clusterSplayDelegate: widget.clusterSplayDelegate,
        );

    // Find or create the marker's ExpandedCluster and use it to find the
    // DisplacedMarker.
    final expandedClusterBeforeMovement =
        _expandedClusterManager.forLayerCluster(layerCluster);
    final createdExpandedCluster =
        expandedClusterBeforeMovement != null ? null : createExpandedCluster();
    final displacedMarker =
        (expandedClusterBeforeMovement ?? createdExpandedCluster)!
            .markersToDisplacedMarkers[layerPoint.originalPoint]!;

    // Move to the DisplacedMarker.
    await move(
      displacedMarker.displacedPoint,
      max(widget.mapCamera.zoom, layerPoint.lowestZoom - 0.99999),
    );

    // Determine the ExpandedCluster after movement, either:
    //   1. We created one (without adding it to ExpandedClusterManager)
    //      because there was none before movement.
    //   2. Movement may have caused the ExpandedCluster to be removed in which
    //      case we create a new one.
    final splayAnimation = _expandedClusterManager.putIfAbsent(
      layerCluster,
      () => createdExpandedCluster ?? createExpandedCluster(),
    );
    if (splayAnimation != null) {
      if (!mounted) return;
      setState(() {});
      await splayAnimation;
    }

    if (showPopup) {
      final popupSpec = PopupSpecBuilder.forDisplacedMarker(
        displacedMarker,
        layerCluster.highestZoom,
      );
      _selectMarker(popupSpec);
    }
  }

  void _onSuperclusterEvent(SuperclusterEvent event) async {
    switch (event) {
      case AddMarkerEvent():
        _superclusterCompleter.operation.then((supercluster) {
          (supercluster as SuperclusterMutable<Marker>).add(event.marker);
          _removeExpandedClustersOfRemovedClusters(supercluster);
          _onMarkersChange();
        });
      case AddAllMarkerEvent():
        _superclusterCompleter.operation.then((supercluster) {
          (supercluster as SuperclusterMutable<Marker>).addAll(event.markers);
          _removeExpandedClustersOfRemovedClusters(supercluster);
          _onMarkersChange();
        });
      case RemoveMarkerEvent():
        _superclusterCompleter.operation.then((supercluster) {
          final removed = (supercluster as SuperclusterMutable<Marker>)
              .remove(event.marker);

          if (removed) {
            _removeExpandedClustersOfRemovedClusters(supercluster);
            _hidePopupsInNamespaceFor([event.marker]);
            _onMarkersChange();
          }
        });
      case RemoveAllMarkerEvent():
        _superclusterCompleter.operation.then((supercluster) {
          final removed = (supercluster as SuperclusterMutable<Marker>)
              .removeAll(event.markers);
          if (removed) {
            _removeExpandedClustersOfRemovedClusters(supercluster);
            _hidePopupsInNamespaceFor(event.markers);
            _onMarkersChange();
          }
        });
      case ReplaceAllMarkerEvent():
        _initializeSupercluster(Future.value(event.markers));
        _expandedClusterManager.clear();
      case ModifyMarkerEvent():
        _superclusterCompleter.operation.then((supercluster) {
          final modified =
              (supercluster as SuperclusterMutable<Marker>).modifyPointData(
            event.oldMarker,
            event.newMarker,
            updateParentClusters: event.updateParentClusters,
          );

          if (modified) {
            _modifyDisplacedMarker(event.oldMarker, event.newMarker);
            _removeExpandedClustersOfRemovedClusters(supercluster);
            _hidePopupsInNamespaceFor([event.oldMarker]);
            _onMarkersChange();
          }
        });
      case CollapseSplayedClustersEvent():
        _expandedClusterManager.collapseThenRemoveAll();
      case ShowPopupsAlsoForEvent():
        if (widget.popupOptions == null) return;
        widget.popupOptions?.popupController.showPopupsAlsoForSpecs(
          PopupSpecBuilder.buildList(
            supercluster: await _superclusterCompleter.operation.value,
            zoom: widget.mapCamera.zoom.ceil(),
            maxZoom: _superclusterConfig.maxZoom,
            markers: event.markers,
            expandedClusters: _expandedClusterManager.all,
          ),
          disableAnimation: event.disableAnimation,
        );
      case MoveToMarkerEvent():
        _moveToMarker(
          markerMatcher: event.markerMatcher,
          showPopup: event.showPopup,
          moveMap: event.moveMap,
        );
      case ShowPopupsOnlyForEvent():
        if (widget.popupOptions == null) return;
        widget.popupOptions?.popupController.showPopupsOnlyForSpecs(
          PopupSpecBuilder.buildList(
            supercluster: await _superclusterCompleter.operation.value,
            zoom: widget.mapCamera.zoom.ceil(),
            maxZoom: _superclusterConfig.maxZoom,
            markers: event.markers,
            expandedClusters: _expandedClusterManager.all,
          ),
          disableAnimation: event.disableAnimation,
        );
      case HideAllPopupsEvent():
        if (widget.popupOptions == null) return;
        widget.popupOptions?.popupController.hideAllPopups(
          disableAnimation: event.disableAnimation,
        );
      case HidePopupsWhereEvent():
        if (widget.popupOptions == null) return;
        widget.popupOptions?.popupController.hidePopupsWhere(
          event.test,
          disableAnimation: event.disableAnimation,
        );
      case HidePopupsOnlyForEvent():
        if (widget.popupOptions == null) return;
        widget.popupOptions?.popupController.hidePopupsOnlyFor(
          event.markers,
          disableAnimation: event.disableAnimation,
        );
      case TogglePopupEvent():
        if (widget.popupOptions == null) return;
        final popupSpec = PopupSpecBuilder.build(
          supercluster: await _superclusterCompleter.operation.value,
          zoom: widget.mapCamera.zoom.ceil(),
          maxZoom: _superclusterConfig.maxZoom,
          marker: event.marker,
          expandedClusters: _expandedClusterManager.all,
        );
        if (popupSpec == null) return;
        widget.popupOptions?.popupController.togglePopupSpec(
          popupSpec,
          disableAnimation: event.disableAnimation,
        );
    }

    setState(() {});
  }

  void _removeExpandedClustersOfRemovedClusters(
      SuperclusterMutable<Marker> supercluster) {
    final toRemove = _expandedClusterManager.all
        .where((e) => !supercluster.containsElement(e.layerCluster));
    if (toRemove.isNotEmpty) {
      _expandedClusterManager.removeAllImmediately(toRemove);
    }
  }

  void _hidePopupsInNamespaceFor(Iterable<Marker> markers) {
    widget.popupOptions?.popupController.hidePopupsWhereSpec((spec) =>
        spec.namespace == SuperclusterLayer.popupNamespace &&
        markers.contains(spec.marker));
  }

  void _modifyDisplacedMarker(Marker oldMarker, Marker newMarker) async {
    final supercluster = await _superclusterCompleter.operation.value;
    LayerPoint<Marker>? foundLayerPoint =
        supercluster.layerPointMatching(MarkerMatcher.equalsMarker(oldMarker));
    if (foundLayerPoint == null) return;

    // Is the marker part of a splay cluster?
    if (_superclusterConfig.maxZoom < foundLayerPoint.lowestZoom) {
      // Find the parent.
      final layerCluster = supercluster.parentOf(foundLayerPoint)!;

      // Find the marker's ExpandedCluster
      // and use it to find the DisplacedMarker.
      final expandedClusterBeforeMovement =
          _expandedClusterManager.forLayerCluster(layerCluster);

      if (expandedClusterBeforeMovement != null) {
        List<DisplacedMarker> displacedMarkers =
            expandedClusterBeforeMovement.displacedMarkers;
        for (var i = 0; i < displacedMarkers.length; i++) {
          if (displacedMarkers[i].marker == oldMarker) {
            // exchange the DisplacedMarker
            // and make the new marker visible in the map
            _expandedClusterManager
                    .forLayerCluster(layerCluster)!
                    .displacedMarkers[i] =
                DisplacedMarker(
                    marker: newMarker,
                    displacedPoint: displacedMarkers[i].displacedPoint);
          }
        }
      }
    }
  }
}
