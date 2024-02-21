import 'package:flutter/material.dart';

import 'custom_cluster_marker_page.dart';
import 'immutable_clustering_page.dart';
import 'mutable_clustering_page.dart';
import 'normal_and_clustered_markers_with_popups_page.dart';
import 'too_close_to_uncluster_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Map Supercluster Examples',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MutableClusteringPage(),
      routes: <String, WidgetBuilder>{
        MutableClusteringPage.route: (context) => const MutableClusteringPage(),
        ClusteringManyMarkersPage.route: (context) =>
            const ClusteringManyMarkersPage(),
        TooCloseToUnclusterPage.route: (context) =>
            const TooCloseToUnclusterPage(),
        NormalAndClusteredMarkersWithPopups.route: (context) =>
            const NormalAndClusteredMarkersWithPopups(),
        CustomClusterMarkerPage.route: (context) =>
            const CustomClusterMarkerPage(),
      },
    );
  }
}
