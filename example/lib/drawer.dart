import 'package:flutter/material.dart';
import 'package:flutter_map_supercluster_example/basic_example_page.dart';
import 'package:flutter_map_supercluster_example/cluster_splaying_page.dart';
import 'package:flutter_map_supercluster_example/mutable_clusters_page.dart';
import 'package:flutter_map_supercluster_example/normal_and_clustered_markers_with_popups_page.dart';

Widget _buildMenuItem(
    BuildContext context, Widget title, String routeName, String currentRoute) {
  var isSelected = routeName == currentRoute;

  return ListTile(
    title: title,
    selected: isSelected,
    onTap: () {
      if (isSelected) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, routeName);
      }
    },
  );
}

Drawer buildDrawer(BuildContext context, String currentRoute) {
  return Drawer(
    child: ListView(
      children: <Widget>[
        const DrawerHeader(
          child: Center(
            child: Text('Flutter Map Supercluster Examples'),
          ),
        ),
        _buildMenuItem(
          context,
          const Text('Basic Example'),
          BasicExamplePage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Mutable Clustering'),
          MutableClustersPage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Cluster Splaying'),
          ClusterSplayingPage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Normal and Clustered Markers With Popups'),
          NormalAndClusteredMarkersWithPopupsPage.route,
          currentRoute,
        ),
      ],
    ),
  );
}
