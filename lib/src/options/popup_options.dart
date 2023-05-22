import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:flutter_map_supercluster/src/options/popup_options_impl.dart';

abstract class PopupOptions {
  /// Control the appearance of popups. If this is ommited popups will not be
  /// displayed and they may be displayed elsewhere by wrapping this widget
  /// in a [PopupScope] and adding a [PopupLayer] inside the [PopupScope].
  PopupDisplayOptions? get popupDisplayOptions;

  /// An optional builder to use when a Marker is selected.
  Widget Function(BuildContext context, Marker marker)?
      get selectedMarkerBuilder;

  /// The default MarkerTapBehavior is
  /// [MarkerTapBehavior.togglePopupAndHideRest] which will toggle the popup of
  /// the tapped marker and hide all other popups. This is a sensible default
  /// when you only want to show a single popup at a time but if you show
  /// multiple popups you probably want to use [MarkerTapBehavior.togglePopup].
  ///
  /// For more information and other options see [MarkerTapBehavior].
  MarkerTapBehavior get markerTapBehavior;

  factory PopupOptions({
    PopupDisplayOptions? popupDisplayOptions,
    Widget Function(BuildContext context, Marker marker)? selectedMarkerBuilder,
    MarkerTapBehavior? markerTapBehavior,
  }) = PopupOptionsImpl;
}
