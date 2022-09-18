import 'package:flutter/material.dart';

abstract class AnimationOptions {
  const AnimationOptions();

  static const none = AnimationOptionsNoAnimation();

  /// Specifies the [curve] and **either** the [duration] **or** [velocity] of a
  /// given animation. Velocity is animation dependent where a neutral value
  /// is 1 and a higher value will make the animation faster.
  const factory AnimationOptions.animate({
    required Curve curve,
    Duration? duration,
    double? velocity,
  }) = AnimationOptionsAnimate;
}

class AnimationOptionsNoAnimation extends AnimationOptions {
  const AnimationOptionsNoAnimation();
}

class AnimationOptionsAnimate extends AnimationOptions {
  final Curve curve;
  final Duration? duration;
  final double? velocity;

  const AnimationOptionsAnimate({
    required this.curve,
    this.duration,
    this.velocity,
  }) : assert((duration == null) ^ (velocity == null));
}
