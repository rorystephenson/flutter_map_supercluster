import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';
import 'package:flutter_map_supercluster/src/state/inherited_supercluster_scope.dart';

abstract class SuperclusterState {
  bool get loading;

  ClusterData? get aggregatedClusterData;

  static SuperclusterState? maybeOf(
    BuildContext context, {
    bool listen = true,
  }) {
    return InheritedSuperclusterScope.maybeOf(
      context,
      listen: listen,
    )?.superclusterState;
  }

  static SuperclusterState of(
    BuildContext context, {
    bool listen = true,
  }) {
    final SuperclusterState? result = maybeOf(context, listen: listen);
    assert(result != null, 'No SuperclusterState found in context.');
    return result!;
  }
}

class SuperclusterStateImpl extends Equatable implements SuperclusterState {
  @override
  final ClusterData? aggregatedClusterData;

  final Supercluster<Marker>? _supercluster;

  @override
  bool get loading => _supercluster == null;

  const SuperclusterStateImpl({
    required this.aggregatedClusterData,
    required Supercluster<Marker>? supercluster,
  }) : _supercluster = supercluster;

  @override
  List<Object?> get props => [loading, aggregatedClusterData];
}
