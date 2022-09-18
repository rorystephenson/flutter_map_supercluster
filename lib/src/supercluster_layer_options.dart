import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:supercluster/supercluster.dart';

typedef ClusterWidgetBuilder = Widget Function(
    BuildContext context, int markerCount, ClusterDataBase? extraClusterData);

class SuperclusterLayerOptions {
  /// Cluster builder
  final ClusterWidgetBuilder builder;

  /// Initial list of markers, additions/removals must be made using the
  /// [controller].
  final List<Marker> initialMarkers;

  /// The minimum number of points required to form a cluster, if there is less
  /// than this number of points within the [maxClusterRadius] the markers will
  /// be left unclustered.
  final int? minimumClusterSize;

  /// The maximum radius in pixels that a cluster can cover.
  final int maxClusterRadius;

  /// Implement this function to extract extra data from Markers which can be
  /// used in the [builder] and [computeSize].
  final ClusterDataBase Function(Marker marker)? clusterDataExtractor;

  /// Function to call when a Marker is tapped
  final void Function(Marker)? onMarkerTap;

  /// Popup's options that show when tapping markers or via the PopupController.
  final PopupOptions? popupOptions;

  /// If true markers will be counter rotated to the map rotation
  final bool? rotate;

  /// The origin of the coordinate system (relative to the upper left corner of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  final Offset? rotateOrigin;

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as the [rotateOrigin], both are applied.
  ///
  /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [Directionality.of] returns
  /// [TextDirection.ltr], and `1.0` if [Directionality.of] returns
  /// [TextDirection.rtl].	 Similarly [AlignmentDirectional.centerEnd] is the
  /// same as an [Alignment] whose [Alignment.x] value is `1.0` if
  /// [Directionality.of] returns	 [TextDirection.ltr], and `-1.0` if
  /// [Directionality.of] returns [TextDirection.rtl].
  final AlignmentGeometry? rotateAlignment;

  /// Cluster size
  final Size clusterWidgetSize;

  /// Cluster anchor
  final AnchorPos? anchor;

  /// Control cluster zooming (triggered by cluster tap) animation. Use
  /// [AnimationOptions.none] to disable animation. See
  ///  [AnimationOptions.animate] for more information on animation options.
  final AnimationOptions clusterZoomAnimation;

  SuperclusterLayerOptions({
    required this.builder,
    this.initialMarkers = const [],
    this.onMarkerTap,
    this.minimumClusterSize,
    this.maxClusterRadius = 80,
    this.clusterDataExtractor,
    this.clusterWidgetSize = const Size(30, 30),
    this.clusterZoomAnimation = const AnimationOptions.animate(
      curve: Curves.linear,
      velocity: 1,
    ),
    this.popupOptions,
    this.rotate,
    this.rotateOrigin,
    this.rotateAlignment,
    this.anchor,
  });
}

abstract class AnimationOptions {
  const AnimationOptions();

  static const none = AnimationOptionsNoAnimation();

  /// Specifies the [curve] and **either** the [duration] **or** [velocity] of a
  /// given animation. Velocity is animation dependent where a neutral value
  /// is 1 and a higher value will make the animation faster.
  const factory AnimationOptions.animate({
    required Curve curve,
    Duration? duration,
    double? velocity,
  }) = AnimationOptionsAnimate;
}

class AnimationOptionsNoAnimation extends AnimationOptions {
  const AnimationOptionsNoAnimation();
}

class AnimationOptionsAnimate extends AnimationOptions {
  final Curve curve;
  final Duration? duration;
  final double? velocity;

  const AnimationOptionsAnimate({
    required this.curve,
    this.duration,
    this.velocity,
  }) : assert((duration == null) ^ (velocity == null));
}

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
