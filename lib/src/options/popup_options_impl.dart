import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:flutter_map_supercluster/src/options/popup_options.dart';

class PopupOptionsImpl implements PopupOptions {
  final PopupController popupController;

  @override
  final PopupDisplayOptions? popupDisplayOptions;
  @override
  final Widget Function(BuildContext context, Marker marker)?
      selectedMarkerBuilder;
  @override
  final MarkerTapBehavior markerTapBehavior;

  PopupOptionsImpl({
    this.popupDisplayOptions,
    this.selectedMarkerBuilder,
    MarkerTapBehavior? markerTapBehavior,
  })  : markerTapBehavior =
            markerTapBehavior ?? MarkerTapBehavior.togglePopupAndHideRest(),
        popupController = PopupController(),
        super();
}
