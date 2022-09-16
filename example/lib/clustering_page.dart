import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_fast_cluster/flutter_map_fast_cluster.dart';
import 'package:flutter_map_fast_cluster_example/drawer.dart';
import 'package:latlong2/latlong.dart';

class ClusteringPage extends StatefulWidget {
  static const String route = 'clusteringPage';

  const ClusteringPage({Key? key}) : super(key: key);

  @override
  _ClusteringPageState createState() => _ClusteringPageState();
}

class _ClusteringPageState extends State<ClusteringPage> {
  late final MutableFastClusterLayerController _fastClusterLayerController;

  late List<Marker> markers;
  late int pointIndex;
  List points = [
    LatLng(51.5, -0.09),
    LatLng(49.8566, 3.3522),
  ];
  int? tappedMarkerIndex;

  @override
  void initState() {
    _fastClusterLayerController = MutableFastClusterLayerController();
    pointIndex = 0;
    markers = [
      Marker(
        anchorPos: AnchorPos.align(AnchorAlign.center),
        height: 30,
        width: 30,
        point: points[pointIndex],
        builder: (ctx) => const Icon(Icons.pin_drop),
      ),
      Marker(
        anchorPos: AnchorPos.align(AnchorAlign.center),
        height: 30,
        width: 30,
        point: LatLng(53.3498, -6.2603),
        builder: (ctx) => const Icon(Icons.pin_drop),
      ),
      Marker(
        anchorPos: AnchorPos.align(AnchorAlign.center),
        height: 30,
        width: 30,
        point: LatLng(53.3488, -6.2613),
        builder: (ctx) => const Icon(Icons.pin_drop),
      ),
    ];

    super.initState();
  }

  @override
  void dispose() {
    _fastClusterLayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clustering Page'),
      ),
      drawer: buildDrawer(context, ClusteringPage.route),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          pointIndex++;
          if (pointIndex >= points.length) {
            pointIndex = 0;
          }
          setState(() {
            markers[0] = Marker(
              point: points[pointIndex],
              anchorPos: AnchorPos.align(AnchorAlign.center),
              height: 30,
              width: 30,
              builder: (ctx) => const Icon(Icons.pin_drop),
            );
            markers = List.from(markers);
          });
        },
        child: const Icon(Icons.refresh),
      ),
      body: FlutterMap(
        options: MapOptions(
          center: points[0],
          zoom: 5,
          maxZoom: 15,
          plugins: [
            FastClusterPlugin(),
          ],
          onTap: (_, latLng) {
            _fastClusterLayerController.add(
              Marker(
                anchorPos: AnchorPos.align(AnchorAlign.center),
                height: 30,
                width: 30,
                point: latLng,
                builder: (ctx) => const Icon(Icons.pin_drop_outlined),
              ),
            );
          }, // Hide popup when the map is tapped.
        ),
        children: <Widget>[
          TileLayerWidget(
            options: TileLayerOptions(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
            ),
          ),
          FastClusterLayerWidget(
            options: FastClusterLayerOptions(
              initialMarkers: markers,
              onMarkerTap: (marker) {
                _fastClusterLayerController.remove(marker);
              },
              controller: _fastClusterLayerController,
              rotate: true,
              clusterWidgetSize: const Size(40, 40),
              anchor: AnchorPos.align(AnchorAlign.center),
              clusterZoomAnimation: const AnimationOptions.animate(
                curve: Curves.linear,
                velocity: 1,
              ),
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
      ),
    );
  }
}
