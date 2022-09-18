import 'package:flutter_map/plugin_api.dart';

const defaultMinZoom = 1;
const defaultMaxZoom = 20;

int minZoomFor(FlutterMapState mapState) =>
    mapState.options.minZoom?.ceil() ?? defaultMinZoom;

int maxZoomFor(FlutterMapState mapState) =>
    mapState.options.maxZoom?.ceil() ?? defaultMaxZoom;
