import 'package:flutter_map/flutter_map.dart';

extension MarkerExtension on Marker {
  Anchor get anchor => Anchor.fromPos(
        anchorPos ?? AnchorPos.align(AnchorAlign.center),
        width,
        height,
      );
}
