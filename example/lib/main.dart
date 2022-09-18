import 'package:flutter/material.dart';
import 'package:flutter_map_supercluster_example/clustering_many_markers_page.dart';
import 'package:flutter_map_supercluster_example/mutable_clustering_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clustering Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MutableClusteringPage(),
      routes: <String, WidgetBuilder>{
        MutableClusteringPage.route: (context) => const MutableClusteringPage(),
        ClusteringManyMarkersPage.route: (context) =>
            const ClusteringManyMarkersPage(),
      },
    );
  }
}
