import 'package:flutter_map/plugin_api.dart';

extension MarkerExtension on Marker {
  Anchor get anchorWithDefault =>
      anchor ??
      Anchor.fromPos(
        AnchorPos.defaultAnchorPos,
        width,
        height,
      );
}
