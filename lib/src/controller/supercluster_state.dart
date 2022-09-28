import 'package:equatable/equatable.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';

class SuperclusterState extends Equatable {
  final bool loading;

  final ClusterData? aggregatedClusterData;

  const SuperclusterState({
    required this.loading,
    required this.aggregatedClusterData,
  });

  @override
  List<Object?> get props => [loading, aggregatedClusterData];
}
