import 'dart:math';

import 'package:flutter/cupertino.dart';

class WorldObject {

  Rectangle<double>? rectangle;
  Widget Function()? provider;

  WorldObject(
      {
        this.rectangle,
        this.provider,
      }
      );

  Widget build(BoxConstraints constraints) {
    return Positioned(
      left: (rectangle?.left ?? 0) * constraints.maxWidth,
      top: (rectangle?.top ?? 0) * constraints.maxHeight,
      width: (rectangle?.width ?? 0) * constraints.maxWidth,
      height: (rectangle?.height ?? 0) * constraints.maxHeight,
      child: (provider ?? () => Container())(),
    );
  }
}