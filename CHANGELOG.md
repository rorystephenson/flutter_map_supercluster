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
