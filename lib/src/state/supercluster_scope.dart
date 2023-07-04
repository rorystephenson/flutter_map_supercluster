import 'package:flutter/material.dart';
import 'package:flutter_map_supercluster/src/state/inherited_supercluster_scope.dart';
import 'package:flutter_map_supercluster/src/state/supercluster_state.dart';

class SuperclusterScope extends StatefulWidget {
  final Widget child;

  const SuperclusterScope({
    super.key,
    required this.child,
  });

  @override
  State<SuperclusterScope> createState() => _SuperclusterScopeState();
}

class _SuperclusterScopeState extends State<SuperclusterScope> {
  late SuperclusterState superclusterState;

  @override
  void initState() {
    super.initState();
    superclusterState = const SuperclusterStateImpl(
      supercluster: null,
      aggregatedClusterData: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InheritedSuperclusterScope(
      superclusterState: superclusterState,
      setSuperclusterState: (superclusterState) => setState(() {
        this.superclusterState = superclusterState;
      }),
      child: widget.child,
    );
  }
}
