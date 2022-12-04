import 'package:collectgame/data/move/move.dart';

import '../data/item/item.dart';
import 'battler.dart';

enum BattleActionType {
  move, item, swap, run;
}

class BattleActionAttackParam {
  const BattleActionAttackParam(this.move, this.target);
  final Move move;
  final MoveTarget target;
}

class BattleActionItemParam {
  const BattleActionItemParam(this.item, [this.target]);
  final Item item;
  final Individual? target;
}

// Represents choosing a move, using an item, or switching out
class BattleAction {
  const BattleAction(this.type, this.param);
  final BattleActionType type;
  final dynamic param;

  /*
  Priorities -6 - 6: regular moves, default 0
  Priority 7: Swap out a pokemon
  Priority 8: Special for pursuit when used on a swapping Pokemon
  Priority 9: Using an item
  Priority 10: Running from a wild battle, immediately ends the battle
   */
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