import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:flutter_map_supercluster_example/drawer.dart';
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

  late final SuperclusterImmutableController _superclusterController;

  late List<Marker> markers;

  @override
  void initState() {
    _superclusterController = SuperclusterImmutableController();

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
      appBar: AppBar(
        title: const Text('Clustering Many Markers Page'),
        actions: [
          StreamBuilder<ClusterData?>(
              stream: _superclusterController.aggregatedClusterDataStream,
              builder: (context, snapshot) {
                return Center(
                    child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child:
                      Text('Total markers: ${snapshot.data?.markerCount ?? 0}'),
                ));
              }),
        ],
      ),
      drawer: buildDrawer(context, ClusteringManyMarkersPage.route),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng((maxLatLng.latitude + minLatLng.latitude) / 2,
              (maxLatLng.longitude + minLatLng.longitude) / 2),
          zoom: 6,
          maxZoom: 15,
        ),
        children: <Widget>[
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          SuperclusterImmutableLayer(
            initialMarkers: markers,
            controller: _superclusterController,
            calculateAggregatedClusterData: true,
            clusterWidgetSize: const Size(40, 40),
            anchor: AnchorPos.align(AnchorAlign.center),
            popupOptions: PopupOptions(
              selectedMarkerBuilder: (context, marker) => const Icon(
                Icons.pin_drop,
                color: Colors.red,
              ),
              popupBuilder: (BuildContext context, Marker marker) => Container(
                color: Colors.white,
                child: Text(marker.point.toString()),
              ),
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
        ],
      ),
    );
  }
}
