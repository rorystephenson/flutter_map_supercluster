import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_fast_cluster/flutter_map_fast_cluster.dart';
import 'package:flutter_map_fast_cluster_example/drawer.dart';
import 'package:kdbush/kdbush.dart';
import 'package:latlong2/latlong.dart';

class RadiusClusterManagerPage extends StatefulWidget {
  static const String route = 'radiusClusterManagerPage';

  const RadiusClusterManagerPage({Key? key}) : super(key: key);

  @override
  _RadiusClusterManagerPageState createState() =>
      _RadiusClusterManagerPageState();
}

class _RadiusClusterManagerPageState extends State<RadiusClusterManagerPage> {
  static const totalMarkers = 2000.0;
  final minLatLng = LatLng(49.8566, 1.3522);
  final maxLatLng = LatLng(58.3498, -10.2603);

  late final KDBush<Marker, double> _kdbush;

  @override
  void initState() {
    super.initState();

    final latitudeRange = maxLatLng.latitude - minLatLng.latitude;
    final longitudeRange = maxLatLng.longitude - minLatLng.longitude;

    final stepsInEachDirection = sqrt(totalMarkers).floor();
    final latStep = latitudeRange / stepsInEachDirection;
    final lonStep = longitudeRange / stepsInEachDirection;

    final markers = <Marker>[];
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

    _kdbush = KDBush(
      points: markers,
      getX: (m) => m.point.longitude,
      getY: (m) => m.point.latitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialLatLng = LatLng(
      (minLatLng.latitude + maxLatLng.latitude) / 2,
      (minLatLng.longitude + maxLatLng.longitude) / 2,
    );
    return Scaffold(
      appBar: AppBar(title: Text('$RadiusClusterManager Page')),
      drawer: buildDrawer(context, RadiusClusterManagerPage.route),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng((maxLatLng.latitude + minLatLng.latitude) / 2,
              (maxLatLng.longitude + minLatLng.longitude) / 2),
          zoom: 6,
          maxZoom: 15,
          plugins: [FastClusterPlugin()],
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
              onMarkerTap: (m) => debugPrint('${m.point}'),
              createClusterManager: (controller) {
                debugPrint('initial: $initialLatLng');
                return RadiusClusterManager(
                  radiusInKm: 100.0,
                  clusterLayerController: controller,
                  search: _search,
                  maximumMarkerOrClusterSize: const Size(40, 40),
                  initialRadiusSearchResult: RadiusSearchResult(
                    center: initialLatLng,
                    supercluster: _search(initialLatLng, 200.0),
                  ),
                );
              },
              clusterWidgetSize: const Size(40, 40),
              anchor: AnchorPos.align(AnchorAlign.center),
              builder: (context, clusterData) {
                clusterData as ClusterDataWithCount;
                return Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: Colors.blue),
                  child: Center(
                    child: Text(
                      clusterData.markerCount.toString(),
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

  Future<Supercluster<Marker>> _search(LatLng center, double radiusInKm) async {
    final points = <Marker>[];
    for (final index in _kdbush.withinGeographicalRadius(
        center.longitude, center.latitude, radiusInKm)) {
      points.add(_kdbush.points[index]);
    }

    await (Future.delayed(const Duration(seconds: 2)));
    return Supercluster<Marker>(
      points: points,
      getX: (m) => m.point.longitude,
      getY: (m) => m.point.latitude,
      extractClusterData: (marker) => ClusterDataWithCount(marker),
    );
  }
}
