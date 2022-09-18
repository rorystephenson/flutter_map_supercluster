# Flutter Map Supercluster

Two different Marker clustering layers for [flutter_map](https://github.com/fleaflet/flutter_map):

- `SuperclusterLayer`: An extremely fast Marker clustering layer, Markers may not be added/removed.
- `SuperclusterMutableLayer`: An slightly slower (but still very fast) Marker clustering layer.
  Markers can be added/removed.

If you want beautiful clustering animations check out `flutter_map_marker_plugin`. It will perform
well for quite a lot of Markers on most devices. If you are running in to performance issues and are
happy to sacrifice animations then this package may be for you.

## Usage

Add flutter_map and flutter_map_supercluster to your pubspec:

```yaml
dependencies:
  flutter_map: any
  flutter_map_supercluster: any # or the latest version on Pub
```

Add it to FlutterMap:

```dart
  Widget build(BuildContext context) {
  return FlutterMap(
    options: MapOptions(
      zoom: 5,
      maxZoom: 15,
    ),
    children: <Widget>[
      TileLayer(
        options: TileLayerOptions(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
      ),
      SuperclusterLayer(
        initialMarkers: markers, // Provide your own
        clusterWidgetSize: const Size(40, 40),
        builder: (context, markerCount, extraClusterData) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: Colors.blue,
            ),
            child: Center(
              child: Text(
                markerCount.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      ),
    ],
  );
}
```

### Run the example

See the `example/` folder for a working example app.