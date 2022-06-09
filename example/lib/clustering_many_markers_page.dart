import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_fast_cluster/flutter_map_fast_cluster.dart';
import 'package:flutter_map_fast_cluster_example/drawer.dart';
import 'package:latlong2/latlong.dart';

class ClusteringManyMarkersPage extends StatefulWidget {
  static const String route = 'clusteringManyMarkersPage';

  const ClusteringManyMarkersPage({Key? key}) : super(key: key);

  @override
  _ClusteringManyMarkersPageState createState() =>
      _ClusteringManyMarkersPageState();
}

class _ClusteringManyMarkersPageState extends State<ClusteringManyMarkersPage> {
  static const totalMarkers = 2000.0;
  final minLatLng = LatLng(49.8566, 1.3522);
  final maxLatLng = LatLng(58.3498, -10.2603);

  late List<Marker> markers;

  @override
  void initState() {
    final latitudeRange = maxLatLng.latitude - minLatLng.latitude;
    final longitudeRange = maxLatLng.longitude - minLatLng.longitude;

    final stepsInEachDirection = sqrt(totalMarkers).floor();
    final latStep = latitudeRange / stepsInEachDirection;
    final lonStep = longitudeRange / stepsInEachDirection;

    markers = [];
    for (var i = 0; i < stepsInEachDirection; i++) {
      for (var j = 0; j < stepsInEachDirection; j++) {
        final latLng = LatLng(
          minLatLng.latitude + i * latStep,
          minLatLng.longitude + j * lonStep,
        );

        markers.add(
          Marker(
            height: 30,
            width: 30,
            point: latLng,
            builder: (ctx) => const Icon(Icons.pin_drop),
          ),
        );
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clustering Many Markers Page')),
      drawer: buildDrawer(context, ClusteringManyMarkersPage.route),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng((maxLatLng.latitude + minLatLng.latitude) / 2,
              (maxLatLng.longitude + minLatLng.longitude) / 2),
          zoom: 6,
          maxZoom: 15,
          plugins: [
            FastClusterPlugin(),
          ],
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
              //maxClusterRadius: 45,
              size: const Size(40, 40),
              anchor: AnchorPos.align(AnchorAlign.center),
              fitBoundsOptions: const FitBoundsOptions(
                padding: EdgeInsets.all(50),
                maxZoom: 15,
              ),
              markers: markers,
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
