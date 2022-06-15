import 'dart:async';

class ClusterLayerController {
  final StreamController<ClusterLayerEvent> _streamController;

  ClusterLayerController()
      : _streamController = StreamController<ClusterLayerEvent>();

  void markersUpdated() {
    _streamController.add(ClusterLayerEvent.markersUpdated);
  }

  void dispose() {
    _streamController.close();
  }

  Stream<ClusterLayerEvent> get stream => _streamController.stream;
}

enum ClusterLayerEvent { markersUpdated }
