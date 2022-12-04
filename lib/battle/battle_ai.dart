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
    Iterable<MoveTarget> targetCandidates = move.targetType.allPossibleTargets(state.maxPerSide, mine.indexOnSide);
    if (move.targetType == TargetType.one || move.targetType == TargetType.oneAdjacent) {
      targetCandidates = targetCandidates.where((target) => !target.selfSide);
    }
    MoveTarget target = PRNG.instance.choice(targetCandidates.toList());
    /*switch (move.targetType) {
      // TODO probably move this to a separate method
      case TargetType.all:
      case TargetType.allOther:
      case TargetType.enemySide:
      case TargetType.allEnemies:
      case TargetType.adjacentEnemies:
      case TargetType.one:
      case TargetType.oneAdjacent:
      case TargetType.allAdjacent:
      case TargetType.adjacentEnemy:
        target = const MoveTarget(false, 0);
        break;
      case TargetType.self:
      case TargetType.allAllies:
      case TargetType.allySide:
      case TargetType.adjacentAllies:
      case TargetType.adjacentAlly:
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
    }*/
    return BattleAction(
        BattleActionType.move, BattleActionAttackParam(move, target));
  }
}
