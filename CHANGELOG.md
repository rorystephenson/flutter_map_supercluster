## [1.0.0]

- BREAKING: Now requires flutter_map 3.0.0 or higher.
- BREAKING: Rename the package to flutter_map_supercluster:
    - FlutterMapFastCluster becomes SuperclusterImmutableLayer
    - etc. (see example if you are unsure).
- Added SuperclusterMutable which allows adding/removing markers efficiently. It
  is no longer necessary to rebuild the whole index when changing markers.
- Changing the markers is now done via the respective controller
  (SuperclusterImmutableController/SuperclusterMutableController).

## [0.0.2]

- Increase cluster/point search bounds to accomodate the cluster width/height so
  that the clusters are visible as soon as any part of the cluster is visible
  instead of when half or more of the cluster is within the bounds.
- Remove comptueSize option as it made the above change impossible.

## [0.0.1]

- First release
