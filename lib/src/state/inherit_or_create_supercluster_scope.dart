import 'package:flutter/material.dart';
import 'package:flutter_map_supercluster/src/state/inherited_supercluster_scope.dart';
import 'package:flutter_map_supercluster/src/state/supercluster_scope.dart';

class InheritOrCreateSuperclusterScope extends StatelessWidget {
  final Widget child;
  const InheritOrCreateSuperclusterScope({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final superclusterScopeState =
        InheritedSuperclusterScope.maybeOf(context, listen: false);

    return superclusterScopeState != null
        ? child
        : SuperclusterScope(child: child);
  }
}
