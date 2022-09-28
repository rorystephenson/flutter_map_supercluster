import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:supercluster/supercluster.dart';

class LoadingOverlay extends StatelessWidget {
  final Future<Supercluster<Marker>> superclusterFuture;
  final WidgetBuilder? loadingOverlayBuilder;

  const LoadingOverlay({
    super.key,
    required this.superclusterFuture,
    required this.loadingOverlayBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Supercluster<Marker>>(
      future: superclusterFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const SizedBox.shrink();
        }

        return loadingOverlayBuilder?.call(context) ??
            Container(
              color: Colors.black26,
              child: Center(
                child: Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 16.0),
                        Text('Building clusters'),
                      ],
                    ),
                  ),
                ),
              ),
            );
      },
    );
  }
}
