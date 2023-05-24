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
  _TooCloseToUnclusterPageState createState() =>
      _TooCloseToUnclusterPageState();
}

class _TooCloseToUnclusterPageState extends State<TooCloseToUnclusterPage>
    with TickerProviderStateMixin {
  late final SuperclusterImmutableController _superclusterController;
  late final AnimatedMapController _animatedMapController;

  static final points = [
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
  late List<Marker> markers;

  @override
  void initState() {
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

    super.initState();
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
        floatingActionButton: Builder(
          builder: (context) {
            final popupState = PopupState.of(context);
            final popupVisible = popupState.selectedMarkers.isNotEmpty;
            return FloatingActionButton.extended(
              label: SizedBox(
                  width: 100,
                  child: Text(popupVisible ? 'Hide popups' : 'Show popups')),
              icon: Icon(popupVisible ? Icons.web_asset : Icons.web_asset_off),
              onPressed: popupVisible
                  ? () => _superclusterController.hideAllPopups()
                  : () => _superclusterController.showPopupsOnlyFor(markers),
            );
          },
        ),
        drawer: buildDrawer(context, TooCloseToUnclusterPage.route),
        body: FlutterMap(
          mapController: _animatedMapController,
          options: MapOptions(
            center: LatLng(51.4931, -0.1003),
            zoom: 10,
            maxZoom: 15,
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
              onClusterTap: (center, zoom, splayCluster) =>
                  _animatedMapController.animateTo(dest: center, zoom: zoom),
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
}
