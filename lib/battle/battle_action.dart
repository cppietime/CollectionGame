import 'package:collectgame/data/move/move.dart';

enum BattleActionType {
  move, item, swap, run;
}

class BattleActionAttackParam {
  const BattleActionAttackParam(this.move, this.target);
  final Move move;
  final MoveTarget target;
}

// Represents choosing a move, using an item, or switching out
class BattleAction {
  const BattleAction(this.type, this.param);
  final BattleActionType type;
  final dynamic param;

  int priority() {
    switch (type) {
      case BattleActionType.run:
        return 10;
      case BattleActionType.item:
        return 9;
      case BattleActionType.swap:
        return 7;
      case BattleActionType.move:
        final moveParam = param as BattleActionAttackParam;
        return moveParam.move.priority;
    }
  }
}