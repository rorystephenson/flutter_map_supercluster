import 'package:flutter_map/plugin_api.dart';

abstract class SuperclusterEvent {
  const SuperclusterEvent();
}

class AddMarkerEvent extends SuperclusterEvent {
  final Marker marker;

  const AddMarkerEvent(this.marker);
}

class RemoveMarkerEvent extends SuperclusterEvent {
  final Marker marker;

  const RemoveMarkerEvent(this.marker);
}

class ReplaceAllMarkerEvent extends SuperclusterEvent {
  final List<Marker> markers;

  const ReplaceAllMarkerEvent(this.markers);
}

class ModifyMarkerEvent extends SuperclusterEvent {
  final Marker oldMarker;
  final Marker newMarker;
  final bool updateParentClusters;

  const ModifyMarkerEvent(
    this.oldMarker,
    this.newMarker, {
    required this.updateParentClusters,
  });
}

class CollapseSplayedClustersEvent extends SuperclusterEvent {
  const CollapseSplayedClustersEvent();
}

class ShowPopupsAlsoForEvent extends SuperclusterEvent {
  final List<Marker> markers;
  final bool disableAnimation;

  const ShowPopupsAlsoForEvent(
    this.markers, {
    required this.disableAnimation,
  });
}

class ShowPopupsOnlyForEvent extends SuperclusterEvent {
  final List<Marker> markers;
  final bool disableAnimation;

  const ShowPopupsOnlyForEvent(
    this.markers, {
    required this.disableAnimation,
  });
}

class HideAllPopupsEvent extends SuperclusterEvent {
  final bool disableAnimation;

  const HideAllPopupsEvent({required this.disableAnimation});
}

class HidePopupsWhereEvent extends SuperclusterEvent {
  final bool Function(Marker marker) test;
  final bool disableAnimation;

  const HidePopupsWhereEvent(
    this.test, {
    required this.disableAnimation,
  });
}

class HidePopupsOnlyForEvent extends SuperclusterEvent {
  final List<Marker> markers;

  final bool disableAnimation;

  const HidePopupsOnlyForEvent(
    this.markers, {
    required this.disableAnimation,
  });
}

class TogglePopupEvent extends SuperclusterEvent {
  final Marker marker;
  final bool disableAnimation;

  const TogglePopupEvent(
    this.marker, {
    required this.disableAnimation,
  });
}
