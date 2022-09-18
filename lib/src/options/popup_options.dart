import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

class PopupOptions {
  /// Used to construct the popup.
  final PopupBuilder popupBuilder;

  /// If a PopupController is provided it can be used to programmatically show
  /// and hide the popup.
  final PopupController popupController;

  /// Controls the position of the popup relative to the marker or popup.
  final PopupSnap popupSnap;

  /// Allows the use of an animation for showing/hiding popups. Defaults to no
  /// animation.
  final PopupAnimation? popupAnimation;

  /// An optional builder to use when a Marker is selected.
  final Widget Function(BuildContext context, Marker marker)?
      selectedMarkerBuilder;

  /// Whether or not the markers rotate counter clockwise to the map rotation,
  /// defaults to false.
  final bool markerRotate;

  /// The default MarkerTapBehavior is
  /// [MarkerTapBehavior.togglePopupAndHideRest] which will toggle the popup of
  /// the tapped marker and hide all other popups. This is a sensible default
  /// when you only want to show a single popup at a time but if you show
  /// multiple popups you probably want to use [MarkerTapBehavior.togglePopup].
  ///
  /// For more information and other options see [MarkerTapBehavior].
  final MarkerTapBehavior markerTapBehavior;

  PopupOptions({
    required this.popupBuilder,
    this.popupSnap = PopupSnap.markerTop,
    PopupController? popupController,
    this.popupAnimation,
    this.selectedMarkerBuilder,
    this.markerRotate = false,
    MarkerTapBehavior? markerTapBehavior,
  })  : markerTapBehavior =
            markerTapBehavior ?? MarkerTapBehavior.togglePopupAndHideRest(),
        popupController = popupController ?? PopupController();
}
