import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:flutter_map_supercluster/src/layer/supercluster_config.dart';

/// A callback used to create a supercluster index. See [IndexBuilders] for
/// predefined builders and guidelines on which one to use.
typedef IndexBuilder = Future<Supercluster<Marker>> Function(
  Supercluster<Marker> Function(SuperclusterConfig config) createSupercluster,
  SuperclusterConfig superclusterConfig,
);

/// Predefined builders for creating a supercluster index. The following is a
/// guideline for determining which [IndexBuilder] to use:
///
///   - If you have few index enough markers that index creation does not cause
///     jank use [IndexBuilders.rootIsolate], otherwise...
///   - To create your index in a separate isolate using flutter's [compute]
///     when using Markers which DO NOT override hashCode/== use
///     [computeWithOriginalMarkers].
///   - To create your index in a separate isolate using flutter's [compute]
///     when using Markers which DO override hashCode/== use
///     [computeWithCopiedMarkers].
///   - To create your index in a separate isolate which you manage yourself
///     (i.e. with the worker_manager package) when using Markers which DO NOT
///     override hashCode/== use [customWithOriginalMarkers].
///   - To create your index in a separate isolate which you manage yourself
///     (i.e. with the worker_manager package) when using Markers which DO
///     override hashCode/== you should use a plain [IndexBuilder].
class IndexBuilders {
  const IndexBuilders._();

  /// Creates the supercluster in the root isolate. This is the best choice if
  /// you don't experience jank when creating the index.
  static IndexBuilder rootIsolate =
      ((createSupercluster, superclusterConfig) async =>
          createSupercluster(superclusterConfig));

  /// Creates the supercluster in a separate isolate using flutter's [compute]
  /// method and then replaces the copied Marker instances in the supercluster
  /// with the original ones passed to SuperclusterLayer. The replacing of the
  /// Markers requires iterating all of the provided Markers which may slow
  /// down index creation for large numbers of Markers. This is unnecessary if
  /// you extend Marker and override its hashCode/== methods, in which case you
  /// should use [computeWithCopiedMarkers].
  static IndexBuilder computeWithOriginalMarkers =
      ((createSupercluster, superclusterConfig) async =>
          compute(createSupercluster, superclusterConfig).then((supercluster) =>
              supercluster..replacePoints(superclusterConfig.markers)));

  /// Creates the supercluster in a separate isolate using flutter's [compute]
  /// method. Dart creates copies of objects when running code in a separate
  /// isolate and as such the resulting supercluster's Markers will not be the
  /// same Marker instances that are passed to SuperclusterLayer. If you use
  /// this method you must extend Marker and override its hashCode/== methods
  /// so that the copied Markers are equal to and have the same hashCode as the
  /// original ones. Alternatively you may use [computeWithOriginalMarkers].
  ///
  /// Failure to override hashCode/== will prevent popups from working properly
  /// for splayed clusters and may cause other issues.
  static IndexBuilder computeWithCopiedMarkers =
      ((createSupercluster, superclusterConfig) async =>
          compute(createSupercluster, superclusterConfig));

  /// Calls the provided [indexBuilder] before replacing the resulting index's
  /// markers with the original markers. This is only necessary when the
  /// [indexBuilder] creates the index in a separate isolate and the provided
  /// Markers do not override hashCode/==. If [indexBuilder] does not create
  /// the index in a separate isolate or the Markers override hashCode/== you
  /// should just use a plain IndexBuilder instance.
  static IndexBuilder customWithOriginalMarkers(IndexBuilder indexBuilder) =>
      ((createSupercluster, superclusterConfig) async => indexBuilder
          .call(createSupercluster, superclusterConfig)
          .then((supercluster) =>
              supercluster..replacePoints(superclusterConfig.markers)));
}
