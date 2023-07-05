import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:flutter_map_supercluster_example/drawer.dart';
import 'package:latlong2/latlong.dart';

class TooCloseToUnclusterPage extends StatefulWidget {
  static const String route = 'tooCloseToUnclusterPage';

  const TooCloseToUnclusterPage({Key? key}) : super(key: key);

  @override
  State<TooCloseToUnclusterPage> createState() =>
      _TooCloseToUnclusterPageState();
}

class _TooCloseToUnclusterPageState extends State<TooCloseToUnclusterPage>
    with TickerProviderStateMixin {
  late final SuperclusterImmutableController _superclusterController;
  late final AnimatedMapController _animatedMapController;

  static final points = [
    const LatLng(51.4001, -0.08001),
    const LatLng(51.4003, -0.08003),
    const LatLng(51.4005, -0.08005),
    const LatLng(51.4006, -0.08006),
    const LatLng(51.4009, -0.08009),
    const LatLng(51.5, -0.09),
    const LatLng(51.5, -0.09),
    const LatLng(51.5, -0.09),
    const LatLng(51.5, -0.09),
    const LatLng(51.5, -0.09),
    const LatLng(51.59, -0.099),
  ];
  late List<Marker> markers;

  @override
  void initState() {
    super.initState();

    _superclusterController = SuperclusterImmutableController();
    _animatedMapController = AnimatedMapController(vsync: this);

    markers = points
        .map(
          (point) => Marker(
            anchorPos: AnchorPos.align(AnchorAlign.top),
            rotateAlignment: AnchorAlign.top.rotationAlignment,
            height: 30,
            width: 30,
            point: point,
            rotate: true,
            builder: (ctx) => const Icon(Icons.pin_drop),
          ),
        )
        .toList();
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
        appBar: AppBar(title: const Text('Too close to uncluster page')),
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
        drawer: buildDrawer(context, TooCloseToUnclusterPage.route),
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
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
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
              anchor: AnchorPos.align(AnchorAlign.center),
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
