import 'package:collectgame/battle/battle_player.dart';
import 'package:collectgame/battle/battle_state.dart';
import 'package:collectgame/data/prng.dart';

import '../data/move/move.dart';
import 'battle_action.dart';
import 'battler.dart';

// Decides which moves an AI player uses
abstract class BattleAi {
  BattleAction decide(BattleState state, Battler mine, BattlePlayer me);
}

// Chooses moves at random, never uses items or swaps out.
class RandomBattleAi extends BattleAi {
  @override
  BattleAction decide(BattleState state, Battler mine, BattlePlayer me) {
    List<Move> candidates = [];
    final moves = mine.availableMoves;
    for (int i = 0; i < 4; i++) {
      if (moves[i] != null && mine.individual.movePP[i] > 0) {
        candidates.add(moves[i]!);
      }
    }
    final move =
        candidates.isEmpty ? Move.struggle : PRNG.instance.choice(candidates);
    MoveTarget target;
    switch (move.targetType) {
      case TargetType.all:
      case TargetType.enemySide:
      case TargetType.allEnemies:
      case TargetType.adjacentEnemies:
        target = const MoveTarget(false, 0);
        break;
      case TargetType.self:
      case TargetType.allAllies:
      case TargetType.allySide:
      case TargetType.adjacentAllies:
        target = const MoveTarget(true, 0);
        break;
      case TargetType.oneAlly:
        final mySide = state.sideOf(mine);
        if (mySide.length == 1) {
          target = const MoveTarget(true, 0);
          break;
        }
        List<int> choices =
            mySide.keys.where((i) => mySide[i] != mine).toList();
        target = MoveTarget(true, PRNG.instance.choice(choices));
        break;
      case TargetType.oneEnemy:
        final enemySide = state.sideAgainst(mine);
        target = MoveTarget(false, PRNG.instance.upto(enemySide.length));
        break;
    }
    return BattleAction(
        BattleActionType.move, BattleActionAttackParam(move, target));
  }
}
