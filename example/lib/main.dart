import 'package:flutter/material.dart';
import 'package:flutter_map_supercluster_example/immutable_clustering_page.dart';
import 'package:flutter_map_supercluster_example/mutable_clustering_page.dart';

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
      },
    );
  }
}
