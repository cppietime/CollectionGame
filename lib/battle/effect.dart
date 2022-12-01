import 'package:collectgame/battle/battle_state.dart';
import 'package:collectgame/data/move/move.dart';

import 'battler.dart';

typedef EffectSuccessModifier = bool Function(BattleState battleState, Battler battler, BattleEffect effect, Move move, bool successful);
typedef EffectEndOfTurn = void Function(BattleState battleState, Battler battler, BattleEffect effect);
typedef EffectInfliction = bool Function(BattleState battleState, Battler target, Battler? source);

// Effects/statuses that affect a single battler
enum Effect {
  poison, // Param = 0 if normal, turns badly poisoned otherwise
  paralysis,
  burn,
  freeze,
  sleep, // Param = turns asleep
  confusion(volatile: true), // Param = turns confused
  protect(volatile: true), // Param = turns in a row protect/detect was used
  lastMoveFailed(volatile: true),
  tookDamageThisTurn(volatile: true),
  movedThisTurn(volatile: true);

  const Effect({this.volatile = false, this.successModifier, this.endOfTurn, this.onInflict});

  final bool volatile;
  final EffectSuccessModifier? successModifier; // TODO
  final EffectEndOfTurn? endOfTurn; // TODO
  final EffectInfliction? onInflict;
}

class BattleEffect {
  BattleEffect(this.effect, this.param);
  final Effect effect;
  int param;
}
