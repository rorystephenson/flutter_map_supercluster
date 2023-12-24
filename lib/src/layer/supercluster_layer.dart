import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:flutter_map_supercluster/src/controller/supercluster_controller_impl.dart';
import 'package:flutter_map_supercluster/src/layer/supercluster_layer_impl.dart';
import 'package:flutter_map_supercluster/src/options/popup_options_impl.dart';
import 'package:flutter_map_supercluster/src/state/inherit_or_create_supercluster_scope.dart';
import 'package:latlong2/latlong.dart';

/// Builder for the cluster widget.
typedef ClusterWidgetBuilder = Widget Function(
  BuildContext context,
  LatLng position,
  int markerCount,
  ClusterDataBase? extraClusterData,
);

/// See [SuperclusterLayer.moveMap].
typedef MoveMapCallback = FutureOr<void> Function(LatLng center, double zoom);

class SuperclusterLayer extends StatelessWidget {
  static const popupNamespace = 'flutter_map_supercluster';

  final bool isMutableSupercluster;

  /// Cluster builder
  final ClusterWidgetBuilder builder;

  /// Controller for managing [Marker]s and listening to changes.
  final SuperclusterController? controller;

  /// Initial list of markers, additions/removals must be made using the
  /// [controller].
  final List<Marker> initialMarkers;

  /// Builder used to create the supercluster index. See [IndexBuilders] for
  /// predefined builders and guidelines on which one to use.
  ///
  /// Defaults to IndexBuilder.rootIsolate which may be slow for large amounts
  /// of markers.
  final IndexBuilder? indexBuilder;

  /// The maximum zoom at which clusters will be formed, at higher zooms all
  /// points will be visible. Defaults to the FlutterMap maxZoom or, if it is
  /// not set, 20.
  ///
  /// This value must not be higher than the FlutterMap's maxZoom if it is set
  /// as this will break splay cluster functionality and causes unnecesssary
  /// calculations since not all clusters/points will be able to be viewed.
  final int? maxClusterZoom;

  /// The minimum number of points required to form a cluster, if there is less
  /// than this number of points within the [maxClusterRadius] the markers will
  /// be left unclustered.
  final int? minimumClusterSize;

  /// The maximum radius in pixels that a cluster can cover.
  final int maxClusterRadius;

  /// Implement this function to extract extra data from Markers which can be
  /// used in the [builder].
  ///
  /// Note that if index creation happens in an isolate, code which does not
  /// work on a separate isolate (e.g. riverpod) will fail. In this case either
  /// refactor your clusterDataExtractor to stop using code which does not work
  /// in a separate isolate or see [IndexBuilders] for how to prevent index
  /// creation from occuring in a separate isolate.
  final ClusterDataBase Function(Marker marker)? clusterDataExtractor;

  /// When tapping a cluster or moving to a [Marker] with
  /// [SuperclusterController]'s moveToMarker method this callback controls
  /// if/how the movement is performed. The default is to move with no
  /// animation.
  ///
  /// When moving to a splay cluster (see [clusterSplayDelegate]) or a [Marker]
  /// inside a splay cluster the splaying will start once this callback
  /// completes.
  final MoveMapCallback? moveMap;

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

  /// Cluster anchor position.
  final Alignment clusterAlignment;

  /// If true then whenever the aggregated cluster data changes (that is, the
  /// combined cluster data of all Markers as calculated by
  /// [clusterDataExtractor]) dependents of SuperclusterState will be notified
  /// with the updated value.
  final bool calculateAggregatedClusterData;

  /// Splaying occurs when it is not possible to open a cluster because its
  /// points are visible at a zoom higher than the max zoom. This delegate
  /// controls the animation and style of the cluster splaying.
  final ClusterSplayDelegate clusterSplayDelegate;

  const SuperclusterLayer.immutable({
    super.key,
    SuperclusterImmutableController? this.controller,
    required this.builder,
    required this.indexBuilder,
    this.initialMarkers = const [],
    this.moveMap,
    this.onMarkerTap,
    this.maxClusterZoom,
    this.minimumClusterSize,
    this.maxClusterRadius = 80,
    this.clusterDataExtractor,
    this.calculateAggregatedClusterData = false,
    this.clusterWidgetSize = const Size(30, 30),
    this.loadingOverlayBuilder,
    PopupOptions? popupOptions,
    this.clusterAlignment = Alignment.center,
    this.clusterSplayDelegate = const SpreadClusterSplayDelegate(
      duration: Duration(milliseconds: 300),
      splayLineOptions: SplayLineOptions(),
    ),
  })  : isMutableSupercluster = false,
        popupOptions =
            popupOptions == null ? null : popupOptions as PopupOptionsImpl;

  const SuperclusterLayer.mutable({
    super.key,
    SuperclusterMutableController? this.controller,
    required this.builder,
    this.indexBuilder,
    this.initialMarkers = const [],
    this.moveMap,
    this.onMarkerTap,
    this.maxClusterZoom,
    this.minimumClusterSize,
    this.maxClusterRadius = 80,
    this.clusterDataExtractor,
    this.calculateAggregatedClusterData = false,
    this.clusterWidgetSize = const Size(30, 30),
    this.loadingOverlayBuilder,
    PopupOptions? popupOptions,
    this.clusterAlignment = Alignment.center,
    this.clusterSplayDelegate = const SpreadClusterSplayDelegate(
      duration: Duration(milliseconds: 400),
    ),
  })  : isMutableSupercluster = true,
        popupOptions =
            popupOptions == null ? null : popupOptions as PopupOptionsImpl;

  @override
  Widget build(BuildContext context) => InheritOrCreateSuperclusterScope(
        child: SuperclusterLayerImpl(
          isMutableSupercluster: isMutableSupercluster,
          mapCamera: MapCamera.of(context),
          mapController: MapController.of(context),
          controller: controller == null
              ? null
              : controller as SuperclusterControllerImpl,
          builder: builder,
          indexBuilder: indexBuilder ?? IndexBuilders.rootIsolate,
          initialMarkers: initialMarkers,
          moveMap: moveMap,
          onMarkerTap: onMarkerTap,
          maxClusterZoom: maxClusterZoom,
          minimumClusterSize: minimumClusterSize,
          maxClusterRadius: maxClusterRadius,
          clusterDataExtractor: clusterDataExtractor,
          calculateAggregatedClusterData: calculateAggregatedClusterData,
          clusterWidgetSize: clusterWidgetSize,
          loadingOverlayBuilder: loadingOverlayBuilder,
          popupOptions: popupOptions,
          clusterAlignment: clusterAlignment,
          clusterSplayDelegate: clusterSplayDelegate,
        ),
      );
}
