## [5.0.0-dev.1]
- FEATURE: Add maxClusterZoom option to prevent clusters from being formed
  above a certain zoom.
- FEATURE: Added SuperclusterScope and SuperclusterState.of(context) methods.
  This allows accessing of the supercluster layer state from children of the
  relevant SuperclusterScope. For example if you wrap your Scaffold in
  SuperclusterScope() and the scaffold contains a FlutterMap with a
  SuperclusterLayer you will be able to access the state of the layer from
  children of Scaffold.
- FEATURE: Added addAll() and removeAll() to SuperclusterMutableController for
  efficiently adding/removing multiple markers at once.
- FEATURE: SuperclusterMutableController's add/remove methods now fully
  recluster markers affected by an addition/removal.
- FEATURE: The indexBuilder option now defaults to building in the root index.
- FEATURE: Popups will now be hidden automatically when removing their Marker.
- FEATURE: Splayed clusters will now be collapsed automatically when removing
  one of their points or inserting a point which causes the splay cluster to
  change.
- FEATURE: flutter_map 6.0.0
- FEATURE: flutter_map_marker_popup v6.1.1
- FEATURE: supercluster v3.0.1.
- DEPRECATION: SuperclusterLayer's anchor has been renamed to clusterAnchorPos.
- CHORE: Example app tidy-up. Added desktop platforms and renamed/simplified
  examples.

Note that this version included major changes internally. I was close to
completing this verison before I noticed some issues with how FlutterMap works
which required a huge refactor of FlutterMap. That PR has taken quite some time 
which put this version on hold. As a result I have come back to some incomplete
changes and there may be breaking changes or deprecations missing in the
CHANGELOG despite my best efforts to list them all. If you notice something
don't hesitate to open an issue.

## [4.3.0]

- FEATURE: flutter_map 5.0.0
- FEATURE: latlon2 0.9.0
- BUGFIX: Fix bug where not providing a controller caused an exception.

## [4.2.1]

- BUGFIX: Correct the splay cluster's target zoom level which determines how
  far markers are spread and when their popups are hidden.
- CHORE: Remove unused code.

## [4.2.0]

- BREAKING: Remove maxZoom option. It was a workaround for clusters that
  couldn't be opened because the markers were too close to be unclustered at
  the map's maxZoom but the implementation is actually flawed in that it will
  only work if the maxZoom is one greater than the map's maxZoom. Otherwise the
  behaviour would be undefined.

## [4.1.0]

- BREAKING: Requires dart 3.

## [4.0.0+1]

- BUGFIX: Removed example dependency overrides.

## [4.0.0]

- BREAKING: Animated movement is no longer implemented by this plugin.
  Animation is now supported using the onClusterTap/onMarkerTap callbacks to
  trigger animated movement. The examples have been updated to use the
  flutter_map_animations to drive animated movement.
- BREAKING: Updated flutter_map_marker_popup to 5.0.0, breaking changes:
  - The popupBuilder, popupSnap and popupAnimation options from PopupOptions
    are now combined in to a single option: popupDisplayOptions.
  - PopupMarkerLayerOptions.rotationAlignmentFor has been replaced with a new
    arotateAlignment extension method on AnchorAlign. So
    PopupMarkerLayerOptions.rotationAlignmentFor(AnchorAlign.top) becomes
    AnchorAlign.top.rotationAlignment.
- BREAKING: Popups are now controlled via the SuperclusterController. This is
  necessary to properly support displaying popups for splayed markers.
- BREAKING: The following marker rotation options have been removed, they
  should be set on the markers themselves:
  - markerRotate
  - markerRotateAlignment
  - markerAnchorAlign
- BREAKING: The wrapIndexCreation optional callback has now been replaced with
  the required indexBuilder callback. This makes makes the choice between
  building the index in the root isolate or a separate isolate explicit and
  some predefined IndexBuilders have been added. See the IndexBuilders
  documentation for a full explanation.

## [3.0.0+1]

- DOCS: Improved the SuperclusterLayer clusterDataExtractor documentation to
        warn about code which cannot be run in a separate isolate.

## [3.0.0]

- FEATURE: flutter_map 4.0.0
- FEATURE: Added cluster 'splaying' for clusters whose markers are too close to
           uncluster at the maxZoom. See clusterSplayDelegate option for more
           information. The example app has a new page to demonstrate splaying.
- FEATURE: Added collapseSplayedClusters() to SuperclusterController. 

## [2.3.0]

- FEATURE: Add maxClusterZoom to control the maximum zoom at which clustering
  will occur.

## [2.2.1]

- BUGFIX: Don't hide popups too early when zooming out.

## [2.2.0]

- BREAKING: Cluster builder now includes the cluster position as a parameter.

## [2.1.1]

- FEATURE: Make clusters always appear above markers.

## [2.1.0]

- BUGFIX: Prevent animated zooming from breaking when starting an animation
  before the last one finished.
- FEATURE: Emit MapEventMove events with an id which indicates the movement
  state:
    - CenterZoomAnimation.started
    - CenterZoomAnimation.inProgress
    - CenterZoomAnimation.finished

## [2.0.1]

- BUGFIX: Remove existing points when re-creating the index for
  `SuperclusterLayer.mutable`.

## [2.0.0]

- BREAKING: SuperclusterImmutableLayer is now SuperclusterLayer.immutable.
- BREAKING: SuperclusterMutableLayer is now SuperclusterLayer.mutable.
- BREAKING: SuperclusterController's aggregatedClusterDataStream has been
  replaced with stateStream which contains a new SuperclusterState object
  containing the aggregated cluster data and the loading state.
- BREAKING: SuperclusterController's `all()` method now returns a
  `Future<Iterable<Marker>>` instead of an `Iterable<Marker>` as it is possible
  that the index is still loading.
- BREAKING: Creation of the supercluster index is now done in a separate isolate
  by default using Flutter's `compute` function. This can be changed with the
  new `wrapIndexCreation` option. Note due to how `compute` works the Marker
  instances inside the index will be clones of the original Markers and will not
  be equal to or have the same hashCode as the original Markers. If you need to
  show popups or perform other actions which required matching against the
  original Marker instances you should implement an equals and hashcode or use a
  library like equatable which simplifies doing so.
- Whilst the index is loading a loading overlay is displayed. This overlay can
  be customised with the new `loadingOverlayBuilder` option.

## [1.0.0]

- BREAKING: Now requires `flutter_map` 3.0.0 or higher.
- BREAKING: Renamed the package to `flutter_map_supercluster`:
    - `FlutterMapFastCluster` becomes `SuperclusterImmutableLayer`
    - etc. (see example if you are unsure).
- Added `SuperclusterMutable` which allows adding/removing markers efficiently.
  It is no longer necessary to rebuild the whole index when changing markers.
- Changing the markers is now done via the respective controller
  (`SuperclusterImmutableController`/`SuperclusterMutableController`).

## [0.0.2]

- Increase cluster/point search bounds to accomodate the cluster width/height so
  that the clusters are visible as soon as any part of the cluster is visible
  instead of when half or more of the cluster is within the bounds.
- Remove comptueSize option as it made the above change impossible.

## [0.0.1]

- First release
