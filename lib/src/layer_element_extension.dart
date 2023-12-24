import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supercluster/supercluster.dart';

extension LayerElementExtension on LayerElement<Marker> {
  LatLng get latLng => handle(
        cluster: (cluster) => LatLng(cluster.latitude, cluster.longitude),
        point: (point) => point.originalPoint.point,
      );
}
