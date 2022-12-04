import 'dart:math';

import 'package:collectgame/battle/battle_state.dart';
import 'package:collectgame/data/move/move.dart';

import '../data/ability/ability.dart';
import '../data/prng.dart';
import '../data/species/creature_type.dart';
import '../data/species/stat.dart';
import 'battler.dart';

typedef EffectSuccessModifier = bool Function(BattleState battleState,
    Battler battler, BattleEffect effect, Move move, bool successful);

typedef EffectInflictCheck = bool Function(
    BattleState battleState, Battler battler, Battler? source, Move? move);

typedef EffectEndOfTurn = void Function(
    BattleState battleState, Battler battler, BattleEffect effect);
typedef EffectPersistCheck = bool Function(
    BattleState battleState, Battler battler, BattleEffect effect);

typedef EffectInfliction = bool Function(
    BattleState battleState, Battler target, Battler? source);

// Effects/statuses that affect a single battler
enum Effect {
  poison(
      onInflict: _poisonOnInflict,
      endOfTurn: _poisonEndOfTurn,
      canAffect:
          _poisonCanAffect), // Param = 0 if normal, turns badly poisoned otherwise
  paralysis,
  burn,
  freeze,
  sleep, // Param = turns asleep
  confusion(volatile: true), // Param = turns confused
  protect(
    volatile: true,
    successModifierDefend: _protectSuccessModifierDefend,
    persists: _commonAlwaysRemove,
  ), // Param = turns in a row protect/detect was used
  lastMoveFailed(volatile: true),
  tookDamageThisTurn(volatile: true),
  movedThisTurn(volatile: true),
  flinched(
      volatile: true,
      persists: _commonAlwaysRemove,
      successModifierAttack: _flinchSuccessModifierAttack);

  const Effect({
    this.volatile = false,
    this.successModifierAttack,
    this.successModifierDefend,
    this.endOfTurn,
    this.onInflict,
    this.persists,
    this.canAffect,
  });

  final bool volatile;
  final EffectSuccessModifier? successModifierAttack; // TODO
  final EffectSuccessModifier? successModifierDefend; // TODO
  final EffectEndOfTurn? endOfTurn; // TODO
  final EffectInfliction? onInflict;

  final EffectInflictCheck? canAffect;

  final EffectPersistCheck? persists;
}

class BattleEffect {
  BattleEffect(this.effect, this.param);

  final Effect effect;
  int param;
}

void _commonDecrementEndOfTurn(
    BattleState state, Battler subject, BattleEffect effect) {
  effect.param--;
}

bool _commonAlwaysRemove(
        BattleState state, Battler subject, BattleEffect effect) =>
    false;

bool _commonRemoveIfZero(
    BattleState state, Battler subject, BattleEffect effect) {
  return effect.param > 0;
}

bool _poisonCanAffect(
    BattleState state, Battler target, Battler? source, Move? move) {
  final corrosive = source?.effectiveAbility == Ability.abilities['corrosion'];
  final typeImmune = target.effectiveTypes.contains(CreatureType.steel) ||
      target.effectiveTypes.contains(CreatureType.poison);
  if (typeImmune && !corrosive) {
    return false;
  }
  if (target.individual.statusCondition != null) {
    return false;
  }
  return true;
}

bool _poisonOnInflict(BattleState state, Battler target, Battler? source) {
  final corrosive = source?.effectiveAbility == Ability.abilities['corrosion'];
  final typeImmune = target.effectiveTypes.contains(CreatureType.steel) ||
      target.effectiveTypes.contains(CreatureType.poison);
  if (typeImmune && !corrosive) {
    return false;
  }
  if (target.individual.statusCondition != null) {
    return false;
  }
  target.individual.statusCondition = Effect.poison;
  state.log("$target was poisoned!");
  return true;
}

void _poisonEndOfTurn(BattleState state, Battler subject, BattleEffect effect) {
  // TODO check for poison cure, etc.
  final damage = subject.calcStat(Stat.hp) ~/ 8;
  subject.individual.hp -= damage;
  state.log("$subject took poison damage.");
}

bool _protectSuccessModifierDefend(BattleState state, Battler defender,
    BattleEffect _, Move move, bool success) {
  if (move.flags.contains(MoveFlag.protect)) {
    state.log('$defender protected itself!');
    return false;
  }
  return success;
}

bool _protectOnInflict(BattleState state, Battler target, Battler? source) {
  final protected = target.currentEffect(Effect.protect);
  final turns = min(3, protected?.param ?? 0);
  final chance = pow(2, turns) as int;
  return PRNG.instance.upto(chance) == 0;
}

bool _flinchSuccessModifierAttack(
    BattleState state, Battler attacker, BattleEffect _, Move __, bool ___) {
  state.log('$attacker flinched!');
  return false;
}
