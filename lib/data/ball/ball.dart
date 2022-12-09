import '../../battle/battle.dart';

typedef CatchModifier = double Function(BattleState state, Battler captive);

class Ball {
  Ball (this.catchModifier, {this.bypassCheck = false});

  // TODO will probably need other callbacks
  final CatchModifier catchModifier;
  final bool bypassCheck;

  // TODO implement all ball types
  static final normal = Ball((_, __) => 1);
  static final great = Ball((_, __) => 1.5);
  static final ultra = Ball((_, __) => 2);
  static final master = Ball((_, __) => 1, bypassCheck: true);

  static final values = [
    normal,
    great,
    ultra,
    master,
  ];
}