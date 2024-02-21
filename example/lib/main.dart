import 'package:flutter/material.dart';
import 'package:flutter_map_supercluster_example/cluster_splaying_page.dart';
import 'package:flutter_map_supercluster_example/custom_cluster_marker_page.dart';
import 'package:flutter_map_supercluster_example/normal_and_clustered_markers_with_popups_page.dart';

import 'basic_example.dart';
import 'mutable_clustering_page.dart';

void main() => runApp(const MyApp());

const tileLayerPackageName = 'ng.balanci.flutter_map_supercluster.example';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Map Supercluster Examples',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BasicExamplePage(),
      routes: <String, WidgetBuilder>{
        BasicExamplePage.route: (context) => const BasicExamplePage(),
        MutableClustersPage.route: (context) => const MutableClustersPage(),
        ClusterSplayingPage.route: (context) => const ClusterSplayingPage(),
        NormalAndClusteredMarkersWithPopupsPage.route: (context) =>
            const NormalAndClusteredMarkersWithPopupsPage(),
        CustomClusterMarkerPage.route: (context) =>
            const CustomClusterMarkerPage(),
      },
    );
  }
}
