import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:flutter_map_supercluster_example/drawer.dart';
import 'package:flutter_map_supercluster_example/main.dart';
import 'package:latlong2/latlong.dart';

class ClusterSplayingPage extends StatefulWidget {
  static const String route = 'clusterSplayingPage';

  const ClusterSplayingPage({super.key});

  @override
  State<ClusterSplayingPage> createState() => _ClusterSplayingPageState();
}

class _ClusterSplayingPageState extends State<ClusterSplayingPage>
    with TickerProviderStateMixin {
  late final SuperclusterImmutableController _superclusterController;
  late final AnimatedMapController _animatedMapController;

  static const points = [
    LatLng(51.4001, -0.08001),
    LatLng(51.4003, -0.08003),
    LatLng(51.4005, -0.08005),
    LatLng(51.4006, -0.08006),
    LatLng(51.4009, -0.08009),
    LatLng(51.5, -0.09),
    LatLng(51.5, -0.09),
    LatLng(51.5, -0.09),
    LatLng(51.5, -0.09),
    LatLng(51.5, -0.09),
    LatLng(51.59, -0.099),
  ];
  static final List<Marker> markers = points
      .map(
        (point) => Marker(
          alignment: Alignment.topCenter,
          height: 30,
          width: 30,
          point: point,
          rotate: true,
          child: const Icon(Icons.pin_drop),
        ),
      )
      .toList();

  @override
  void initState() {
    super.initState();

    _superclusterController = SuperclusterImmutableController();
    _animatedMapController = AnimatedMapController(vsync: this);
  }

  @override
  void dispose() {
    _superclusterController.dispose();
    _animatedMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopupScope(
      child: Scaffold(
        appBar: AppBar(title: const Text('Cluster Splaying')),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Builder(
              builder: (context) => FloatingActionButton.extended(
                label: const SizedBox(child: Text('Select random marker')),
                icon: const Icon(Icons.shuffle),
                onPressed: () => _superclusterController.moveToMarker(
                  MarkerMatcher.equalsMarker(
                    _randomNextMarker(PopupState.of(context, listen: false)),
                  ),
                ),
              ),
            ),
          ],
        ),
        drawer: buildDrawer(context, ClusterSplayingPage.route),
        body: FlutterMap(
          mapController: _animatedMapController.mapController,
          options: MapOptions(
            initialCenter: const LatLng(51.4931, -0.1003),
            initialZoom: 10,
            maxZoom: 16,
            onTap: (_, __) {
              _superclusterController.collapseSplayedClusters();
            },
          ),
          children: <Widget>[
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: tileLayerPackageName,
            ),
            SuperclusterLayer.immutable(
              initialMarkers: markers,
              indexBuilder: IndexBuilders.rootIsolate,
              controller: _superclusterController,
              moveMap: (center, zoom) => _animatedMapController.animateTo(
                dest: center,
                zoom: zoom,
              ),
              clusterWidgetSize: const Size(40, 40),
              clusterAlignment: Alignment.center,
              popupOptions: PopupOptions(
                selectedMarkerBuilder: (context, marker) => const Icon(
                  Icons.pin_drop,
                  color: Colors.red,
                ),
                popupDisplayOptions: PopupDisplayOptions(
                  builder: (BuildContext context, Marker marker) => Container(
                    color: Colors.white,
                    child: Text(marker.point.toString()),
                  ),
                ),
              ),
              builder: (context, position, markerCount, extraClusterData) {
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
      ),
    );
  }

  Marker _randomNextMarker(PopupState popupState) {
    final candidateMarkers = List.from(markers);

    while (candidateMarkers.isNotEmpty) {
      final randomIndex = Random().nextInt(candidateMarkers.length);
      final candidateMarker = candidateMarkers.removeAt(randomIndex);
      if (!popupState.isSelected(candidateMarker)) return candidateMarker;
    }

    throw 'No deselected markers found';
  }
}
