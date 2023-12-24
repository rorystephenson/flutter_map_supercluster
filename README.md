# Flutter Map Supercluster

Two different Marker clustering layers for [flutter_map](https://github.com/fleaflet/flutter_map):

- `SuperclusterLayer.immutable`: An extremely fast Marker clustering layer, Markers may not be
  added/removed.
- `SuperclusterLayer.mutable`: A slightly slower (but still very fast) Marker clustering layer.
  Markers can be added/removed.

![Example](https://github.com/rorystephenson/project_gifs/blob/master/flutter_map_supercluster/demo.gif)

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
      SuperclusterLayer.immutable(
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

See the `example/` folder for a working example app which demonstrates both immutable and mutable
cluster layers.
