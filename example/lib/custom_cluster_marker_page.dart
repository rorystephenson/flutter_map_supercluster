import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:latlong2/latlong.dart';

import 'drawer.dart';

class CustomClusterMarkerPage extends StatelessWidget {
  static const String route = 'customClusterMarkerPage';

  const CustomClusterMarkerPage({Key? key}) : super(key: key);

  // Initialise randomly generated Markers
  static final _random = Random(42);
  static const _initialCenter = LatLng(42.0, 10.0);
  static final _markers = List<CustomMarker>.generate(
    3000,
    (_) => CustomMarker(
      builder: (context) => const Icon(Icons.location_on),
      point: LatLng(
        _random.nextDouble() * 3 - 1.5 + _initialCenter.latitude,
        _random.nextDouble() * 3 - 1.5 + _initialCenter.longitude,
      ),
      greenCount: _random.nextInt(10),
      blueCount: _random.nextInt(10),
      purpleCount: _random.nextInt(10),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Cluster Marker')),
      drawer: buildDrawer(context, CustomClusterMarkerPage.route),
      body: FlutterMap(
        options: MapOptions(
          center: _initialCenter,
          zoom: 8,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          SuperclusterLayer.immutable(
            // Replaces MarkerLayer
            initialMarkers: _markers,
            clusterDataExtractor: (marker) =>
                CustomClusterData(marker as CustomMarker),
            indexBuilder: IndexBuilders.rootIsolate,
            builder: (context, position, markerCount, extraClusterData) =>
                CustomClusterMarker(
              markerCount: markerCount,
              customClusterData: extraClusterData as CustomClusterData,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomClusterData extends ClusterDataBase {
  final int greenTotal;
  final int blueTotal;
  final int purpleTotal;

  CustomClusterData(CustomMarker marker)
      : greenTotal = marker.greenCount,
        blueTotal = marker.blueCount,
        purpleTotal = marker.purpleCount;

  CustomClusterData._({
    required this.greenTotal,
    required this.blueTotal,
    required this.purpleTotal,
  });

  @override
  CustomClusterData combine(CustomClusterData data) => CustomClusterData._(
        greenTotal: greenTotal + data.greenTotal,
        blueTotal: blueTotal + data.blueTotal,
        purpleTotal: purpleTotal + data.purpleTotal,
      );

  int get total => greenTotal + blueTotal + purpleTotal;
}

class CustomMarker extends Marker {
  final int greenCount;
  final int blueCount;
  final int purpleCount;

  CustomMarker({
    required super.point,
    required super.builder,
    required this.greenCount,
    required this.blueCount,
    required this.purpleCount,
  });
}

class CustomClusterMarker extends StatelessWidget {
  final int markerCount;
  final CustomClusterData customClusterData;

  const CustomClusterMarker({
    super.key,
    required this.markerCount,
    required this.customClusterData,
  });

  @override
  Widget build(BuildContext context) {
    final total = customClusterData.total;
    final greenPortion = customClusterData.greenTotal / total;
    final bluePortion = customClusterData.blueTotal / total;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        // For simplicity this example abuses SweepGradient to simulate a pi
        // graph. You may be better served using a CustomPainter to draw a pi
        // graph properly or whatever representation you prefer.
        gradient: SweepGradient(colors: const [
          Colors.green,
          Colors.green,
          Colors.blue,
          Colors.blue,
          Colors.deepPurple,
          Colors.deepPurple,
        ], stops: [
          0,
          greenPortion,
          greenPortion + 0.000000001,
          greenPortion + bluePortion,
          greenPortion + bluePortion + 0.000000001,
          1
        ]),
        color: Colors.blue,
      ),
      child: Center(
        child: Text(
          markerCount.toString(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
