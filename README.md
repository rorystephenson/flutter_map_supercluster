# Flutter Map Supercluster

A very fast clustering plugin for [flutter_map](https://github.com/fleaflet/flutter_map) which uses
the supercluster algorithm. Adding/removing markers is also supported
with `SuperclusterMutableLayer`.

If you want beautiful clustering animations check out `flutter_map_marker_plugin`. It will perform
well for quite a lot of Markers on most devices. If you are running in to performance issues and are
happy to sacrifice animations then this plugin may be for you.

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
      TileLayerWidget(
        options: TileLayerOptions(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
      ),
      SuperclusterLayer(
        options: FastClusterLayerOptions(
          size: const Size(40, 40),
          markers: markers, // Provide your own.
          builder: (context, markerCount, extraClusterData) {
            return Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: Colors.blue),
              child: Center(
                child: Text(
                  markerCount.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}
```

### Run the example

See the `example/` folder for a working example app.