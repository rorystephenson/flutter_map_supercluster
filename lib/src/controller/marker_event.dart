import 'package:flutter_map/plugin_api.dart';

abstract class MarkerEvent {}

class AddMarkerEvent extends MarkerEvent {
  final Marker marker;

  AddMarkerEvent(this.marker);
}

class RemoveMarkerEvent extends MarkerEvent {
  final Marker marker;

  RemoveMarkerEvent(this.marker);
}

class ReplaceAllMarkerEvent extends MarkerEvent {
  final List<Marker> markers;

  ReplaceAllMarkerEvent(this.markers);
}

class ModifyMarkerEvent extends MarkerEvent {
  final Marker oldMarker;
  final Marker newMarker;
  final bool updateParentClusters;

  ModifyMarkerEvent(
    this.oldMarker,
    this.newMarker, {
    required this.updateParentClusters,
  });
}
