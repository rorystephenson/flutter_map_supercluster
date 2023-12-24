import 'package:flutter/material.dart';
import 'package:flutter_map_supercluster/src/state/supercluster_state.dart';

class InheritedSuperclusterScope extends InheritedWidget {
  final SuperclusterState superclusterState;
  final void Function(SuperclusterStateImpl stateImpl) setSuperclusterState;

  const InheritedSuperclusterScope({
    super.key,
    required this.superclusterState,
    required this.setSuperclusterState,
    required super.child,
  });

  static InheritedSuperclusterScope? maybeOf(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<InheritedSuperclusterScope>();
    } else {
      return context
          .getInheritedWidgetOfExactType<InheritedSuperclusterScope>();
    }
  }

  static InheritedSuperclusterScope of(
    BuildContext context, {
    bool listen = true,
  }) {
    final result = maybeOf(context, listen: listen);
    assert(
        result != null, 'No InheritedSuperclusterScopeState found in context.');
    return result!;
  }

  @override
  bool updateShouldNotify(InheritedSuperclusterScope oldWidget) =>
      oldWidget.superclusterState != superclusterState;
}
